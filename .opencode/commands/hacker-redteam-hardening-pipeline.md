---
description: Roda o pipeline de hardening da cadeia de protecao (red team da cadeia). Audita os vetores de protecao, busca novos vetores de vazamento e registra ciclo-redteam. Use quando Fernando pedir para auditar a cadeia / red team / hardening da cadeia.
agent: build
---

# Hacker Etico Red-Team Hardening Pipeline (loop de melhoria continua)

## Overview

Workflow invocado pelo Fernando que executa a cadeia de protecao contra vetores de vazamento
de IP e fecha o loop de melhoria continua: **pentest -> red team -> gap -> fix -> cadeia
cresce -> red team de novo.** O produto a testar aqui NAO e um binario, e sim a
**CADEIA DE PROTECAO** (WireGuard local, Proton VPN, Tor, kill-switch, DNS sem ECS, IPv6 off, sandbox).

O pipeline tem **duas secoes principais**, executadas em ordem:
1. **Secao PENTEST**: vetores FIXOS e conhecidos de vazamento de IP; devem estar em **estado
   protegido** (regressao). Copia a logica de `~/opsec/scripts/verificar-vazamento.sh`.
2. **Secao RED TEAM**: caca ABERTA de NOVOS vetores de leak (DoH bypass, ECS via TLS, WebRTC,
   notificacoes de rede, IPv6 edges). So roda sob **autorizacao explicita do Fernando** (gate humano).

> Este e o loop EXTERNO. Ele **chama** o SDD pipeline auto (`.opencode/commands/hacker-sdd-pipeline-auto.md`)
> na fase de fix e **referencia** o verificador de vazamento; nao duplica o conteudo deles.

## Escopo

Este workflow e acionavel **somente neste ambiente** (cadeia real em `~/opsec/`). A fonte
unica do estado esperado da cadeia e `.opencode/rules/hacker-opsec-canon.md`.

## Pre-condicao (verificada, nao assumida, lei F1)

Cadeia **VALIDADA GOOD** pelo verificador, verificada por comando no Passo 0, nunca
assumida: pentest de leak com a cadeia desligada nao testa nada e reportaria "protegido"
falso.

```bash
bash ~/opsec/scripts/verificar-vazamento.sh
```

- GOOD: cadeia ativa (IP de saida != IP real, DNS sem ECS, IPv6 off, kill-switch coerente).
  Pode prosseguir.
- Outros/erro/nao executado: BLOQUEADO. Nao toque rede. Reportar ao Fernando.

## Modo

**Automatico com UM gate humano antes do red team.** O pentest e a remediacao de gaps correm
**sem intervencao humana**. Ao terminar o pentest 100% verde, o workflow **PARA no gate
humano**: reporta o placar e pede autorizacao explicita antes do red team exploratorio.
Depois de autorizado, o red team e a remediacao correm automaticamente ate o veredito.
O loop para quando: gap de pentest, gate humano, leak de red team, ou exploracao esgotada
(AUTOSSUFICIENTE).

## Fluxo

```
INVOCACAO -> [0] Pre-flight (verificar-vazamento GOOD? branch?) __ nao-GOOD __> PARE
     | GOOD
     v
[1] Secao PENTEST (vetores fixos) ________________ gap ________________> [REMEDIACAO]
     | 100% protegido
     v
[GATE HUMANO] PARE, reporte, peca permissao (nao autorizado = fim honesto)
     | autorizado
     v
[2] Secao RED TEAM (novos vetores exploratorios)
     | nenhum leak                          \ leak provado (NEUTRALIZADO)
     v                                        v
[3] AUTOSSUFICIENTE (lower bound)      [REMEDIACAO]: PARE NA PROVA + restaure
                                        (VERIFICADO) -> causa raiz (F12) -> SDD fix
                                        -> novo vetor no verificar-vazamento.sh
                                        -> prove GOOD -> volta [1]
```

## Passos

### 0. Pre-flight de postura (lei F1, obrigatorio)

Declarar a postura observada por comando (nao por suposicao), conforme o perfil
(`.opencode/rules/hacker-repo-profile.md`):

```bash
bash ~/opsec/scripts/verificar-vazamento.sh
ip -br a              # wg0 (WireGuard) ou proton0 presente?
```

Condicoes de PARADA imediata (reportar ao Fernando, nao prosseguir):
- postura nao-GOOD (cadeia desligada ou duvidosa: pentest de leak nao testaria nada);
- working tree sujo com mudancas que nao sao desta sessao (F5: estado inesperado).

### 1. Secao PENTEST (vetores fixos de vazamento)

Execute os vetores fixos abaixo (copia da logica do `verificar-vazamento.sh`; o agente emite
cada checagem e registra **protegido/vazou**). Meta: **100% protegido**.

