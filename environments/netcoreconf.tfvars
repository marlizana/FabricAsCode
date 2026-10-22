# Sesion «Y yo aqui creando workspaces a mano» (NetCoreConf Madrid, 23/10/2026).
# Va en su propio terraform workspace ("netcoreconf"): estado separado de la demo
# de Popkorn, con su propia capacity, que se crea y se destruye en directo.
#
# project_name NO esta aqui a proposito: Terraform (o scripts/demo.ps1) lo pregunta.
# Uso: .\scripts\demo.ps1 help

capacity_name           = "fbcnetcoreconf"
randomize_capacity_name = true
capacity_sku            = "F2"
region                  = "spaincentral"
capacity_admin_members  = ["mar.lizana@akanemar.onmicrosoft.com"]
admin_group_members = [
  "mar.lizana@akanemar.onmicrosoft.com",
  "mingelmejor@akanemar.onmicrosoft.com",
]

template     = "medallion-cicd"
layers       = ["bronze", "silver", "gold"]
environments = ["dev", "test", "prod"] # en directo: demo.ps1 qa anade "qa"

# Sin repo de contenido en esta sesion: el foco es Terraform.
enable_github_cicd = false
github_owner       = "marlizana"

# Sin budget en la charla: pedia correos y no aporta a la demo.
budget_amount = 0

tags = {
  managed_by = "terraform"
  event      = "netcoreconf-2026"
}
