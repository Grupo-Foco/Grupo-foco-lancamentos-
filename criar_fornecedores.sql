-- Tabela de fornecedores — Grupo Foco
CREATE TABLE IF NOT EXISTS fornecedores (
  id         BIGSERIAL PRIMARY KEY,
  nome       TEXT NOT NULL,
  cnpj       TEXT,
  criado_em  TIMESTAMPTZ DEFAULT NOW()
);

-- Índice para busca rápida por nome
CREATE INDEX IF NOT EXISTS idx_fornecedores_nome ON fornecedores (nome);

-- Permissões públicas (igual às demais tabelas)
ALTER TABLE fornecedores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public_all" ON fornecedores FOR ALL USING (true) WITH CHECK (true);

-- Popular com fornecedores já existentes nos lançamentos
INSERT INTO fornecedores (nome)
SELECT DISTINCT UPPER(fornecedor)
FROM lancamentos
WHERE fornecedor IS NOT NULL AND fornecedor <> ''
ON CONFLICT DO NOTHING;
