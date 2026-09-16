# SPEC_011: Correcao do session-start-hacking-security.sh + Remocao Docker + Teste Mock

> Referencia: ISSUE-009-teste-session-start-fora-de-escopo.md (decisoes de 2026-09-14)

## REQUEST

Corrigir o `session-start-hacking-security.sh` removendo a Etapa Docker (nao solicitada e com bug de sintaxe), restaurar o comportamento anterior a sessao 3 preservando a correcao de deteccao via ultima linha + exit code, apagar o `validar-session-start.sh` (nome enganoso, criado sem autorizacao) e criar um `teste-session-start.sh` que rode por padrao sem sudo/rede/efeito colateral via mock do gate script.

## CATEGORY

Bugfix + Refactor + Test

## PROBLEM

- `session-start-hacking-security.sh` contem Etapa Docker (linhas 60-154) com chamadas `pass()` e `info()` minusculas (linhas 78, 88, 97, 104, 122, 129, 132, 148, 151, 153), que falham silenciosamente por ser bash case-sensitive (so existem `PASS()`/`INFO()` maiusculas definidas no topo).
- A Etapa Docker nao foi solicitada e nao foi revisada; subir containers automaticamente no session-start e algo que deve entrar como issue propria se desejavel.
- Detecao de Tor nativo na porta 9050 (linhas 69-74, 83-92, 117-143) e parte da mesma mudanca nao autorizada.
- O `validar-session-start.sh` existe no disco (400 linhas) com nome enganoso ("validar" em vez de "teste"), foi criado e executado em modo real sem autorizacao (classe C).
- Nao existe teste funcional do session-start que rode por padrao sem efeitos colaterais.

## CONTEXT

### Arquivos afetados

- `~/opsec/scripts/session-start-hacking-security.sh` (MODIFY: remover linhas 60-154, manter Etapa 4 como Etapa 3)
- `~/opsec/scripts/verificar-vazamento.sh` (NO MODIFY: `_EXIT_CODE` e `exit "$_EXIT_CODE"` ja estao presentes e corretos, confirmados na leitura atual)
- `~/opsec/scripts/validar-session-start.sh` (DELETE apos leitura completa)
- `~/opsec/scripts/teste-session-start.sh` (CREATE: teste mock, novo)

### Comportamento atual do session-start (pos-leitura do disco, 253 linhas)

- **Linhas 1-13**: shebang, set, funcoes PASS/FAIL/WARN/INFO (maiusculas)
- **Linhas 15-27**: variaveis REPO, DATE, RESULTADO, SCRIPTS_DIR, COMPOSE_DIR
- **Linhas 30-33**: Etapa 1: iniciar-sessao.sh (manter)
- **Linhas 35-58**: Etapa 2: WireGuard wg0 (manter)
- **Linhas 60-154**: Etapa 3: Docker (REMOVER: gluetun up, deteccao Tor nativo, aguardar containers, resumo)
- **Linhas 156-160**: Etapa 4: verificar-vazamento.sh (renumerar para Etapa 3)
- **Linhas 162-174**: Etapa 5: bash -n sintaxe (renumerar para Etapa 4)
- **Linhas 176-201**: Logica de resultado (manter: ultima linha [GOOD]/[LEAK] + exit code + WG_RESULTADO)
- **Linhas 203-253**: Atestado e LEDGER (manter)

### Comportamento atual do verificar-vazamento.sh (pos-leitura do disco, 138 linhas)

- `_EXIT_CODE=0` definido na linha 121
- `_EXIT_CODE=1` atribuido em: IPv6 leak (linha 124), kill-switch inativo (linha 126), nenhuma camada ativa (linha 135)
- `exit "$_EXIT_CODE"` na linha 138
- Cenário do falso positivo original: TESTE 1 emite PASS "Cadeia ativa" (linha 129) quando Tor esta OK, mas se houver IPv6 leak ou kill-switch inativo, o `_EXIT_CODE` vai para 1 e o TESTE 5 emite FAIL. A logica atual ja cobre esse cenario via precedencia de `_EXIT_CODE != 0` (linhas 122-126) antes do check de IP_TOR/IP_PROXY.

