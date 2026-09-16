# Template de Contrato de Handoff (F9)

> Preenchido pelo orquestrador ANTES de despachar ao agente.
> O agente nasce sem memoria. O contrato e COMPLETO.

## Contrato

### OBJETIVO
[Descricao completa e inequivoca da tarefa]

### ARQUIVOS (paths exatos)
- [path 1]
- [path 2]

### INVARIANTES (regras que se aplicam)
- GATE DE PROTECAO GOOD obrigatorio antes de acao de rede.
- Sem IP real em nenhum registro (sempre IP de saida WireGuard/Proton/Tor).
- Uso etico: lab autorizado e pesquisas com escopo formal.
- Sem alteracao de escopo por conta propria.
- Sem git de escrita.

### PRE-FLIGHT REDE
```bash
bash ~/opsec/scripts/verificar-vazamento.sh
# GOOD obrigatorio antes de qualquer acao de rede.
```

### O QUE NAO FAZER
- Nao tocar arquivos fora da lista de ARQUIVOS.
- Nao introduzir dependencias novas sem aprovacao.
- Nao executar git de escrita.
- Nao "aproveitar e melhorar" nada adjacente.

### COMANDO DE VERIFICACAO
[comando especifico da tarefa, perfil: bash -n / shellcheck / py_compile / docker compose config / git diff --check]

### ECONOMIA (F9)
Leitura direcionada primeiro: grepar o trecho necessario antes de ler arquivo inteiro.

### FORMATO DO RESULTADO
- Diff dos arquivos tocados.
- Saida literal do comando de verificacao.
- CONFIANCA/LACUNAS: o que NAO foi verificado e por que.

### PLANO ORIGINAL
`.opencode/plans/PLAN_NNN_nome-descritivo.md` (referencia)