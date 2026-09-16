---
name: hacker-critical-analysis
description: Analise critica de propostas (specs). Ativa sempre que uma spec de mudanca e gerada (Skill 1) e antes de execucao (Skill 3). Emite veredito P1 e P2 com gate duplo. Como parte do fluxo subagent-driven, a revisao P2 e feita por subagente independiente do autor.
---

# SKILL: Análise Crítica de Proposta

## Contexto

O objetivo do pipeline SDD e desenhar mudancas pequenas, cirurgicas e verificadas antes de qualquer
codificacao. A analise critica existe para a mudanca pequena continuar pequena: detecta excesso de
escopo antes que ele vire uma mudanca enorme. Nao features, nao premature, nao viagem.

A analise e feita de cabe sulizio que o agente quer prosseguir: o proprio modelo pode querer a
feature ou ficar seduzido por ela. Ha real conflito de interesses aqui e o metodo resolve isso
separando o revisor do autor (subagente independiente, ver hacker-subagent-driven-development).

## Ligações

- AGENTS.md: invariantes 2, 2A, 2B, 8
- `.opencode/rules/hacker-fable-method.md`: leis F1, F2, F3, F4, F5, F6, F8, F9
- `.opencode/rules/hacker-epistemic-safety.md`
- `.opencode/rules/hacker-repo-profile.md`: postura de protecao pre-flight F1

## Processo

### Entrada (spur)

Fontes: (1) issue novo do usuario, (2) impulsos de melhoria continua do pipeline, (3) spur de
execucao. Spur acumulados no Playlist ou Issue Research.

### Gate de entrada

Spur presente e sem duplicidade com specs/plans existentes.

### Build da spec

1. **RAG de conhecimento externo (Skill 1.5)** - consultar doc oficial da tecnologia afetada
   (WireGuard, ProtonVPN, Tor, gluetun, Docker, systemd-resolved, DNS, IPv6, ferramentas de pentest) e doc
   canonica interna (`~/opsec/README.md`, `SETUP-HACKER-ETICO.md`, `LEDGER.md`,
   `.opencode/rules/hacker-opsec-canon.md`). O conteudo atual (nunca memoria) orienta a spec.
2. **Auditoria de alcance** - spec pequena: no maximo 1-2 arquivos, nada de novo recurso.
3. **ADVERSARIA** - verificar se a mudanca pode quebrar a cadeia de protecao (wg0/WireGuard, proton0, Tor,
   kill-switch, DNS, IPv6, sandbox).
4. **Resultado** - spec em `.opencode/specs/<ticket>.md`.

### Ponto 1: Analise Critica da spec (gate duplo, autor)

1. **Isso resolve o problema que o usuario tem?** - o problema atual, espelhado na spec. Nao
   "programacao em geral".
2. **Isso e minimo?** - menor cobertura que resolve.
3. **Arquivos em perigo?** - mudanca tocando arquivos fora de `~/opsec/scripts/`, `.opencode/`,
   `LEDGER.md` e `README.md`: REJEITAR (pedir confirmacao do usuario).
4. **Circunscrito e respeitoso?** - tom objetivo, sem lecture no PR nem criticism pessoal.

Veredito P1: PROSSEGUIR / REJEITAR / AMBIGUA. Se AMBIGUA, perguntar ao usuario com opcoes.

### Ponto 2: Analise Critica da spec (gate duplo, subagente revisor independiente)

1. **Impacto na cadeia de servicos** - lista os servicos tocados (WireGuard host, Proton VPN host, gluetun, Tor,
   kali-sandbox, kill-switch, DNS) e o impacto esperado. A postura de protecao pre-flight e
   CONFIRMADA aqui: sem verificar-vazamento GOOD e sem P2.
2. **Arquivos em perigo (hard block)** - nenhuma spec pode alterar: `.env`, credenciais, segredos.
   Se tocar `.env`: REJEITAR sem negociacao.
3. **Red team involuntario** - a mudanca nao pode ter efeito colateral que exponha IP de origem
   ou degrade a cadeia.
4. **Grounding (F6)** - decisões apoiadas nas fontes consultadas (RAG). Spec que toca tecnologia
   externa sem citar fonte = AMBIGUA.
5. **Escala** - sem mudanca de escopo; se a spec sai do trilho (F9), REJEITAR para nova spec.

Veredito P2: PROSSEGUIR / REJEITAR / AMBIGUA.

## Restricoes principais

- Atropelar gate so por decisao explicita do usuario; o agente nao mata o gate por conta propria.
- [RESTRICAO] Agente alterou spec sem permissao explicita do usuario depois de escrita = BLOQUEADO.
- [RESTRICAO] Spec para codigo-fonte que nao foi lido via RAG (somente memoria) = BLOQUEADO.
- O veredito P2 sai do subagente revisor independiente, nao do autor.

## Texto

Sem travessao (em dash) em texto de saida (hacker-documentation-style).