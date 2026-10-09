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
      name     = a.name
      upn      = azuread_user.attendee[k].user_principal_name
      password = random_password.attendee[k].result
      repo     = github_repository.attendee[k].html_url
    }
  }
}

output "team_repo_url" {
  description = "Repo colaborativo."
  value       = github_repository.team.html_url
}
