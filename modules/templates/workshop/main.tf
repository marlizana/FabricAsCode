# Template "workshop": un entorno aislado por asistente + uno compartido.
#
# Por asistente:
#   - Usuario de Entra ID  <prefix>-NN@<dominio>  (password inicial aleatoria)
#   - Workspace Fabric     <prefix>-NN            (solo ese usuario, rol Admin)
#   - Repo GitHub privado  <prefix>-NN            (solo ese asistente como collaborator)
# Compartido:
#   - Grupo de Entra con todos los asistentes
#   - Workspace Fabric     <prefix>-team          (grupo como Contributor)
#   - Repo GitHub          <prefix>-team          (todos como collaborators; main protegida)
#
# Nadie ve el workspace ni el repo de otra persona: los workspaces no tienen mas
# role assignments que su dueno (y la identidad que ejecuta Terraform, que queda
# como Admin por crearlos) y los repos privados solo tienen a su asistente.

locals {
  attendees = {
    for i, a in var.attendees :
    format("%s-%02d", var.prefix, i + 1) => a
  }
}

# ---------- Identidades ----------

resource "random_password" "attendee" {
  for_each = local.attendees

  length           = 16
  special          = true
  override_special = "!#%*-_"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "azuread_user" "attendee" {
  for_each = local.attendees

  user_principal_name   = "${each.key}@${var.tenant_domain}"
  display_name          = "${each.value.name} (${each.key})"
  mail_nickname         = each.key
  password              = random_password.attendee[each.key].result
  force_password_change = false
  usage_location        = var.usage_location
}

resource "azuread_group" "attendees" {
  display_name     = "sg-${var.prefix}-attendees"
  security_enabled = true
  owners           = var.group_owners
  members          = [for u in azuread_user.attendee : u.object_id]
}

# ---------- Fabric ----------

resource "fabric_workspace" "attendee" {
  for_each = local.attendees

  display_name = each.key
  description  = "Workshop Git - ${each.value.name}"
  capacity_id  = var.capacity_id
}

resource "fabric_workspace_role_assignment" "attendee" {
  for_each = local.attendees

  workspace_id = fabric_workspace.attendee[each.key].id
  role         = "Admin"

  principal = {
    id   = azuread_user.attendee[each.key].object_id
    type = "User"
  }
}

resource "fabric_workspace" "team" {
  display_name = "${var.prefix}-team"
  description  = "Workshop Git - espacio colaborativo"
  capacity_id  = var.capacity_id
}

resource "fabric_workspace_role_assignment" "team" {
  workspace_id = fabric_workspace.team.id
  role         = "Contributor"

  principal = {
    id   = azuread_group.attendees.object_id
    type = "Group"
  }
}

resource "fabric_workspace_role_assignment" "facilitators" {
  for_each = toset(var.facilitator_object_ids)

  workspace_id = fabric_workspace.team.id
  role         = "Admin"

  principal = {
    id   = each.value
    type = "User"
  }
}

# ---------- GitHub ----------

resource "github_repository" "attendee" {
  for_each = local.attendees

  name        = each.key
  description = "Workshop Git para Power BI - ${each.value.name}"
  visibility  = "private"
  auto_init   = true

  has_issues   = false
  has_projects = false
  has_wiki     = false
}

resource "github_repository_collaborator" "attendee" {
  for_each = { for k, a in local.attendees : k => a if a.github_username != "" }

  repository = github_repository.attendee[each.key].name
  username   = each.value.github_username
  permission = "push"
}

resource "github_repository" "team" {
  name        = "${var.prefix}-team"
  description = "Workshop Git para Power BI - repo colaborativo"
  # En cuentas Free, la proteccion de ramas solo existe en repos publicos.
  visibility = var.team_repo_visibility
  auto_init  = true

  has_issues   = true
  has_projects = false
  has_wiki     = false
}

resource "github_repository_collaborator" "team" {
  for_each = { for k, a in local.attendees : k => a if a.github_username != "" }

  repository = github_repository.team.name
  username   = each.value.github_username
  permission = "push"
}

resource "github_branch_protection" "team_main" {
  count = var.protect_team_main ? 1 : 0

  repository_id  = github_repository.team.node_id
  pattern        = "main"
  enforce_admins = false

  required_pull_request_reviews {
    required_approving_review_count = 1
  }

  # Se protege despues de sembrar: con main protegida el commit directo fallaria.
  depends_on = [github_repository_file.team_seed]
}

locals {
  seed_files = {
    for f in fileset(var.seed_dir, "**") : f => file("${var.seed_dir}/${f}")
  }

  attendee_seed = merge([
    for k in keys(local.attendees) : {
      for f, content in local.seed_files : "${k}/${f}" => { repo = k, file = f, content = content }
    }
  ]...)
}

resource "github_repository_file" "attendee_seed" {
  for_each = local.attendee_seed

  repository          = github_repository.attendee[each.value.repo].name
  branch              = "main"
  file                = each.value.file
  content             = each.value.content
  commit_message      = "Material inicial del workshop"
  commit_author       = "Workshop bot"
  commit_email        = "workshop@example.invalid"
  overwrite_on_create = true
}

resource "github_repository_file" "team_seed" {
  for_each = local.seed_files

  repository          = github_repository.team.name
  branch              = "main"
  file                = each.key
  content             = each.value
  commit_message      = "Material inicial del workshop"
  commit_author       = "Workshop bot"
  commit_email        = "workshop@example.invalid"
  overwrite_on_create = true
}
