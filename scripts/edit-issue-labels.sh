#!/usr/bin/env bash
#
# Aplica labels a un issue de GitHub.
# Uso: ./scripts/edit-issue-labels.sh --add-label bug --add-label needs-triage --remove-label untriaged
#
# El número de issue se lee del payload del evento (nunca de un argumento),
# para que Claude solo pueda etiquetar el issue que disparó el workflow.
#

set -euo pipefail

ISSUE=$(jq -r '.issue.number // empty' "${GITHUB_EVENT_PATH:?GITHUB_EVENT_PATH not set}")
if ! [[ "$ISSUE" =~ ^[0-9]+$ ]]; then
  echo "Error: no hay número de issue en el payload del evento" >&2
  exit 1
fi

ADD_LABELS=()
REMOVE_LABELS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --add-label)
      ADD_LABELS+=("$2")
      shift 2
      ;;
    --remove-label)
      REMOVE_LABELS+=("$2")
      shift 2
      ;;
    *)
      echo "Error: argumento desconocido (solo se aceptan --add-label y --remove-label)" >&2
      exit 1
      ;;
  esac
done

if [[ ${#ADD_LABELS[@]} -eq 0 && ${#REMOVE_LABELS[@]} -eq 0 ]]; then
  exit 1
fi

# Solo se aplican labels que realmente existen en el repo (evita fallos por
# labels alucinados o mal escritos).
VALID_LABELS=$(gh label list --limit 500 --json name --jq '.[].name')

FILTERED_ADD=()
for label in "${ADD_LABELS[@]}"; do
  if grep -qxF "$label" <<<"$VALID_LABELS"; then
    FILTERED_ADD+=("$label")
  fi
done

FILTERED_REMOVE=()
for label in "${REMOVE_LABELS[@]}"; do
  if grep -qxF "$label" <<<"$VALID_LABELS"; then
    FILTERED_REMOVE+=("$label")
  fi
done

if [[ ${#FILTERED_ADD[@]} -eq 0 && ${#FILTERED_REMOVE[@]} -eq 0 ]]; then
  exit 0
fi

GH_ARGS=("issue" "edit" "$ISSUE")

for label in "${FILTERED_ADD[@]}"; do
  GH_ARGS+=("--add-label" "$label")
done

for label in "${FILTERED_REMOVE[@]}"; do
  GH_ARGS+=("--remove-label" "$label")
done

gh "${GH_ARGS[@]}"

if [[ ${#FILTERED_ADD[@]} -gt 0 ]]; then
  echo "Añadidos: ${FILTERED_ADD[*]}"
fi
if [[ ${#FILTERED_REMOVE[@]} -gt 0 ]]; then
  echo "Eliminados: ${FILTERED_REMOVE[*]}"
fi