### Padrao de mock (runner.sh da ISSUE-003)

- Variavel de ambiente `GATE_SCRIPT` aponta para script mock em `/tmp/`
- Mock emite saida identica ao script real (marcadores `[GOOD]`, `[LEAK]`, `[5] RESULTADO FINAL`)
- Sem sudo, sem rede, sem containers

### Fontes consultadas (RAG)

- Codigo real: `~/opsec/scripts/session-start-hacking-security.sh` (253 linhas, lido por completo)
- Codigo real: `~/opsec/scripts/verificar-vazamento.sh` (138 linhas, lido por completo)
- Codigo real: `~/opsec/scripts/validar-session-start.sh` (400 linhas, lido por completo)
- Padrao mock: `.hacker/scripts/runner.sh` (86 linhas, lido por completo)
- Issue: `.opencode/issues/ISSUE-009-teste-session-start-fora-de-escopo.md` (128 linhas, lido por completo)
- Regras: `.opencode/rules/hacker-repo-profile.md`, `.opencode/rules/hacker-epistemic-safety.md`

## REQUIREMENTS

### R1: Remover Etapa Docker do session-start (decisao 1 + 2 da ISSUE-009)

Remover de `~/opsec/scripts/session-start-hacking-security.sh`:
- Bloco da Etapa 3 Docker (linhas 60-154): verificacao .env, deteccao Tor nativo (`ss -tlnp`), `docker compose up -d gluetun`, `docker compose up -d tor-host`, aguardar containers (loops com `docker inspect`), resumo de containers.
- Nao remover nada alem deste bloco.

### R2: Renumerar etapas

Apos remocao da Etapa 3:
- Etapa 4 (verificar-vazamento) passa a ser Etapa 3.
- Etapa 5 (bash -n) passa a ser Etapa 4.
- A logica de resultado (definicao de GOOD/LEAK) continua apos as etapas, sem numeracao de etapa propria.

### R3: Manter logica de deteccao via ultima linha + exit code (decisao 3)

Manter inalterado o bloco de decisao de resultado (linhas 176-201 atuais):
- `ULTIMA_LINHA_RESULTADO` extraida do output do verificar-vazamento (grep de `[GOOD]`/`[LEAK]`, tail -1)
- Decisao por exit code (`$VERIFICAR_EXIT -ne 0`), depois por `ULTIMA_LINHA_RESULTADO` contendo `[GOOD]` ou `[LEAK]`
- Checagem adicional de `WG_RESULTADO == ATIVO` como condicao para GOOD
- Nao reintroduzir `grep -q "[GOOD]"` generico.

### R4: Manter `_EXIT_CODE`/`exit` no verificar-vazamento.sh (decisao 4)

Nao alterar `~/opsec/scripts/verificar-vazamento.sh`. O `_EXIT_CODE` e `exit "$_EXIT_CODE"` ja estao presentes (linhas 121 e 138) e refletem corretamente GOOD/LEAK em todos os cenarios:
- `_EXIT_CODE=0` quando Tor OK + IPv6 off + kill-switch OK
- `_EXIT_CODE=1` quando IPv6 leak, kill-switch inativo, ou nenhuma camada ativa

### R5: Apagar validar-session-start.sh (decisao 5, item a)

1. Ler por completo o arquivo (ja feito: 400 linhas)
2. Registrar o que foi descartado (validacao: existencia de Docker, fases 0-6, 25 PASS mockados)
3. Deletar `~/opsec/scripts/validar-session-start.sh`
4. Confirmar que nao existe mais no disco

### R6: Criar teste-session-start.sh (decisao 5, item b)

Criar `~/opsec/scripts/teste-session-start.sh`:
- **Modo padrao (mock)**: roda sem sudo, sem rede, sem subir container
  - Variavel de ambiente `SESSION_START_MOCK=1` (ou `GATE_SCRIPT` apontando para mock, como no runner.sh)
  - Mock do `verificar-vazamento.sh` emita saida simulada com cenarios
  - Nao grava atestado nem LEDGER
