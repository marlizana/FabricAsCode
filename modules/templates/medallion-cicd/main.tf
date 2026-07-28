# Capas, entornos y roles se fijan aqui como locals (no como variables
# configurables): son la definicion misma de este template. Si se necesita
# otra combinacion, eso es un template nuevo, no una variante de este.
locals {
  layers       = ["bronze", "silver", "gold"]
  environments = ["dev", "test", "prod"]

  workspace_specs = {
    for pair in setproduct(local.layers, local.environments) :
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
