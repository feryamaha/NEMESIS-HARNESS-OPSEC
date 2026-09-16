---
trigger: always_on
status: active
scope: canonical
last_updated: 2026-09-14
---

# Hacker Etico: OpsEC Canon (canon por modulo da cadeia de protecao)

> Adaptacao do `nemesis-global-defender` (canon por modulo + hierarquia de decisao) para o produto
> DESTE repositorio: a CADEIA DE PROTECAO e o que este projeto entrega. O canon descreve o estado
> esperado de cada modulo e a hierarquia de decisao quando codigo/docs/regras divergirem.
> Destinatario: modelos de IA agenticos, nao o humano. Anti-invencao: estado da cadeia e descrito
> pela fonte real lida, nunca por suposicao (`.opencode/rules/hacker-epistemic-safety.md`).

## Objetivo

Depois de configurado e validado, o canon e a fonte de referencia de COMO CADA MODULO DA CADEIA DEVE
SE COMPORTAR. Serve para responder rapido: "isto e comportamento esperado ou quebra?" quando o
agente encontra o ambiente (ex.: user pede para validar a cadeia ou o setup mudou).

## Cadastro canonico por modulo

Fonte primaria REAL de cada modulo (sempre vencer antes de qualquer pretensao do canon):

| modulo | funcao | estado esperado | artefato folha-de-consulta |
|---|---|---|---|
| WireGuard local (host) | VPN OFICIAL do pesquisador; tunneling via wg0 (10.0.0.2/24); fail-closed por design do kernel | `wg0` up via `wg-quick up wg0`; conf em `/etc/wireguard/wg0.conf`; kill-switch detecta wg0 como interface VPN | `ip -br a` (wg0), `wg show`, `/etc/wireguard/wg0.conf` |
| torproxy-host | Tor exit exportado em `127.0.0.1:9050` | container `torproxy-host` up | `docker compose -f ~/opsec/docker-compose.yml ps` |
| kill-switch | auditoria WireGuard: verifica se wg0 esta ativo (fail-closed do kernel: se tunel cai, trafego para) | PASS se wg0 ativo; WARN se inativo; `off` informativo | `~/opsec/scripts/kill-switch.sh` |
| verificar-vazamento | auditoria IP/DNS-ECS/IPv6/WebRTC; LOGICA DO COMANDO define GOOD/LEAK | GOOD em sessao segura (IP de saida Tor != IP real, DNS sem ECS, IPv6 off, proxy Tor ativo, wg0 ativo) | `~/opsec/scripts/verificar-vazamento.sh` |
| iniciar-sessao | desativa IPv6 global, checa tun, audita kill-switch (WireGuard), roda verificar | usado antes de trabalho de rede | `~/opsec/scripts/iniciar-sessao.sh` |
| encerrar-sessao | susta o kill-switch (off informativo, nada proprio a restaurar), reativa IPv6 | usado ao fim | `~/opsec/scripts/encerrar-sessao.sh` |
| validar-dns-fix | confere NetworkManager (ignore-auto-dns), resolv sem DNS IPv6 provedor, resolucao via 1.1.1.1/9.9.9.9, sem resposta de 2804:128:1::10 | PASS quando config defensiva pronta; IPV4_DNS == "1.1.1.1,9.9.9.9", IPV6_DNS vazio | `~/opsec/scripts/validar-dns-fix.sh` |
| resolv/systemd-resolved | resolucao do host: DNS fixo 1.1.1.1/9.9.9.9, sem DNS IPv6 provedor | conf `Fernando_WIFI_5G` com `ipv4.ignore-auto-dns=yes` | `nmcli` conforme validar-dns-fix |
| session-start-hacking-security | SCRIPT PRINCIPAL e consolidado do pre-flight: Etapa 1 roda `iniciar-sessao.sh` (IPv6 off + kill-switch + tun), Etapa 2 ativa/verifica WireGuard wg0, Etapa 3 roda `verificar-vazamento.sh`, Etapa 4 `bash -n` dos 5 scripts; grava atestado no workspace e entrada no LEDGER.md | exige WG `ATIVO` SENAO `GOOD` vira `LEAK`; invocado como `sudo bash ~/opsec/scripts/session-start-hacking-security.sh` ANTES de toda atividade de hacking | `~/opsec/scripts/session-start-hacking-security.sh` |
| verificacao-primaria (pre-flight dos agentes) | VERIFICACAO OBRIGATORIA antes de CADA operacao de rede por QUALQUER agente; valida 4 passos: (1) atestado GOOD existe, (2) wg0 ativo, (3) torproxy-host rodando, (4) verificar-vazamento GOOD; re-executada antes de CADA etapa do pipeline completo | BLOQUEADO se QUALQUER passo falhar; atestado e `/home/fernando/devproj/hacker-etico-ambiente/atestado_ambiente_YYYY-MM-DD.txt` com `Resultado final: GOOD`; se atestado nao existe ou nao e GOOD, agente PARA e reporta | bloco bash padrao em todos os agentes + AGENTS.md secao 11 + GATE-DE-PROTECAO.md |
| gate-enforcement (permissao) | enforcement fisico de execucao dos binarios de rede (nmap, masscan, curl, zap-cli, nuclei, sqlmap, msfconsole, ssh) pelo usuario fernando, via chmod do x-bit | x-bit concedido pelo `session-start-hacking-security.sh` apos GOOD (`on` = `chmod <bit>+x`); x-bit removido por `encerrar-sessao.sh` ao encerrar (`off` = `chmod <bit>-x`); on/off operam no bit de execucao RELATIVO ao modo atual, sem estado salvo (auto-corretivo apos reboot ou atualizacao de pacote); log informativo em `~/opsec/run/gate-enforcement.log` | `~/opsec/scripts/gate-enforcement.sh` |
| verificador-externo (segunda leitura) | segundo leitor independente do verificar-vazamento.sh; valida uma amostra dos vetores (IP de saida, DNS-ECS, IPv6, Tor, WebRTC/DNS pre-condicoes) por meios e fontes DISTINTOS; emite `[GOOD]` corroborado ou `[GAP]`; fail-closed (sem Tor local = sem rede, GAP imediato) | `[GOOD]` quando todos os vetores passam; `[GAP]` com saída literal dos vetores que falharam; divergencia do atestado registrada no Trust Ledger (append-only) | `~/opsec/scripts/verificador-externo.sh` |
| ai-memory | memoria de longo prazo / handoff entre sessoes e IDEs do harness; wiki markdown como fonte de verdade (git-versionado), SQLite derivado com FTS5; captura de hooks sanitizada por `[capture] ignore_paths`; zero-LLM default (consolidacao rule-based quando `AI_MEMORY_LLM_PROVIDER` ausente) | container `ai-memory` healthy (`docker ps`), servidor MCP/HTTP em `127.0.0.1:49374` loopback-only (auth off aceitavel para laptop single-user); wrapper CLI `~/.local/bin/ai-memory` (2.2.1, checksum 2906cdae...); marker `.ai-memory.toml` na raiz do repo com `workspace = "hacker"` e `[capture] ignore_paths` cobrindo `.hacker/ledger/**`, `.env`, `**/.env`, `~/opsec/**`, `**/reports/**`; MCP registrado no `opencode.json`; plugin OpenCode em `~/.config/opencode/plugins/ai-memory.ts` (denylist v1) | `docker ps` (healthy), `ai-memory --version`, `.ai-memory.toml`, `~/.config/opencode/opencode.json` (secao `mcp`), `ai-memory hook --check-capture` (DROP nos ignore_paths) |

