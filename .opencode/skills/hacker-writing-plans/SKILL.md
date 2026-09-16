---
name: hacker-writing-plans
description: >
  Converte especificacao aprovada em plano de implementacao com tarefas atomicas
  (2-5 min cada). Cada tarefa tem paths exatos, codigo completo na stack do perfil do repo
  e comando de verificacao do perfil.
---

# Hacker Writing Plans

Converter especificacao aprovada em plano de implementacao abrangente com tarefas atomicas.

> **Texto unico.** O comando de verificacao por tarefa e os paths vem do perfil do repo
> (`.opencode/rules/hacker-repo-profile.md`): scripts = `bash -n <script>` / `shellcheck <script>`;
> python3 = `python3 -m py_compile <arquivo>`; docker = `docker compose -f ~/opsec/docker-compose.yml config`.

**Anuncio de inicio**: "Estou usando a skill hacker-writing-plans para gerar o plano de implementacao."

**Pre-requisito**: Uma especificacao aprovada existe em `.opencode/specs/`.

## Processo

### Step 1: Carregar e Revisar Spec

Ler a especificacao aprovada. Identificar:
- O que deve ser construido (REQUEST/REQUIREMENTS)
- Quais arquivos serao afetados (FILES INVOLVED)
- Quais restricoes se aplicam (RESTRICTIONS)
- Quais sao os criterios de aceitacao (EXPECTED DELIVERY)

### Step 2: Ler Codigo Fonte Obrigatorio (lei F1)

**OBRIGATORIO**: Ler TODOS os arquivos listados na secao FILES INVOLVED da spec.
Nao gerar plano sem ter lido o codigo real (scripts, docker-compose.yml, arquivos a modificar).

### Step 3: Mapear Estrutura de Arquivos

Antes de definir tarefas, confirmar quais arquivos serao criados ou modificados:

```
CREATE: <path exato do arquivo novo>
MODIFY: <path exato do arquivo existente>
TEST:   <path exato do teste>
```

Cada arquivo tem uma responsabilidade clara. Arquivos que mudam juntos vivem juntos.

### Step 4: Decompor em Tarefas Atomicas

**Cada tarefa = 1 arquivo, 1 mudanca, 1 verificacao. Tempo: 2-5 minutos.**

Granularidade:
- Ler arquivo existente = um passo
- Analisar linha de mudanca = um passo
- Implementar mudanca = um passo
- Executar o comando de verificacao por tarefa do perfil = um passo

**Exemplo (perfil opsec):**
```
TASK 1: Adicionar novo vetor de verificacao em verificar-vazamento.sh
  FILE: ~/opsec/scripts/verificar-vazamento.sh (MODIFY)
  DEPENDE_DE: nenhuma
  VERIFICACAO: bash -n ~/opsec/scripts/verificar-vazamento.sh && shellcheck ~/opsec/scripts/verificar-vazamento.sh

TASK 2: Integrar chamada nova no bloco principal
  FILE: ~/opsec/scripts/verificar-vazamento.sh (MODIFY, secao de chamadas)
  DEPENDE_DE: TASK 1
  VERIFICACAO: bash -n ~/opsec/scripts/verificar-vazamento.sh

TASK 3: Atualizar docker-compose.yml com novo servico
  FILE: ~/opsec/docker-compose.yml (MODIFY)
  DEPENDE_DE: nenhuma
  VERIFICACAO: docker compose -f ~/opsec/docker-compose.yml config
```

**DEPENDE_DE (obrigatorio em toda tarefa):** lista das TASKs pre-requisito, ou `nenhuma`.
E dele que a `hacker-subagent-driven-development` deriva as waves de execucao paralela:
tarefas sem dependencia entre si E com arquivos disjuntos executam em paralelo. Declarar a
dependencia REAL (dado/funcao consumida), nao a ordem de escrita do plano; dependencia
inflada mata o paralelismo, dependencia omitida quebra a wave.

**Exemplo ruim**:
```
TASK 1: "Implementar tudo no novo script"   ← Muito grande
TASK 2: "TBD: adicionar testes depois"     ← Placeholder
TASK 3: "Similar a TASK 1"                 ← Referencia indireta
```

### Step 5: Escrever o Plano

**Header obrigatorio**:

