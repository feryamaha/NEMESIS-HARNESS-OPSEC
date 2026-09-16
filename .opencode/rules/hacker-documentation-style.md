---
trigger: always_on
status: active
scope: canonical
last_updated: 2026-09-09
---

# Hacker Etico: Estilo de Documentacao

> Regra canonica e transversal para todo conteudo textual de documentacao deste repositorio (README,
> AGENTS.md, ledgers, specs, plans, PRs, artefatos MD voltados ao leitor).
> Destinatario: modelos de IA agenticos, nao o humano. Nunca inventar conteudo citado:
> qualquer fato citado em doc vem da fonte real (`.opencode/rules/hacker-epistemic-safety.md`).

## Regra 1: Sem travessao

Nao usar em dash (—) nem en dash (–) em nenhum texto, em qualquer idioma. Usar virgula, dois-pontos
ou parenteses no lugar. Para intervalos numericos, usar "1 a 3" em vez de "1–3".

## Regra 2: Sem primeira pessoa do singular

Nao usar "eu", "meu", "minha", "meus", "minhas" em textos de documentacao. Usar voz impessoal,
terceira pessoa ou estrutura passiva.
Exemplos:
- "Eu escolhi esse numero" -> "A escolha desse numero" ou "Esse numero foi escolhido"
- "Minha posicao" -> "a posicao do agente" ou "a postura observada"

## Regra 3: Texto minimo, maximo de imagens

Minificar a quantidade de texto dissertativo. Condensar paragrafos longos em bullets curtos ou
frases diretas quando possivel. Manter rastreabilidade tecnica (citacoes de arquivo-fonte) de forma
concisa.

## Regra 4: Nunca registre IP real / credencial / PII de terceiros

Nenhum documento, spec, ledger ou relatorio deste repo grava IP real de origem do pesquisador,
credenciais, tokens ou dados pessoais de terceiros. Quando um relatorio de vazamento exigir citar
IP, cite o IP de saida (WireGuard/Proton/Tor), nunca o real.

## Integracao

Aplique junto com: as invariantes de seguranca do AGENTS.md, a disciplina epistemica
(.opencode/rules/hacker-epistemic-safety.md) e o SDD pipeline.