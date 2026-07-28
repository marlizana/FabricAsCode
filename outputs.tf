output "capacity_id" {
  description = "GUID nativo de Fabric de la capacity creada (el que consumen las workspaces)."
  value       = module.capacity.capacity_id
}

output "capacity_arm_id" {
  description = "Resource ID de ARM de la capacity (util para tags/RBAC de Azure)."
  value       = module.capacity.capacity_arm_id
}

output "resource_group_name" {
  description = "Resource group creado para alojar la capacity."
  value       = module.capacity.resource_group_name
}

output "workspace_ids" {
  description = "Mapa '<layer>-<env>' -> Fabric workspace ID (9 entradas para medallion-cicd)."
  value       = one(module.medallion_cicd[*].workspace_ids)
}

output "ad_group_object_ids" {
  description = "Mapa '<layer>-<env>-<role>' -> object ID del grupo AD (36 entradas para medallion-cicd)."
  value       = one(module.medallion_cicd[*].ad_group_object_ids)
}
