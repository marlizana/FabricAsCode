# Guia de validacion FabricAsCode

Esta guia prueba el flujo completo:

1. Terraform crea la capacity, los workspaces y los grupos de Entra ID.
2. Terraform crea y prepara el repositorio de contenido GitHub.
3. Los tres workspaces `dev` se conectan a GitHub.
4. GitHub Actions ejecuta `fabric-cicd` hacia `test`.
5. Tras una aprobacion, el mismo commit se promociona a `prod`.

No se usan Fabric Deployment Pipelines.

## 1. Identidades y permisos

Usa dos identidades separadas:

| Identidad | Uso | Permisos recomendados |
|---|---|---|
| Service Principal de Terraform | Capacity, workspaces, grupos y repositorio | Contributor en la suscripcion o scope que permita crear el Resource Group; rol de directorio `Groups Administrator` o `Application Administrator` |
| Service Principal de GitHub Actions | Publicar contenido con `fabric-cicd` | Acceso a Fabric APIs y rol `Contributor` en los seis workspaces `test` y `prod` |
| Usuario administrador de Fabric | Conexion inicial de los tres `dev` a GitHub | Workspace Admin en cada `dev`, acceso al repositorio GitHub y PAT con acceso al repo |

Se pueden usar el mismo Service Principal de Terraform y de Actions, pero separarlos
reduce el alcance de permisos y facilita localizar errores.

### 1.1 Service Principal de Terraform

En Azure Portal:

1. Abrir **Subscriptions** y seleccionar la suscripcion objetivo.
2. Entrar en **Access control (IAM) > Add role assignment**.
3. Asignar `Contributor` al Service Principal en la suscripcion.
4. Comprobar en **Role assignments** que aparece el object ID correcto.

El rol `Contributor` permite crear el Resource Group y la Fabric Capacity. Si la
organizacion no permite Contributor a nivel de suscripcion, usar un Resource Group
preexistente y un rol custom que incluya la escritura de `Microsoft.Fabric/capacities`
y `Microsoft.Resources/resourceGroups`; el codigo actual crea el Resource Group, por
lo que el permiso debe existir antes del primer `apply`.

En **Microsoft Entra admin center**:

1. Abrir **Roles and administrators**.
2. Asignar temporalmente o de forma controlada `Groups Administrator` al Service
   Principal para crear los grupos de seguridad.
3. Como alternativa, usar `Application Administrator` si es la politica aceptada.
4. Anotar el **Object ID** de la aplicacion y el **Directory (tenant) ID** en
   **App registrations > la aplicacion > Overview**.

No confundir:

- `Application (client) ID`: se usa como `ARM_CLIENT_ID`.
- `Object ID`: se usa para `capacity_admin_members`, `ad_group_owners` o miembros de grupos.
- `Directory (tenant) ID`: se usa como `ARM_TENANT_ID`.

### 1.2 Permisos del tenant Fabric

Un administrador de Fabric debe revisar **Admin portal > Tenant settings** y habilitar
para el grupo que contiene al Service Principal:

- **Service principals can use Fabric APIs** o la opcion equivalente disponible en el
  tenant.
- **Users can create Fabric items**, si se van a crear items desde la interfaz.
- **Users can synchronize workspace items with their Git repositories**.
- **Users can synchronize workspace items with GitHub repositories**.

La disponibilidad exacta de algunos nombres puede depender de si la funcionalidad esta
en preview. Si el Service Principal obtiene `401` o `403` al publicar, revisar primero
esta lista y la pertenencia del Service Principal al grupo permitido en cada tenant setting.

### 1.3 Permisos de GitHub

Para ejecutar Terraform con `enable_github_cicd = true`, define `GITHUB_TOKEN` solo en
la sesion o runner que ejecuta Terraform.

Para un repositorio privado, un PAT clasico con alcance `repo` es la opcion mas sencilla.
Con un PAT fine-grained, conceder al owner/repositorio como minimo:

- `Administration: Read and write`, para crear y configurar el repositorio.
- `Contents: Read and write`, para crear los archivos bootstrap.
- `Metadata: Read`, que GitHub requiere siempre.

Si `github_owner` es una organizacion, la politica de la organizacion debe permitir el
PAT y el usuario debe tener permiso para crear repositorios. No guardes el PAT en
`terraform.tfvars`, el repositorio ni los logs.

