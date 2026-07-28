resource "azurerm_resource_group" "this" {
  name     = "rg-fbc-${var.name}"
  location = var.region
  tags     = var.tags
}

# Sufijo estable entre re-applies: keepers ata la regeneracion unicamente a
# cambios en var.name, no a cada plan/apply.
resource "random_string" "suffix" {
  count = var.randomize_capacity_name ? 1 : 0

  length  = 4
  special = false
  upper   = false

  keepers = {
    name = var.name
  }
}

locals {
  resolved_name = var.randomize_capacity_name ? "${var.name}${random_string.suffix[0].result}" : var.name
}

resource "azurerm_fabric_capacity" "this" {
  name                   = local.resolved_name
  resource_group_name    = azurerm_resource_group.this.name
  location               = var.region
  administration_members = var.admin_members
  tags                   = var.tags

  sku {
    name = var.sku
    tier = "Fabric"
  }
}

# fabric_workspace.capacity_id espera el GUID nativo de Fabric, no el Resource
# ID de ARM que exporta azurerm_fabric_capacity.id: son dos espacios de
# identificadores distintos. Esta data source hace de puente entre ambos.
data "fabric_capacity" "this" {
  display_name = azurerm_fabric_capacity.this.name
}
