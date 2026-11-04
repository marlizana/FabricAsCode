# Template "workshop": un entorno aislado por asistente + uno compartido.
#
# Por asistente (N = 1, 2, 3...):
#   - Usuario de Entra ID  userN-<prefix>@<dominio>  (password inicial aleatoria)
#   - Workspace Fabric     ws-<prefix>-userN         (Admin: ese usuario y sg-<prefix>-admins)
#   - Repo GitHub privado  <prefix>-userN            (opcional: create_repos; en el taller lo crea cada uno)
# Compartido:
#   - Grupo de Entra       sg-<prefix>-attendees
#   - Grupo de Entra       sg-<prefix>-admins        (ponentes: Admin de todos los workspaces)
#   - (opcional) los asistentes entran tambien en un grupo persistente con permiso para
#     crear workspaces (tenant setting). Hace falta para "Branch out" a un workspace nuevo.
# Por equipo (var.teams, p. ej. ventas y logistica):
#   - Grupo de Entra       sg-<prefix>-<equipo>      (los asistentes de ese equipo)
#   - Workspace Fabric     ws-<prefix>-<equipo>      (su equipo Contributor, sg-<prefix>-admins Admin)
#   - Repo GitHub          <prefix>-<equipo>         (opcional: create_team_repo; main protegida)
# Los asistentes se reparten en bloques: con 20 y dos equipos, user1-10 al primero y
# user11-20 al segundo. Un asistente puede fijar el suyo con "team".
#
# Ningun alumno ve el workspace ni el repo de otro: cada workspace tiene como Admin a su
# dueno, al grupo de ponentes (sg-<prefix>-admins) y a la identidad que ejecuta Terraform
# (por crearlo); los repos privados solo tienen a su asistente.

locals {
  # Clave = "userN"; de ella salen el usuario, el workspace y el repo.
  attendees = {
    for i, a in var.attendees : "user${i + 1}" => a
  }

  repo_attendees = var.create_repos ? local.attendees : {}

  # Equipo de cada asistente: el que indique o, si no, por bloques consecutivos.
  attendee_team = {
    for i, a in var.attendees : "user${i + 1}" => (
      a.team != "" ? a.team : var.teams[floor(i * length(var.teams) / length(var.attendees))]
    )
  }

  teams = toset(var.teams)

  team_repos = var.create_team_repo ? local.teams : toset([])

  team_collaborators = var.create_team_repo ? {
    for k, a in local.attendees : k => { team = local.attendee_team[k], github_username = a.github_username }
    if a.github_username != ""
  } : {}
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

  user_principal_name   = "${each.key}-${var.prefix}@${var.tenant_domain}"
  display_name          = "${each.value.name} (${each.key})"
  mail_nickname         = "${each.key}-${var.prefix}"
  password              = random_password.attendee[each.key].result
  force_password_change = false
  usage_location        = var.usage_location
}

resource "azuread_group" "attendees" {
  display_name     = "sg-${var.prefix}-attendees"
  security_enabled = true
  owners           = var.group_owners
  members          = [for u in azuread_user.attendee : u.object_id]

  lifecycle {
    precondition {
      condition     = alltrue([for t in values(local.attendee_team) : contains(var.teams, t)])
      error_message = "Algun asistente tiene un team que no esta en teams."
    }
  }
}

resource "azuread_group" "team" {
  for_each = local.teams

  display_name     = "sg-${var.prefix}-${each.key}"
  description      = "Workshop Git - equipo ${each.key}"
  security_enabled = true
  owners           = var.group_owners
  members          = [for k, t in local.attendee_team : azuread_user.attendee[k].object_id if t == each.key]
}

# Ponentes: Admin de todos los workspaces del taller (ver mas abajo).
resource "azuread_group" "admins" {
  display_name     = "sg-${var.prefix}-admins"
  description      = "Ponentes del workshop: Admin de todos los workspaces"
  security_enabled = true
  owners           = var.group_owners
  members          = var.facilitator_object_ids
}

# Grupo que NO gestiona este modulo: existe antes del taller y esta en el tenant setting
# "Users can create Fabric workspaces". El grupo sg-<prefix>-attendees no sirve para eso:
# se crea y se borra con cada apply/destroy y su object ID cambia.
resource "azuread_group_member" "workspace_creator" {
  for_each = var.workspace_creators_group_id != "" ? local.attendees : {}

  group_object_id  = var.workspace_creators_group_id
  member_object_id = azuread_user.attendee[each.key].object_id
}

