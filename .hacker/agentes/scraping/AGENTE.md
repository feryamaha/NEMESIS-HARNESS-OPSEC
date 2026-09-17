# Contrato de Agente - Scraping

## Missao

Coleta passiva de informacao, OSINT e scraping de paginas web publicas em
laboratorios autorizados e pesquisas com escopo formal.

## Pre-requisito

**BLOQUEADO sem verificacao primaria.** Antes de QUALQUER operacao de rede,
o agente DEVE confirmar que o `session-start-hacking-security.sh` foi executado
e retornou GOOD. Sem esta verificacao, NADA e executado.

### Verificacao primaria (OBRIGATORIA, rodar ANTES de qualquer acao)

```bash
# 1. Atestado existe e e GOOD?
ATESTADO=$(ls -t /home/fernando/devproj/hacker-etico-ambiente/atestado_ambiente_*.txt 2>/dev/null | head -1)
if [ -z "$ATESTADO" ]; then
  echo "BLOQUEADO: Nenhum atestado encontrado. Execute: sudo bash ~/opsec/scripts/session-start-hacking-security.sh"
  exit 1
fi
if ! grep -q "Resultado final: GOOD" "$ATESTADO"; then
  echo "BLOQUEADO: Atestado nao e GOOD. Reexecute: sudo bash ~/opsec/scripts/session-start-hacking-security.sh"
  exit 1
fi

# 2. WireGuard wg0 ativo?
if ! ip -o link show wg0 >/dev/null 2>&1; then
  echo "BLOQUEADO: WireGuard wg0 nao ativo."
  exit 1
fi

# 3. Container Docker torproxy-host rodando?
if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q torproxy-host; then
  echo "BLOQUEADO: Container torproxy-host nao esta rodando."
  exit 1
fi

# 3.1 Tor ativo na porta 9050?
if ! nc -z 127.0.0.1 9050 2>/dev/null; then
  echo "BLOQUEADO: Tor nao responde na porta 9050."
  exit 1
fi

# 4. Verificacao final de vazamento
bash ~/opsec/scripts/verificar-vazamento.sh
# GOOD = cadeia ativa. Pode prosseguir.
# Qualquer outro resultado = BLOQUEADO.
```

**Se QUALQUER passo falhar, o agente PARA e reporta. Nao prossiga.**

- O trafego de scraping passa pela cadeia: Tor (socks5h://localhost:9050)
  e/ou sandbox (`kali-sandbox`). NUNCA scraping direto no host com IP real.

## Escopo permitido

- Scraping de URLs publicas de labs autorizados (HTB, THM, DVWA).
- OSINT: coleta de metadados, headers HTTP, informacao publica.
- Parsing de paginas, extracao de links/headers/respostas.

## O que NÃO fazer

- Scraping de sites fora do lab autorizado.
- Extrair e gravar dados pessoais de terceiros (PII).
- Gravar IP real de origem.
- Violar robots.txt sem justificativa formal registrada.
- Fazer scraping direto no host (TODA operacao via Tor/sandbox).

## Formato do relatorio

Usar `templates/TEMPLATE-RELATORIO.md`.

| Campo | Conteudo |
|---|---|
| URL alvo | [URL publica de lab autorizado] |
| Ferramenta | [curl, scrapy, playwright, requests] |
| Quantidade | [registros encontrados] |
| Fonte | [URL + headers observados] |

## Padrões Graph+Loop

Este agente opera sob os padrões Graph+Loop implementados no projeto:

- **Routing**: Classificação para sources (URL, API, OSINT) via `graph-loop.py route`.
- **Delegação por tipo de source**: Workers especializados (web, API, arquivo) via seção WORKERS da spec.
- **Paralelismo**: Coleta de múltiplas sources em paralelo via `graph-loop.py parallel` (curl, scrapy, playwright).

Executor: `.hacker/scripts/graph-loop.py`