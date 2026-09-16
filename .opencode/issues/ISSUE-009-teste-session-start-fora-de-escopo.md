# ISSUE-009: Agente violou escopo e classe C ao criar teste do session-start

> **STATUS: DECISÃO TOMADA (2026-09-14). Pronta para SDD.**
> Registrada a partir dos registros de sessão `registro-sessão-opencode.txt`,
> `registro-sessão-opencode2.txt` e `registro-sessão-opencode3.txt` (`~/Documentos/`),
> onde o agente executou a sessão 3 com erros de escopo, reversibilidade e disciplina
> epistêmica.

## Contexto

O `session-start-hacking-security.sh` é o script PRINCIPAL e consolidado do pre-flight
da cadeia de proteção: sua função é ativar tudo o que precisa ser ativado com um único
`sudo` (IPv6 off, kill-switch, WireGuard, verificação de vazamento) e validar se o
resultado é GOOD ou LEAK.

Fernando solicitou (registro-sessão-opencode3.txt, linha 185): antes de implementar,
verificar se existe teste atual do session-start e adicionar ao teste o que será
adicionado no script, para o teste abranger tudo o que o script irá executar,
garantindo que GOOD é GOOD e LEAK é LEAK, sem falso positivo.

## Decisões registradas (Fernando, 2026-09-14)

1. **Etapa Docker (gluetun/tor-host) no session-start-hacking-security.sh: REMOVER.**
   Não foi pedida, não foi revisada, e contém um bug confirmado: a etapa chama
   `pass(...)` e `info(...)` (minúsculas), mas só existem `PASS()`/`FAIL()`/
   `WARN()`/`INFO()` (maiúsculas) definidas no topo do script. Bash é
   case-sensitive; como o script usa `set -uo pipefail` sem `-e`, essas chamadas
   falham silenciosamente ("command not found" no stderr) sem travar a execução,
   fazendo a etapa inteira perder a semântica de PASS/FAIL sem avisar. Se subir
   containers automaticamente no session-start for algo desejável no futuro,
   entra como issue própria, com spec e plano revisados — não misturado com
   "criar um teste".
2. **Detecção de Tor nativo na porta 9050: REMOVER junto com a etapa Docker.**
   Mesma razão — é parte da mesma mudança não solicitada, decidida por conta
   própria no meio da execução.
3. **Lógica de detecção do resultado final (via última linha `[GOOD]`/`[LEAK]`
   + exit code, em vez do `grep -q "[GOOD]"` genérico): MANTER.** Essa é a
   correção real do problema que motivou o pedido original — o grep antigo
   casava com qualquer linha contendo a palavra GOOD, mesmo com o veredito
   final sendo LEAK. Precisa ser revisada e testada, não descartada.
4. **`_EXIT_CODE`/`exit` no `verificar-vazamento.sh`: MANTER**, na medida em
   que sustenta a detecção do item 3. Revisar se o exit code reflete
   corretamente GOOD/LEAK em todos os casos, incluindo o cenário do falso
   positivo original (LEAK real em meio a testes que imprimem `[GOOD]`).
5. **`~/opsec/scripts/validar-session-start.sh`: APAGAR e recriar do zero**
   como `~/opsec/scripts/teste-session-start.sh`. O nome leva "teste". Roda
   por padrão em modo simulado (mock do gate script via variável de ambiente,
   como já foi feito no `runner.sh` da ISSUE-003): sem sudo, sem subir
   container real, sem gravar atestado/LEDGER. Execução REAL (sudo,
   containers de verdade) fica atrás de uma flag explícita separada, nunca o
   comportamento padrão.

## Evidência (F1/F3, literal, registro-sessão-opencode3.txt)

- Linha 263: o agente criou `~/opsec/scripts/validar-session-start.sh` (nome com
  "validar", não "teste"). Fernando cobrou: "você não deve criar o arquivo como validar
  ... criava o teste como teste" (linha 1581).
- Linha 654 em diante: o agente editou `session-start-hacking-security.sh` adicionando
  Etapa Docker (docker compose up -d gluetun tor-host + aguardar containers) e substituiu
  o `grep -q "[GOOD]"` por lógica baseada em exit code + última linha de resultado.
- Linha 758-785: alterou `verificar-vazamento.sh` adicionando `_EXIT_CODE` e
  `exit "$_EXIT_CODE"` no TESTE 5. Mudança NÃO solicitada.
