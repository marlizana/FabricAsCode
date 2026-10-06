variable "prefix" {
  description = "Prefijo de usuarios, workspaces y repos (ej. gitws -> gitws-01, gitws-team)."
  type        = string
}

variable "attendees" {
  description = "Asistentes en orden. github_username puede ir vacio y anadirse despues."
  type = list(object({
    name            = string
    github_username = optional(string, "")
  }))
}

variable "tenant_domain" {
  description = "Dominio de Entra ID para los usuarios del workshop (ej. akanemar.onmicrosoft.com)."
  type        = string
}

variable "usage_location" {
  description = "Pais de uso de los usuarios (necesario para asignar o activar licencias)."
  type        = string
  default     = "ES"
}

variable "capacity_id" {
  description = "GUID nativo de Fabric de la capacity."
  type        = string
}

variable "group_owners" {
  description = "Object IDs owners del grupo de asistentes."
  type        = list(string)
}

variable "facilitator_object_ids" {
  description = "Object IDs de facilitadores con Admin en el workspace compartido."
  type        = list(string)
  default     = []
}

variable "team_repo_visibility" {
  description = "Visibilidad del repo compartido. En cuentas GitHub Free, la proteccion de ramas exige public."
  type        = string
  default     = "public"
}

variable "protect_team_main" {
  description = "Exigir PR con 1 aprobacion para mergear a main en el repo compartido."
  type        = bool
  default     = true
}

variable "seed_dir" {
  description = "Carpeta cuyo contenido se siembra en todos los repos (README, ejercicios, PBIP de partida)."
  type        = string
}
