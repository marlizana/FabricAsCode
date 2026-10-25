# Workshop de Git para Power BI: cómo se monta

Viernes 6/11, 10:00-14:00 (DataSaturday Madrid). Unas 20 personas: aun no hay lista, asi que se crean
20 alumnos genericos (`workshop_attendee_count = 20`) y se reparten en tarjetas. Template de Terraform: `workshop`.

Los primeros 30 minutos son de puesta a punto (slide 3 del deck): usuario y contrasena nueva, MFA con
Authenticator, trial de Power BI Pro y cuenta de GitHub, que les ayudamos a crear si no la tienen.

## Qué se crea

| Por asistente (`userN`) | Compartido (`team`) |
|---|---|
| Usuario de Entra `userN-gitws@akanemar.onmicrosoft.com` con password aleatoria | Grupo `sg-gitws-attendees` con todos |
| Workspace Fabric `ws-gitws-userN`: esa persona y `sg-gitws-admins` (Admin) | Workspace `ws-gitws-team`: el grupo como Contributor, `sg-gitws-admins` como Admin |
| | Grupo `sg-gitws-admins`: las ponentes (`admin_group_members`) |
| Repo GitHub **privado** que crea cada persona en su cuenta (ejercicio 1) | Repo `gitws-team`: todas como collaborators, `main` protegida con PR + 1 aprobación |
| README con los ejercicios (`workshop/seed/`) | El mismo README |

Aislamiento: ningún alumno tiene rol en el workspace de otra persona ni acceso a su repo. Las ponentes
entran en todos por `sg-gitws-admins`; para sumar a alguien, se añade al grupo y no hay que tocar los workspaces.
La identidad que ejecuta Terraform queda como Admin de todo, porque lo crea.

## Requisitos extra del service principal

Además de lo de la demo, para crear usuarios necesita el rol de Entra **User Administrator**
(o crear los usuarios con otra identidad que lo tenga).

## Decisiones pendientes (Mar)

1. **Licencias de Power BI.** Por debajo de F64, crear informes y modelos semánticos
   exige Pro. Opciones:
   - **A (recomendada)**: trial de Power BI Pro autoservicio. En el centro de admin de
     M365, en *Self-service trials and purchases*, permitir el trial de Power BI Pro.
     Cada asistente pulsa "Start trial" en Fabric. Hay que probarlo el viernes con 2 usuarios.
   - B: limitar el taller a items de Fabric que no son de Power BI (lakehouse, notebook).
     Se pierde la parte de PBIP/TMDL.
   - C: que cada persona traiga su tenant. Se pierde el control del entorno.
2. **MFA.** El tenant tiene *security defaults* activados, así que los 25 usuarios nuevos
   tendrán que registrar Authenticator al entrar. Opciones:
   - Avisar y que lo registren en los primeros 10 minutos.
   - Desactivar los security defaults solo el día del taller y reactivarlos tras el destroy.
3. **GitHub.** El repo compartido es público porque en cuentas Free la protección de ramas
   no existe en repos privados. Si se prefiere privado, crear una organización con plan Team
   o quitar la protección (`protect_team_main = false`).

## Antes del taller

| Cuándo | Qué |
|---|---|
| 1 semana antes | Una sola vez, para Branch out (ver abajo): crear el grupo `sg-fabric-workspace-creators` y añadirlo al tenant setting de crear workspaces |
| 1 semana antes | Mail a asistentes (si la organizacion nos da la lista): traer movil para MFA y, si pueden, cuenta de GitHub |
| 2/11 | `environments/workshop.tfvars` con `workshop_attendee_count = 20` y `terraform apply` desde un equipo sin Global Secure Access |
| Durante la puesta a punto | Apuntar el usuario de GitHub de cada persona; en el descanso, invitarles a `gitws-team` (re-apply con `github_username` o desde GitHub) |
| Día anterior | Probar con 2 usuarios: login, MFA, trial de Pro, conexión Git, commit, PR y **Branch out a un workspace nuevo** |
| Día anterior | Preparar en `ws-gitws-team` un informe con una página por alumno (`user1`…`user20`) y hacer commit |
| Día anterior | Mar conecta `ws-gitws-team` al repo `gitws-team`, rama `main`, carpeta `/` (los alumnos son Contributor y no pueden conectarlo) |
| Día anterior | Imprimir credenciales (`terraform output -json workshop_credentials`) |
| Al acabar | `terraform destroy` y, si se desactivaron, reactivar los security defaults |

