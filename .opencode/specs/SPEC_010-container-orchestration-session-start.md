# SPEC_010: Orquestracao de Containers Docker no session-start-hacking-security.sh

> **STATUS: RASCUNHO (aguarda analise critica P1)**
> **ISSUE referência**: ISSUE-010

## REQUEST

Reimplementar a subida dos containers gluetun e torproxy-host dentro do
session-start-hacking-security.sh, de forma correta (sem o bug de
case-sensitivity da ISSUE-009), com timeout e tratamento de erro, para que o
harness volte a ser utilizavel para hacking/pentest/scraping real.

## CATEGORY

Feature (restauracao de funcionalidade removida na ISSUE-009)

## PROBLEM

- Apos a remocao da Etapa Docker na ISSUE-009, nada no pipeline sobe os
  containers gluetun/torproxy-host
- verificar-vazamento.sh depende de Tor ativo na porta 9050 (fornecido por
  torproxy-host) para retornar GOOD
- Sem containers rodando, verificar-vazamento.sh sempre retorna LEAK
- gate-enforcement.sh so libera +x com GOOD real, entao nenhuma ferramenta de
  rede fica disponivel
- Resultado: harness inutilizavel para hacking/pentest/scraping real, sem
  risco de exposicao (fail-closed mantido)

## CONTEXT

**Arquivos afetados:**
- `~/opsec/scripts/session-start-hacking-security.sh` (MODIFY, area sensivel)
- `~/opsec/scripts/teste-session-start.sh` (MODIFY)
- `~/opsec/README.md` (MODIFY)
- `hacker-etico-ambiente/README.md` (MODIFY)

**Codigo real lido (RAG interno):**
- `~/opsec/docker-compose.yml`: 4 servicos (gluetun, tor-host, tor-on-vpn,
  kali). gluetun precisa de OPENVPN_USER/OPENVPN_PASSWORD do .env.
  torproxy-host expoe 127.0.0.1:9050. tor-on-vpn depende de gluetun
  (network_mode: service:gluetun).
- `~/opsec/scripts/session-start-hacking-security.sh` (160 linhas): Etapa 1
  (iniciar-sessao.sh) -> Etapa 2 (WireGuard) -> Etapa 3
  (verificar-vazamento.sh) -> Etapa 4 (syntax check). SEM etapa Docker.
- `~/opsec/scripts/verificar-vazamento.sh` (138 linhas): TESTE 1 tenta
  conexao Tor via `curl -s4 -x socks5h://127.0.0.1:9050`. TESTE 5 emite
  `[GOOD]` ou `[LEAK]` como ultima linha. Exit code 0 = GOOD, 1 = LEAK.
- `~/opsec/scripts/gate-enforcement.sh` (70 linhas): `on()` so e chamado por
  session-start quando RESULTADO=GOOD. Libera +x em nmap, masscan, curl, etc.
- `~/opsec/scripts/teste-session-start.sh` (344 linhas): 4 cenarios mockados
  (GOOD sem WG, LEAK real, falso positivo, LEAK com exit 0). SEM cenarios de
  container.
- `~/opsec/README.md`: documenta `docker compose up -d --build` como passo
  manual separado do session-start.

**Fontes externas consultadas:**
- Docker Compose CLI: `docker compose up -d <service>` sobe servicos
  especificados com dependencias automaticas
- gluetun docs: container requer NET_ADMIN + /dev/net/tun; .env com
  OPENVPN_USER/OPENVPN_PASSWORD; status healthy quando tun up
- dperson/torproxy: container simples, expoe 9050, sem dependencias externas

**Assumpcoes documentadas:**
- O .env com credenciais Proton ja existe em ~/opsec/.env (preenchido pelo
  Fernando). Se nao existir ou estiver vazio, gluetun nao conecta, mas
  torproxy-host sobe normalmente na porta 9050
- Docker e docker compose ja estao instalados no ambiente
- O Fernando executa session-start com sudo (ja e o caso atual)

## REQUIREMENTS

### R1: Nova Etapa Docker (entre Etapa 2 e Etapa 3)

Inserir entre WireGuard (Etapa 2) e verificar-vazamento (Etapa 3):

1. Verificar se docker e docker compose estao disponiveis (`docker compose
   version`)
2. Verificar se docker-compose.yml existe em ~/opsec/
3. Subir servicos gluetun e tor-host via `docker compose up -d gluetun
   tor-host` (o docker-compose resolve dependencias automaticamente; tor-host
   sobe independente, gluetun precisa de .env)
4. Aguardar que torproxy-host esteja respondendo na porta 9050 (loop com
   timeout de 120 segundos, checando `ss -tlnp sport = :9050` ou
   `curl -s --max-time 3 -x socks5h://127.0.0.1:9050 http://httpbin.org/ip`)
