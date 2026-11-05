-- ============================================================
-- AUDITORIA DE LANÇAMENTOS — Grupo Foco
-- Registra automaticamente toda inclusão, edição e exclusão de
-- lançamentos (quem, quando, o quê mudou). Rodar UMA vez no
-- SQL Editor do Supabase. É idempotente (pode rodar de novo sem erro).
-- ============================================================

-- 1) Coluna que carrega o usuário logado em cada alteração (o app envia)
alter table public.lancamentos add column if not exists alterado_por text;

-- 2) Tabela da trilha de auditoria
create table if not exists public.lanc_auditoria (
  id            bigint generated always as identity primary key,
  lancamento_id bigint,
  acao          text,                       -- INSERT / UPDATE / DELETE
  usuario       text,                       -- quem fez (nome do login)
  quando        timestamptz not null default now(),
  fornecedor    text,                       -- snapshot p/ referência (mesmo após exclusão)
  valor         numeric,
  vencimento    date,
  mudancas      jsonb                        -- {campo: {de, para}} no UPDATE; snapshot no INSERT/DELETE
);
create index if not exists idx_aud_lanc   on public.lanc_auditoria(lancamento_id);
create index if not exists idx_aud_quando on public.lanc_auditoria(quando desc);
create index if not exists idx_aud_user   on public.lanc_auditoria(usuario);

-- 3) Função do gatilho — compara OLD x NEW e grava o que mudou
create or replace function public.fn_lanc_auditoria()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user   text;
  v_mud    jsonb := '{}'::jsonb;
  v_campos text[] := array['fornecedor','documento','solicitante','data_doc','vencimento',
                           'pagamento','status','valor','conta','correntista','fazenda',
                           'cg','historico','forma_pagamento','safra','cultura','cnpj'];
  c   text;
  joa jsonb;
  jna jsonb;
begin
  if (tg_op = 'DELETE') then
    insert into public.lanc_auditoria(lancamento_id, acao, usuario, fornecedor, valor, vencimento, mudancas)
    values (old.id, 'DELETE', coalesce(old.alterado_por,'—'), old.fornecedor, old.valor, old.vencimento,
            jsonb_build_object('status', old.status, 'valor', old.valor, 'vencimento', old.vencimento));
    return old;

  elsif (tg_op = 'INSERT') then
    insert into public.lanc_auditoria(lancamento_id, acao, usuario, fornecedor, valor, vencimento, mudancas)
    values (new.id, 'INSERT', coalesce(new.alterado_por,'—'), new.fornecedor, new.valor, new.vencimento,
            jsonb_build_object('status', new.status, 'valor', new.valor, 'vencimento', new.vencimento));
    return new;

  else -- UPDATE
    joa := to_jsonb(old); jna := to_jsonb(new);
    foreach c in array v_campos loop
      if (joa->>c) is distinct from (jna->>c) then
        v_mud := v_mud || jsonb_build_object(c, jsonb_build_object('de', joa->>c, 'para', jna->>c));
      end if;
    end loop;
    -- só registra se houve mudança real (ignora update que só carimbou alterado_por)
    if v_mud <> '{}'::jsonb then
      insert into public.lanc_auditoria(lancamento_id, acao, usuario, fornecedor, valor, vencimento, mudancas)
      values (new.id, 'UPDATE', coalesce(new.alterado_por,'—'), new.fornecedor, new.valor, new.vencimento, v_mud);
    end if;
    return new;
  end if;
end;
$$;

-- 4) Liga o gatilho na tabela de lançamentos
drop trigger if exists trg_lanc_auditoria on public.lancamentos;
create trigger trg_lanc_auditoria
  after insert or update or delete on public.lancamentos
  for each row execute function public.fn_lanc_auditoria();

-- 5) Segurança: todos podem LER a trilha; ninguém (via app/anon) pode
--    inserir/editar/apagar direto — só o gatilho (security definer) escreve.
alter table public.lanc_auditoria enable row level security;
drop policy if exists aud_select on public.lanc_auditoria;
create policy aud_select on public.lanc_auditoria for select using (true);
grant select on public.lanc_auditoria to anon, authenticated;

-- Pronto. A partir de agora toda alteração em lançamentos fica registrada.
-- Teste rápido: edite um lançamento no sistema e rode:
--   select quando, usuario, acao, lancamento_id, mudancas
--   from public.lanc_auditoria order by quando desc limit 20;
