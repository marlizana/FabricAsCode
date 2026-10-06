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