5. Se timeout: WARN (nao FAIL) e continuar. verificar-vazamento.sh detectara
   LEAK e o fluxo continuara corretamente
6. Se docker ausente: WARN e continuar (cenario de host sem Docker)

### R2: Funcoes de log corretas

Todas as chamadas devem usar PASS(), FAIL(), WARN(), INFO() maiusculas
-consistente com o resto do script. ZERO chamadas a pass()/info() minusculas.

### R3: Tratamento de erro do docker compose

- Exit code do `docker compose up` deve ser capturado
- Se falhar: WARN com mensagem descritiva, nao travar o script
- Se .env ausente: INFO informativo (gluetun pode nao conectar, mas
  torproxy-host funciona normalmente)

### R4: Nao quebrar fluxo existente

- As 4 etapas existentes devem continuar funcionando igual
- A Etapa Docker e INSERIDA, nao substitui nada
- Se containers ja estao rodando: `docker compose up -d` e idempotente
  (nao derruba nada)

### R5: teste-session-start.sh atualizado

Adicionar 2 novos cenarios mockados (sem sudo, sem Docker real):

- **Cenario 5: Containers OK** - mock de docker compose up + torproxy
  respondendo na porta 9050 -> caminho para GOOD (se WG tambem OK)
- **Cenario 6: Containers timeout** - mock de docker compose up mas torproxy
  nao responde -> WARN no session-start, LEAK no verificar-vazamento

Manter os 4 cenarios existentes (1-4) inalterados.

### R6: Documentacao atualizada

- `~/opsec/README.md`: secao "Uso rapido" refletir que session-start agora
  sobe containers automaticamente. Remover `docker compose up -d --build` como
  passo manual obrigatorio (manter como nota para setup inicial)
- `hacker-etico-ambiente/README.md`: secao "Como usar" refletir fluxo atualizado

## FILES INVOLVED

- `~/opsec/scripts/session-start-hacking-security.sh` (MODIFY, area sensivel,
  classe C)
- `~/opsec/scripts/teste-session-start.sh` (MODIFY)
- `~/opsec/README.md` (MODIFY)
- `hacker-etico-ambiente/README.md` (MODIFY)

## RESTRICTIONS

- Regras 1-6 do perfil do repo (linguagem bash, toolchain bash -n/shellcheck,
  areas sensiveis classe C, escopo ~/opsec/ + .opencode/, git = Fernando,
  sem credenciais em docs)
- Nao alterar verificar-vazamento.sh (ja funcional, detecta Tor na porta 9050)
- Nao alterar gate-enforcement.sh (ja funcional, fail-closed)
- Nao alterar docker-compose.yml (ja funcional)
- Nao gravar IP real, credenciais ou PII em nenhum documento
- Diff completo apresentado a Fernando ANTES de qualquer edicao (classe C)
- Nenhuma execucao de rede, sudo ou docker sem confirmacao explicita

## EXPECTED DELIVERY

1. session-start-hacking-security.sh com Etapa Docker entre Etapa 2 e 3
2. ZERO chamadas pass()/info() minusculas (confirmado por grep)
3. ZERO `grep -q "[GOOD]"` generico (confirmado por grep)
4. teste-session-start.sh com 6 cenarios (4 existentes + 2 novos)
5. Todos os 6 cenarios PASS no modo mock
6. bash -n nos scripts modificados: PASS
7. README.md e ~/opsec/README.md atualizados
8. Gate-enforcement continua fail-closed (evidencia: `on()` so chamado quando
   RESULTADO=GOOD no session-start, linhas 96 do script atual)

## VERIFICATION

```bash
# 1. Sintaxe
bash -n ~/opsec/scripts/session-start-hacking-security.sh
bash -n ~/opsec/scripts/teste-session-start.sh

# 2. ZERO pass()/info() minusculas
grep -n 'pass "\|info "' ~/opsec/scripts/session-start-hacking-security.sh | grep -v 'PASS\|FAIL\|WARN\|INFO' | wc -l
# Esperado: 0

# 3. ZERO grep -q [GOOD] generico
grep -n 'grep -q "\[GOOD\]"' ~/opsec/scripts/session-start-hacking-security.sh | wc -l
# Esperado: 0

# 4. Etapa Docker presente
grep -n "docker compose" ~/opsec/scripts/session-start-hacking-security.sh
# Esperado: ao menos 1 ocorrencia

# 5. Teste mockado
bash ~/opsec/scripts/teste-session-start.sh
# Esperado: TODOS OS TESTES PASSARAM (exit 0)

# 6. gate-enforcement fail-closed (evidencia)
grep -n "gate-enforcement.sh" ~/opsec/scripts/session-start-hacking-security.sh
# Esperado: so na linha dentro do bloco RESULTADO=GOOD
```
