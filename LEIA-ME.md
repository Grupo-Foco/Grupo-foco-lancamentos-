# Logo na aba fixada — padrão igual ao da Fazenda Santa Rita

## Por que o Grupo Foco não aparecia
Os ícones do Grupo Foco apontavam para a pasta `icons/`, que nunca foi publicada
(dava 404). A Santa Rita (que funciona) tem os ícones na RAIZ e usa apple-touch-icon
+ rel=icon 192/512 — sem mask-icon. Copiei exatamente esse padrão.

## Como instalar (igual você fez na Santa Rita)
1. Suba os 9 arquivos `icon-*.png` na **RAIZ** do repositório (NÃO em pasta icons/).
2. Suba os 7 HTML e o `manifest.json` (substituindo os atuais).
3. No Safari: feche a aba fixada antiga, feche e reabra o Safari, e **fixe de novo**.

Pode apagar do repositório (opcional, não atrapalham): favicon.ico, favicon-16.png,
favicon-32.png, apple-touch-icon.png, safari-pinned-tab.svg e a pasta icons/ — não são
mais usados neste padrão.

## Para o Foco Logística
Mesmo processo: ícones `icon-*.png` na raiz + este bloco no <head> de cada página +
manifest apontando para a raiz. Se a logo for diferente, me manda que eu gero os ícones.