### Branch out: crear workspaces y asignarlos a la capacity

Branch out a un workspace nuevo (ejercicios 4 y 6) crea un workspace con la identidad del
alumno. Necesita dos permisos que un usuario recién creado no tiene:

1. **Crear workspaces.** En el tenant, el setting está limitado a grupos. Una sola vez:
   ```powershell
   az ad group create --display-name sg-fabric-workspace-creators --mail-nickname sg-fabric-workspace-creators
   ```
   y en el portal de admin de Fabric: *Tenant settings → Workspace settings → Create workspaces*,
   añadir `sg-fabric-workspace-creators` junto a `sg-fabric-automation`. Terraform mete a los
   alumnos en ese grupo (`workshop_workspace_creators_group`) y los saca en el `destroy`.
   El grupo no lo crea Terraform a propósito: si se borrara en cada `destroy`, habría que
   volver a añadirlo al tenant setting cada vez.
   Atajo: `workshop_workspace_creators_group = "sg-fabric-automation"` funciona sin tocar nada,
   a cambio de mezclar alumnos con el grupo de automatización.
2. **Asignar el workspace a la capacity.** El rol Contributor de la capacity no se puede dar
   por API, así que con `workshop_attendees_capacity_admins = true` los alumnos son admins de la
   capacity del taller (solo existe ese día). Los usuarios tienen que existir antes que la
   capacity, así que el primer despliegue va en dos pasos:
   `terraform apply -var-file=environments/workshop.tfvars "-target=module.workshop[0].azuread_user.attendee"`
   y después el `apply` completo. Si se usa una capacity existente
   (`existing_capacity_id`), poner a mano en el portal de admin *Capacity settings →
   Contributor permissions* el grupo `sg-fabric-workspace-creators`.

Los cambios de pertenencia a grupos tardan un rato en llegar a Fabric: hacer el `apply` el día
anterior, no esa misma mañana. Plan B si Branch out falla: **Checkout new branch** en su propio
workspace (no crea workspace nuevo).

Para quien se apunte tarde: añadirlo al final de la lista (para no renumerar a nadie) y volver a hacer `apply`.

## Agenda (4 h)

| Hora | Bloque | Ejercicio |
|---|---|---|
| 10:00-10:30 | Puesta a punto: usuario, MFA, trial de Pro y cuenta de GitHub | — |
| 10:30-10:50 | Fundamentos: repo, commit, rama, merge, PR (con el dibujo de la rama) | — |
| 10:50-11:20 | Conectar el workspace a GitHub | 1 y 2 |
| 11:20-11:45 | Las tripas: PBIP y TMDL | 3 (o demo si vamos tarde) |
| 11:45-12:15 | Ramas y pull requests | 4 |
| 12:15-12:30 | Descanso: invitar a todas a `gitws-team` | |
| 12:30-13:15 | Repo común `gitws-team`, conflicto incluido | 5 |
| 13:15-13:30 | Deshacer con Revert en el repo común | 6 |
| 13:30-13:50 | Pasar entre entornos: variable libraries, deployment pipelines y fabric-cicd | Demo |
| 13:50-14:00 | Novedades (deployment plans), si llegamos, y cierre | Demo |

## Coste orientativo

F8 durante 5 horas (montaje, taller y margen), pausada el resto del tiempo. Lo cubren los
créditos MVP. El budget avisa al 50, 80 y 100 %.
