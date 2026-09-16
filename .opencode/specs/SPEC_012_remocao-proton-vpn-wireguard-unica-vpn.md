# SPEC_012 - Remoção Proton VPN / WireGuard como única VPN

## REQUEST

Remover toda dependência de Proton VPN e gluetun do harness de hacking. WireGuard (wg0) deve ser a única VPN. O kill-switch deve ser validado com base no WireGuard, não no gluetun.

## CATEGORY

Refactor + Bugfix

## PROBLEM

- `verificar-vazamento.sh` TESTE 4.5 verifica regras de firewall do container gluetun (netns). Se gluetun não está conectado à Proton, retorna LEAK mesmo com Tor funcionando via torproxy-host.
- `kill-switch.sh` audita o netns do gluetun. Sem gluetun, retorna FAIL.
- `session-start-hacking-security.sh` Etapa 2.5 sobe gluetun + torproxy-host. gluetun não deve ser mais usado.
- `iniciar-sessao.sh` invoca kill-switch.sh que depende de gluetun.
- `docker-compose.yml` tem gluetun como dependência de tor-on-vpn e kali-sandbox.
- Resultado: harness nunca retorna GOOD porque o teste 4.5 exige gluetun conectado à Proton.

## CONTEXT

- **Scripts afetados:**
  - `~/opsec/scripts/verificar-vazamento.sh` (linhas 91-116: TESTE 4.5)
  - `~/opsec/scripts/kill-switch.sh` (arquivo inteiro: auditoria gluetun)
  - `~/opsec/scripts/session-start-hacking-security.sh` (linhas 60-107: Etapa 2.5)
  - `~/opsec/scripts/iniciar-sessao.sh` (linha 47: chamada kill-switch)
  - `~/opsec/docker-compose.yml` (gluetun, tor-on-vpn, kali-sandbox)
- **Decisão do Fernando:** "VPN SOMENTE WIREGUARD - PROIBIDO USAR VPN PROTON NESTE PROJETO"
- **Fontes consultadas:**
  - `~/opsec/docker-compose.yml` (gluetun: VPN_PROVIDER=protonvpn, FIREWALL=on)
  - `~/opsec/scripts/kill-switch.sh` (auditoria netns gluetun)
  - `~/opsec/scripts/verificar-vazamento.sh` (TESTE 4.5: netns gluetun)
  - `~/opsec/scripts/session-start-hacking-security.sh` (Etapa 2.5: compose up gluetun)
  - `~/opsec/scripts/iniciar-sessao.sh` (linha 47: kill-switch.sh on)
  - LEDGER.md (linhas 93-109: GOOD com Proton; linhas 566-615: LEAK sem Proton)
- **Arquitetura atual (rejeitada):** WireGuard + Proton(gluetun) + Tor
- **Arquitetura alvo (aceita):** WireGuard + Tor (wireguard é a VPN oficial)
- **Nota sobre WireGuard fail-closed:** WireGuard no kernel Linux é fail-closed por design. Se o túnel wg0 cai, o tráfego para (não roteia pela interface física). Isso elimina a necessidade de um kill-switch tradicional no netns. O teste 4.5 verifica se wg0 está ativo como indicador de proteção.

## REQUIREMENTS

### R1: Remover TESTE 4.5 do verificar-vazamento.sh

O TESTE 4.5 (linhas 91-116) verifica o kill-switch do gluetun no netns. Este teste deve ser **removido** porque gluetun não faz mais parte da cadeia.

**Substituto:** Verificar se o tráfego sai pela interface wg0 (WireGuard). Se wg0 está ativo, o tráfego está protegido pelo túnel WireGuard.

Novo TESTE 4.5:
- Verificar se `wg0` está ativo (`ip -o link show wg0`)
- Se ativo: PASS "WireGuard ativo - tráfego protegido pelo túnel wg0"
- Se inativo: WARN "WireGuard inativo - tráfego pode não estar protegido"
- NUNCA retornar LEAK por causa do kill-switch (WireGuard não tem kill-switch no netns como gluetun)

### R2: Reescrever kill-switch.sh para WireGuard

O kill-switch.sh atual audita o netns do gluetun. Deve ser reescrito para:
- **Modo AUDITOR WireGuard:** verificar se wg0 está ativo e se o tráfego sai pelo túnel
- Verificar se a interface física NÃO está roteando tráfego diretamente (sem VPN)
- Se wg0 ativo: PASS
- Se wg0 inativo: WARN (host pode estar sem proteção)
- NUNCA usar `nsenter` (não há netns do gluetun)
- Compatível com `on` e `off` (off = informativo, nada a restaurar)

