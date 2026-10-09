# Entorno de demo de Mar (tenant akanemar.onmicrosoft.com, suscripcion sub-creditos-mvp).
# Uso: terraform plan -var-file=environments/akanemar-demo.tfvars
# Sin credenciales: ARM_* / FABRIC_* / GITHUB_TOKEN van en variables de entorno.

capacity_name = "fbcakanemardemo"
capacity_sku  = "F2"
# Con el patrocinio de Azure no hay cuota de Fabric en West Europe; en Spain Central si.
region       = "spaincentral"
template     = "medallion-cicd"
project_name = "demo"

randomize_capacity_name = true

# Tu usuario como admin de la capacity, para verla y gestionarla desde Fabric.
# El service principal que ejecuta Terraform se anade siempre.
capacity_admin_members = ["mar.lizana@akanemar.onmicrosoft.com"]
admin_group_members = [
  "mar.lizana@akanemar.onmicrosoft.com",
  "mingelmejor@akanemar.onmicrosoft.com",
]

enable_github_cicd           = true
github_owner                 = "marlizana"
github_repository_name       = "fabricascode-demo-content"
github_repository_visibility = "private"

# Red de seguridad para los creditos MVP.
budget_amount         = 150
budget_contact_emails = ["akanemar@gmail.com"]

tags = {
  managed_by = "terraform"
  project    = "fabric-as-code-demo"
  owner      = "mar"
}