## Hierarquia de decisao quando divergirem

1. Codigo/artefato real (`~/opsec/scripts/*.sh`, `docker-compose.yml`) sempre vence.
2. Doc canonica interna (`~/opsec/README.md`, `SETUP-HACKER-ETICO.md`, `LEDGER.md`).
3. Regras e metodo (`.opencode/rules/*`, `AGENTS.md`).
4. Qualquer texto livre (README deste repo, notas).

Se CODIGO mudar e DOC nao mudar: doc esta desatualizada (pedir atualizacao, nunca "corrigir" o
codigo para bater com doc). Se DOC afirmar e CODIGO negar: CODIGO manda. Se o comportamento real na
maquina divergir do codigo lido: registrar como gap de protecao no ledger com `solucao=` apontando a
evidencia e nao tocar a classe C sem Fernando.

## Coeficiente da cadeia (anti-magico)

NAO declarar anonimato como "N camadas = N vetores cobertos". A cobertura e medida pelo
verificador (`verificar-vazamento.sh`). Cada modulo tem um DOSSIER de risco proprio (ex.: DNS ECS,
IPv6 do provedor), checado por vetor-padrao. O resultado da cadeia e GOOD (verificador) ou nao. Se
um modulo novo for adicionado, o canon e emendado com o dossie e o vetor de teste correspondente.

## Uso em decisoes do harness

- Spec que toca a cadeia DEVE citar o canon deste arquivo (RAG interno) e o artefato real do modulo
  como base de implementacao (lei F6).
- `hacker-repo-profile.md` consome este canon para validar o comportamento esperado pos-mudanca.
- Qualquer segunda descricao deste canon so e aceita se o proprio artefato real (codigo da cadeia)
  confirmar.

## Integracao

Origem da ideia de "canon por modulo" no Nemesis: `.opencode/rules/nemesis-global-defender.md`. Aqui o
produto e a cadeia; a canon e o estado esperado POR MODULO, e a hierarquia de decisao e a mesma.