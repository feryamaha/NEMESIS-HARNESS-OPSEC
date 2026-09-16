---
name: hacker-specification-design
description: >
  Converte request informal em especificacao tecnica estruturada para o projeto
  hacker-etico-ambiente (bash scripts, python3, Docker/Compose). Auto-ativa quando Fernando
  descreve uma necessidade. NUNCA escreva codigo antes do design ser validado. No modo
  autonomo (default) o gate da spec e a analise critica (Skill 0, Ponto 1); a spec e
  gravada sem aguardar aprovacao humana.
---

# Hacker Specification Design

Converter requests informais em especificacoes tecnicas estruturadas.

> **Texto unico.** Stack, comandos e paths vem do perfil do repo
> (`.opencode/rules/hacker-repo-profile.md`).

**Anuncio de inicio**: "Estou usando a skill hacker-specification-design para gerar uma especificacao tecnica."

## GATE (por modo)

NAO execute qualquer skill de implementacao e NAO escreva codigo antes do design validado.

- **MODO AUTONOMO (default)**: o gate e AUTOMATICO. Apos gerar a spec, invocar
  `hacker-critical-analysis` (Ponto 1). Veredito PROSSEGUIR = gravar a spec e seguir o
  pipeline sem pausa. Veredito REJEITAR = ajustar e re-analisar (1 ciclo); segundo REJEITAR =
  parada de emergencia (reportar ao Fernando).
- **MODO SUPERVISIONADO** (so quando o Fernando pedir): apresentar a spec e BLOQUEAR ate
  aprovacao explicita ("sim", "pode", "aprovado", "ok", "prossiga", "continua").

## Processo

### Step 1: Entender Contexto do Projeto

Ler a paisagem do repo para grounding da analise, conforme o perfil:

```bash
# Projeto opsec:
ls ~/opsec/scripts/
cat ~/opsec/docker-compose.yml
ls ~/opsec/README.md ~/opsec/SETUP-HACKER-ETICO.md 2>/dev/null
ls .opencode/rules/
```

Identificar: stack do perfil, arquivos afetados, padroes existentes, regras vigentes.

### Step 1.5: RAG Retrieval (obrigatorio, lei F6)

Antes de gerar a especificacao, consultar as fontes canonicas relevantes ao problema e
re-injetar o conteudo no contexto da spec. Hierarquia de fontes (onde divergirem, o de
cima manda):

1. **Codigo real em `~/opsec/scripts/` e `~/opsec/docker-compose.yml`** - fonte #1, sempre
   vence.
2. **Doc canonica do projeto**: `~/opsec/README.md`, `~/opsec/SETUP-HACKER-ETICO.md`,
   `LEDGER.md`, `.opencode/rules/hacker-opsec-canon.md`.
3. **Doc oficial externa** das tecnologias que o projeto depende (WireGuard, ProtonVPN, Tor,
   dperson/torproxy, gluetun, Docker, systemd-resolved) - API atual, versao, breaking
   changes.
4. **Regras e metodo** (`.opencode/rules/hacker-repo-profile.md`,
   `.opencode/rules/hacker-fable-method.md`).

**1a. RAG interno (codigo do projeto):**

Ler os scripts relevantes ao problema, docker-compose.yml, e docs do projeto:

```bash
# Listar scripts disponiveis
ls ~/opsec/scripts/

# Ler scripts relevantes ao problema
cat ~/opsec/scripts/<script-relevante>.sh
```

Para cada script relevante ao problema, extrair: funcao, dependencias, restricoes, areas
sensiveis. Re-injetar na secao CONTEXT da spec, citando o path consultado.

**1b. RAG externo (tecnologias que o projeto depende):**

Identificar tecnologias externas relevantes ao problema (ex.: spec toca torproxy ->
consultar doc oficial de dperson/torproxy; spec toca VPN -> consultar doc oficial de
ProtonVPN/gluetun; spec toca Docker -> consultar doc oficial de Docker Compose; spec toca VPN -> consultar doc oficial de WireGuard).

Para cada tecnologia identificada, consultar a documentacao oficial autoritativa e trazer
o conteudo relevante (API atual, versao, breaking changes, padroes) para o contexto da spec.

**Gate de grounding:** a spec DEVE citar as fontes consultadas (interno: path do script/doc;
externo: URL ou path da doc oficial) na secao CONTEXT. Spec que toca codigo do projeto ou
tecnologia externa sem citar fonte consultada = AMBIGUA (nao PROSSEGUIR ate fundamentar).

**1c. Pre-flight de postura (OBRIGATORIO):**

Se a mudanca proposta tocar rede, a spec DEVE incluir na secao VALIDACAO/EXPECTED DELIVERY
o comando `bash ~/opsec/scripts/verificar-vazamento.sh` com veredito GOOD como requisito.

### Step 2: Analisar Request e Gerar Especificacao

Analise o request de Fernando e gere a especificacao **COMPLETA** em uma unica passagem.
NAO faca perguntas socraticas.

**Mapa de traducao (informal -> tecnica), exemplos:**
- "o script nao valida" -> "Script X nao valida condicao Y na linha Z"
- "o container nao sobe" -> "docker compose config retorna erro W em servico S"
- "ta vazando DNS" -> "verificar-vazamento.sh retorna resultado Z em vez de GOOD"
- "ta lento" -> "Latencia/performance acima de threshold"

