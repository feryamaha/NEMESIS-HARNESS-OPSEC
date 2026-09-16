---
name: hacker-etico
description: Carrega o contexto completo do projeto hacker-etico-ambiente, ambiente de pentest etico com cadeia de protecao (WireGuard local + ProtonVPN + gluetun + torproxy + Kali sandbox + kill-switch + DNS fix + IPv6 off) em bash scripts, python3 e Docker/Compose. Use sempre que o usuario pedir qualquer coisa sobre o projeto: cadeia de protecao, scripts, docker-compose, postura de protecao, escopo de uso etico, e tambem para escrever documentacao, onboarding ou artigos sobre ele. Traz os fatos oficiais e os links canonicos.
---

# Hacker Etico Ambiente, Contexto Tecnico e Conceitual

Fontes canonicas (consultar quando precisar de detalhe atual ou mudanca recente):
- Scripts: `~/opsec/scripts/`
- Docker Compose: `~/opsec/docker-compose.yml`
- Documentacao tecnica: `~/opsec/README.md`
- Setup do ambiente: `~/opsec/SETUP-HACKER-ETICO.md`
- Ledger de operacoes: `LEDGER.md`
- Regra canônica: `.opencode/rules/hacker-opsec-canon.md`

Autor e mantenedor: Fernando.

## O que e

Ambiente de pentest etico com cadeia de protecao multicamada, escrito em bash scripts
e python3, com orquestracao via Docker/Compose. Nao e ferramenta de ataque; e infraestrutura
de seguranca operacional para realizacao de testes de penetracao em ambientes AUTORIZADOS.
Cada componente da cadeia tem funcao especifica e falha e fechada (fail-closed).

## Cadeia de protecao

A cadeia opera em `~/opsec/` e e composta por (em ordem de trafego):

1. **WireGuard local (host)**: VPN OFICIAL do pesquisador. Tunneling local via wg0 (10.0.0.2/24). Primeira camada de anonimizacao.
2. **Proton VPN (host)**: VPN externa adicional. App Proton conectado pelo Fernando; cria proton0; assume resolucao DNS quando conectada.
3. **gluetun (container)**: cliente VPN dentro de Docker que mantem o trafego do container tunelado.
4. **torproxy-host**: proxy Tor no host, roteando trafego pela rede Tor.
5. **torproxy-vpn**: proxy Tor dentro da cadeia de Docker, combinando VPN + Tor.
6. **Kali Sandbox (container)**: ambiente Kali isolado onde rodam os tools de pentest.
7. **kill-switch**: script que interrompe todo o trafego de rede se a VPN cair. Fail-closed:
   se a VPN desce, o trafego para.
8. **DNS fix**: correcao de DNS para evitar vazamento via resolucao local. Usa
   systemd-resolved ou configuracao manual.
9. **IPv6 off**: desabilitacao de IPv6 em toda a cadeia para evitar vazamento de endereco.

## Scripts principais

Localizados em `~/opsec/scripts/`:

- **session-start-hacking-security.sh**: SCRIPT PRINCIPAL e consolidado do pre-flight de hacking
  (lei F1). Integra Etapa 1 (iniciar-sessao.sh), Etapa 2 (ativa/verifica WireGuard wg0), Etapa 3
  (verificar-vazamento.sh) e Etapa 4 (bash -n dos 5 scripts); grava atestado no workspace e no
  LEDGER.md. GOOD so com WG ATIVO. Invocacao: `sudo bash ~/opsec/scripts/session-start-hacking-security.sh`
  ANTES de QUALQUER atividade de hacking. Area sensivel (classe C).
- **verificar-vazamento.sh**: verifica se a cadeia de protecao esta operacional. Retorna
  GOOD se tudo ok, resultado diferente se houver problema. Etapa 3 do session-start.
- **kill-switch.sh**: interrompe trafego de rede se VPN cair. Area sensivel (classe C).
- **iniciar-sessao.sh**: inicia a cadeia de protecao completa. Etapa 1 do session-start.
  Area sensivel (classe C).
- **encerrar-sessao.sh**: encerra a cadeia de protecao de forma segura. Area sensivel (classe C).
- **validar-dns-fix.sh**: valida se a correcao de DNS esta funcionando. Area sensivel (classe C).

Todos os scripts de protecao sao **areas sensíveis (classe C)** e exigem confirmacao do
Fernando para modificacao.

