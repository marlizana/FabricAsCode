output "capacity_id" {
  description = "GUID nativo de Fabric de la capacity creada (el que consumen las workspaces)."
  value       = local.capacity_id
}

output "capacity_arm_id" {
  description = "Resource ID de ARM de la capacity (util para tags/RBAC de Azure)."
  value       = one(module.capacity[*].capacity_arm_id)
}

output "resource_group_name" {
  description = "Resource group creado para alojar la capacity."
  value       = one(module.capacity[*].resource_group_name)
}

output "workspace_ids" {
  description = "Workspace IDs del template activo ('<layer>-<env>' en medallion-cicd, asistente en workshop)."
  value       = coalesce(one(module.medallion_cicd[*].workspace_ids), one(module.workshop[*].workspace_ids))
}

output "ad_group_object_ids" {
  description = "Mapa '<layer>-<env>-<role>' -> object ID del grupo AD."
  value       = one(module.medallion_cicd[*].ad_group_object_ids)
}

output "github_repository_url" {
  description = "URL del repositorio GitHub de contenido Fabric, si enable_github_cicd esta activado."
  value       = var.enable_github_cicd ? github_repository.fabric_content[0].html_url : null
}

output "github_repository_clone_url" {
  description = "URL HTTPS para clonar el repositorio de contenido Fabric."
  value       = var.enable_github_cicd ? github_repository.fabric_content[0].http_clone_url : null
}

output "capacity_name" {
  description = "Nombre final de la capacity (con sufijo si randomize_capacity_name = true). Lo usa fab-ops.sh para pausar/reanudar."
  value       = one(module.capacity[*].capacity_name)
}

output "workshop_credentials" {
  description = "Credenciales de los asistentes (terraform output -json workshop_credentials)."
  sensitive   = true
  value       = one(module.workshop[*].credentials)
}

output "workshop_team_repo_url" {
  description = "Repo colaborativo del workshop."
  value       = one(module.workshop[*].team_repo_url)
}