**Disciplina epistemica:**
- Regra canonica: `.opencode/rules/hacker-epistemic-safety.md` (anti-invencao: spec so com
  sintomas observaveis e paths reais; NUNCA inventar arquivo, comando ou resultado)
- NUNCA tratar framing do usuario como verdade absoluta
- Quando evidencia e ambigua: declarar incerteza na spec
- Fazer assumpcoes razoaveis quando necessario, documentadas em CONTEXT

**Estrutura de especificacao (gerar completa de uma vez):**

1. **REQUEST** - Traducao tecnica da necessidade
2. **CATEGORY** - Bugfix | Feature | Refactor | Infra | Docs
3. **PROBLEM** - Sintomas observaveis somente, SEM hipoteses causais
4. **CONTEXT** - Arquivos afetados, sintomas, comportamento esperado, assumpcoes, fontes consultadas
5. **REQUIREMENTS** - O que deve ser feito (tecnico, na stack do perfil)
6. **FILES INVOLVED** - Paths exatos
7. **RESTRICTIONS** - Limites nao-negociaveis (regras do perfil, areas sensiveis, seguranca)
8. **EXPECTED DELIVERY** - Resultado concreto e verificavel, com os comandos de validacao
   do perfil e o resultado esperado de cada um

**Exemplo (perfil opsec):**
```
REQUEST: Estender verificar-vazamento.sh com novo vetor de verificacao de DNS

CATEGORY: Feature

PROBLEM:
- Atual: verificar-vazamento.sh nao verifica se o DNS resolve para o IP correto do proxy
- Esperado: Script detecta divergencia entre DNS resolvido e IP esperado e retorna NAO-GOOD

CONTEXT:
- Script afetado: ~/opsec/scripts/verificar-vazamento.sh
- Dependencia: funcao de verificacao de DNS ja existe (resolver DNS)
- Fontes consultadas: doc oficial de systemd-resolved (§resolvectl), doc de dperson/torproxy
- Assumpcao: o vetor de DNS ja e coberto por outra camada da cadeia
- Pre-flight: bash ~/opsec/scripts/verificar-vazamento.sh GOOD obrigatorio antes de acoes
  de rede

REQUIREMENTS:
1. Adicionar funcao verificar_dns() que resolve o IP do proxy e compara com o esperado
2. Integrar chamada no fluxo principal de verificacao
3. Retornar GOOD se DNS OK, NAO-GOOD se divergencia

FILES INVOLVED:
- ~/opsec/scripts/verificar-vazamento.sh (modify, adicionar funcao e chamada)

RESTRICTIONS:
- Regras 1-6 do perfil do repo (linguagem, toolchain, areas sensiveis, escopo, git, artefatos)
- Nao quebrar verificacoes existentes
- Script e area sensivel (classe C, exige confirmacao do Fernando)

EXPECTED DELIVERY:
- Nova funcao verificar_dns() integrada
- bash -n ~/opsec/scripts/verificar-vazamento.sh: PASS
- shellcheck ~/opsec/scripts/verificar-vazamento.sh: PASS
- verificar-vazamento.sh GOOD em condicao normal de rede

VERIFICATION:
$ bash -n ~/opsec/scripts/verificar-vazamento.sh
$ shellcheck ~/opsec/scripts/verificar-vazamento.sh
$ bash ~/opsec/scripts/verificar-vazamento.sh
```

### Step 2.5: Ler o codigo real dos pontos de contato (obrigatorio, lei F1/F6)

Antes de fechar FILES INVOLVED, ler os arquivos que a spec cita (metodo Fable, F1:
nenhum path citado sem confirmacao no disco; F6: nenhuma assinatura sem grep).
Assumpcoes que nao puderam ser verificadas ficam DECLARADAS na secao CONTEXT.

### Step 3: Validar (gate automatico no modo autonomo)

Invocar `hacker-critical-analysis` (Ponto 1) sobre a spec gerada.

- **PROSSEGUIR**: seguir para Step 4 (gravar) sem pausa.
- **REJEITAR**: ajustar a spec conforme a justificativa e re-analisar (maximo 1 ciclo).
  Segundo REJEITAR = parada de emergencia: reportar veredito + evidencia ao Fernando.

No modo supervisionado: apresentar a spec ao Fernando e bloquear ate aprovacao.

### Step 4: Salvar Especificacao

Apos veredito PROSSEGUIR (ou aprovacao, no modo supervisionado), salvar em `.opencode/specs/`,
nome `SPEC_NNN_nome-descritivo.md`, numero auto-increment verificado com `ls` antes de
gravar (nunca assumir).

## Lembrar

- NUNCA escrever codigo antes de design validado (analise critica no autonomo; Fernando no supervisionado)
- RAG retrieval (Step 1.5) e obrigatorio: consultar codigo do projeto + docs canonicas + doc oficial externa antes de gerar a spec
- Ler o codigo real dos pontos de contato ANTES de fechar a spec (nenhum path inventado)
- Gerar especificacao completa SEM fazer perguntas
- Somente sintomas observaveis, NUNCA hipoteses causais
- Documentar assumpcoes quando fizer inferencias razoaveis
- Se mudanca tocar rede: incluir verificar-vazamento.sh GOOD na secao VALIDACAO
- Responder SEMPRE em PT-BR, escrever specs em PT-BR

## Proxima Skill

**Apos spec gravada** (modo autonomo, sem pausa):
1. Invocar `pre-writing-rule-control` para validacao de regras
2. Se validacao PASS: invocar `hacker-writing-plans`
