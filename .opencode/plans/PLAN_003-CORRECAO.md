# PLAN_003-CORRECAO: Correcao do Ciclo REPROVADO SPEC_003/PLAN_003

- data: 2026-09-11
- ciclo: PLAN_003-CORRECAO
- status: PROPOSTA (aguarda aprovacao do Fernando)
- categoria: Docs (artefato de correcao de ciclo reprovado, sem redesenho de arquitetura)
- **REVISAO**: Plano gerado a partir da SPEC_003-CORRECAO (arquivo `.opencode/specs/SPEC_003-CORRECAO.md`), que cobre exatamente os defeitos confirmados pela auditoria. Referencia de reprovacao: Trust Ledger [2026-09-11] `parada-emergencia` (ciclo PLAN_003).

## REQUEST

Converter a SPEC_003-CORRECAO em plano de implementacao com tarefas atomicas (uma por defeito) para corrigir o ciclo SPEC_003/PLAN_003 REPROVADO. A correcao cobre os defeitos 1, 2, 3, 6, 7 e 8 (mais 4 e 5 conforme decisao do Fernando na Parte 3). Nao redesenha R1/R2/R5/R6 (permanecem ATENDIDO). Nao implementa ferramentas novas: corrige artefatos existentes e define como o teste pratico sera reexecutado (ZAP + Nuclei, gate checado antes, sem troca de metodo sem nova autorizacao).

**Spec de origem**: `.opencode/specs/SPEC_003-CORRECAO.md`

## CATEGORY

Infra | Docs | Correcao de ciclo reprovado (`.hacker/` + `.opencode/specs/` + `.opencode/plans/` + `.opencode/ledger/`)

## PROBLEMA

- Implementacao de SPEC_003 REPROVADA por: hashes fabricados no ledger, placeholder `<chave>` e stub "exemplo conceitual" em `.hacker/scripts/`, teste pratico so com Nuclei sem ZAP e sem evidencia de gate, suite final T12 sem cobertura de `.hacker/scripts/`, tabela markdown invalida no README-RAG, e edicao nao autorizada no red-team.
- Decisoes da Parte 3 (Fernando): item 4 (scrapy no gate) MANTIDO como extensao aprovada retroativamente; item 5 (red-team) REVERTIDO ao texto original. Reversao ja aplicada (sha256=c8cf2fbe1bcb1775).

## CONTEXT

- Registro em `.hacker/ledger/operacoes.md`: OP-20260911-004 (retratacao de hashes), OP-20260911-005 (decisao Parte 3), OP-20260911-006 (errata do hash de OP-005). Cobertura de registros no escopo desta correcao completada nas tarefas abaixo.
- Post-mortem F12 ja registrado no Trust Ledger; nenhuma acao adicional para o defeito 8.
- Leitura literal em 2026-09-11: contagem `.hacker/` = 19 (bate com o esperado do script); placeholders em `.hacker/scripts/PLANO-TESTE-PRATICO.md` linhas 77, 78 e 84; tabela quebrada em `.hacker/rag/README-RAG.md` linhas 41-46 (secao "Regra F6 para scan web" dentro do bloco da tabela).

## ARQUIVOS AFETADOS

### MODIFY (correcao de defeitos)
- `.hacker/rag/README-RAG.md` (defeito 3: reorganizar tabela da secao "Hierarquia de fontes do harness")
- `.hacker/scripts/PLANO-TESTE-PRATICO.md` (defeito 6: remover placeholder `<chave>` e stub "exemplo conceitual")
- `.hacker/scripts/validar-scan-web.sh` (defeito 6: incluir `.hacker/scripts/` na cobertura da suite)
- `.hacker/ledger/operacoes.md` (defeitos 1/2/8: entradas de registro da correcao, append-only)