Para la conexion Git de Fabric, el usuario administrador debe tener acceso al repositorio
y un PAT con lectura y escritura de sus contenidos. Ese PAT se introduce en Fabric, no
en Terraform.

## 2. Preparacion local

Desde la raiz del repositorio:

```powershell
$env:ARM_CLIENT_ID = "<terraform-client-id>"
$env:ARM_CLIENT_SECRET = "<terraform-client-secret>"
$env:ARM_TENANT_ID = "<tenant-id>"
$env:ARM_SUBSCRIPTION_ID = "<subscription-id>"
$env:GITHUB_TOKEN = "<github-token>"

terraform init
terraform fmt -check
terraform validate
```

Copia y edita `terraform.tfvars` a partir de `terraform.tfvars.example`:

```hcl
enable_github_cicd = true
github_owner = "<usuario-o-organizacion>"
github_repository_name = "ventas-fabric-content"
github_repository_visibility = "private"
```

No pongas secretos en ese archivo.

## 3. Primer despliegue Terraform

Primero crea la capacity y confirma que aparece:

```powershell
terraform plan -target=module.capacity
terraform apply -target=module.capacity
```

Comprobar:

- En Azure Portal existe `rg-fbc-<capacity_name>`.
- La Fabric Capacity esta en estado activo.
- El SKU y la region son los esperados.
- El usuario o grupo de administradores aparece en la capacity.

Despues crea los workspaces, grupos y repositorio:

```powershell
terraform plan -out fabric.tfplan
terraform apply fabric.tfplan
terraform output
```

La salida esperada incluye:

- 9 workspace IDs.
- 36 object IDs de grupos.
- `github_repository_url`.
- `github_repository_clone_url`.

En Fabric, verificar que existen estos nombres:

```text
<project>-bronze-dev    <project>-bronze-test    <project>-bronze-prod
<project>-silver-dev    <project>-silver-test    <project>-silver-prod
<project>-gold-dev      <project>-gold-test      <project>-gold-prod
```

En cada workspace, revisar que los cuatro grupos tengan el rol correcto:

```text
Admin, Contributor, Member, Viewer
```

Si falla el `data.fabric_capacity`, esperar a que Azure propague la capacity y repetir
`terraform apply`. Si falla la creacion de grupos, revisar el rol de Entra y el object ID
usado como owner.

## 4. Verificar el repositorio GitHub

Abrir el output `github_repository_url` y confirmar:

```text
.github/workflows/fabric-cicd.yml
.github/scripts/deploy.py
requirements.txt
fabric-content/bronze/parameter.yml
fabric-content/silver/parameter.yml
fabric-content/gold/parameter.yml
```

En **Settings > Actions > General**:

1. Permitir Actions si la organizacion las restringe.
2. Mantener `Read repository contents` como minimo.
3. Crear la repository variable `FABRIC_PROJECT_NAME` con el valor de `project_name`.

En **Settings > Environments**, crear:

- `test`, sin aprobacion obligatoria inicialmente.
- `prod`, con los reviewers que deben aprobar una promocion.

En cada Environment, crear estos secrets:

```text
FABRIC_TENANT_ID
FABRIC_CLIENT_ID
FABRIC_CLIENT_SECRET
```

El Service Principal de Actions debe pertenecer como miembro a los grupos
`<project>-<layer>-<env>-contributor` de los seis workspaces `test` y `prod`, o recibir
el equivalente mediante Fabric. Actualmente Terraform crea los grupos, pero no añade
automaticamente ese Service Principal como miembro.

## 5. Conectar los workspaces dev a GitHub

Repetir estos pasos para bronze, silver y gold:

1. Abrir `<project>-<layer>-dev` en Fabric.
2. Ir a **Workspace settings > Git integration**.
3. Elegir **GitHub** y autorizar la cuenta/PAT.
4. Seleccionar el repositorio creado por Terraform.
5. Seleccionar branch `main`.
6. Seleccionar la carpeta:
   - `fabric-content/bronze`
   - `fabric-content/silver`
   - `fabric-content/gold`
7. Seleccionar **Connect and sync**.

Comprobar que el workspace muestra estado **Synced** y que los archivos
`parameter.yml` aparecen en el repositorio. Esta conexion inicial es manual porque la
conexion GitHub de Fabric no se establece actualmente de forma no interactiva con un
Service Principal.