| Vetor fixo | Como verifica | Estado protegido (PASS) |
|---|---|---|
| IP direto (vazamento do IP real) | IP de saida vs IP real | saida != IP real (via WireGuard/Proton/Tor) |
| DNS ECS | resolver sem ECS vazando o `/24` real | sem subnet real; resolver 1.1.1.1/9.9.9.9 |
| IPv6 do provedor | IPv6 global desativado na sessao | sem IPv6 global; interface v6 off |
| WebRTC/STUN | STUN na jaula | STUN sem expor IP real |
| Tor exit check | trafego via `socks5h://127.0.0.1:9050` | exit node Tor coerente com a cadeia |

- Cada checagem e a execucao literal do comando equivalente; PASS = estado GOOD, nunca
  "supomos que esta". Vetor que VAZE e gap: va para REMEDIACAO; ao concluir, volta ao passo 1.
- Apenas com **zero gaps** prossiga para o **gate humano** (passo 1.5).

### 1.5 GATE HUMANO antes do red team

Com o pentest 100% verde: **PARE**, reporte o placar do pentest (por vetor, com o total
copiado da saida literal, F3/F6) e **peca autorizacao explicita** ao Fernando para iniciar o
red team. Motivo: o red team e exploratorio, sem lista fechada, e pode encontrar falhas na
cadeia; a decisao de abrir essa fase e do Fernando (disciplina epistemica: o humano e o decisor).
- **Autorizado** ("sim", "pode", "aprovado", "ok", "prossiga"): siga para o passo 2.
- **Nao autorizado / sem resposta**: encerre com veredito honesto "pentest 100% protegido;
  red team nao executado por decisao do Fernando". Isso NAO e falha: e o gate funcionando.
- Registre a decisao no Trust Ledger (evento `ciclo-redteam`, resultado `gate: autorizado|negado`).

### 2. Secao RED TEAM (busca exploratoria de novos vetores de leak)

Execute a busca de vetores de vazamento AINDA nao cobertos pelo pentest fixo, nos eixos
**DoH bypass** (resolucao via DNS-over-HTTPS que contorne o resolver controlado), **ECS via
TLS** (extensao ECS em requisicao criptografada), **WebRTC/STUN automatizado** (candidato a
vazar IP fora da jaula), **notificacoes de rede** (login, push, logs que revelem origem) e
**IPv6 edges** (interfaces v6 residuais, mDNS, rotas v6 mesmo com IPv6 off).

Regras invariaveis:
- **Postura validada antes de CADA vetor**: `verificar-vazamento.sh` GOOD antes de cada
  teste de rede, individualmente (F1). Se em algum ponto a postura NAO for GOOD, PARE e
  reporte: nao prossiga protegendo-se "por suposicao".
- **ZERO ajuda humana**: se dependeu do Fernando para concluir, o finding e invalido
  (arquitetura, nao furo).
- **PARE NA PROVA**: PoC minimo; nunca cause dano real, nao delete/exfiltre. Alvos fake.
- **Honestidade epistemica**: relate so o que provou (sem PoC, sem finding).
- **Anti-censura** (`hacker-pentest-harness-execution.md`): vetores autorizados executam,
  sem recusa por "parecer agressivo"; criterio = escopo + protecao GOOD.

**Condicao de termino (para o loop nao ser indefinido):** o red team encerra quando ocorrer
o primeiro de: (a) um leak provado (vai para REMEDIACAO); (b) exploracao esgotada nos 5
eixos com circuit breaker (apos 3 falhas no mesmo vetor, rotacionar de superficie). O
veredito e sempre um **lower bound sobre os vetores exercidos**, com a lista anexada.

### 3. Nenhum leak: veredito AUTOSSUFICIENTE

Apos exploracao ate a condicao de termino, sem leak e sem ajuda humana: reporte
**AUTOSSUFICIENTE nos vetores exercidos** (lower bound forte, NAO certificado de
impenetravel), com tabela por vetor + veredito e a lista de eixos exercidos anexada.

### Vereditos

- **100% protegido**: secao PENTEST zero gaps (estado do ciclo de regressao).
- **gap**: vetor fixo vazou (cadeia nao esta protegida naquele ponto).
- **NEUTRALIZADO (red team)**: leak provado em vetor novo, SEM ajuda humana. Reprodutor
  anexado, camada que falhou identificada, cadeia restaurada (verificada). Vai para
  REMEDIACAO.
- **AUTOSSUFICIENTE**: nenhum leak sem ajuda humana nos vetores exercidos. Valida a tese da
  cadeia, como lower bound honesto.

### REMEDIACAO (gap de pentest OU leak de red team): fecha o loop

