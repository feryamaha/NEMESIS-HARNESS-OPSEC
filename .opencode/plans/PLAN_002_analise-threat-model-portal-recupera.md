# PLAN_002: Analise de threat model do portal Recupera

- data: 2026-09-08
- ciclo: PLAN_002
- status: PROSSEGUIR (P1)
- categoria: Docs (artefato de planejamento, sem mudanca de codigo)

## REQUEST

Fernando solicitou a conversao da SPEC_002 em um plano de implementacao com
tarefas atomicas (2-5 min cada) para auditoria de surface de ataque do portal
`https://fmf.recupera.com.br/RecuperaPortal2/login`, focado em AppSec e
pentest de APIs em ecossistema financeiro.

## CATEGORY

Docs: planejamento de auditoria conceitual, sem alteracao de scripts,
containers, rede nem config da cadeia de protecao.

## PROBLEM

- Converter analise de threat modeling em plano de acoes verificaveis
  dentro do ambiente hacker-etico-ambiente.
- Respeitar invariantes de seguranca: nao tocar `~/opsec/`, cadeia de
  protecao, containers, rede sem postura GOOD verificada.
- Entregar tarefas autonomas com comandos de verificacao de perfil.

## CONTEXT

- Alvo: portal de login da integracao SIA + sistemas de cobranca terceirizados.
- Tres focos de analise (da SPEC_002):
  1. Mecanica de autenticao CPF/codigo de acesso.
  2. Riscos IDOR/BOLA em endpoints pos-login.
  3. Vetor de fraude em callbacks/webhooks de pagamento.
- Orbitas do harness aplicaveis:
  - hacker-repo-profile.md: areas sensiveis com flag opsec_sensitive.
  - hacker-opsec-canon.md: estado esperado de cada modulo da cadeia.
  - AGENTS.md invariantes 1, 6, 8, 11.

## TASKS ATOMicas

### T1: Validar syntaxe e atributos da SPEC_002
- Verificar ausencia de em/en-dash no texto
- Confirmar zero IP literal (fora URLs citadas)
- Confirmar ausencia de primeira pessoa
- Ferramentas: conferencia visual de ausencia de travesao; `grep -rl '1[0-9][0-9]\.[0-9][0-9][0-9]\.[0-9][0-9][0-9]\.[0-9][0-9][0-9]' .opencode/specs/SPEC_002_*.md`

### T2: Registrar veredito no Trust Ledger
- Registrar entrada de spec creation no Trust Ledger
- Formato: `[data] | ciclo=SPEC_002 | skill=hacker-specification-design | evento=spec-created | resultado=PASS | base=arquivo presente e atributos validados`

### T3: Criar PLAN_002 a partir da SPEC_002
- Converter especulacao em tarefas atomicas com paths exatos
- Mapear classes CWE e superficies de verificacao
- Incluir condicoes de execucao (escopo formal + autorizacao no trust-ledger)

### T4: Verificacao de postura de protecao (F1 pre-flight)
- Rodar `bash ~/opsec/scripts/verificar-vazamento.sh`
- Registrar resultado (GOOD ou BLOCKED) antes de qualquer acao de rede

### T5: Documentar findings conceituais por hipotese
- Hipotese 1 (CWE-287/307/203): Broken Authentication via CPF/codigo de acesso
  - Superficie: ausencia de rate limiting, retorno de perfil completo so com CPF
  - Teste conceptual: analisar se backend expoe dados financeiros com APENAS CPF
- Hipotese 2 (CWE-639): IDOR/BOLA em endpoints pos-login
  - Superficie: parametro alunoId/boleto nao validado contra sessao do usuario
  - Teste conceptual: verificar se requisicao com outro alunoId retorna dados terceiros
- Hipotese 3 (CWE-345/354): Forja de callback/webhook de pagamento
  - Superficie: validacao falha do lado do servidor em status de pagamento
  - Teste conceptual: mapear fluxo de callback e validacao de integridade

## FILES INVOLVED

- `.opencode/specs/SPEC_002_analise-threat-model-portal-recupera.md` (espec original)
- `.opencode/plans/PLAN_002_analise-threat-model-portal-recupera.md` (plano gerado)
- `.opencode/ledger/trust-ledger.md` (registro de eventos do ciclo)

## RESTRICTIONS

- Sem execucao de vetor contra `fmf.recupera.com.br` neste plano.
- Sem IP real de origem, credenciais ou PII de terceiros no artefato.
- Sem travesao (em dash/en dash) e sem primeira pessoa no texto.
- Plan de Docs: nao toca `~/opsec/`, cadeia de protecao, containers, rede nem `.env`.
- Respeitar disciplina epistemica: tarefas declaradas como analise conceitual;
  nenhuma afirmacao de vulnerabilidade sem evidencia observada.

## EXPECTED DELIVERY

- Arquivo `.opencode/plans/PLAN_002_analise-threat-model-portal-recupera.md`
  gravado, contendo REQUEST, TASKS ATOMicas, superficies de verificacao e limites.
- Verificacao por atributo:
  - `ls .opencode/plans/PLAN_002_analise-threat-model-portal-recupera.md` (arquivo presente);
  - `grep -n '\xC2\x80\x94\|\xC2\x80\x93' .opencode/plans/PLAN_002_*.md` (zero em/en dash);
  - `grep -rl '1[0-9][0-9]\.[0-9][0-9][0-9]\.[0-9][0-9][0-9]\.[0-9][0-9][0-9]'
    .opencode/plans/PLAN_002_*.md` (zero IP literal, fora de URL citada).
- Veredito P1: PROSSEGUIR (documentado no trust-ledger).