## 6. Crear un contenido minimo de prueba

Para no empezar con un despliegue vacio, crear en cada workspace `dev` un conjunto pequeno
de items soportados, por ejemplo:

- Un Lakehouse.
- Un Notebook que use ese Lakehouse.
- Un Data Pipeline sencillo, si se va a desplegar ese tipo de item.

Crear los items en el workspace `dev`, comprobar que ejecutan correctamente y hacer
**Commit** desde Source control. Confirmar que las definiciones aparecen bajo la carpeta
Fabric correspondiente en GitHub.

Antes de desplegar a `test`, completar los bindings reales en el `parameter.yml` de cada
capa. El archivo inicial contiene `find_replace: []` como placeholder.

## 7. Ejecutar la primera promocion a test

Desde GitHub:

1. Abrir **Actions > Fabric CI/CD**.
2. Seleccionar **Run workflow**.
3. Introducir el mismo `project_name` usado por Terraform.
4. Ejecutar el workflow.

Revisar en orden:

1. Los tres jobs de `deploy-test` arrancan.
2. `pip install` instala `fabric-cicd` sin errores.
3. `DefaultAzureCredential` obtiene el token del Service Principal.
4. Cada job encuentra su carpeta `fabric-content/<layer>`.
5. `publish_all_items` crea o actualiza los items en el workspace `test`.
6. `unpublish_all_orphan_items` termina correctamente.
7. Los tres jobs finalizan en verde.

En Fabric, abrir los workspaces `test` y verificar que los items existen, que las
referencias apuntan a recursos de `test` y que un notebook o pipeline de prueba se ejecuta.

Repetir el mismo workflow sin cambios. El segundo despliegue debe ser idempotente: no debe
crear duplicados ni fallar por recursos ya existentes.

Errores frecuentes:

| Sintoma | Comprobacion |
|---|---|
| `401/403` de Fabric | Tenant setting, Service Principal permitido y rol Contributor en el workspace |
| Workspace no encontrado | `FABRIC_PROJECT_NAME` y nombres `<project>-<layer>-<env>` |
| Carpeta no encontrada | El commit esta en `fabric-content/<layer>` y el checkout contiene esa ruta |
| Referencia a otro entorno | Reglas de `parameter.yml` incompletas |
| Items no soportados | Revisar `ITEM_TYPES` en `.github/scripts/deploy.py` |
| Error instalando Python | Usar Python 3.9-3.13; el workflow usa 3.11 |

## 8. Promocionar a prod

Cuando `test` este validado:

1. Volver a ejecutar el workflow con el commit probado, o hacer merge del cambio en `main`.
2. Confirmar que los tres jobs `deploy-test` finalizan correctamente.
3. Esperar la pausa del Environment `prod`.
4. Revisar el commit y aprobar la ejecucion.
5. Confirmar que los tres jobs `deploy-prod` finalizan en verde.
6. Verificar los items y bindings en los tres workspaces `prod`.

La promocion usa el contenido del commit checkouteado por GitHub Actions; no copia datos
entre entornos. Los datos, conexiones, refreshes y secretos deben validarse de forma
separada.

## 9. Criterios de aceptacion

El flujo se considera probado cuando se cumplen todos estos puntos:

- `terraform validate` y `terraform plan` terminan correctamente.
- Capacity, 9 workspaces, 36 grupos y 36 role assignments existen.
- El repositorio GitHub contiene el bootstrap esperado.
- Los tres `dev` aparecen como **Synced** con sus carpetas correctas.
- Una modificacion de contenido llega a `test` desde GitHub Actions.
- El despliegue repetido es idempotente.
- `prod` requiere la aprobacion configurada.
- El mismo cambio llega a los tres workspaces `prod` despues de aprobar.
- Las referencias y conexiones son las del entorno destino.
- Ningun secreto aparece en Git, Terraform plan, logs o outputs.

## 10. Limpieza de un entorno de prueba

Para destruir la infraestructura creada por Terraform:

```powershell
terraform destroy
```

Antes de hacerlo, confirmar que no se estan usando los workspaces ni el repositorio. La
eliminacion de la capacity puede afectar a todos los workspaces alojados en ella.
