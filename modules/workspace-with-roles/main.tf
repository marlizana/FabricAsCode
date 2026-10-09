resource "fabric_workspace" "this" {
  display_name = var.workspace_name
  description  = var.description
  capacity_id  = var.capacity_id
}

resource "azuread_group" "roles" {
  for_each = var.roles

  display_name     = "${var.ad_group_prefix}-${lower(each.value)}"
  security_enabled = true
  owners           = var.group_owners
  # Solo el grupo Admin lleva miembros fijos; el resto se gestiona fuera de Terraform.
  members = each.value == "Admin" ? var.admin_members : null
}

resource "fabric_workspace_role_assignment" "this" {
  for_each = azuread_group.roles

  workspace_id = fabric_workspace.this.id
  role         = each.key

  principal = {
    id   = each.value.object_id
    type = "Group"
  }
}
