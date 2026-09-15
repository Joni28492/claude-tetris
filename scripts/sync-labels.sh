#!/usr/bin/env bash
#
# Crea o actualiza en el repo los labels definidos en .github/labels.json.
# Idempotente: se puede ejecutar en cada run del workflow sin duplicar nada.
#
# Requiere: gh CLI autenticado (GH_TOKEN en el entorno) y jq.
#

set -euo pipefail

LABELS_FILE="${1:-.github/labels.json}"

if [[ ! -f "$LABELS_FILE" ]]; then
  echo "Error: no se encuentra $LABELS_FILE" >&2
  exit 1
fi

jq -c '.[]' "$LABELS_FILE" | while read -r label; do
  name=$(jq -r '.name' <<<"$label")
  color=$(jq -r '.color' <<<"$label")
  description=$(jq -r '.description' <<<"$label")

  gh label create "$name" --color "$color" --description "$description" --force
  echo "Sincronizado: $name"
done
