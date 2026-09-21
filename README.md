# FabricAsCode

Terraform para provisionar infraestructura de Microsoft Fabric: una Fabric Capacity
(dado un nombre, sku y region) y, sobre esa capacity, una arquitectura de workspaces
definida por un template.

Alcance: infraestructura Terraform (capacity, workspaces, grupos de seguridad AD y sus
role assignments) mas el bootstrap opcional de un repositorio GitHub y un workflow de
GitHub Actions para promocionar contenido con `fabric-cicd`. No usa Fabric Deployment
Pipelines.

## Templates disponibles

- `medallion-cicd`: 9 workspaces (bronze/silver/gold x dev/test/prod), todas asignadas
  a la misma capacity. Por cada workspace se crean 4 grupos de seguridad en Entra ID
  (Admin, Contributor, Member, Viewer) vinculados a esa workspace mediante
  `fabric_workspace_role_assignment` (36 grupos y 36 role assignments en total).

Cuando `enable_github_cicd = true`, Terraform crea un repositorio de contenido e
inicializa en el branch `main`:

- `.github/workflows/fabric-cicd.yml`, con despliegues por capa a `test` y `prod`.
- `.github/scripts/deploy.py`, que ejecuta `fabric-cicd`.
- `fabric-content/<layer>/parameter.yml`, para bindings especificos de cada entorno.

## Prerequisitos

- Terraform >= 1.8
- Python 3.9-3.13 para ejecutar `fabric-cicd`.
- Suscripcion de Azure con cuota disponible para Fabric Capacity en la region elegida
- Tenant de Entra ID
- Un Service Principal con:
  - Rol `Contributor` en el scope donde se creara el resource group
  - Rol de directorio `Application Administrator` o `Groups Administrator` (para crear
    `azuread_group`)
  - El ajuste "Service principals can call Fabric public APIs" habilitado en el admin
    portal de Fabric

## Autenticacion

Nunca se ponen credenciales en archivos `.tf` ni `.tfvars`. Se configuran como
variables de entorno antes de ejecutar Terraform:

```
ARM_CLIENT_ID
ARM_CLIENT_SECRET
ARM_TENANT_ID
ARM_SUBSCRIPTION_ID

# Solo si enable_github_cicd = true
GITHUB_TOKEN
```

Estas mismas cubren la autenticacion por defecto de `azurerm` y `azuread`. El
provider `fabric` (microsoft/fabric) soporta variables equivalentes (por ejemplo
`FABRIC_CLIENT_ID` / `FABRIC_CLIENT_SECRET` / `FABRIC_TENANT_ID`) ademas de Azure CLI,
OIDC y managed identity; confirmar los nombres exactos contra la version instalada
del provider en `terraform init` / su documentacion.

El provider `github` lee `GITHUB_TOKEN` del entorno. El token debe poder crear el
repositorio y sus archivos iniciales.

## Uso

```
terraform init
terraform validate
cp terraform.tfvars.example terraform.tfvars   # editar valores, nunca commitear
terraform plan
terraform apply
```

Con `enable_github_cicd = true`, el repositorio creado se muestra en el output
`github_repository_url`. Terraform siembra el workflow y los archivos de bootstrap,
pero no crea automaticamente items Fabric: las definiciones de notebooks, lakehouses,
pipelines y demas artefactos deben guardarse bajo `fabric-content/`.

## Flujo GitHub Actions con fabric-cicd

El workflow no usa Deployment Pipelines de Fabric. Cada ejecucion despliega las tres
capas en paralelo a `test` y, solo si todas terminan correctamente, continua a `prod`.
El Environment `prod` de GitHub debe configurarse con aprobadores obligatorios si se
requiere aprobacion manual antes de produccion.

Crear estos secrets en el repositorio de contenido:

```
FABRIC_TENANT_ID
FABRIC_CLIENT_ID
FABRIC_CLIENT_SECRET
```

Crear tambien la repository variable `FABRIC_PROJECT_NAME` con el mismo valor que
`project_name`, por ejemplo `ventas`. El Service Principal necesita acceso a los seis
workspaces `test` y `prod` que recibiran los despliegues.

### Conexion de los workspaces dev a GitHub

La conexion inicial de GitHub se completa desde Fabric para cada workspace `dev`:

1. Abrir el workspace `ventas-bronze-dev`, `ventas-silver-dev` o `ventas-gold-dev`.
2. Ir a **Workspace settings > Git integration**.
3. Seleccionar GitHub, autorizar la cuenta/PAT y elegir el repositorio creado.
4. Usar `main` y la carpeta correspondiente: `fabric-content/bronze`,
   `fabric-content/silver` o `fabric-content/gold`.
5. Repetir para las otras dos workspaces.

Fabric no admite actualmente establecer esta conexion de GitHub de forma no interactiva
con un Service Principal. Por eso Terraform crea y prepara el repositorio, pero esta
primera vinculacion requiere una cuenta autorizada en Fabric.

Las promociones posteriores se ejecutan exclusivamente desde GitHub Actions mediante
`fabric-cicd`. Los bindings y referencias entre entornos deben declararse en cada
`fabric-content/<layer>/parameter.yml`.

Para probar el despliegue completo, consultar la [guia de validacion paso a paso](docs/validation-guide.md),
que incluye permisos, secrets, comprobaciones y criterios de aceptacion.

Despliegue escalonado recomendado para el primer apply en un entorno nuevo:

```
terraform apply -target=module.capacity
terraform apply
```

Esto aisla dos riesgos conocidos antes de tocar las 9 workspaces y 36 grupos:

1. **Colision de nombre de capacity**: los nombres de Fabric Capacity deben ser
   unicos (existe `az fabric capacity check-name-availability`). Si `capacity_name`
   ya esta en uso, el apply falla con un error claro de Azure; en ese caso cambiar el
   nombre o activar `randomize_capacity_name = true` para que se agregue un sufijo
   aleatorio automatico.
2. **Desfase de propagacion ARM -> Fabric**: `fabric_workspace.capacity_id` requiere
   el GUID nativo de Fabric, no el Resource ID de ARM. El modulo `capacity` lo resuelve
   con `data.fabric_capacity` buscando por `display_name` justo despues de crear
   `azurerm_fabric_capacity`. Puede haber un breve desfase de consistencia eventual
   entre ambos planos de control; si el primer apply falla en esa data source, un
   segundo `terraform apply` normalmente lo resuelve.

## Extender con un nuevo template

1. Crear `modules/templates/<nombre>/` con su propio `main.tf`/`variables.tf`/`outputs.tf`.
2. Sumar `"<nombre>"` a la validacion de `var.template` en `variables.tf`.
3. Agregar en `main.tf` un bloque `module "<nombre>" { count = var.template == "<nombre>" ? 1 : 0 ... }`.
4. Extender los `merge()` de `outputs.tf` para incluir los outputs del nuevo template.

No hace falta tocar el template `medallion-cicd` existente.
