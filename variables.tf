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
  # Sin default a proposito: si no viene en el tfvars ni en TF_VAR_project_name,
  # Terraform lo pregunta al hacer plan/apply. Todo se nombra a partir de el.
  description = "Nombre del proyecto (ej. ventas, stocks). Prefijo de workspaces, grupos de Entra y budget."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}$", var.project_name))
    error_message = "project_name debe tener 2-31 caracteres, minusculas, digitos y guiones, empezando por una letra."
  }
}

variable "capacity_admin_members" {
  description = "UPNs u object IDs con rol de administrador de la capacity, ademas de la identidad que ejecuta Terraform."
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

variable "budget_amount" {
  description = "Presupuesto mensual en la moneda de la suscripcion. 0 desactiva el budget."
  type        = number
  default     = 0
}

variable "budget_contact_emails" {
  description = "Correos que reciben las alertas del budget (50%, 80% y 100%)."
  type        = list(string)
  default     = []

  validation {
    condition     = var.budget_amount == 0 || length(var.budget_contact_emails) > 0
    error_message = "budget_contact_emails es obligatorio cuando budget_amount > 0."
  }
}

variable "layers" {
  description = "Capas del medallion (template medallion-cicd)."
  type        = list(string)
  default     = ["bronze", "silver", "gold"]

  validation {
    condition     = length(var.layers) == length(distinct(var.layers)) && alltrue([for l in var.layers : can(regex("^[a-z][a-z0-9]{1,15}$", l))])
    error_message = "layers: nombres unicos, en minusculas y sin guiones (ej. bronze)."
  }
}

variable "environments" {
  description = "Entornos (template medallion-cicd). Anadir \"qa\" crea sus workspaces y grupos en el siguiente apply."
  type        = list(string)
  default     = ["dev", "test", "prod"]

  validation {
    condition     = length(var.environments) == length(distinct(var.environments)) && alltrue([for e in var.environments : can(regex("^[a-z][a-z0-9]{1,9}$", e))])
    error_message = "environments: nombres unicos, en minusculas y sin guiones (ej. dev, qa)."
  }
}
