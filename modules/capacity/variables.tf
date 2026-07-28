variable "name" {
  description = "Nombre de la Fabric Capacity."
  type        = string
}

variable "sku" {
  description = "SKU de la Fabric Capacity (F2, F4, F8, ... F2048)."
  type        = string

  validation {
    condition = contains(
      ["F2", "F4", "F8", "F16", "F32", "F64", "F128", "F256", "F512", "F1024", "F2048"],
      var.sku
    )
    error_message = "sku debe ser uno de: F2, F4, F8, F16, F32, F64, F128, F256, F512, F1024, F2048."
  }
}

variable "region" {
  description = "Region de Azure donde se crea el resource group y la capacity."
  type        = string
}

variable "admin_members" {
  description = "UPNs u object IDs con rol de administrador de la capacity."
  type        = list(string)
}

variable "randomize_capacity_name" {
  description = "Si es true, agrega un sufijo aleatorio de 4 caracteres al nombre de la capacity para evitar colisiones de nombre global."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags aplicados al resource group y a la capacity."
  type        = map(string)
  default     = {}
}
