#!/usr/bin/env bash
#
# Publica (o actualiza) el comentario "sticky" con el diagnóstico de triage
# en el issue que disparó el workflow.
#
# Uso: ./scripts/upsert-triage-comment.sh ruta/al/diagnostico.md
#
# El número de issue se lee del payload del evento (nunca de un argumento),
# igual que en edit-issue-labels.sh. Un marcador HTML oculto al inicio del
# cuerpo permite encontrar el comentario anterior y reescribirlo en vez de
# crear uno nuevo en cada edición del issue.
#

set -euo pipefail

MARKER="<!-- claude-triage-diagnostico -->"

BODY_FILE="${1:?Uso: upsert-triage-comment.sh <fichero-markdown>}"
if [[ ! -f "$BODY_FILE" ]]; then
  echo "Error: no se encuentra $BODY_FILE" >&2
  exit 1
fi

ISSUE=$(jq -r '.issue.number // empty' "${GITHUB_EVENT_PATH:?GITHUB_EVENT_PATH not set}")
if ! [[ "$ISSUE" =~ ^[0-9]+$ ]]; then
  echo "Error: no hay número de issue en el payload del evento" >&2
  exit 1
fi

REPO="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY not set}"

# Antepone el marcador al fichero de diagnóstico en un fichero temporal,
# sin modificar el original.
TMP_BODY=$(mktemp)
trap 'rm -f "$TMP_BODY"' EXIT
{
  echo "$MARKER"
  echo
  cat "$BODY_FILE"
} >"$TMP_BODY"

# El marcador es una constante fija (sin comillas ni backslashes), así que
# se puede interpolar directamente en el filtro jq.
JQ_FILTER=$(printf '[.[] | select(.body | startswith("%s"))] | last | .id // empty' "$MARKER")
EXISTING_ID=$(gh api "repos/$REPO/issues/$ISSUE/comments" --paginate --jq "$JQ_FILTER")

if [[ -n "$EXISTING_ID" ]]; then
  gh api -X PATCH "repos/$REPO/issues/comments/$EXISTING_ID" -F body=@"$TMP_BODY" >/dev/null
  echo "Comentario de triage actualizado (id $EXISTING_ID)"
else
  gh api -X POST "repos/$REPO/issues/$ISSUE/comments" -F body=@"$TMP_BODY" >/dev/null
  echo "Comentario de triage creado"
fi