## Docker Compose

`~/opsec/docker-compose.yml` orquestra os containers da cadeia (gluetun, torproxy-vpn,
kali-sandbox, etc.). Arquivo com flag `opsec_sensitive` (classe C).

Comando de validacao: `docker compose -f ~/opsec/docker-compose.yml config`

## Stack tecnico

- **Bash scripts**: linguagem principal dos scripts de operacao e protecao
- **Python3**: scripts auxiliares e ferramentas de analise
- **Docker/Compose**: orquestracao de containers da cadeia de protecao
- **Markdown**: documentacao e especificacoes

Comandos de validacao por tipo de mudanca:
- Scripts: `bash -n <script>` + `shellcheck <script>` (quando disponivel)
- Python3: `python3 -m py_compile <arquivo>`
- Docker: `docker compose -f ~/opsec/docker-compose.yml config`
- Git: `git diff --check`

## Postura de protecao

**PRE-FLIGHT OBRIGATORIO (F1)**: antes de QUALQUER acao que toque rede:

```bash
bash ~/opsec/scripts/verificar-vazamento.sh
```

- **GOOD**: rede segura, pode prosseguir.
- **Qualquer outro resultado**: PARE. Nao toque rede. Reporte ao Fernando.

Esta regra e ABSOLUTA e NAO tem excecoes.

## Hierarquia RAG (Retrieval-Augmented Generation)

Fontes de conhecimento, onde divergirem o de cima manda:

1. **Codigo real** em `~/opsec/scripts/` e `~/opsec/docker-compose.yml` - fonte #1.
2. **Doc canonica do projeto**: `~/opsec/README.md`, `~/opsec/SETUP-HACKER-ETICO.md`,
   `LEDGER.md`, `.opencode/rules/hacker-opsec-canon.md`.
3. **Doc oficial externa**: WireGuard, ProtonVPN, Tor, dperson/torproxy, gluetun, Docker,
   systemd-resolved.
4. **RAG de metodo**: `.opencode/rag/fable/` (espelho 1:1 do Fable_Knowledge_Harness) +
   `.opencode/rag/ORQUESTRADOR-FABLE-HACKER.md` (indice RAG: situacao de hacking -> skill
   Fable a ler). O orquestrador e carregado nas instructions do opencode.json. O RAG nunca
   amplia a autoridade do modelo: AGENTS.md, as regras e o Fernando vencem sempre.
5. **Regras e metodo**: `.opencode/rules/hacker-repo-profile.md`,
   `.opencode/rules/hacker-fable-method.md`, `.opencode/rules/hacker-epistemic-safety.md`
   (anti-invencao: nenhum modelo inventa dado, path, IP, versao, saida; prove, nao suponha).

## Invariantes de seguranca

1. **Cadeia de protecao antes de agir**: `sudo bash ~/opsec/scripts/session-start-hacking-security.sh`
   (script principal: sessao segura + WireGuard + verificacao) obrigatorio antes de qualquer
   atividade de hacking; GOOD so com WG ATIVO.
2. **Git e do Fernando**: agente nunca executa git de escrita.
3. **Sudo/autenticacao so Fernando**: agente nunca usa sudo ou autenticacao.
4. **Provar nao supor**: IP de saida nunca e igual a IP real; nunca citar IP real em docs.
5. **Fail-closed**: qualquer falha na cadeia = parada, nao continuacao desprotegida.
6. **Escopo etico**: so ambientes AUTORIZADOS. Nunca usar contra alvos nao autorizados.

## Escopo de uso etico

Este projeto e usado EXCLUSIVAMENTE para:
- Testes de penetracao em ambientes AUTORIZADOS pelo proprietario
- Treinamento e educacao em seguranca ofensiva
- Pesquisa academica em seguranca da informacao

USO CONTRA ALVOS NAO AUTORIZADOS E ILEGAL E NAO E O PROPOSITO DESTE PROJETO.

## Erros de diagnostico a nao repetir

- afirmar que a rede esta segura sem executar verificar-vazamento.sh: era inferencia, nao fato;
- confundir container com host: o gluetun roda dentro do Docker, nao no host;
- assumir que IPv6 esta desabilitado sem verificar: sempre confirmar com comando.
Regra: provar, nao supor; distinguir host de container; nunca tratar decisao de design como
defeito acidental.
