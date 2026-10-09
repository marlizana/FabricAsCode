# Workshop de Git para Power BI: cómo se monta

4 horas, 20-25 asistentes, todo en Fabric y GitHub. Template de Terraform: `workshop`.

## Qué se crea

| Por asistente (`userN`) | Compartido (`team`) |
|---|---|
| Usuario de Entra `userN-gitws@akanemar.onmicrosoft.com` con password aleatoria | Grupo `sg-gitws-attendees` con todos |
| Workspace Fabric `ws-gitws-userN`: solo esa persona (Admin) | Workspace `ws-gitws-team`: el grupo como Contributor, facilitadoras como Admin |
| Repo GitHub **privado** `gitws-userN`: solo esa persona como collaborator | Repo `gitws-team`: todas como collaborators, `main` protegida con PR + 1 aprobación |
| README con los ejercicios (`workshop/seed/`) | El mismo README |

Aislamiento: nadie tiene rol en el workspace de otra persona ni acceso a su repo.
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
| 1 semana antes | Mail a asistentes: crear cuenta de GitHub y enviarnos el usuario |
| 3 días antes | Rellenar `environments/workshop.tfvars` y `terraform apply`. Las invitaciones de GitHub caducan a los 7 días |
| 3 días antes | Recordatorio: aceptar la invitación de GitHub (llega por mail) |
| Día anterior | Probar con 2 usuarios: login, MFA, trial de Pro, conexión Git, commit y PR |
| Día anterior | Imprimir credenciales (`terraform output -json workshop_credentials`) |
| Al acabar | `terraform destroy` y, si se desactivaron, reactivar los security defaults |

Para quien se apunte tarde: añadirlo al final de la lista (para no renumerar a nadie) y volver a hacer `apply`.

## Agenda (4 h)

| Tiempo | Bloque | Ejercicio |
|---|---|---|
| 0:00-0:20 | "¿Ha oído usted hablar de Git?" Qué problema resuelve | Login, MFA, trial |
| 0:20-0:50 | Fundamentos: repo, commit, rama, merge, PR | — |
| 0:50-1:20 | Configuración: conectar el workspace a GitHub | 1 y 2 |
| 1:20-1:50 | Las tripas: PBIP, TMDL, report.json | 3 |
| 1:50-2:00 | Descanso | |
| 2:00-2:40 | Ramas y pull requests | 4 y 5 |
| 2:40-3:00 | Variables: variable libraries para cambiar de entorno | Demo |
| 3:00-3:40 | Trabajo en equipo en `ws-gitws-team`, conflicto incluido | 6 |
| 3:40-4:00 | Deployment pipelines vs fabric-cicd, y cierre | Demo con FabricAsCode |

## Coste orientativo

F8 durante 5 horas (montaje, taller y margen), pausada el resto del tiempo. Lo cubren los
créditos MVP. El budget avisa al 50, 80 y 100 %.
