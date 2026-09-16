# Método Composto de Verificação do Tor - Plano de Implementação

> **Para agentes**: Use hacker-subagent-driven-development para executar este plano.

**Objetivo**: Padronizar a verificação do Tor em todos os 6 agentes usando método composto: `docker ps` (container) + `nc -z` (porta 9050).

**Spec**: `.opencode/specs/SPEC_014-metodo-composto-verificacao-tor.md`

**Arquivos Afetados**: 6 agentes em `.hacker/agentes/*/AGENTE.md`

**Arquitetura**: Adicionar verificação `nc -z` após `docker ps` em 5 agentes; adicionar `docker ps` antes de `nc -z` em 1 agente (pentest). Todos ficam com verificação composta idêntica.

**Stack**: markdown (documentação de agentes)

---

## TASK 1: Atualizar blue-team/AGENTE.md

**Arquivo**: `.hacker/agentes/blue-team/AGENTE.md`

**Arquivos**:
- MODIFY: `.hacker/agentes/blue-team/AGENTE.md` (linhas 36-40)

**Depende de**: nenhuma

**Verificacao**:
```bash
grep -A5 "Container Docker torproxy-host" .hacker/agentes/blue-team/AGENTE.md
```

**Descricao Detalhada**:
Adicionar verificação `nc -z` após a verificação `docker ps` na seção de verificação do Tor.

**Implementacao**:
```bash
# 3. Container Docker torproxy-host rodando?
if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q torproxy-host; then
  echo "BLOQUEADO: Container torproxy-host nao esta rodando."
  exit 1
fi

# 3.1 Tor ativo na porta 9050?
if ! nc -z 127.0.0.1 9050 2>/dev/null; then
  echo "BLOQUEADO: Tor nao responde na porta 9050."
  exit 1
fi
```

---

## TASK 2: Atualizar red-team/AGENTE.md

**Arquivo**: `.hacker/agentes/red-team/AGENTE.md`

**Arquivos**:
- MODIFY: `.hacker/agentes/red-team/AGENTE.md` (linhas 37-41)

**Depende de**: nenhuma

**Verificacao**:
```bash
grep -A5 "Container Docker torproxy-host" .hacker/agentes/red-team/AGENTE.md
```

**Descricao Detalhada**:
Adicionar verificação `nc -z` após a verificação `docker ps` na seção de verificação do Tor.

**Implementacao**:
```bash
# 3. Container Docker torproxy-host rodando?
if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q torproxy-host; then
  echo "BLOQUEADO: Container torproxy-host nao esta rodando."
  exit 1
fi

# 3.1 Tor ativo na porta 9050?
if ! nc -z 127.0.0.1 9050 2>/dev/null; then
  echo "BLOQUEADO: Tor nao responde na porta 9050."
  exit 1
fi
```

---

## TASK 3: Atualizar scraping/AGENTE.md

**Arquivo**: `.hacker/agentes/scraping/AGENTE.md`

**Arquivos**:
- MODIFY: `.hacker/agentes/scraping/AGENTE.md` (linhas 34-38)

**Depende de**: nenhuma

**Verificacao**:
```bash
grep -A5 "Container Docker torproxy-host" .hacker/agentes/scraping/AGENTE.md
```

**Descricao Detalhada**:
Adicionar verificação `nc -z` após a verificação `docker ps` na seção de verificação do Tor.

**Implementacao**:
```bash
# 3. Container Docker torproxy-host rodando?
if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q torproxy-host; then
  echo "BLOQUEADO: Container torproxy-host nao esta rodando."
  exit 1
fi

# 3.1 Tor ativo na porta 9050?
if ! nc -z 127.0.0.1 9050 2>/dev/null; then
  echo "BLOQUEADO: Tor nao responde na porta 9050."
  exit 1
fi
```

---

## TASK 4: Atualizar web-scanner/AGENTE.md

**Arquivo**: `.hacker/agentes/web-scanner/AGENTE.md`

**Arquivos**:
- MODIFY: `.hacker/agentes/web-scanner/AGENTE.md` (linhas 38-42)

**Depende de**: nenhuma

**Verificacao**:
```bash
grep -A5 "Container Docker torproxy-host" .hacker/agentes/web-scanner/AGENTE.md
```

**Descricao Detalhada**:
Adicionar verificação `nc -z` após a verificação `docker ps` na seção de verificação do Tor.

**Implementacao**:
```bash
# 3. Container Docker torproxy-host rodando?
if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q torproxy-host; then
  echo "BLOQUEADO: Container torproxy-host nao esta rodando."
  exit 1
fi

# 3.1 Tor ativo na porta 9050?
if ! nc -z 127.0.0.1 9050 2>/dev/null; then
  echo "BLOQUEADO: Tor nao responde na porta 9050."
  exit 1
fi
```

---

## TASK 5: Atualizar orquestrador-pipeline/AGENTE.md

**Arquivo**: `.hacker/agentes/orquestrador-pipeline/AGENTE.md`