### VERIFY (sem alteracao de conteudo, ja aplicado e/ou decidido)
- `.hacker/agentes/red-team/AGENTE.md` (defeito 5: reversao ja aplicada, conferir sha256)
- `.hacker/gate/GATE-DE-PROTECAO.md` (defeito 4: manter scrapy conforme decisao, conferir estado)

### REGISTRO
- `.opencode/ledger/trust-ledger.md` (entradas do PLAN_003-CORRECAO e das tarefas)

## DEPENDENCIAS ENTRE TAREFAS

| Tarefa | Depende de | Tipo |
|---|---|---|
| T1 (ledger: recalcular hashes reais) | nenhuma | independente |
| T2 (ledger: conferir retratacao OP-004/006) | T1 | depende de T1 |
| T3 (corrigir tabela RAG) | nenhuma | independente |
| T4 (conferir decisao Parte 3 no gate) | nenhuma | independente |
| T5 (conferir reversao red-team) | nenhuma | independente |
| T6 (corrigir placeholders em PLANO-TESTE-PRATICO e suite) | nenhuma | independente |
| T7 (reexecutar teste pratico, ZAP + Nuclei, gate antes) | T6 (precisa de plano de teste sem placeholder) | depende de T6 |
| T8 (registrar no ledger operacional) | T1..T7 | depende de todas |
| T9 (registrar no Trust Ledger) | T8 | depende de T8 |

---

## TASKS ATOMICAS

### T1: Recalcular SHA-256 real dos artefatos do ledger (defeito 1)

**Arquivo**: `.hacker/ledger/operacoes.md` (verificacao; reescrita apenas de novas entradas)

**Depende de**: nenhuma

**Verificacao**:
```bash
sha256sum .opencode/plans/PLAN_003_web-app-scan-report.md .hacker/scripts/validar-scan-web.sh .hacker/scripts/PLANO-TESTE-PRATICO.md .hacker/reports/JUICE-SHOP-20260911-001.md | cut -c1-16
# comparar cada valor com o HASH das entradas OP-20260911-004 no operacoes.md
```

**Descricao Detalhada**:
Recalcular o sha256 dos 4 artefatos que as entradas OP-20260911-001, 002 e 003 referenciam (16 hex). Comparar com os valores ja registrados na OP-20260911-004 (retratacao). Confirmar que os hashes fabricados (a3f2b1c9..., b4c3d2e1..., 7c4d5e6f...) das linhas originais 10-12 NUNCA sao editados (append-only) e seguem como registro do erro. Esta tarefa e de verificacao: os valores ja foram aplicados na OP-20260911-004; a conferencia literal e o resultado.

### T2: Conferir retratacao presente (defeito 2)

**Arquivo**: `.hacker/ledger/operacoes.md`

**Depende de**: T1

**Verificacao**:
```bash
grep -c 'OP-20260911-004' .hacker/ledger/operacoes.md
grep -c 'OP-20260911-006' .hacker/ledger/operacoes.md
# esperado: >= 1 para cada, e entradas originais OP-001/002/003 inalteradas (append-only)
```

**Descricao Detalhada**:
Conferir que a retratacao OP-20260911-004 (que cita hashes reais calculados, referencia a reprovacao no Trust Ledger e mantem as entradas antigas como historico) e a errata OP-20260911-006 existem e estao completas. Nao alterar nenhuma entrada antiga. Resultado: PASS se ambas presentes e as antigas intactas (conferir por leitura das 3 primeiras linhas da tabela).

### T3: Corrigir tabela markdown quebrada no RAG (defeito 3)

**Arquivo**: `.hacker/rag/README-RAG.md` (MODIFY)

**Depende de**: nenhuma