```markdown
# [Nome da Feature] - Plano de Implementacao

> **Para agentes**: Use hacker-subagent-driven-development para executar este plano.

**Objetivo**: [Uma sentenca clara]

**Spec**: `.opencode/specs/SPEC_NNN_nome-descritivo.md`

**Arquivos Afetados**: [lista de arquivos, conforme o perfil]

**Arquitetura**: [2-3 sentencas sobre abordagem tecnica]

**Stack**: [bash, python3, Docker/Compose, conforme o perfil]

---
```

**Estrutura de tarefa (obrigatoria para TODA tarefa)**:

```markdown
## TASK N: [Descricao curta]

**Arquivo**: [caminho exato]

**Arquivos**:
- CREATE: `<path exato>`
- MODIFY: `<path exato>` (linhas XXX-YYY)
- TEST:   `<path exato>`

**Depende de**: [TASK N, TASK M | nenhuma]

**Verificacao**:
[comando de verificacao por tarefa do perfil]

**Descricao Detalhada**:
[O que fazer, contexto tecnico, padroes do perfil a seguir]

**Implementacao**:
[Codigo completo a ser escrito - NAO deixar placeholders]
```

### Step 6: Sem Placeholders

NUNCA escrever:
- "TBD", "TODO", "implementar depois", "fill in details"
- "Adicionar tratamento de erro apropriado" sem codigo real
- "Escrever testes para o acima" sem codigo de teste real
- "Similar a TASK N" - repetir o codigo, tarefas podem ser lidas fora de ordem

Cada tarefa deve ter:
- Codigo **completo** e **exato** na stack do perfil
- Comando de verificacao **exato** (com expected output)
- Assumpcoes **documentadas**

### Step 7: Auto-Review (checklist obrigatorio)

Checklist interno (reprovou em algum item = corrigir o plano antes de seguir):
- [ ] Todos os paths sao exatos e confirmados no disco?
- [ ] Codigo completo em cada tarefa? (sem placeholders)
- [ ] Cada tarefa tem o comando de verificacao do perfil?
- [ ] Ordem faz sentido? (tipos antes de funcoes, entrypoints antes de integracoes, testes
      por ultimo; a suposicao mais arriscada do plano e verificada nas PRIMEIRAS tarefas,
      nao nas ultimas)
- [ ] Toda tarefa declara DEPENDE_DE (real, nao inflado)? Tarefas paralelizaveis (mesma
      wave potencial) tem arquivos disjuntos?
- [ ] Nenhuma tarefa executa git write operations?
- [ ] Verificacao final inclui a suite completa do perfil? (bash -n + shellcheck + py_compile
      + docker compose config + git diff --check)
- [ ] Pre-flight de postura: `bash ~/opsec/scripts/verificar-vazamento.sh` GOOD antes de
      qualquer acao de rede declarada no plano?

**MODO AUTONOMO (default)**: nao ha aprovacao humana aqui. O gate do plano e a
`hacker-critical-analysis` (Ponto 2), invocada apos a gravacao (Step 8). Veredito
PROSSEGUIR = disparar a execucao sem pausa; REJEITAR = ajustar e re-analisar (1 ciclo);
segundo REJEITAR = parada de emergencia.

**MODO SUPERVISIONADO** (so quando o Fernando pedir): apresentar o plano e bloquear ate
aprovacao explicita ("sim", "pode", "aprovado", "ok", "prossiga", "execute").

### Step 8: Salvar Plano

Salvar em `.opencode/plans/`, nome `PLAN_NNN_nome-descritivo.md`, numero auto-increment
verificado com `ls` antes de gravar.

## Lembrar

- Ler codigo ANTES de gerar plano - obrigatorio
- Paths exatos SEMPRE
- Codigo completo em cada passo
- Comandos exatos com output esperado
- Regra canonica anti-invencao: `.opencode/rules/hacker-epistemic-safety.md`. Paths e comandos
  do plano existem de verdade no repo (verificar antes de escrever); nunca inventar comando.
- Tarefas atomicas, sequenciais, verificaveis
- Pre-flight de postura: verificar-vazamento.sh GOOD antes de acoes de rede
- Responder SEMPRE em PT-BR

## Integracao

**Skill anterior**: `pre-writing-rule-control`
**Proxima skill apos aprovacao**: `hacker-subagent-driven-development`
