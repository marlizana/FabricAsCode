output "workspace_ids" {
  description = "Mapa '<layer>-<env>' -> Fabric workspace ID (9 entradas)."
  value       = { for k, m in module.workspace : k => m.workspace_id }
}

output "ad_group_object_ids" {
  description = "Mapa '<layer>-<env>-<role>' -> object ID del grupo AD (36 entradas)."
  value = merge([
    for wk, m in module.workspace : {
      for role, oid in m.group_object_ids : "${wk}-${lower(role)}" => oid
    }
  ]...)
}
