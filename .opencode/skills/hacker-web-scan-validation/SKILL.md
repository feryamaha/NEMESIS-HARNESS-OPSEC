---
name: hacker-web-scan-validation
description: >
  Valida a capability de Scan de Aplicacoes Web + Geracao de Relatorio Tecnico
  (SPEC_003 / PLAN_003). Executa suite reutilizavel de 42 testes: existencia e
  integridade dos arquivos, consistencia entre componentes (Agent, Rule, Template,
  Gate, Orquestrador, Ledger), logica do fluxo (Gate -> Scan -> Parse -> Relatorio
  -> Ledger), completude do Template de Relatorio, separacao de camadas, ausencia
  de arquivos orfaos e contradicoes. Apos validar, executa teste pratico com
  ambiente vulneravel (OWASP Juice Shop ou DVWA) em container Docker local.
---

# Hacker Web Scan Validation

Validacao completa da capability de Scan Web + Relatorio Tecnico.

## Anuncio de inicio

"Estou usando a skill hacker-web-scan-validation para validar a capability de scan web."

## Pre-requisito

- PLAN_003 concluido (todos os arquivos criados e estendidos)
- Docker funcional (`docker ps` OK)
- `verificar-vazamento.sh` GOOD (se operacao de rede for iniciada)

## Processo

### Parte 1: Suite de Validacao

Executar o script reutilizavel:

```bash
bash .hacker/scripts/validar-scan-web.sh
```

**Espera-se**: 42 PASS, 0 FAIL, 0 WARN.

Se PASS → prosseguir para Parte 2.
Se FAIL → investigar a causa raiz (Fase 4 do hacker-tests), fixar e re-executar.

### Parte 2: Teste Pratico com Ambiente Vulneravel

#### 2.1 Escolha do ambiente

Prioridade:
1. **OWASP Juice Shop** — `docker run -d -p 3000:3000 --name juice-shop bkimminich/juice-shop`
2. **DVWA** — `docker run -d -p 8080:80 --name dvwa vulnerables/web-dvwa`

#### 2.2 Iniciar ambiente (local, nao toca rede externa)

```bash
docker run -d -p 3000:3000 --name juice-shop bkimminich/juice-shop
sleep 10
docker ps | grep juice-shop
```

Ou para DVWA:
```bash
docker run -d -p 8080:80 --name dvwa vulnerables/web-dvwa
sleep 10
docker ps | grep dvwa
```

**Nota**: Iniciar container Docker e operacao LOCAL. Nao e operacao de rede
externa. O gate `verificar-vazamento.sh` aplica-se a operacoes que saem da
maquina. Container local na mesma maquina.

#### 2.3 Executar validacao no ambiente

- ZAP scan (se disponivel): container `owasp/zap2docker-stable` na porta 8080
- Nuclei scan com templates OWASP Top 10
- Parse JSON + JSONL → consolidacao
- Enriquecimento CVSS v3.1 + CWE

#### 2.4 Gerar relatorio

- Usar `templates/TEMPLATE-RELATORIO.md`
- Salvar em `.hacker/reports/JUICE-SHOP-YYYYMMDD-NNN.md`
- Estrutura: Cabeçalho → Execução → Escopo → Metodologia → Findings → Conclusão

#### 2.5 Registrar no Ledger

- Entrada em `.hacker/ledger/operacoes.md` com: DATA, OPERACAO-ID, AGENTE,
  ESCOPO, GATE, VETOR, RESULTADO, BASE (comandos reais), HASH

#### 2.6 Finalizar

- Parar container: `docker stop juice-shop` ou `docker stop dvwa`
- Registrar entrada no Trust Ledger
- Atualizar memoria (`.hacker/memoria/MEMORIA.md`)

## Integracao com o harness

- A suite de validacao e executada pelo `hacker-tests` (Skill 4) como parte
  da validacao pos-implementacao.
- O teste pratico e executado pelo `hacker-subagent-driven-development` (Skill 3)
  quando o Fernando autorizar operacao de teste.
- O orquestrador (`ORQUESTRADOR.md`) pode despachar o web-scanner para
  executar o fluxo pratico.
- A regra AI (`hacker-web-scan-report.md`) governa o comportamento durante o
  teste pratico.

## Regras

- NENHUM scan real sem autorizacao explicita do Fernando.
- NENHUM IP real registrado em relatorio ou ledger.
- Container Docker = operacao LOCAL (nao toca rede externa).
- Separação de camadas mantida: .opencode/ = desenvolvimento, .hacker/ = operacional.
- Todo resultado e evidencia literal (comandos + saidas).

## Arquivos

| Arquivo | Caminho |
|---|---|
| Suite de validacao | `.hacker/scripts/validar-scan-web.sh` |
| Plano de teste pratico | `.hacker/scripts/PLANO-TESTE-PRATICO.md` |
| Skill desta skill | `.opencode/skills/hacker-web-scan-validation/SKILL.md` |
| Regra AI | `.opencode/rules/hacker-web-scan-report.md` |
| Agente | `.hacker/agentes/web-scanner/AGENTE.md` |
| Orquestrador | `.hacker/orquestrador/ORQUESTRADOR.md` |
| Templates | `.hacker/templates/TEMPLATE-*.md` |