### R3: Atualizar session-start-hacking-security.sh Etapa 2.5

A Etapa 2.5 (linhas 60-107) deve:
- **REMOVER** a inicialização do gluetun (`compose up -d gluetun`)
- Manter apenas `torproxy-host` (`compose up -d tor-host`)
- Remover verificação de `.env` (não mais necessário para Proton)
- Mantar health check do torproxy-host na porta 9050

### R4: Atualizar iniciar-sessao.sh

- A chamada `kill-switch.sh on` (linha 47) agora usa o novo kill-switch WireGuard
- Funcionará corretamente sem gluetun

### R5: Atualizar docker-compose.yml

- **MANTER** `tor-host` (torproxy-host): independente, sem dependência de gluetun
- **REMOVER** `gluetun` (serviço)
- **REMOVER** `tor-on-vpn` (depende de gluetun, não é necessário sem Proton)
- **REMOVER** `kali-sandbox` (depende de gluetun; sem VPN Proton, rede ficaria exposta)

### R6: Limpar referências a proton0/Proton em scripts

- `iniciar-sessao.sh` linha 30: remover `proton0` da lista de detecção de VPN
- `verificar-vazamento.sh` linha 21: remover `proton0` do loop de detecção
- `verificador-externo.sh` linha 34: remover `proton0` do grep de interface VPN
- `validar-dns-fix.sh`: remover referências textuais a Proton no output

### R7: Atualizar docs

- `~/opsec/README.md`: remover referências a gluetun/Proton como parte da cadeia
- `hacker-etico-ambiente/README.md`: atualizar descrição da cadeia
- `.opencode/rules/hacker-opsec-canon.md`: remover módulo gluetun, atualizar kill-switch

## FILES INVOLVED

- `~/opsec/scripts/verificar-vazamento.sh` (modificar: remover TESTE 4.5 gluetun, adicionar verificação wg0, limpar proton0)
- `~/opsec/scripts/kill-switch.sh` (reescrever: modo WireGuard)
- `~/opsec/scripts/session-start-hacking-security.sh` (modificar: Etapa 2.5 só tor-host)
- `~/opsec/scripts/iniciar-sessao.sh` (modificar: limpar proton0 da detecção)
- `~/opsec/scripts/verificador-externo.sh` (modificar: limpar proton0)
- `~/opsec/scripts/validar-dns-fix.sh` (modificar: limpar referências Proton)
- `~/opsec/scripts/teste-session-start.sh` (modificar: atualizar cenários para nova arquitetura)
- `~/opsec/docker-compose.yml` (modificar: remover gluetun, tor-on-vpn, kali-sandbox)
- `~/opsec/README.md` (atualizar doc)
- `hacker-etico-ambiente/README.md` (atualizar doc)
- `.opencode/rules/hacker-opsec-canon.md` (atualizar canon)

## RESTRICTIONS

- WireGuard (wg0) é a única VPN permitida
- Proton VPN e gluetun são PROIBIDOS neste projeto
- Tor (torproxy-host) continua sendo usado para anonimato
- Kill-switch agora é baseado em WireGuard, não em gluetun
- Scripts em ~/opsec/scripts/ são áreas sensíveis (classe C)
- Não quebrar testes existentes (cenários 1-6 do teste-session-start.sh precisam ser atualizados)

## EXPECTED DELIVERY

1. `verificar-vazamento.sh` sem TESTE 4.5 de gluetun; novo TESTE 4.5 verifica wg0
2. `kill-switch.sh` reescrito para auditar WireGuard (sem nsenter, sem gluetun)
3. `session-start-hacking-security.sh` Etapa 2.5 sobe apenas tor-host
4. `docker-compose.yml` sem dependência de gluetun para tor-host
5. Todos os scripts passam `bash -n`
6. `verificar-vazamento.sh` retorna GOOD com WireGuard + Tor (sem gluetun)
7. Testes do teste-session-start.sh atualizados para refletir nova arquitetura

## VERIFICATION

```bash
# Sintaxe
bash -n ~/opsec/scripts/verificar-vazamento.sh
bash -n ~/opsec/scripts/kill-switch.sh
bash -n ~/opsec/scripts/session-start-hacking-security.sh
bash -n ~/opsec/scripts/iniciar-sessao.sh

# Validação do compose
docker compose -f ~/opsec/docker-compose.yml config

# Validação funcional (com wg0 ativo e tor-host rodando)
bash ~/opsec/scripts/verificar-vazamento.sh
# Esperado: GOOD (sem LEAK de kill-switch)
```
