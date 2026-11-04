output "workspace_ids" {
  description = "Mapa asistente -> workspace ID, mas uno por equipo."
  value = merge(
    { for k, w in fabric_workspace.attendee : k => w.id },
    { for t, w in fabric_workspace.team : t => w.id }
  )
}

output "credentials" {
  description = "Usuario, password inicial, workspace y repo de cada asistente. Repartir en papel o por mensaje privado."
  sensitive   = true
  value = {
    for k, a in local.attendees : k => {
      name      = a.name
      upn       = azuread_user.attendee[k].user_principal_name
      password  = random_password.attendee[k].result
      workspace = fabric_workspace.attendee[k].display_name
      repo      = var.create_repos ? github_repository.attendee[k].html_url : null
      team      = local.attendee_team[k]
      team_ws   = fabric_workspace.team[local.attendee_team[k]].display_name
    }
  }
}

output "team_repo_urls" {
  description = "Repo comun de cada equipo."
  value       = { for t, r in github_repository.team : t => r.html_url }
}

output "teams" {
  description = "Equipo -> asistentes (userN)."
  value       = { for t in local.teams : t => sort([for k, x in local.attendee_team : k if x == t]) }
}

output "attendee_upns" {
  description = "UPNs de los asistentes (para darles permisos fuera del modulo, p. ej. en la capacity)."
  value       = [for k in keys(local.attendees) : azuread_user.attendee[k].user_principal_name]
}

output "admins_group_name" {
  description = "Grupo de ponentes con Admin en todos los workspaces del taller."
  value       = azuread_group.admins.display_name
}