# ---------- Fabric ----------

resource "fabric_workspace" "attendee" {
  for_each = local.attendees

  display_name = "ws-${var.prefix}-${each.key}"
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

# Las ponentes entran por un grupo, sg-<prefix>-admins, que es Admin de cada workspace de
# alumno y de cada equipo. Para sumar o quitar a alguien basta con tocar el grupo, no 21 workspaces.
# Los alumnos siguen sin ver el workspace de los demas.
resource "fabric_workspace_role_assignment" "attendee_admins" {
  for_each = local.attendees

  workspace_id = fabric_workspace.attendee[each.key].id
  role         = "Admin"

  principal = {
    id   = azuread_group.admins.object_id
    type = "Group"
  }
}

resource "fabric_workspace" "team" {
  for_each = local.teams

  display_name = "ws-${var.prefix}-${each.key}"
  description  = "Workshop Git - espacio comun del equipo ${each.key}"
  capacity_id  = var.capacity_id
}

# Cada equipo solo entra en su workspace comun.
resource "fabric_workspace_role_assignment" "team" {
  for_each = local.teams

  workspace_id = fabric_workspace.team[each.key].id
  role         = "Contributor"

  principal = {
    id   = azuread_group.team[each.key].object_id
    type = "Group"
  }
}

resource "fabric_workspace_role_assignment" "team_admins" {
  for_each = local.teams

  workspace_id = fabric_workspace.team[each.key].id
  role         = "Admin"

  principal = {
    id   = azuread_group.admins.object_id
    type = "Group"
  }
}

# ---------- GitHub ----------

resource "github_repository" "attendee" {
  for_each = local.repo_attendees

  name        = "${var.prefix}-${each.key}"
  description = "Workshop Git para Power BI - ${each.value.name}"
  visibility  = "private"
  auto_init   = true

  has_issues   = false
  has_projects = false
  has_wiki     = false
}

resource "github_repository_collaborator" "attendee" {
  for_each = { for k, a in local.repo_attendees : k => a if a.github_username != "" }

  repository = github_repository.attendee[each.key].name
  username   = each.value.github_username
  permission = "push"
}

resource "github_repository" "team" {
  for_each = local.team_repos

  name        = "${var.prefix}-${each.key}"
  description = "Workshop Git para Power BI - repo comun del equipo ${each.key}"
  # En cuentas Free, la proteccion de ramas solo existe en repos publicos.
  visibility = var.team_repo_visibility
  auto_init  = true

  has_issues   = true
  has_projects = false
  has_wiki     = false
}

# Cada asistente solo se invita al repo de su equipo.
resource "github_repository_collaborator" "team" {
  for_each = local.team_collaborators

  repository = github_repository.team[each.value.team].name
  username   = each.value.github_username
  permission = "push"
}

resource "github_branch_protection" "team_main" {
  for_each = var.protect_team_main ? local.team_repos : toset([])

  repository_id  = github_repository.team[each.key].node_id
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
    for k in keys(local.repo_attendees) : {
      for f, content in local.seed_files : "${k}/${f}" => { repo = k, file = f, content = replace(content, "{{equipo}}", local.attendee_team[k]) }
    }
  ]...)

  # En el README de cada repo comun, {{equipo}} pasa a ser el nombre del equipo.
  team_seed = merge([
    for t in local.team_repos : {
      for f, content in local.seed_files : "${t}/${f}" => { team = t, file = f, content = replace(content, "{{equipo}}", t) }
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
  for_each = local.team_seed

  repository          = github_repository.team[each.value.team].name
  branch              = "main"
  file                = each.value.file
  content             = each.value.content
  commit_message      = "Material inicial del workshop"
  commit_author       = "Workshop bot"
  commit_email        = "workshop@example.invalid"
  overwrite_on_create = true
}

# Estados creados con un unico espacio comun "team": se conservan como el equipo "team".
moved {
  from = fabric_workspace.team
  to   = fabric_workspace.team["team"]
}

moved {
  from = fabric_workspace_role_assignment.team
  to   = fabric_workspace_role_assignment.team["team"]
}

moved {
  from = fabric_workspace_role_assignment.team_admins
  to   = fabric_workspace_role_assignment.team_admins["team"]
}

moved {
  from = github_repository.team[0]
  to   = github_repository.team["team"]
}

moved {
  from = github_branch_protection.team_main[0]
  to   = github_branch_protection.team_main["team"]
}
