data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}

locals {
  # La identidad que ejecuta Terraform siempre es admin de la capacity (la necesita
  # para asignar workspaces); var.capacity_admin_members suma personas a esa lista.
  effective_capacity_admins = distinct(concat(
    var.capacity_admin_members,
    [data.azurerm_client_config.current.object_id]
  ))

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
  layers       = var.layers
  environments = var.environments
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
    ".github/workflows/fabric-ops.yml"    = file("${path.module}/.github/workflows/fabric-ops.yml")
    "scripts/fab-ops.sh"                  = file("${path.module}/scripts/fab-ops.sh")
  } : {}

  # Todo lo que haya bajo fabric-content/ (parameter.yml e items de ejemplo) se
  # siembra tal cual en el repo de contenido, preservando rutas.
  github_content_files = var.enable_github_cicd ? {
    for f in fileset("${path.module}/fabric-content", "**") :
    "fabric-content/${f}" => file("${path.module}/fabric-content/${f}")
  } : {}
}

resource "github_repository_file" "bootstrap" {
  for_each = merge(local.github_bootstrap_files, local.github_content_files)

  repository          = github_repository.fabric_content[0].name
  branch              = "main"
  file                = each.key
  content             = each.value
  commit_message      = "Bootstrap Fabric CI/CD"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.invalid"
  overwrite_on_create = true
}

# Presupuesto mensual sobre la suscripcion: con creditos de patrocinio es la red de
# seguridad para no quemarlos con una capacity olvidada encendida.
data "azurerm_subscription" "current" {}

resource "azurerm_consumption_budget_subscription" "this" {
  count = var.budget_amount > 0 ? 1 : 0

  name            = "budget-fbc-${var.project_name}"
  subscription_id = data.azurerm_subscription.current.id
  amount          = var.budget_amount
  time_grain      = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
  }

  dynamic "notification" {
    for_each = [50, 80, 100]
    content {
      enabled        = true
      threshold      = notification.value
      operator       = "GreaterThanOrEqualTo"
      threshold_type = "Actual"
      contact_emails = var.budget_contact_emails
    }
  }

  lifecycle {
    # start_date se calcula en el primer apply; no recrear el budget cada mes.
    ignore_changes = [time_period]
  }
}
