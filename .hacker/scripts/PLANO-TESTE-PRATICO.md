# Plano de Teste Pratico, Scan Web com Ambiente Vulneravel

- data: 2026-09-11
- ciclo: TEST_PRATICO_SPEC_003
- status: PREPARADO (aguarda autorizacao do Fernando)
- **RESTRICAO**: Nenhum scan real sera executado sem autorizacao explicita do Fernando.

## AMBIENTE DE TESTE RECOMENDADO

### Opcao 1 (Preferida): OWASP Juice Shop

- **URL**: `http://localhost:3000` (container Docker)
- **Por que**: Ambiente intencionalmente vulneravel, mantido pela OWASP, com vulnerabilidades
  classificadas por severidade (Easy, Medium, Hard). Suporta OWASP Top 10.
- **Docker**: `docker run -d -p 3000:3000 bkimminich/juice-shop`
- **Vulnerabilidades**: SQL Injection, XSS, Escalation, CORS, NoSQL Injection, etc.
- **Ferramentas aplicaveis**: ZAP (`localhost:8080`), Nuclei com templates OWASP.

### Opcao 2: DVWA (Damn Vulnerable Web Application)

- **URL**: `http://localhost:8080/dvwa` (container Docker)
- **Por que**: Clássico para testes de segurança web, com niveis de dificuldade (Low, Medium, High).
- **Docker**: `docker run -d -p 8080:80 -v $PWD/dvwa:/var/www/html vulnerables/web-dvwa`
- **Vulnerabilidades**: SQL Injection, XSS, CSRF, File Inclusion, Command Injection.
- **Ferramentas aplicaveis**: ZAP, Nuclei.

### Opcao 3: Metasploitable 2 (se necessário)

- **URL**: `http://192.168.1.100` (VM)
- **Por que**: VM intencionalmente vulneravel para treinamento de pentest.
- **Nota**: Requer VM local ou sandbox. Mais adequado para rede do que apenas web.

## FLUXO PRATICO (Gate → Scan → Relatorio → Ledger)

### Etapa 0: Pre-flight de Protecao (OBRIGATORIO)

```bash
sudo bash ~/opsec/scripts/session-start-hacking-security.sh
# Resultado esperado: GOOD (com WG ATIVO)
```

Se GOOD → prosseguir. Se NAO → PARAR.

### Etapa 1: Iniciar Ambiente de Teste

```bash
# Opção 1 (Juice Shop):
docker run -d -p 3000:3000 --name juice-shop bkimminich/juice-shop
docker ps | grep juice-shop

# Opção 2 (DVWA):
docker run -d -p 8080:80 --name dvwa vulnerables/web-dvwa
docker ps | grep dvwa
```

**NOTA**: Esta etapa requer Docker, que eh ferramenta local (nao toca rede externa).
O gate `verificar-vazamento.sh` aplica-se a operacoes que saem da maquina.
Iniciar containers locais NÃO é operação de rede externa.

### Etapa 2: Validar Gate

```bash
bash ~/opsec/scripts/verificar-vazamento.sh
# GOOD = prosseguir com scan
# OUTRO = BLOQUEAR
```

### Etapa 3: Executar ZAP Scan

```bash
# Iniciar ZAP container (imagem oficial atual: owasp/zap2docker-stable foi descontinuada; usar ghcr):
docker run -d -p 8080:8080 --name zap-juice ghcr.io/zaproxy/zaproxy:stable zap.sh -daemon -host 0.0.0.0 -port 8080

# Aguardar ZAP iniciar:
sleep 30

# Obter a API key do container ZAP (valor real exportado, nao fixo em arquivo):
ZAP_API_KEY=$(docker exec zap-juice cat /root/.ZAP/config.xml | grep -oP '(?<=<apikey>)[^<]+' 2>/dev/null || true)
# Se a config nao existir, gerar chave via API antes do scan (ZAP dasa \:ACCESS-LOG etc.) e exportar como variavel:
# ZAP_API_KEY=$(docker exec zap-juice curl -s http://localhost:8080/JSON/core/view/optionEnv 2>/dev/null)

# Executar scan ativa (ver alta: requer autorizacao explicita para execucao real):
# zap-cli -apikey "$ZAP_API_KEY" quick-scan -s xss,sqli http://localhost:3000 -r -o zap-report.xml
```

### Etapa 4: Executar Nuclei Scan

```bash
# Scan alvo Juice Shop (template direcionado ao alvo, nao trocado apos inicio sem nova autorizacao):
# nuclei -u http://localhost:3000 -t http/technologies/ -t http/misconfiguration/ -jsonl -o juice-shop-results.jsonl
# nuclei -u http://localhost:3000 -t http/vulnerabilities/ -jsonl -o juice-shop-vulns.jsonl
```

### Etapa 5: Parse e Enriquecimento

- Consolidar JSON do ZAP + JSONL do Nuclei em JSON estruturado unificado
- Mapear CVSS v3.1 + CWE para cada finding
- Deduplicar vulnerabilidades

### Etapa 6: Gerar Relatorio Tecnico

- Usar `templates/TEMPLATE-RELATORIO.md` com campos de finding
- Gerar relatorio seguindo a estrutura da regra `hacker-web-scan-report.md`:
  1. Cabeçalho
  2. Execução
  3. Escopo
  4. Metodologia
  5. Findings (Critical → Informational)
  6. Conclusão
- Salvar em `.hacker/reports/JUICE-SHOP-YYYYMMDD-NNN.md`

### Etapa 7: Registrar no Ledger

- Entrada em `.hacker/ledger/operacoes.md`:
  - DATA, OPERACAO-ID, AGENTE=web-scanner, ESCOPO=Juice Shop/DVWA, GATE=GOOD
  - VETOR, RESULTADO, BASE (comandos reais + citacao)
  - HASH SHA-256

### Etapa 8: Reportar ao Orquestrador

- Orquestrador consolida e apresenta ao Fernando.

## RESTRICOES

- **NENHUM scan real sera executado sem autorizacao explicita do Fernando**.
- As etapas 3 e 4 (ZAP e Nuclei) descrevem comandos reais executaveis; a execucao so ocorre apos autorizacao explicita.
- O ambiente de teste e LOCAL (container Docker), nao toca rede externa.
- IP real de origem NUNCA sera registrado em relatorio ou ledger.
- Se o Fernando autorizar, o fluxo sera executado passo a passo com saida literal.

## ARQUIVOS CRIADOS

- `.hacker/scripts/validar-scan-web.sh`: suite de validacao reutilizavel
- `.hacker/scripts/PLANO-TESTE-PRATICO.md`: este plano de teste pratico

## PREPARACAO NECESSARIA (antes de autorizacao)

1. Docker instalado e funcional (`docker ps` OK)
2. ZAP disponivel (container `ghcr.io/zaproxy/zaproxy:stable`) ou `zap-cli` instalado
3. Nuclei disponivel (`nuclei -version`)
4. `verificar-vazamento.sh` GOOD (cadeia ativa)
5. Autorizacao explicita do Fernando para scan do ambiente escolhido