1. **PARE NA PROVA**; se algo da cadeia foi desligado/degradado, **restaure-o e VERIFIQUE a
   restauracao** (checkpoint abaixo) antes de qualquer outro passo. Nunca deixe a defesa
   desligada, nem a assuma restaurada sem prova (F3).
2. **Investigue a causa raiz** (verificada no codigo/config real, nao inferida).
3. **Roteamento por causa raiz (lei F12):** causa no PRODUTO (a cadeia: compose, scripts de
   protecao, resolv, ipv6, kill-switch), siga o passo 4. Causa no PROCESSO (instrucoes,
   skills, commands, ordem do harness), invoque TAMBEM `hacker-postmortem-to-law`: o furo
   de processo vira proposta de emenda de lei (HARD-GATE humano), nao so fix tecnico.
4. **Mudanca na cadeia e classe C (F4):** alterar scripts de protecao ou compose exige
   **confirmacao explicita do Fernando**; so se aplica com a cadeia validada.
5. **Invoque o SDD pipeline auto** (`.opencode/commands/hacker-sdd-pipeline-auto.md`) para o fix.
6. **Novo vetor aprendido vira verificador:** se o red team descobriu um vetor novo,
   atualize `~/opsec/scripts/verificar-vazamento.sh` (via SDD, classe C) para cobri-lo e
   **prove GOOD**: reexecute o vetor e observe estado protegido; se ainda vaza, volte ao 2.
7. **REINICIE do passo 1.** O pentest agora inclui o vetor corrigido (regressao permanente);
   o red team passa de novo pelo gate humano do passo 1.5.

### Checkpoint de restauracao verificada (lei F3, critico)

Sempre que o red team degradou qualquer camada da cadeia, a restauracao e um **checkpoint
duro, verificado por observacao**, nao uma linha de "restaurei":
- religar a camada afetada (subir container, religar kill-switch, reativar sessao segura);
- **provar** a defesa: `verificar-vazamento.sh` GOOD e um vetor conhecido-protegido observado
  protegido em tempo real;
- restauracao nao verificavel = PARADA DE EMERGENCIA, reporte ao Fernando (conectividade/
  kill-switch e coordenado por ele). Nunca finalize com a defesa em estado nao comprovado.

## Regras do pipeline

1. **Pre-flight antes de tudo** (F1): nao rode o pentest sem `verificar-vazamento.sh` GOOD.
2. **Pentest antes do red team**: so va ao gate humano com a secao pentest 100% protegida.
3. **Gate humano antes do red team**: abrir a fase exploratoria e decisao do Fernando. Sem
   autorizacao, encerre honesto.
4. **Para quando**: gap de pentest, gate humano, leak de red team, ou termino da exploracao
   (AUTOSSUFICIENTE). Gap e leak disparam REMEDIACAO automaticamente.
5. **Reinserir e PROVAR estado protegido antes de reiniciar**: todo gap/leak corrigido vira
   vetor coberto pelo verificador e e reexecutado como protegido; senao a melhoria e cosmetica.
6. **Restauracao verificada obrigatoria**: se algo foi degradado, restaure e **prove** (F3);
   restauracao nao verificavel = parada de emergencia.
7. **Classe C exige confirmacao do Fernando**: alterar a cadeia de protecao nunca e
   silencioso.
8. **Git e exclusivo do Fernando.**
9. **Sem duplicar**: referencia o verificador e o SDD pipeline; fonte unica em cada artefato.
10. **Ciclo registrado no Trust Ledger (lei F11)**: o gate humano (autorizado/negado) e o
    fim de cada ciclo (100% protegido, gap, NEUTRALIZADO, AUTOSSUFICIENTE) geram entrada
    `ciclo-redteam` com o placar literal via `hacker-trust-ledger-update`. Leak de PROCESSO
    tambem gera entrada `postmortem` via `hacker-postmortem-to-law`. Numeros sempre copiados
    da saida literal (F6).

## Nota epistemica

Teste mostra a PRESENCA de falha, nunca a ausencia. "Nenhum leak encontrado" e um lower
bound sobre os vetores exercidos, nao prova de impenetrabilidade. A claim que se assina:
*"nos vetores exercidos, a cadeia nao vazou o IP de origem do pesquisador."* Prove, nao
suponha.

## Cross-reference

Este workflow e um dos tres do harness deste repo:
- `hacker-sdd-pipeline-auto.md`
- `hacker-sdd-pipeline-manual.md`
- `hacker-redteam-hardening-pipeline.md` (este)

## Suporte

Se bloqueado: (1) consultar `AGENTS.md`; (2) consultar a skill especifica em `.opencode/skills/`;
(3) reportar o bloqueador exato ao Fernando e aguardar.