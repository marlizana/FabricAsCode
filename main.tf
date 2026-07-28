data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}

locals {
  effective_capacity_admins = length(var.capacity_admin_members) > 0 ? (
    var.capacity_admin_members
  ) : [data.azurerm_client_config.current.object_id]

  effective_group_owners = length(var.ad_group_owners) > 0 ? (
    var.ad_group_owners
  ) : [data.azuread_client_config.current.object_id]
}

module "capacity" {
  source = "./modules/capacity"

  name                    = var.capacity_name
  sku                     = var.capacity_sku
  region                  = var.region
  admin_members           = local.effective_capacity_admins
  randomize_capacity_name = var.randomize_capacity_name
  tags                    = var.tags
}

# Terraform no permite seleccionar el `source` de un modulo dinamicamente:
# un bloque de modulo por template conocido, activado por count, es el patron
# estandar. Para sumar un template nuevo: crear modules/templates/<nombre>,
# anadirlo a la validacion de var.template, y agregar aqui un bloque analogo.
module "medallion_cicd" {
  count  = var.template == "medallion-cicd" ? 1 : 0
  source = "./modules/templates/medallion-cicd"

  project_name = var.project_name
  capacity_id  = module.capacity.capacity_id
  group_owners = local.effective_group_owners
}
