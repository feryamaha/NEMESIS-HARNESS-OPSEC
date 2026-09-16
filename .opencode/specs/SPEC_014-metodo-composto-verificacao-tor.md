# SPEC_014: Método Composto de Verificação do Tor (docker ps + nc -z)

## REQUEST

Unificar a verificação do Tor em todos os agentes usando método composto: `docker ps` (container) + `nc -z` (porta 9050), alinhando com o `session-start-hacking-security.sh` que já usa `nc -z`.

## CATEGORY

Bugfix (divergência de implementação)

## PROBLEM

- **Sintoma 1**: 5 agentes usam apenas `docker ps` para verificar Tor
- **Sintoma 2**: 1 agente (pentest) usa apenas `nc -z` para verificar Tor
- **Sintoma 3**: `session-start-hacking-security.sh` usa `nc -z` (linha 86)
- **Resultado**: Verificações inconsistentes entre agentes e script principal

## CONTEXT

- **Arquivos afetados**: 6 agentes em `.hacker/agentes/*/AGENTE.md`
- **Script de referência**: `~/opsec/scripts/session-start-hacking-security.sh` (usa `nc -z`)
- **Container**: `torproxy-host` (dperson/torproxy, porta 9050)
- **Fontes consultadas**:
  - `~/opsec/scripts/session-start-hacking-security.sh:86` (usa `nc -z`)
  - `.hacker/agentes/pentest/AGENTE.md:36` (usa `nc -z`)
  - `.hacker/agentes/red-team/AGENTE.md:38` (usa `docker ps`)
  - `.hacker/agentes/blue-team/AGENTE.md:37` (usa `docker ps`)
  - `.hacker/agentes/scraping/AGENTE.md:35` (usa `docker ps`)
  - `.hacker/agentes/web-scanner/AGENTE.md:39` (usa `docker ps`)
  - `.hacker/agentes/orquestrador-pipeline/AGENTE.md:39` (usa `docker ps`)
- **Assumpção**: O método composto é mais robusto porque verifica dois cenários:
  1. Container rodando (`docker ps`)
  2. Porta respondendo (`nc -z`)

## REQUIREMENTS

1. **Padronizar verificação do Tor** em todos os 6 agentes usando método composto:
   ```bash
   # 3. Tor ativo? (container + porta)
   if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q torproxy-host; then
     echo "BLOQUEADO: Container torproxy-host nao esta rodando."
     exit 1
   fi
   if ! nc -z 127.0.0.1 9050 2>/dev/null; then
     echo "BLOQUEADO: Tor nao responde na porta 9050."
     exit 1
   fi
   ```

2. **Manter alinhamento** com `session-start-hacking-security.sh` (que já usa `nc -z`)

3. **Não alterar** a lógica de verificação do script principal

## FILES INVOLVED

- `.hacker/agentes/blue-team/AGENTE.md` (modificar: adicionar `nc -z` após `docker ps`)
- `.hacker/agentes/red-team/AGENTE.md` (modificar: adicionar `nc -z` após `docker ps`)
- `.hacker/agentes/pentest/AGENTE.md` (modificar: adicionar `docker ps` antes de `nc -z`)
- `.hacker/agentes/scraping/AGENTE.md` (modificar: adicionar `nc -z` após `docker ps`)
- `.hacker/agentes/web-scanner/AGENTE.md` (modificar: adicionar `nc -z` após `docker ps`)
- `.hacker/agentes/orquestrador-pipeline/AGENTE.md` (modificar: adicionar `nc -z` após `docker ps`)

## RESTRICTIONS

- **Somente mover/corrigir documentação** — não alterar lógica de scripts bash
- **Não alterar** `session-start-hacking-security.sh` (já usa `nc -z`)
- **Não alterar** `verificar-vazamento.sh`
- **Manter** o padrão de comentário existente em cada agente
- ** Área sensível**: agentes são contratos de operação; zmuda deve ser mínima e exata

## EXPECTED DELIVERY

Todos os 6 agentes com verificação composta:
- `docker ps` (verifica container)
- `nc -z` (verifica porta 9050)

## VERIFICATION

```bash
# Todos os agentes devem ter AMBAS as verificações
grep -l "docker ps.*torproxy-host" .hacker/agentes/*/AGENTE.md | wc -l
# Esperado: 6

grep -l "nc -z.*9050" .hacker/agentes/*/AGENTE.md | wc -l
# Esperado: 6

# Nenhum agente deve ter apenas uma verificação
for f in .hacker/agentes/*/AGENTE.md; do
  has_docker=$(grep -c "docker ps.*torproxy-host" "$f" || true)
  has_nc=$(grep -c "nc -z.*9050" "$f" || true)
  if [ "$has_docker" -eq 0 ] || [ "$has_nc" -eq 0 ]; then
    echo "FALHA: $f não tem verificação composta"
  fi
done
# Esperado: zero saídas (todos passam)
```
