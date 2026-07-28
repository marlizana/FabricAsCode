output "workspace_id" {
  description = "ID de la Fabric workspace."
  value       = fabric_workspace.this.id
}

output "workspace_display_name" {
  description = "Display name de la Fabric workspace."
  value       = fabric_workspace.this.display_name
}

output "group_object_ids" {
  description = "Mapa <rol> -> object ID del grupo AD creado para ese rol."
  value       = { for role, group in azuread_group.roles : role => group.object_id }
}
