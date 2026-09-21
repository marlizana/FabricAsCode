variable "capacity_name" {
  description = "Nombre de la Fabric Capacity a crear en Azure."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{2,62}$", var.capacity_name))
    error_message = "capacity_name debe tener 3-63 caracteres, solo minusculas y digitos, y empezar por una letra."
  }
}

variable "capacity_sku" {
  description = "SKU de la Fabric Capacity (F2, F4, F8, ... F2048)."
  type        = string

  validation {
    condition = contains(
      ["F2", "F4", "F8", "F16", "F32", "F64", "F128", "F256", "F512", "F1024", "F2048"],
      var.capacity_sku
    )
    error_message = "capacity_sku debe ser uno de: F2, F4, F8, F16, F32, F64, F128, F256, F512, F1024, F2048."
  }
}

variable "region" {
  description = "Region de Azure donde se crea la Fabric Capacity (ej. westeurope)."
  type        = string
}

variable "template" {
  description = "Nombre de la arquitectura de workspaces a provisionar."
  type        = string

  validation {
    condition     = contains(["medallion-cicd"], var.template)
    error_message = "template debe ser uno de los templates soportados: medallion-cicd."
  }
}

variable "project_name" {
  description = "Nombre del dominio/proyecto usado como prefijo de workspaces y grupos AD (ej. ventas)."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}$", var.project_name))
    error_message = "project_name debe tener 2-31 caracteres, minusculas, digitos y guiones, empezando por una letra."
  }
}

variable "capacity_admin_members" {
  description = "UPNs u object IDs con rol de administrador de la capacity. Si esta vacio, se usa la identidad que ejecuta Terraform."
  type        = list(string)
  default     = []
}

variable "ad_group_owners" {
  description = "Object IDs que seran owners de los grupos de seguridad AD creados. Si esta vacio, se usa la identidad que ejecuta Terraform."
  type        = list(string)
  default     = []
}

variable "randomize_capacity_name" {
  description = "Si es true, agrega un sufijo aleatorio de 4 caracteres al nombre de la capacity para evitar colisiones de nombre global en Azure."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags aplicados al resource group y a la Fabric Capacity."
  type        = map(string)
  default     = {}
}

variable "enable_github_cicd" {
  description = "Crea el repositorio GitHub destinado al contenido Fabric y los workflows de fabric-cicd."
  type        = bool
  default     = false
}

variable "github_owner" {
  description = "Usuario u organizacion de GitHub propietaria del repositorio de contenido Fabric."
  type        = string
  default     = ""

  validation {
    condition     = !var.enable_github_cicd || can(regex("^[A-Za-z0-9-]+$", var.github_owner))
    error_message = "github_owner es obligatorio cuando enable_github_cicd es true."
  }
}

variable "github_repository_name" {
  description = "Nombre del repositorio GitHub que alojara las definiciones de contenido Fabric."
  type        = string
  default     = ""

  validation {
    condition     = !var.enable_github_cicd || can(regex("^[A-Za-z0-9_.-]+$", var.github_repository_name))
    error_message = "github_repository_name es obligatorio cuando enable_github_cicd es true."
  }
}

variable "github_repository_visibility" {
  description = "Visibilidad del repositorio GitHub de contenido Fabric."
  type        = string
  default     = "private"

  validation {
    condition     = contains(["private", "public", "internal"], var.github_repository_visibility)
    error_message = "github_repository_visibility debe ser private, public o internal."
  }
}