**Arquivos**:
- MODIFY: `.hacker/agentes/orquestrador-pipeline/AGENTE.md` (linhas 38-42)

**Depende de**: nenhuma

**Verificacao**:
```bash
grep -A5 "Container Docker torproxy-host" .hacker/agentes/orquestrador-pipeline/AGENTE.md
```

**Descricao Detalhada**:
Adicionar verificação `nc -z` após a verificação `docker ps` na seção de verificação do Tor.

**Implementacao**:
```bash
# 3. Container Docker torproxy-host rodando?
if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q torproxy-host; then
  echo "BLOQUEADO: Container torproxy-host nao esta rodando."
  exit 1
fi

# 3.1 Tor ativo na porta 9050?
if ! nc -z 127.0.0.1 9050 2>/dev/null; then
  echo "BLOQUEADO: Tor nao responde na porta 9050."
  exit 1
fi
```

---

## TASK 6: Atualizar pentest/AGENTE.md

**Arquivo**: `.hacker/agentes/pentest/AGENTE.md`

**Arquivos**:
- MODIFY: `.hacker/agentes/pentest/AGENTE.md` (linhas 35-39)

**Depende de**: nenhuma

**Verificacao**:
```bash
grep -B2 -A5 "nc -z.*9050" .hacker/agentes/pentest/AGENTE.md
```

**Descricao Detalhada**:
Adicionar verificação `docker ps` ANTES da verificação `nc -z` existente. O agente pentest já tem `nc -z`, mas falta `docker ps`.

**Implementacao**:
```bash
# 3. Container Docker torproxy-host rodando?
if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q torproxy-host; then
  echo "BLOQUEADO: Container torproxy-host nao esta rodando."
  exit 1
fi

# 3.1 Tor ativo na porta 9050? (Docker ou nativo)
if ! nc -z 127.0.0.1 9050 2>/dev/null; then
  echo "BLOQUEADO: Tor nao responde na porta 9050."
  exit 1
fi
```

---

## TASK 7: Validação Final

**Arquivo**: N/A (comando de verificação)

**Arquivos**:
- TEST: todos os 6 agentes

**Depende de**: TASK 1, TASK 2, TASK 3, TASK 4, TASK 5, TASK 6

**Verificacao**:
```bash
# Todos os agentes devem ter AMBAS as verificações
echo "=== Verificando docker ps ==="
grep -l "docker ps.*torproxy-host" .hacker/agentes/*/AGENTE.md | wc -l
# Esperado: 6

echo "=== Verificando nc -z ==="
grep -l "nc -z.*9050" .hacker/agentes/*/AGENTE.md | wc -l
# Esperado: 6

echo "=== Verificando verificação composta ==="
for f in .hacker/agentes/*/AGENTE.md; do
  has_docker=$(grep -c "docker ps.*torproxy-host" "$f" || true)
  has_nc=$(grep -c "nc -z.*9050" "$f" || true)
  if [ "$has_docker" -eq 0 ] || [ "$has_nc" -eq 0 ]; then
    echo "FALHA: $f não tem verificação composta"
  fi
done
# Esperado: zero saídas (todos passam)
```

**Descricao Detalhada**:
Executar a suite de validação para garantir que todos os 6 agentes foram atualizados corretamente com o método composto.

**Implementacao**:
```bash
#!/bin/bash
set -euo pipefail

echo "=== VALIDAÇÃO FINAL ==="
echo ""

# Verificar docker ps
DOCKER_COUNT=$(grep -l "docker ps.*torproxy-host" .hacker/agentes/*/AGENTE.md 2>/dev/null | wc -l)
echo "Agentes com docker ps: $DOCKER_COUNT (esperado: 6)"

# Verificar nc -z
NC_COUNT=$(grep -l "nc -z.*9050" .hacker/agentes/*/AGENTE.md 2>/dev/null | wc -l)
echo "Agentes com nc -z: $NC_COUNT (esperado: 6)"

# Verificar compostos
echo ""
echo "=== Verificação composta por agente ==="
for f in .hacker/agentes/*/AGENTE.md; do
  agent=$(basename $(dirname "$f"))
  has_docker=$(grep -c "docker ps.*torproxy-host" "$f" || true)
  has_nc=$(grep -c "nc -z.*9050" "$f" || true)
  if [ "$has_docker" -gt 0 ] && [ "$has_nc" -gt 0 ]; then
    echo "  ✓ $agent: COMPOSTO (docker ps + nc -z)"
  else
    echo "  ✗ $agent: INCOMPLETO (docker=$has_docker, nc=$has_nc)"
  fi
done

echo ""
echo "=== RESULTADO ==="
if [ "$DOCKER_COUNT" -eq 6 ] && [ "$NC_COUNT" -eq 6 ]; then
  echo "TODOS OS AGENTES COM VERIFICAÇÃO COMPOSTA"
else
  echo "FALHA: Agentes incompletos"
  exit 1
fi
```
