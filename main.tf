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

resource "github_repository" "fabric_content" {
  count = var.enable_github_cicd ? 1 : 0

  name        = var.github_repository_name
  description = "Contenido de Microsoft Fabric desplegado con fabric-cicd."
  visibility  = var.github_repository_visibility

  has_issues      = true
  has_projects    = false
  has_wiki        = false
  has_discussions = false
  auto_init       = true
}

locals {
  github_bootstrap_files = var.enable_github_cicd ? {
    ".github/scripts/deploy.py"           = file("${path.module}/.github/scripts/deploy.py")
    ".github/workflows/fabric-cicd.yml"   = file("${path.module}/.github/workflows/fabric-cicd.yml")
    "requirements.txt"                    = file("${path.module}/requirements.txt")
    "fabric-content/bronze/parameter.yml" = file("${path.module}/fabric-content/bronze/parameter.yml")
    "fabric-content/silver/parameter.yml" = file("${path.module}/fabric-content/silver/parameter.yml")
    "fabric-content/gold/parameter.yml"   = file("${path.module}/fabric-content/gold/parameter.yml")
  } : {}
}

resource "github_repository_file" "bootstrap" {
  for_each = local.github_bootstrap_files

  repository          = github_repository.fabric_content[0].name
  branch              = "main"
  file                = each.key
  content             = each.value
  commit_message      = "Bootstrap Fabric CI/CD"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.invalid"
  overwrite_on_create = true
}
