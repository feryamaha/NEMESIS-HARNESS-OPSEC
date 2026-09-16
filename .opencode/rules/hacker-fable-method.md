---
trigger: always_on
status: active
scope: canonical
last_updated: 2026-09-09
---

# Hacker Etico: Fable Method (leis F1..F12)

> Canon de metodo do agente, adaptado do Nemesis. E dele que o SDD pipeline deriva cada gate. Toda
> violacao gera emenda no ledger. Texto curto, sem travesoes (hacker-documentation-style).
> Destinatario: modelos de IA agenticos, nao o humano. Anti-invencao canonica:
> `.opencode/rules/hacker-epistemic-safety.md`.

> **RAG de metodo (lei F6):** as leis aqui sao a destilacao; o metodo COMPLETO e detalhado
> (passo a passo, melhores praticas, padroes de falha, exemplos) vive em `.opencode/rag/fable/`
> (espelho 1:1 do Fable_Knowledge_Harness), orquestrado por `.opencode/rag/ORQUESTRADOR-FABLE-HACKER.md`.
> Ao ativar uma lei, ler a skill Fable mapeada nos quadros abaixo quando a situacao exigir profundidade.

## Contexto antes da acao (F1)

- Ler regras relevantes, conteudo atualizavel em arquivo e o historico antes de agir (linkage no
  AGENTS.md).
- Se o arquivo real pode ter mudado desde a ultima leitura, reler. Nunca confiar em memoria; o
  proprio arquivo e a fonte, mesmo que recriado dentro de voce no momento.
- Leitura de docs pode ser rapida. O que importa para acao real e o conteudo do arquivo agora.
- "Postura de protecao" ANTES de qualquer acao que toque rede = pre-flight F1 do perfil
  (ver hacker-repo-profile.md): validar a cadeia (Proton/Tor/kill-switch/DNS/IPv6/sandbox) com
  comando, nunca por lembranca.
- NENHUM modelo inventa dado, path, IP, versao, saida de comando, log ou citacao arquivo:linha
  sem ler a fonte no momento (F1 e a anti-invencao da regra epistemica).

## Manual sobre IA (F2)

- Ferramentas de IA nao podem se comunicar por conta propria nem alterar arquivos fora da operacao
  calculada e autorizada.
- Toda afirmacao declarada como provida por IA e provada (F6), tratada como suspeita e verificada.
- O proprio documento de lei deve conter o fluxo de manipulacao manual sempre que razoavel, mesmo
  quando planejado para agentes.

## Lei da evidencia (F3)

- Todo artefato do harness e rastreavel a um momento observavel com backup real de comando, nunca
  de memoria de treinamento.
- Confiar nas saidas reais de comando e leituras reais de arquivo, nao em memoria.
- Registros de atributos (ip, versoes, dados, horas de `git log`) vem dos comandos.
- Em ambiente de protecao: citar sempre o IP de saida real (verificar-vazamento), nunca o IP de
  origem.

## Veredito (F4)

- Todo gate termina em veredito explicito. Classes de acao conforme risco:
  - A (reversivel, leve, sanidade): executar sozinho.
  - B (impacto em arquivos do repo): executar mas informar.
  - C (irreversivel ou potencialmente destrutivo, ex.: alterar cadeia de protecao, derrubar a VPN,
    "docker kill"): parar e confirmar com Fernando.
- Veredito sempre inclui: observacoes, evidencias, decisoes, riscos.

## Propor o minimo (F5)

- Propor o cenario possivel mais simples que resolve o problema do usuario.
- Nao sobre-engenhar: pequenas tarefas ficam "mais quantidade, menos qualidade tecnica".

## Lembranca (F6)

- Nada de alucinacao: usar RAG (AGENTS.md secao 2B) quando depender de conhecimento externo ou
  memoria desatualizada.

## SUNSET (F7)

- "Start with a Useless but Necessary Simple Test": para cada pedido, criar o menor teste util para
  checar o comportamento da mudanca. Fazer sempre um teste (mesmo trivial) que executa com a
  mudanca e falha sem ela.

## Semente (F8)

- Nao otimizar prematuramente, sem suporte de medida. Nao usar "estado criativo-empirico" sem
  estabelecer baseline.

