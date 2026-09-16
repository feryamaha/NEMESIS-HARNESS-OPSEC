# Hacker-Etico-Ambiente

Ambiente de estudo e prática (PTES autorizado) com proteção de IP em camadas.

> **Uso ético obrigatório:** apenas testes autorizados, laboratórios próprios
> (HackTheBox, TryHackMe, DVWA, VulnHub) e pesquisas com escopo formal.
> Ferramentas de anonimato NÃO tornam atividade ilegal em legal.

## Estrutura

```
hacker-etico-ambiente/
├── AGENTS.md                    ← Documento canônico do agente (invariantes, leis F1..F12, mapa)
├── LEDGER.md                    ← Registro cronológico completo do que foi feito
├── opencode.json                ← Config do opencode (instructions: regras carregadas como instruções)
└── .opencode/
    ├── rules/                   ← 8 regras canônicas (documentation-style, epistemic-safety,
    │                                  fable-method, trust-ledger, repo-profile,
    │                                  pentest-harness-execution, harness-integrity, opsec-canon)
    ├── skills/                  ← 12 skills do SDD + meta-skill (SKILL.md por pasta, nome==pasta)
    ├── agents/                  ← 4 agentes opencode (orquestrador, implementador, revisor, documentador)
    ├── commands/                ← 3 comandos (pipelines auto/manual/redteam-hardening)
    ├── ledger/
    │   ├── trust-ledger.md      ← Ledger estruturado (append-only, 10 tipos de evento)
    │   └── modules/             ← Ledger por módulo da cadeia (criado quando módulo alterado)
    ├── rag/                     ← RAG de método: espelho Fable (15 skills) + orquestrador
    ├── specs/                   ← Especificações do pipeline SDD
    └── plans/                   ← Planos do pipeline SDD
    (o ambiente operacional vive em ~/opsec/)
```

## Os blocos do ambiente

| Bloco | Onde | Função |
|---|---|---|
| WireGuard local (host) | wg0 (10.0.0.2/24) | Camada 1 — VPN oficial do pesquisador |
| Docker + Compose | sistema | Base do sandbox |
| Tor (dperson/torproxy) | container torproxy-host | Camada 2 — anonimato |
| Kill-switch WireGuard | ~/opsec/scripts/kill-switch.sh | Auditoria fail-closed do wg0 |
| Verificador de vazamento | ~/opsec/scripts/verificar-vazamento.sh | Auditoria IP/DNS/IPv6/WebRTC |
| Segunda leitura | ~/opsec/scripts/verificador-externo.sh | Corroboracao independente do verificador (SPEC_006) |
| Sessao segura | iniciar-sessao.sh / encerrar-sessao.sh | IPv6 off + kill-switch + checagem |

## Como usar (resumo)
1. `sudo bash ~/opsec/scripts/session-start-hacking-security.sh`: script PRINCIPAL, ativa WireGuard (wg0), sobe container torproxy-host, IPv6 off, kill-switch, valida vazamentos (verificar-vazamento.sh), gera atestado e grava no LEDGER
2. Proxy Tor p/ browser/scripts: `socks5h://127.0.0.1:9050`
3. Ao terminar: `bash ~/opsec/scripts/encerrar-sessao.sh`

Detalhes em `~/opsec/README.md`.

## Harness de desenvolvimento (SDD)

O método SDD (Specification-Driven Development) do Nemesis Defender foi copiado e adaptado como
harness de desenvolvimento deste repo, na estrutura da TUI do opencode (`.opencode/`). O
pipeline orquestra o ciclo completo de alterações no projeto:
spec → análise crítica → regras → planos → implementação → testes → doc-sync → finalização.

Modos disponíveis (comandos do opencode):
- **Auto** (default): pipeline 100% autônomo até a PARADA ÚNICA ao fim da doc-sync (`/hacker-sdd-pipeline-auto`)
- **Manual**: cada skill bloqueia para aprovação explícita (`/hacker-sdd-pipeline-manual`)
- **Red Team da cadeia**: audita os vetores de proteção, busca novos vetores, registra ciclo-redteam (`/hacker-redteam-hardening-pipeline`)

Invariantes do agente (resumo): cadeia de proteção validada ANTES de qualquer ação de rede;
git = Fernando; sudo/auth = Fernando; provar com evidência (nunca supor); usar o ledger para
registrar decisões imediatamente.

Detalhes completos em `AGENTS.md` e `.opencode/rules/`.

## Harness Hacker (operacional)

O harness hacker orquestra exercicios de pentest, scraping, red team e blue team em
laboratorios autorizados, com **gate de protecao obrigatório** antes de qualquer
acao de rede.

```
.hacker/
├── gate/          ← Dark-Moon: verificar-vazamento.sh GOOD antes de rede
├── orquestrador/  ← Supervisor (ScreenBog + Decepticon)
├── agentes/       ← contratos: red-team, blue-team, pentest, scraping
├── memoria/       ← 3 camadas: conhecimento/grafo, sessao, integridade (Memory Guard)
├── ledger/        ← append-only, SHA-256 por entrada, sem IP real
├── rag/           ← conhecimento (OWASP, MITRE, canon interno)
└── templates/     ← operacao, contrato de handoff, relatorio
```

Invariantes: cadeia de protecao validada ANTES de acao de rede; sem IP real
em relatorios; uso etico (lab autorizado); escopo definido pelo Fernando.

Destilado de: ScreenBog (RAG), Decepticon (orquestrador), Dark-Moon (gate),
llmitm_v2/PentestGPT/pentestagent (memoria+ledger), OWASP Memory Guard (integridade).
Detalhes completos em `.hacker/README.md`.