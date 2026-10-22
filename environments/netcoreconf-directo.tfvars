# NetCoreConf, demo en directo desde GitHub Actions (workflow terraform-directo.yml).
# El publico elige el nombre del proyecto y el workflow lo pasa en -var=project_name.
# No crea capacity: usa la de la demo grabada, que el workflow busca por nombre y pasa
# en -var=existing_capacity_id. Estado remoto en Azure Storage, uno por proyecto.
#
# Solo DEV para que el apply tarde poco en directo: 3 workspaces, 12 grupos, 12 roles.
# Para el medallion completo: environments = ["dev", "test", "prod"].

template     = "medallion-cicd"
layers       = ["bronze", "silver", "gold"]
environments = ["dev"]

admin_group_members = [
  "mar.lizana@akanemar.onmicrosoft.com",
  "mingelmejor@akanemar.onmicrosoft.com",
]

# Obligatorias en la raiz pero sin efecto aqui (no se crea capacity ni budget).
capacity_name = "fbcnetcoreconf"
capacity_sku  = "F2"
region        = "spaincentral"
budget_amount = 0

enable_github_cicd = false
github_owner       = "marlizana"

tags = {
  managed_by = "terraform"
  event      = "netcoreconf-2026"
}
