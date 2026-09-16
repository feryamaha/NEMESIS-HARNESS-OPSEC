#!/usr/bin/env bash
# build-rag.sh: gera fable-harness-completo.md (concatenaccao 1:1 dos 15 arquivos Fable)
# para carga total (opcao 1 do README do Fable) e verifica integridade do espelho RAG.
# Uso: bash .opencode/rag/build-rag.sh
# Requisito: nada fora do bash. Nao altera o espelho ./fable/.
set -euo pipefail

RAG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FABLE_DIR="$RAG_DIR/fable"
OUT="$RAG_DIR/fable-harness-completo.md"
SRC_FORA="/home/fernando/Downloads/Fable_Knowledge_Harness"

echo "==> Gerando $OUT (concatenaccao 1:1, ordem do README original)"

cat "$FABLE_DIR"/Core_Workflow/*.md \
    "$FABLE_DIR"/Debugging_and_Verification/*.md \
    "$FABLE_DIR"/Decision_Making_and_Judgment/*.md \
    "$FABLE_DIR"/Failure_Modes_and_Prevention/*.md \
    "$FABLE_DIR"/Advanced_Techniques/*.md > "$OUT"

echo "   linhas do arquivo gerado: $(wc -l < "$OUT")"
echo "   somas de linhas por fonte: $(find "$FABLE_DIR" -name '*.md' -not -name 'README*' | xargs wc -l | tail -1 | awk '{print $1}')"

echo "==> Verificando integridade do espelho vs origem"

if diff -r "$SRC_FORA" "$FABLE_DIR" >/dev/null 2>&1; then
    echo "   ESPELHO 1:1 INTEGRO"
else
    echo "   ESPELHO DIVERGENTE: rodar 'diff -r \"$SRC_FORA\" \"$FABLE_DIR\"' e reconciliar"
    exit 1
fi

echo "==> Verificando que cada skill esta presente no arquivo gerado"

OK=1
for f in "$FABLE_DIR"/*/*.md; do
    skill_name="$(grep -m1 '^name: ' "$f" | sed 's/^name: //')"
    if ! grep -q "^name: $skill_name\$" "$OUT"; then
        echo "   FALTANDO no gerado: $skill_name"
        OK=0
    fi
done
if [ "$OK" -eq 1 ]; then
    echo "   TODAS AS 15 SKILLS PRESENTES NO GERADO"
else
    echo "   FALHA na verificacao de presenca"
    exit 1
fi

echo "==> RAG pronto: '$OUT' (carga total) e espelho verificado"