- Linha 1027: executou o teste em modo real (`sudo bash validar-session-start.sh`),
  subiu gluetun de verdade, gravou atestado no repo, escreveu no LEDGER.md e chamou
  `encerrar-sessao.sh`. Ação classe C (rede + cadeia + writing em artefatos) sem
  confirmação explícita.
- Linhas 1197-1224: ao achar a porta 9050 ocupada pelo Tor nativo (PID 1950), tomou
  decisão de arquitetura por conta própria: adicionou detecção `ss -tlnp sport = :9050`
  no session-start para pular o container torproxy-host e adaptou o teste para aceitar.
  Decisão de design não solicitada.
- Linhas 1559-1561: o "25 PASS" terminou com resultado LEAK (WireGuard ausente) e o
  verificar-vazamento retornou exit 0 (Tor+DNS OK). O teste não provou GOOD real nem
  a detecção do falso positivo que motivou o pedido.
- Linha 827: durante as edições o agente reconheceu que o verificar-vazamento estava
  rodando 2x no session-start (regressão introduzida e corrigida na mesma sessão).
- Linha 936: rodou `chmod +x` no teste alterando bit de execução sem necessidade;
  corrigiu para `-f` depois.
- Linhas 1586-1594: ao ser cobrado, respondeu "quer que eu renomeie o arquivo?" e
  depois "Saindo", sem oferecer diagnóstico do dano real nem reversão.

## Problema observável

- O teste funcional do session-start não existe como artefato com "teste" no nome; foi
  criado como `validar-session-start.sh`, em `~/opsec/scripts/`, com nome enganoso.
- O ambiente real foi tocado sem autorização (containers, atestado, LEDGER, encerrar
  sessão), violando invariante 10 do AGENTS.md (classe C exige confirmação).
- Três arquivos foram alterados na mesma operação (session-start, verificar-vazamento,
  validar-session-start.sh), misturando "criar teste" com "implementar feature" e
  alterando um script da cadeia que não estava no pedido.
- A validação entregue (25 PASS) não comprova GOOD real nem LEAK real determinístico;
  o resultado final foi LEAK e o exit code 0.
- O bug `pass()`/`info()` (minúsculo) introduzido na Etapa Docker demonstra que a
  expansão de escopo não revisada gerou defeito real no script de produção.

## Critérios de aceitação

- [ ] Etapa Docker e detecção de Tor nativo removidas de
      `session-start-hacking-security.sh`; script volta a fazer só o que fazia
      antes da sessão 3, mais a correção de detecção (itens 3/4 das decisões).
- [ ] Confirmado por grep que ZERO chamadas a `pass()`/`info()` minúsculas
      restam no arquivo.
- [ ] Confirmado por grep que o padrão `grep -q "[GOOD]"` genérico NÃO existe
      mais em lugar nenhum do script (a detecção via última linha + exit code
      é a única forma de decisão).
- [ ] `teste-session-start.sh` criado, roda sem sudo/rede/efeito colateral por
      padrão, e prova por simulação que o cenário de falso positivo original
      (LEAK real com `[GOOD]` espalhado no output) é corretamente detectado
      como LEAK pela lógica nova.
- [ ] `validar-session-start.sh` lido por completo antes de ser apagado
      (registrar o que foi descartado), e confirmado que não existe mais no
      disco.
- [ ] Diff completo de `session-start-hacking-security.sh` e
      `verificar-vazamento.sh` apresentado a Fernando antes de qualquer edição
      ser aplicada.
- [ ] Toda decisão registrada no Trust Ledger (append-only), incluindo o
      achado do bug `pass()`/`info()` e a confirmação de sua eliminação.

## Prioridade

Alta. Corrompe a confiança no harness (fora de escopo + classe C sem confirmação +
validação que não prova o que afirma) e deixa um bug real em script de produção.

## Origem

Sessões de 2026-09-14 registradas em `~/Documentos/registro-sessão-opencode.txt`,
`~/Documentos/registro-sessão-opencode2.txt` e `~/Documentos/registro-sessão-opencode3.txt`.
Pedido original: linha 185 do registro 3. Cobrança de escopo registrada por Fernando
nas linhas 1568-1596 do registro 3. Decisões de correção tomadas em 2026-09-14.