**Verificacao**:
```bash
# 1) a 3 linhas de conteudo da tabela "Camada | Conteudo" existem (4 celulas por linha, cabecalho presente):
grep -c '^| Conhecimento de seguranca |' .hacker/rag/README-RAG.md
grep -c '^| Conhecimento do ambiente |' .hacker/rag/README-RAG.md
grep -c '^| Conhecimento de operacoes |' .hacker/rag/README-RAG.md
grep -c '^| Conhecimento de vetores |' .hacker/rag/README-RAG.md
# esperado: 1 para cada (todas como linha de celula com pipe no inicio, dentro do bloco)
# 2) a secao F6 esta FORA do bloco da tabela (nesta secao NAO ha pipe no texto imediatamente antes/depois):
grep -A1 -B1 '^## Regra F6 para scan web' .hacker/rag/README-RAG.md
# esperado: nenhuma linha com pipe no contexto da secao F6
# 3) nenhuma linha com pipe orfa fora de bloco de tabela (pipe sem cabecalho valido):
grep -rn '^|' .hacker/rag/README-RAG.md | grep -v '| Camada | Conteudo |\|^[0-9]*:|---\|^[0-9]*:| Prioridade |'
# resultado da suite de validacao apos a correcao:
bash .hacker/scripts/validar-scan-web.sh 2>&1 | tail -n 5
```

**Descricao Detalhada**:
No `.hacker/rag/README-RAG.md`, a secao "## Regra F6 para scan web" (linhas 41-43) esta inserida DENTRO do bloco da tabela "Camada | Conteudo" (iniciada na linha 37), e as linhas de "Conhecimento do ambiente/operacoes/vetores" (44-46) ficaram orfas apos o fechamento incorreto. Corrigir:
- Reorganizar de forma que o bloco da tabela "Camada | Conteudo" contenha as 4 linhas de conteudo (seguranca, ambiente, operacoes, vetores) com o cabecalho e separador corretos no topo.
- Mover a secao "## Regra F6 para scan web" para FORA do bloco da tabela, como secao propria apos o fechamento da tabela.
- Nao perder conteudo, nao mudar o texto ja existente (apenas a posicao estrutural). Sem travessao. Sem placeholders. PT-BR.
**Estado atual lido (2026-09-11)**: linhas 37-46.

### T4: Conferir decisao da Parte 3 aplicada no gate (defeito 4)

**Arquivo**: `.hacker/gate/GATE-DE-PROTECAO.md` (VERIFY)

**Depende de**: nenhuma

**Verificacao**:
```bash
grep -n '\`scrapy\`, \`playwright\`, \`selenium\`' .hacker/gate/GATE-DE-PROTECAO.md
grep -n 'nuclei' .hacker/gate/GATE-DE-PROTECAO.md
# esperado: linha 39 com scrapy/playwright/selenium (decisao Fernando: manter como extensao aprovada); linha 38 com nuclei, httpx (ocorrencia unica, fato observado)
```

**Descricao Detalhada**:
Decisao do Fernando (registrada em OP-20260911-005 e no Trust Ledger): o item `scrapy, playwright, selenium (scraping web)` e MANTIDO como extensao aprovada retroativamente. Nenhuma alteracao no arquivo. A repeticao de nuclei/httpx alegada no prompt NAO foi confirmada por leitura literal: ocorre uma unica vez (linha 38). Esta tarefa confer e reporta o estado como fato, sem editar.

### T5: Conferir reversao do red-team (defeito 5)

**Arquivo**: `.hacker/agentes/red-team/AGENTE.md` (VERIFY)

**Depende de**: nenhuma

**Verificacao**:
```bash
sha256sum .hacker/agentes/red-team/AGENTE.md | cut -c1-16
grep -n 'metasploit, sqlmap' .hacker/agentes/red-team/AGENTE.md
# esperado: sha256 = c8cf2fbe1bcb1775; linha 31 contem "metasploit, sqlmap" sem o adendo "em host real"
```

**Descricao Detalhada**:
Decisao do Fernando (Parte 3): reverter a linha 31 ao texto original, removendo o adendo "em host real". Reversao JA aplicada e registrada (OP-20260911-005/006). Esta tarefa confere por sha256 e por leitura da linha 31 que o estado esta conforme. Nenhuma edicao adicional.

