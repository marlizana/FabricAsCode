output "workspace_ids" {
  description = "Mapa asistente -> workspace ID, mas 'team'."
  value = merge(
    { for k, w in fabric_workspace.attendee : k => w.id },
    { team = fabric_workspace.team.id }
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
    }
  }
}

output "team_repo_url" {
  description = "Repo colaborativo."
  value       = var.create_team_repo ? github_repository.team[0].html_url : null
}

output "attendee_upns" {
  description = "UPNs de los asistentes (para darles permisos fuera del modulo, p. ej. en la capacity)."
  value       = [for k in keys(local.attendees) : azuread_user.attendee[k].user_principal_name]
}

output "admins_group_name" {
  description = "Grupo de ponentes con Admin en todos los workspaces del taller."
  value       = azuread_group.admins.display_name
}
