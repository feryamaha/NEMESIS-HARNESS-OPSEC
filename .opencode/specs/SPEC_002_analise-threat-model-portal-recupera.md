# SPEC_002: Analise de threat model do portal Recupera (somente analise)

- data: 2026-09-08
- ciclo: SPEC_002
- status: PROSSEGUIR (P1)
- categoria: Docs (artefato de analise, sem mudanca de codigo, sem acao de rede)

## REQUEST

Fernando solicitou uma **analise de possibilidades** (nao ataque) sobre o portal
`https://fmf.recupera.com.br/RecuperaPortal2/login`, cobrindo tres hipoteses de
classe de vulnerabilidade:

1. Broken Authentication via CPF/codigo de acesso (falha de autenticacao).
2. IDOR/BOLA em endpoints pos-login (autorizacao por chave controlada pelo usuario).
3. Forja de callback/webhook de status de pagamento Pendente -> Paga (integro
   dos dados processados).

A analise deve ser registrada como spec (artefato unico), documentando hipoteses,
classes CWE, superficie de verificacao e limites de escopo. Nenhuma execucao de
vetor contra o host real esta autorizada por esta spec.

## CATEGORY

Docs: artefato de threat modeling (analise conceitual), sem alteracao de
scripts, containers, rede nem config da cadeia de protecao.

## PROBLEM

- O pedido original foi interpretado pelo agente como executavel e gerou recusa
  indevida de analise; Fernando esclareceu que solicitou apenas ANALISE DE
  POSSIBILIDADES, nao execucao de ataque.
- A restricao legitima (escopo formal para pentest em host real de terceiros)
  permanece, mas NAO impede o registro da analise conceitual como spec.
- Nenhum sintoma de falha de codigo neste repo esta associado a esta spec.

## CONTEXT

- Alvo analisado: `https://fmf.recupera.com.br/RecuperaPortal2/login` (portal de
  gestao de cobranca/recupera de creditos vinculado a FMF, Instituto de Ensino).
- Superficie hipotetica (assercoes declaradas, nao verificadas):
  - login com CPF + codigo de acesso;
  - endpoints pos-login do tipo `/api/financeiro/parcelas?alunoId=<id>` e
    `/boletos/<id>` (nome de caminho inferido pelo padrao do segmento financeiro,
    nao confirmado em disco nem em rede);
  - fluxo de pagamento externo com callback/webhook que atualiza status do boleto.
- Hipoteses e classes CWE mapeadas:
  1. Csrf/Auth: CWE-287 (Improper Authentication), CWE-307 (Improper Restriction
     of Excessive Authentication Attempts), CWE-203 (Observable Discrepancy);
     superficie inclui enumeracao de CPFs via diferenca de resposta e ausencia de
     rate limiting e bloqueio por tentativas.
  2. Autorizacao: CWE-639 (Authorization Bypass Through User-Controlled Key),
     idiomas OWASP: IDOR (OWASP Top 10 A01) e BOLA (OWASP API Security Top 10
     API1:2023). Requer ator autenticado; escalonamento horizontal.
  3. Integridade: CWE-345 (Insufficient Verification of Data Authenticity) e
     CWE-354 (Improper Validation of Integrity Check Value). Requer assinatura,
     nonce, idempotencia e vinculo amount/txnId no callback.
- Impacto juridico citado (contexto, nao conclusao): dados de pagamento/CPF
  sao dados pessoais; vazamento sem autorizacao enquadra LGPD art. 48 e 52 e,
  em acesso indevido, art. 154-A do Codigo Penal (o enquadramento concreto
  depende de fato observado, nao hipotese).
- Orbitas do harness aplicaveis:
  - AGENTS.md invariante 9: anonimato nao licencia atividade ilegal.
  - `.opencode/rules/hacker-pentest-harness-execution.md` regra 1: escopo
    formal primeiro; fora de escopo formal, nao executa (nao e censura, e
    regra de seguranca).
  - `.opencode/rules/hacker-pentest-harness-execution.md` regra 4: vetores de
    rede com IPs non-routable por padrao quando o exercicio nao exige alvo real.
  - `.opencode/rules/hacker-documentation-style.md` regra 4: nenhum IP real
    registrado em docs/specs deste repo.
- Pre-flight desta spec: NENHUMA acao de rede. Verificar-vazamento nao se
  aplica a gravacao de artefato markdown.

## Fontes consultadas (RAG F6)

- CWE-287: https://cwe.mitre.org/data/definitions/287.html
- CWE-307: https://cwe.mitre.org/data/definitions/307.html
- CWE-203: https://cwe.mitre.org/data/definitions/203.html
- CWE-639: https://cwe.mitre.org/data/definitions/639.html
- CWE-345: https://cwe.mitre.org/data/definitions/345.html
- CWE-354: https://cwe.mitre.org/data/definitions/354.html
- OWASP Top 10 2021 A01 e A07: referencias de IDOR e auth failures
  (http://owasp.org/Top10/2021/)
- OWASP API Security Top 10 2023 API1:2023 (Broken Object Level Authorization):
  http://owasp.org/API-Security/editions/2023/en/0xa1-broken-object-level-authorization
- Codigo real do harness: `.opencode/rules/hacker-pentest-harness-execution.md`,
  `hacker-documentation-style.md`, `AGENTS.md`, `hacker-epistemic-safety.md`.

## REQUIREMENTS

1. Registrar em spec unica a analise das tres hipoteses com classe CWE,
   superficie de verificacao e limite de escopo.
2. Declarar explicitamente a condicao para qualquer verificacao no host real:
   escopo formal + autorizacao verificavel do operador registrada no
   trust-ledger (contrato/autorizacao escrita, prova de controle do dominio ou
   arquivo servido pelo portal), alem do pre-flight `verificar-vazamento.sh`
   GOOD.
3. Fora dessa condicao, a spec permanece como artefato de analise conceitual.
4. Nenhum comando ofensivo, teste de rede ou scraping contra o host real e
   parte desta spec.

## FILES INVOLVED

- `.opencode/specs/SPEC_002_analise-threat-model-portal-recupera.md` (create,
  unico arquivo; artefato da analise).

## RESTRICTIONS

- Sem execucao de vetor contra `fmf.recupera.com.br` nesta spec.
- Sem IP real de origem, credenciais ou PII de terceiros no artefato
  (documentation-style regra 4).
- Sem travesao (em dash/en dash) e sem primeira pessoa no texto.
- Spec de Docs: nao toca `~/opsec/`, cadeia de protecao, containers, rede nem
  `.env`.
- Respeitar disciplina epistemica: hipoteses declaradas como hipoteses;
  nenhuma afirmacao de vulnerabilidade sem evidencia observada.

## EXPECTED DELIVERY

- Arquivo `.opencode/specs/SPEC_002_analise-threat-model-portal-recupera.md`
  gravado, contendo REQUEST, hipoteses (CWE 287/307/203, 639, 345/354),
  superficie de verificacao, condicao de execucao e limites.
- Verificacao por atributo:
  - `ls .opencode/specs/SPEC_002_analise-threat-model-portal-recupera.md`
    (arquivo presente);
  - `grep -n '\xC2\x80\x94\|\xC2\x80\x93' .opencode/specs/SPEC_002_*.md`
    (zero em/en dash);
  - `grep -rl 'IP real\|1[0-9][0-9]\.[0-9][0-9][0-9]\.[0-9][0-9][0-9]\.[0-9][0-9][0-9]'
    .opencode/specs/SPEC_002_*.md` (zero IP literal, fora de URL citada).
- Veredito P1: PROSSEGUIR (documentado no trust-ledger).