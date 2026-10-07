# Capas y entornos llegan como variables (por defecto bronze/silver/gold x
# dev/test/prod): anadir "qa" es cambiar una lista, no copiar bloques.
# Los roles siguen fijos: son la definicion de seguridad de este template.
locals {
  workspace_specs = {
    for pair in setproduct(var.layers, var.environments) :
    "${pair[0]}-${pair[1]}" => {
      domain = "${var.project_name}-${pair[0]}" # ej. "ventas-bronze"
      env    = pair[1]
    }
  }
}

module "workspace" {
  source   = "../../workspace-with-roles"
  for_each = local.workspace_specs

  workspace_name  = "${each.value.domain}-${each.value.env}" # "ventas-bronze-dev"
  description     = "Medallion ${each.value.domain} / ${each.value.env}"
  capacity_id     = var.capacity_id
  ad_group_prefix = "sg-fbc-${each.value.domain}-${each.value.env}" # "sg-fbc-ventas-bronze-dev"
  group_owners    = var.group_owners
}
