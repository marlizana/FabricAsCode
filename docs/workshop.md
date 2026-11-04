# Workshop de Git para Power BI: cómo se monta

Viernes 6/11, 10:00-14:00 (DataSaturday Madrid). Unas 20 personas: aun no hay lista, asi que se crean
20 alumnos genericos (`workshop_attendee_count = 20`) y se reparten en tarjetas. Template de Terraform: `workshop`.

Los primeros 30 minutos son de puesta a punto (slide 3 del deck): usuario y contrasena nueva, MFA con
Authenticator, trial de Power BI Pro y cuenta de GitHub, que les ayudamos a crear si no la tienen.

## Qué se crea

| Por asistente (`userN`) | Por equipo (`ventas` y `logistica`) |
|---|---|
| Usuario de Entra `userN-gitws@akanemar.onmicrosoft.com` con password aleatoria | Grupo `sg-gitws-<equipo>` con su mitad (`sg-gitws-attendees` sigue teniendo a todas) |
| Workspace Fabric `ws-gitws-userN`: esa persona y `sg-gitws-admins` (Admin) | Workspace `ws-gitws-<equipo>`: el grupo del equipo como Contributor, `sg-gitws-admins` como Admin |
| | Grupo `sg-gitws-admins`: las ponentes (`admin_group_members`) |
| Repo GitHub **privado** que crea cada persona en su cuenta (ejercicio 1) | Repo `gitws-<equipo>`: las de ese equipo como collaborators, `main` protegida con PR + 1 aprobación |
| README con los ejercicios (`workshop/seed/`) | El mismo README |

Reparto: `workshop_teams = ["ventas", "logistica"]` y, con 20 alumnos, `user1`-`user10` van a ventas y
`user11`-`user20` a logística (el equipo sale en `workshop_credentials`, para la tarjeta; `terraform output
workshop_teams` da la lista). Cada README de repo común lleva el nombre de su equipo.

Aislamiento: ningún alumno tiene rol en el workspace de otra persona ni acceso a su repo, y cada equipo
solo ve su workspace y su repo común. Las ponentes
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
3. **GitHub.** Los repos comunes son públicos porque en cuentas Free la protección de ramas
   no existe en repos privados. Si se prefiere privado, crear una organización con plan Team
   o quitar la protección (`protect_team_main = false`).

## Antes del taller

| Cuándo | Qué |
|---|---|
| 1 semana antes | Una sola vez, para Branch out (ver abajo): crear el grupo `sg-fabric-workspace-creators` y añadirlo al tenant setting de crear workspaces |
| 1 semana antes | Mail a asistentes (si la organizacion nos da la lista): traer movil para MFA y, si pueden, cuenta de GitHub |
| 2/11 | `environments/workshop.tfvars` con `workshop_attendee_count = 20` y `terraform apply` desde un equipo sin Global Secure Access |
| Durante la puesta a punto | Apuntar el usuario de GitHub de cada persona; en el descanso, invitarles al repo de su equipo (re-apply con `github_username` o desde GitHub) |
| Día anterior | Probar con 2 usuarios: login, MFA, trial de Pro, conexión Git, commit, PR y **Branch out a un workspace nuevo** |
| Día anterior | Preparar en `ws-gitws-ventas` un informe con una página por alumno de ventas (`user1`…`user10`) y en `ws-gitws-logistica` otro con las de logística (`user11`…`user20`); commit en cada uno |
| Día anterior | Mar conecta `ws-gitws-ventas` a `gitws-ventas` y `ws-gitws-logistica` a `gitws-logistica`, rama `main`, carpeta `/` (los alumnos son Contributor y no pueden conectarlo) |
| Día anterior | Imprimir credenciales (`terraform output -json workshop_credentials`) |
| Al acabar | `terraform destroy` y, si se desactivaron, reactivar los security defaults |

### Branch out: crear workspaces y asignarlos a la capacity

Branch out a un workspace nuevo (ejercicios 4, 5 y 6) y desplegar a una etapa vacía de un
deployment pipeline (ejercicio 8) crean un workspace con la identidad del
alumno. Necesitan dos permisos que un usuario recién creado no tiene:

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
| 10:00-10:15 | Puesta a punto: usuario, MFA, trial de Pro y cuenta de GitHub | — |
| 10:15-10:30 | Fundamentos: repo, commit, rama, merge, PR (con el dibujo de la rama) | — |
| 10:30-10:50 | Conectar el workspace a GitHub | 1 y 2 |
| 10:50-11:05 | Las tripas: PBIP y TMDL | 3 (o demo si vamos tarde) |
| 11:05-11:30 | Ramas y pull requests | 4 |
| 11:30-12:05 | Estrategias de Git y de ramas: merge, squash y rebase, GitHub Flow, GitFlow y trunk-based, Branch out a fondo | 5 |
| 12:05-12:20 | Descanso: invitar a cada una al repo de su equipo | |
| 12:20-12:50 | Repos comunes `gitws-ventas` y `gitws-logistica`: conflicto y Revert | 6 y 7 |
| 12:50-13:35 | Deployment pipelines: etapas, comparar, reglas, autobinding y permisos | 8 |
| 13:35-13:50 | De dev a prod: las cuatro opciones de Microsoft, variable libraries y madurez | Demo |
| 13:50-14:00 | Novedades y cierre | — |

Limpieza extra por los ejercicios 5 y 8: cada alumna crea un workspace de feature (lo borra
ella misma) y un deployment pipeline con su workspace de producción. Terraform no los conoce,
así que antes del `destroy` hay que borrar los pipelines y los workspaces que queden.

## Coste orientativo

F8 durante 5 horas (montaje, taller y margen), pausada el resto del tiempo. Lo cubren los
créditos MVP. El budget avisa al 50, 80 y 100 %.