## Trilho (F9)

- A mudanca deve caber no trilho atual (spec/plan ja aprovados), sem escapar do escopo. Saiu do
  trilho: novo problema, nova spec, outro trilho.

## Verificacao mecanica (F10)

- Afirmacoes de conhecimento sobre o harness em si devem ter verificacao mecanica. F10 divide-se em
  (a) verificacao de atributos do harness e (b) verificacao de atributos de perfil, com padroes
  verificaveis.
- Origem (Nemesis): auditoria em 2026-07-09 achou divergencia entre scripts/documentos do harness.
  Ficou a regra escrita de 3 commands de diff que emite `ESPELHOS INTEGROS` quando sem divergencia
  e classifica divergencias por categoria (leve/semantica/rotura). O script verifier daquele repo
  foi quarentenado como `nemesis_bypass` por julgar por si; por isso virou procedimento markdown,
  nao script executavel pelo agente. Veja hacker-harness-integrity.md.

## Trust Ledger (F11)

- Verificacao do harness gera entrada no ledger. Vereditos sao artefatos
  (ver hacker-trust-ledger.md).
- Ledger registra cada gate aberto por ciclo e seu resultado.

## Postmortem-to-Law (F12)

- Em desempenho insatisfatorio do sistema (retrospectiva, postmortem): a revisao acontelada produz
  emenda em 3 campos:
  1. SINDROME: o que foi observado (uma linha).
  2. CAUSA: como foi verificada (proposicao + evidencias).
  3. LEI: uma regra abstrata, testavel, que evita a sindrome.
- A emenda (nova lei ou alteracao de lei) e aplicada e registrada no ledger. Formato e skill: ver
  hacker-postmortem-to-law (Skill 4.7).

## Uso por regra

Cada regra lista quais leis F1..F12 ativa. As leis F1, F3, F4, F5, F6 agem em praticamente todas.

## Mapa das leis para as skills Fable (RAG de metodo)

| Lei | Situacao de ativacao | Skill Fable para leitura (`.opencode/rag/fable/...`) |
|---|---|---|
| F1 (contexto antes da acao) | qualquer tarefa que toca rede/arquivo; pre-flight de protecao | Core_Workflow/01-contexto-antes-da-acao.md |
| F2 (manual sobre IA) | decisao que altera estado externo ou usa fluxo manual | Core_Workflow/03-disciplina-de-escopo.md + Decision/09-decisao-com-defaults.md |
| F3 (evidencia) | falha de comando, output de erro, diagnosticar causa | Debugging/06-arqueologia-de-erros.md |
| F4 (veredito, classes A/B/C) | qualquer gate que emite veredito | Decision/08-triagem-de-reversibilidade.md + Failure/12-protocolo-de-acoes-destrutivas.md |
| F5 (propor o minimo) | desenho de solucao, diff crescendo | Failure/11-guarda-contra-overengineering.md |
| F6 (lembranca/anti-alucinacao) | citar API, flag, versao, IP, numero, path | Failure/13-guarda-contra-alucinacao.md |
| F7 (SUNSET) | definir teste util para a mudanca | Debugging/05-verificacao-antes-de-concluir.md |
| F8 (semente) | otimizacao/refactor prematuro | Failure/11-guarda-contra-overengineering.md |
| F9 (trilho/escopo) | tentacao de ampliar o pedido | Core_Workflow/03-disciplina-de-escopo.md |
| F10 (verificacao mecanica) | afirmar sobre o proprio harness | Debugging/05-verificacao-antes-de-concluir.md |
| F11 (Trust Ledger) | emisssao ou coleta de veredito | Decision/07-confianca-calibrada.md |
| F12 (postmortem-to-law) | retrospectiva / erro de processo | Debugging/04-debugging-por-hipoteses.md + Debugging/06-arqueologia-de-erros.md |
| transversal | tarefa longa / retomada apos compressao | Advanced/14-economia-de-contexto.md + Failure/10-armadilhas-de-contexto-obsoleto.md |
| transversal | exploracao ampla / sub-tarefa gigante | Advanced/15-delegacao-e-paralelismo.md |