### T6: Corrigir placeholders e ampliar cobertura da suite (defeito 6)

**Arquivo**: `.hacker/scripts/PLANO-TESTE-PRATICO.md` (MODIFY) e `.hacker/scripts/validar-scan-web.sh` (MODIFY)

**Depende de**: nenhuma

**Verificacao**:
```bash
# a) nenhum placeholder em .hacker/scripts/:
grep -rn '<chave>\|exemplo conceitual\|Exemplo conceitual\|TBD\|TODO' .hacker/scripts/ || echo "ZERO PLACEHOLDERS"
# b) suite cobre .hacker/scripts/ (fase nova):
grep -n 'PLANO-TESTE-PRATICO.md' .hacker/scripts/validar-scan-web.sh
grep -n 'validar-scan-web.sh' .hacker/scripts/validar-scan-web.sh
# c) sintaxe bash valida:
bash -n .hacker/scripts/validar-scan-web.sh && echo "BASH -n OK"
# d) suite termina PASS:
bash .hacker/scripts/validar-scan-web.sh 2>&1 | tail -n 5
```

**Descricao Detalhada**:
**No PLANO-TESTE-PRATICO.md**:
- Remover o placeholder `<chave>` da linha 78. A API key do ZAP e obtida de forma executavel: registrar que o comando usa a chave exportada do container ZAP (ex.: `-apikey "$ZAP_API_KEY"` com a chave obtida de `zap` como variavel), nunca um valor literal fixo. Conteudo real, executavel, sem placeholder.
- Remover o stub "exemplo conceitual" e "Exemplo conceitual" das linhas 77 e 84: transformar em comandos reais (ZAP quick-scan com saida XML, Nuclei com templates direcionados ao alvo), mantendo a restricao de que a execucao real depende de autorizacao explicita.
- Remover o travessao da linha 77 (regra sem travessao).
**No validar-scan-web.sh**:
- Adicionar fase de verificacao que cobre `.hacker/scripts/PLANO-TESTE-PRATICO.md` e `.hacker/scripts/validar-scan-web.sh` (ex.: anti-placeholder, existencia, bash -n) apos as fases existentes, sem remover verificacoes atuais.
- Conferir e ajustar a contagem de arquivos `.hacker/` se necessario (valor real atual: 19), mantendo o WARN apenas para divergencia real.
- Sem travessao em textos novos. PT-BR.

### T7: Reexecutar teste pratico conforme metodo da SPEC (defeito 7)

**Arquivo**: `.hacker/reports/` (novo relatorio) + `.hacker/ledger/operacoes.md` (entrada nova)

**Depende de**: T6

**Verificacao** (execucao, nao simetria de papeis):
```bash
bash ~/opsec/scripts/verificar-vazamento.sh   # saida literal GOOD obrigatoria ANTES de qualquer scan
# ZAP: scan ativo real, saida exportada em XML convertida para JSON (regra 1.3)
# Nuclei: templates direcionados ao alvo (nao troca descartavel de templates)
# conferir findings reais com CVSS/CWE de fonte confiavel ou "unclassified - pending verification"
```

**Descricao Detalhada**:
Reexecutar o teste pratico no ambiente autorizado seguindo o metodo da SPEC_003 (R1.2, R1.3, R1.4):
- **Gate antes**: executar `bash ~/opsec/scripts/verificar-vazamento.sh` e colar a saida literal. GOOD obrigatorio. Se nao GOOD: PARAR e reportar, nao prosseguir.
- **ZAP obrigatorio**: execucao do ZAP (DAST ativo) registrada com comando real e saida exportada. Se ZAP nao disponivel no ambiente: PARAR e reportar a Fernando antes de qualquer alternativa (nao trocar ferramenta por conta propria).
- **Nuclei complementar**: uso permitido com templates direcionados ao alvo; sem troca de templates/metodo apos inicio sem nova autorizacao.
- **Relatorio**: seguir `hacker-web-scan-report.md` (secoes 1.4 a 1.7) e `TEMPLATE-RELATORIO.md`, sem placeholder, sem IP real (somente IP de saida), findings reais deduplicados.
- **Ledger**: nova entrada com hash real de sha256sum, gate colado, resultados.
- **Ferramenta indisponivel ou alvo nao acessivel**: parada registrada como pendencia, reportada a Fernando.

