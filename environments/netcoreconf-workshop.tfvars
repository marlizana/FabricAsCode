# NetCoreConf, demo 2: «monta un workshop de Git para 20 alumnos».
# Estado propio (terraform workspace "netcoreconf-workshop") y SIN capacity propia:
# demo.ps1 le pasa la capacity de la demo 1 en TF_VAR_existing_capacity_id.
#
# Crea, por alumno N:
#   usuario  userN-workshopgit26@akanemar.onmicrosoft.com  (password aleatoria)
#   workspace ws-workshopgit26-userN, con ese usuario como Admin y nadie mas
# y el espacio comun ws-workshopgit26-team (alumnos Contributor, ponentes Admin).
#
# Uso: .\scripts\demo.ps1 taller        (plan con 20 alumnos)
#      .\scripts\demo.ps1 taller-apply  (apply con 3)

template     = "workshop"
project_name = "workshopgit26"

workshop_tenant_domain  = "akanemar.onmicrosoft.com"
workshop_attendee_count = 20
# Repos de GitHub por alumno: fuera en la charla (mas lento y no aporta a la historia).
workshop_create_repos = false

admin_group_members = [
  "mar.lizana@akanemar.onmicrosoft.com",
  "mingelmejor@akanemar.onmicrosoft.com",
]

# Obligatorias en la raiz pero sin efecto aqui (no se crea capacity ni budget).
capacity_name = "fbcnetcoreconf"
region        = "spaincentral"
budget_amount = 0

enable_github_cicd = false
github_owner       = "marlizana"

tags = {
  managed_by = "terraform"
  event      = "netcoreconf-2026"
}
