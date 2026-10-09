# «Cabe en un fichero .tf»: el ejemplo mas pequeno posible.
# Un provider, una variable y un recurso: un workspace en una capacity existente.
#
#   cd examples/01-hola-workspace
#   terraform init
#   terraform apply -var "capacity_id=<GUID de la capacity>"
#   terraform destroy -var "capacity_id=<GUID de la capacity>"
#
# Autenticacion: FABRIC_TENANT_ID / FABRIC_CLIENT_ID / FABRIC_CLIENT_SECRET en el entorno.

terraform {
  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = "~> 1.14"
    }
  }
}

provider "fabric" {}

variable "capacity_id" {
  description = "GUID de Fabric de la capacity (terraform output capacity_id en la raiz del repo)."
  type        = string
}

resource "fabric_workspace" "hola" {
  display_name = "hola-netcoreconf"
  description  = "Mi primer workspace sin hacer clic"
  capacity_id  = var.capacity_id
}

output "workspace_url" {
  value = "https://app.fabric.microsoft.com/groups/${fabric_workspace.hola.id}"
}
