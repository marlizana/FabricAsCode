#!/usr/bin/env bash
# Operaciones del dia a dia con Fabric CLI (fab), el tramo imperativo de la demo:
#   Terraform declara la infraestructura, fabric-cicd promociona el contenido,
#   y fab se encarga de lo que es una accion puntual: encender, apagar, ejecutar.
#
# Uso: scripts/fab-ops.sh <accion> [entorno]
#   status            Capacity y workspaces del proyecto
#   resume            Reanuda la capacity
#   pause             Pausa la capacity (hazlo SIEMPRE al acabar: los creditos corren)
#   run   <env>       Ejecuta nb_ingest_bronze y despues nb_clean_silver en <env>
#   tables <env>      Lista las tablas de bronze y silver en <env>
#   optimize <env>    OPTIMIZE con V-Order de las tablas de la demo en <env>
#
# Variables de entorno:
#   FABRIC_CLIENT_ID, FABRIC_CLIENT_SECRET, FABRIC_TENANT_ID   (service principal)
#   FABRIC_PROJECT_NAME   prefijo de workspaces (ej. demo)
#   FABRIC_CAPACITY_NAME  nombre de la capacity (output capacity_name de Terraform)
# Si no hay credenciales de SP, usa la sesion que ya tengas abierta con `fab auth login`.

set -euo pipefail

action="${1:-status}"
env="${2:-dev}"
project="${FABRIC_PROJECT_NAME:?Define FABRIC_PROJECT_NAME}"
capacity="${FABRIC_CAPACITY_NAME:-}"

login() {
  # En el runner no hay keyring y fab no puede cifrar su cache de tokens (EncryptionFailed).
  # El runner es efimero, asi que se permite la cache en claro.
  [[ -n "${GITHUB_ACTIONS:-}" ]] && fab config set encryption_fallback_enabled true >/dev/null 2>&1
  # Con las variables FAB_SPN_* fab se autentica solo, sin `fab auth login`.
  if [[ -n "${FABRIC_CLIENT_ID:-}" && -n "${FABRIC_CLIENT_SECRET:-}" && -n "${FABRIC_TENANT_ID:-}" ]]; then
    export FAB_SPN_CLIENT_ID="$FABRIC_CLIENT_ID"
    export FAB_SPN_CLIENT_SECRET="$FABRIC_CLIENT_SECRET"
    export FAB_TENANT_ID="$FABRIC_TENANT_ID"
  fi
}

# Ejecuta fab y, si falla, deja el error como anotacion de GitHub (se ve en el resumen del run).
f() {
  local out rc=0
  out=$(fab "$@" 2>&1) || rc=$?
  echo "$out"
  if (( rc != 0 )); then
    [[ -n "${GITHUB_ACTIONS:-}" ]] && echo "::error title=fab $1 $2::$(echo "$out" | tail -n 6 | tr '\n' ' ')"
    return $rc
  fi
}

need_capacity() {
  [[ -n "$capacity" ]] || { echo "Define FABRIC_CAPACITY_NAME (terraform output -raw capacity_name)" >&2; exit 1; }
}

ws() { echo "${project}-$1-${env}.Workspace"; }

login

case "$action" in
  status)
    echo "== Capacities"
    f ls .capacities -l
    echo "== Workspaces de '${project}'"
    f ls -l -q "[?starts_with(name, '${project}-')]"
    ;;
  resume)
    need_capacity
    f start ".capacities/${capacity}.Capacity" -f
    ;;
  pause)
    need_capacity
    # Si ya estaba pausada fab devuelve error; no es un fallo para la pausa nocturna.
    f stop ".capacities/${capacity}.Capacity" -f || echo "La capacity ya estaba pausada (o no se pudo pausar: revisa el portal)."
    ;;
  run)
    echo "== $(ws bronze): nb_ingest_bronze"
    f job run "$(ws bronze)/nb_ingest_bronze.Notebook" --timeout 1200
    echo "== $(ws silver): nb_clean_silver"
    f job run "$(ws silver)/nb_clean_silver.Notebook" --timeout 1200
    ;;
  tables)
    f ls "$(ws bronze)/lh_bronze.Lakehouse/Tables"
    f ls "$(ws silver)/lh_silver.Lakehouse/Tables"
    ;;
  optimize)
    f table optimize "$(ws bronze)/lh_bronze.Lakehouse/Tables/sales_raw" --vorder
    f table optimize "$(ws silver)/lh_silver.Lakehouse/Tables/sales" --vorder
    ;;
  *)
    sed -n '2,20p' "$0"
    exit 1
    ;;
esac
