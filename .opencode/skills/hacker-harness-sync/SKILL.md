---
name: hacker-harness-sync
description: >
  Verifica e reconcilia o harness (lei F10): roda o procedimento deterministico de
  hacker-harness-integrity.md, apresenta a divergencia arquivo a arquivo e reconcilia.
  Divergencia material tem HARD-GATE humano (o Fernando escolhe o canonico); copia
  comprovadamente antiga propaga-se a mais recente com reporte.
---

# Hacker Harness Sync (lei F10)

Verificar e reconciliar o harness deste repo: estrutura de `.opencode/` (agentes, commands,
regras, skills, ledger, rag, specs, plans, pr).

> **Texto unico.** O manifest e o procedimento de verificacao vivem em
> `.opencode/rules/hacker-harness-integrity.md` (fonte unica; nao duplicar aqui).

**Anuncio de inicio**: "Estou usando a skill hacker-harness-sync para verificar e reconciliar o harness."

## Quando invocar

- Apos qualquer edicao em arquivo de harness (mesma sessao).
- No gate F10 do finishing (Step 1.5) quando ha divergencia a reconciliar.
- Sob demanda do Fernando (auditoria periodica).

## Manifest do harness (repo unico)

Estrutura esperada em `.opencode/` (conforme doc oficial opencode.ai/docs e o manifest canônico
em `.opencode/rules/hacker-harness-integrity.md`):
- **4 agentes** em `.opencode/agents/`
- **3 commands** (pipelines) em `.opencode/commands/`
- **8 regras** em `.opencode/rules/`
- **13 skills** (pasta) em `.opencode/skills/`
- **Ledger**: `.opencode/ledger/trust-ledger.md`
- **RAG**: `.opencode/rag/` (+ espelho Fable com checagem propria via `build-rag.sh`)
- **Specs**: `.opencode/specs/`
- **Plans**: `.opencode/plans/`
- **PR**: `.opencode/pr/` (criado no finishing)

Citacoes literais de comandos que o harness referencia:
- `bash ~/opsec/scripts/verificar-vazamento.sh`
- `docker compose -f ~/opsec/docker-compose.yml config`
- `bash -n <script>`
- `git diff --check`

## Processo

### Step 1: Verificar (procedimento da regra canonica)

Executar o procedimento de `hacker-harness-integrity.md`: verificar que cada skill, regra,
workflow e arquivo listado no manifest existe fisicamente e contem o frontmatter correto.
Saida limpa = **HARNESS INTEGRO**: reportar e encerrar.

### Step 2: Classificar cada divergencia (com evidencia, nao suposicao)

Para cada arquivo divergente ou ausente:

1. **Ausencia simples** (existe no manifest, falta no disco): classificar como pendencia.
2. **Versao antigua comprovada**: uma copia e comprovadamente a versao anterior da outra
   (evidencia: conteudo e superconjunto com emendas datadas, frontmatter mais novo,
   git log do arquivo). Classificar como propagacao pendente.
3. **Divergencia material**: o conteudo do arquivo diverge do que o manifest declara
   (adaptacao local, emendas paralelas). Classificar como decisao humana.
4. **Item fora do manifest**: arquivo novo em `.opencode/` que nao e listado no manifest.
   Classificar como pendencia de manifest (ou entra no manifest, ou e removido).

**Categorias de divergencia:**
- **Leve**: metadados, frontmatter, formatacao (sem impacto semantico).
- **Semantica**: conteudo muda significado ou referencia (impacto funcional).
- **Rotura**: arquivo ausente ou referenciar skill/regra inexistente (quebra pipeline).

### Step 3: Reconciliar

- **Classes 1 e 2 (Leve/Semantica):** propagar a versao mais recente, listando cada copia
  feita. Reportar o que foi propagado e por que (evidencia da classe).
- **Classe 3 (Rotura/Semantica, HARD-GATE):** apresentar ao Fernando o diff das versoes
  com a analise em 1 linha por diferenca; BLOQUEAR ate ele escolher o canonico. So entao
  propagar.
- **Classe 4:** propor a atualizacao do manifest (em `hacker-harness-integrity.md`, arquivo
  do harness: a emenda segue o fluxo de emenda de lei, HARD-GATE humano) ou a remocao do
  arquivo. Nao decidir sozinho.

### Step 4: Re-verificar e registrar

1. Re-executar o procedimento do Step 1: precisa retornar **HARNESS INTEGRO**.
2. Registrar no Trust Ledger (`hacker-trust-ledger-update`, evento `harness`): resultado,
   arquivos reconciliados, decisoes do Fernando se houve.

## Formato de saida

```
## Harness Sync (F10)

Verificacao inicial: [HARNESS INTEGRO | DERIVA:<categoria> em N arquivos]

| Arquivo | Classe | Categoria | Acao |
|---|---|---|---|
| [path] | [1-4] | [leve|semantica|rotura] | [propagado | HARD-GATE | manifest] |

Re-verificacao: [HARNESS INTEGRO]
Ledger: [entrada gravada]
```

Resultado final: `HARNESS INTEGRO` ou `DERIVA:<categoria>`.

## Regras duras

- NUNCA "resolver" divergencia material escolhendo uma versao em silencio.
- NUNCA adaptar texto localmente (a parametrizacao e via perfil do repo).
- Propagacao e sempre por copia integral do arquivo canonico (nao merge manual criativo).
- Git e exclusivo do Fernando; esta skill so toca arquivos, nunca faz git de escrita.
- Sempre PT-BR.

## Integracao

**Regra canonica**: `.opencode/rules/hacker-harness-integrity.md` (manifest + procedimento).
**Regra anti-invencao**: `.opencode/rules/hacker-epistemic-safety.md` (veredito so com base
observavel; nunca fabricar diff, resultado de comando nem citacao).
**Invocada por**: gate F10 do `hacker-finishing-branch`, `hacker-doc-sync`,
`hacker-postmortem-to-law` (emendas), ou o Fernando.
**Skill relacionada**: `hacker-trust-ledger-update` (registro do resultado).