- **Cenarios de teste**:
  - GOOD real: exit 0 + ultima linha [GOOD] + WG ATIVO -> resultado GOOD
  - LEAK real: exit 1 + ultima linha [LEAK] -> resultado LEAK
  - Falso positivo original: output contem [GOOD] em linhas intermediarias E [LEAK] na ultima linha -> resultado LEAK (prova que o bug antigo do grep generico nao existe mais)
  - LEAK com exit 0 mas ultima linha [LEAK]: resultado LEAK (edge case)
- **Modo real** (flag explicita): `--real` ou `MODE=real`
  - Requer sudo
  - Roda session-start de verdade
  - Grava atestado/LEDGER
  - So deve ser usado quando Fernando autorizar explicitamente
- **Verificacoes pós-execucao**:
  - grep -n que ZERO chamadas a `pass()`/`info()` minusculas restam em session-start-hacking-security.sh
  - grep -n que `grep -q "[GOOD]"` generico nao existe em session-start-hacking-security.sh
  - confirmacao de que `validar-session-start.sh` nao existe no disco
- **Exit codes**: 0 = todos os cenarios passaram, 1 = falha em ao menos um cenario

### R7: Nao alterar areas sensiveis alem do necessario

- Nao tocar em `~/opsec/scripts/iniciar-sessao.sh`, `encerrar-sessao.sh`, `kill-switch.sh`, `validar-dns-fix.sh`, `gate-enforcement.sh`
- Nao tocar em `~/opsec/docker-compose.yml`
- Operacao classe C (edicao de script de protecao): exigir confirmacao do Fernando ANTES de aplicar qualquer edicao em session-start-hacking-security.sh

## FILES INVOLVED

- `~/opsec/scripts/session-start-hacking-security.sh` (MODIFY: remover linhas 60-154, renumerar etapas)
- `~/opsec/scripts/validar-session-start.sh` (DELETE: apos leitura e registro)
- `~/opsec/scripts/teste-session-start.sh` (CREATE: teste mock)
- `~/opsec/scripts/verificar-vazamento.sh` (NO MODIFY: verificado e correto)

## RESTRICTIONS

- Regras do perfil do repo: bash scripts com `set -uo pipefail`, sem em-dash, sem primeira pessoa
- Areas sensiveis: session-start e script de protecao (classe C, F4)
- Nao subir containers, nao usar sudo, nao gravar atestado/LEDGER no modo padrao do teste
- Nao reintroduzir `grep -q "[GOOD]"` generico
- Nao reintroduzir chamadas `pass()`/`info()` minusculas
- Nao misturar "criar teste" com "implementar feature" (a remocao da Etapa Docker e feature separada do teste)

## EXPECTED DELIVERY

1. `session-start-hacking-security.sh`: 175-190 linhas (removidas ~80 linhas da Etapa Docker), sem Etapa Docker, etapas renumeradas, logica de resultado mantida
2. `validar-session-start.sh`: NAO EXISTE no disco (confirmado por `ls` e `test -f`)
3. `teste-session-start.sh`: ~120-150 linhas, roda sem sudo/rede por padrao, 4 cenarios de mock
4. `verificar-vazamento.sh`: inalterado

## VERIFICATION

```bash
# 1. Sintaxe dos scripts modificados/criados
bash -n ~/opsec/scripts/session-start-hacking-security.sh
bash -n ~/opsec/scripts/teste-session-start.sh

# 2. ZERO chamadas pass()/info() minusculas em session-start
grep -n 'pass "' ~/opsec/scripts/session-start-hacking-security.sh  # deve retornar vazio
grep -n 'info "' ~/opsec/scripts/session-start-hacking-security.sh  # deve retornar vazio

# 3. NENHUM grep -q "[GOOD]" generico em session-start
grep -n 'grep -q "\[GOOD\]"' ~/opsec/scripts/session-start-hacking-security.sh  # deve retornar vazio

# 4. validar-session-start.sh NAO existe
test -f ~/opsec/scripts/validar-session-start.sh && echo "FALHOU: ainda existe" || echo "PASS: removido"

# 5. Teste mock roda sem sudo
bash ~/opsec/scripts/teste-session-start.sh  # exit 0 = todos os cenarios passaram

# 6. verificar-vazamento.sh inalterado
bash -n ~/opsec/scripts/verificar-vazamento.sh
```
