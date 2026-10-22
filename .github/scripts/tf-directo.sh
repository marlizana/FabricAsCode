#!/usr/bin/env bash
# Pasos comunes del workflow terraform-directo.yml.
#
#   tf-directo.sh nombre  "<texto libre>"   Normaliza el nombre que dice el publico
#   tf-directo.sh backend <proyecto>        Login del SP, storage del estado (lo crea si no
#                                           existe), terraform init y workspace del proyecto
#   tf-directo.sh capacity                  Busca la capacity de la demo grabada y comprueba
#                                           que esta encendida
#
# Necesita ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID y ARM_SUBSCRIPTION_ID.
set -euo pipefail

out() { [[ -n "${GITHUB_OUTPUT:-}" ]] && echo "$1=$2" >> "$GITHUB_OUTPUT"; echo "$1=$2"; }
fail() { echo "::error title=$1::$2"; exit 1; }

case "${1:-}" in
  nombre)
    # "Paella Valenciana!" -> "paella-valenciana"; "Ñandú 2" -> "nandu-2"
    p=$(python3 - "$2" <<'PY'
import re, sys, unicodedata
s = unicodedata.normalize("NFKD", sys.argv[1]).encode("ascii", "ignore").decode().lower()
s = re.sub(r"[^a-z0-9]+", "-", s).strip("-")[:24].strip("-")
if s and not s[0].isalpha():
    s = "p-" + s
print(s)
PY
)
    [[ "$p" =~ ^[a-z][a-z0-9-]{1,30}$ ]] || fail "Nombre no valido" "«$2» no deja un nombre usable (minusculas, digitos y guiones). Prueba con otro."
    for r in ${PROYECTOS_RESERVADOS:-ventas}; do
      [[ "$p" == "$r" ]] && fail "Nombre ocupado" "«$p» ya existe (es el de la demo grabada). Pide otro nombre al publico."
    done
    out proyecto "$p"
    ;;

  backend)
    proyecto="$2"
    # Las versiones nuevas de az CLI cambian -p por --client-secret: se prueba una y otra.
    az login --service-principal -u "$ARM_CLIENT_ID" --client-secret "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID" -o none 2>/dev/null \
      || az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID" -o none
    az account set -s "$ARM_SUBSCRIPTION_ID"

    # Storage del estado: nombre estable derivado de la suscripcion. Se crea la primera vez.
    rg="${TFSTATE_RG:-rg-fbc-tfstate}"
    sub="${ARM_SUBSCRIPTION_ID//-/}"
    sa="${TFSTATE_SA:-stfbctf${sub:0:12}}"
    az group create -n "$rg" -l "${TFSTATE_REGION:-spaincentral}" --tags managed_by=github-actions -o none
    if ! az storage account show -n "$sa" -g "$rg" -o none 2>/dev/null; then
      echo "Creando la storage account del estado: $sa"
      az storage account create -n "$sa" -g "$rg" -l "${TFSTATE_REGION:-spaincentral}" \
        --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 \
        --allow-blob-public-access false --allow-shared-key-access true -o none
    fi
    key=$(az storage account keys list -n "$sa" -g "$rg" --query '[0].value' -o tsv)
    echo "::add-mask::$key"
    az storage container create -n tfstate --account-name "$sa" --account-key "$key" -o none
    # El backend azurerm lee la clave de ARM_ACCESS_KEY: no queda en el plan ni en el log.
    [[ -n "${GITHUB_ENV:-}" ]] && echo "ARM_ACCESS_KEY=$key" >> "$GITHUB_ENV"
    export ARM_ACCESS_KEY="$key"

    cp backend.tf.example backend.tf
    terraform init -input=false \
      -backend-config="resource_group_name=$rg" \
      -backend-config="storage_account_name=$sa" \
      -backend-config="container_name=tfstate" \
      -backend-config="key=netcoreconf-directo.tfstate"
    # Un estado por proyecto: en el storage es el blob netcoreconf-directo.tfstateenv:<proyecto>
    terraform workspace select -or-create "$proyecto"
    ;;

  capacity)
    if [[ -n "${FABRIC_CAPACITY_ID:-}" ]]; then
      out capacity_id "$FABRIC_CAPACITY_ID"
      exit 0
    fi
    prefix="${CAPACITY_PREFIX:-fbcnetcoreconf}"
    tok=$(az account get-access-token --resource https://api.fabric.microsoft.com --query accessToken -o tsv)
    caps=$(curl -sSf -H "Authorization: Bearer $tok" https://api.fabric.microsoft.com/v1/capacities)
    sel=$(jq -c --arg p "$prefix" '[.value[] | select(.displayName | startswith($p))] | first // empty' <<<"$caps")
    [[ -n "$sel" ]] || fail "No hay capacity" "No encuentro ninguna capacity que empiece por «$prefix». ¿Se ha creado la de la demo grabada? (.\\scripts\\demo.ps1 apply)"
    name=$(jq -r .displayName <<<"$sel"); state=$(jq -r .state <<<"$sel")
    echo "Capacity: $name ($state)"
    [[ "$state" == "Active" ]] || fail "Capacity pausada" "La capacity $name esta $state. Reanudala antes: .\\scripts\\demo.ps1 reanuda"
    out capacity_id "$(jq -r .id <<<"$sel")"
    out capacity_name "$name"
    ;;

  *)
    echo "Uso: $0 nombre <texto> | backend <proyecto> | capacity" >&2; exit 2 ;;
esac
