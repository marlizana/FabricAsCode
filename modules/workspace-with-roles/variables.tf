variable "workspace_name" {
  description = "Display name de la Fabric workspace."
  type        = string
}

variable "description" {
  description = "Descripcion de la Fabric workspace."
  type        = string
  default     = ""
}

variable "capacity_id" {
  description = "GUID nativo de Fabric de la capacity a la que se asigna la workspace."
  type        = string
}

variable "ad_group_prefix" {
  description = "Prefijo para el display_name de los grupos AD de esta workspace (se le agrega '-<rol>')."
  type        = string
}

variable "roles" {
  description = "Roles de Fabric workspace para los que se crea un grupo AD y su role assignment."
  type        = set(string)
  default     = ["Admin", "Contributor", "Member", "Viewer"]
}

variable "admin_members" {
  description = "Object IDs que seran miembros del grupo del rol Admin."
  type        = list(string)
  default     = []
}

variable "group_owners" {
  description = "Object IDs que seran owners de los grupos AD creados."
  type        = list(string)
}