### T8: Registrar correcao no ledger operacional (append-only)

**Arquivo**: `.hacker/ledger/operacoes.md` (MODIFY, append)

**Depende de**: T1..T7

**Verificacao**:
```bash
sha256sum <cada artefato editado> | cut -c1-16   # hash real por entrada
grep -c 'PLAN_003-CORRECAO\|OP-20260911-007' .hacker/ledger/operacoes.md
```

**Descricao Detalhada**:
Adicionar ENTRADA NOVA (append-only, abaixo da linha de comentario) em `.hacker/ledger/operacoes.md` registrando a execucao deste plano de correcao: custo de correcao (cada arquivo editado com sha256 real), resultado (defeitos corrigidos), gate colado se houve acao de rede. Hash de cada entrada = sha256 real. Sem editar entradas antigas. Sem IP real. PT-BR.

### T9: Registrar no Trust Ledger

**Arquivo**: `.opencode/ledger/trust-ledger.md` (MODIFY, append)

**Depende de**: T8

**Verificacao**:
```bash
grep -c 'PLAN_003-CORRECAO' .opencode/ledger/trust-ledger.md
grep -rn '—\|–' .opencode/ledger/trust-ledger.md | tail -n 3 || true
```

**Descricao Detalhada**:
Adicionar entrada no Trust Ledger (append-only) registrando: plano criado (evento plan-created), e apos a execucao as entradas de validacao/reconciliacao com vereditos. Cada entrada copia os numeros da saida literal (lei F3/F6), nunca de memoria.

---

## RESULTADO ESPERADO

1. Ledger com hashes reais conferidos (defeito 1), retratacao presente e entradas antigas intactas (defeito 2).
2. `.hacker/rag/README-RAG.md` com tabela markdown valida, secao F6 fora do bloco (defeito 3).
3. Gate com scrapy mantido conforme decisao, sem alteracao indevida (defeito 4).
4. Red-team revertido e conferido por sha256 (defeito 5).
5. `.hacker/scripts/` sem placeholder e suite cobrindo estes arquivos, PASS com saida literal (defeito 6).
6. Teste pratico reexecutado com gate GOOD colado, ZAP executado, Nuclei direcionado, relatorio sem placeholder (defeito 7), ou parada reportada se indisponivel.
7. Post-mortem F12 presente (defeito 8) e registrado no Trust Ledger.
8. Suite completa do perfil PASS com saida literal completa em todos os arquivos tocados.

## ACEITACAO

- [ ] `sha256sum` de cada artefato citado em nova entrada do ledger confere com o HASH registrado.
- [ ] Entradas antigas do ledger (OP-001/002/003) intactas (append-only).
- [ ] `.hacker/rag/README-RAG.md`: nenhuma celula de tabela fora de bloco; secao F6 fora da tabela.
- [ ] `.hacker/scripts/`: zero `grep '<chave>\|exemplo conceitual\|TBD\|TODO'`.
- [ ] `.hacker/scripts/validar-scan-web.sh` termina PASS (0 FAIL) e cobre `.hacker/scripts/`.
- [ ] Teste pratico com evidencia literal de `verificar-vazamento.sh` GOOD antes do scan e execucao de ZAP registrada; se indisponivel, parada reportada.
- [ ] Suite completa do ciclo rodada e saida literal completa colada (nao resumo).