output "capacity_id" {
  description = "GUID nativo de Fabric de la capacity (el que consumen fabric_workspace)."
  value       = data.fabric_capacity.this.id
}

output "capacity_arm_id" {
  description = "Resource ID de ARM de la capacity."
  value       = azurerm_fabric_capacity.this.id
}

output "resource_group_name" {
  description = "Resource group que aloja la capacity."
  value       = azurerm_resource_group.this.name
}

output "capacity_name" {
  description = "Nombre final de la capacity."
  value       = azurerm_fabric_capacity.this.name
}
