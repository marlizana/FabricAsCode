variable "project_name" {
  description = "Nombre del dominio/proyecto usado como prefijo de workspaces y grupos AD (ej. ventas)."
  type        = string
}

variable "capacity_id" {
  description = "GUID nativo de Fabric de la capacity compartida por las 9 workspaces."
  type        = string
}

variable "group_owners" {
  description = "Object IDs que seran owners de los grupos AD creados para cada workspace."
  type        = list(string)
}
