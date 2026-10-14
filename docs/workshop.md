# Workshop de Git para Power BI: cómo se monta

Viernes 6/11, 10:00-14:00 (DataSaturday Madrid). Unas 20 personas: aun no hay lista, asi que se crean
20 alumnos genericos (`workshop_attendee_count = 20`) y se reparten en tarjetas. Template de Terraform: `workshop`.

Los primeros 30 minutos son de puesta a punto (slide 3 del deck): usuario y contrasena nueva, MFA con
Authenticator, trial de Power BI Pro y cuenta de GitHub, que les ayudamos a crear si no la tienen.

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
| 1 semana antes | Mail a asistentes (si la organizacion nos da la lista): traer movil para MFA y, si pueden, cuenta de GitHub |
| 2/11 | `environments/workshop.tfvars` con `workshop_attendee_count = 20` y `terraform apply` desde un equipo sin Global Secure Access |
| Durante la puesta a punto | Apuntar el usuario de GitHub de cada persona, rellenar `github_username` y re-aplicar para invitarles a su repo y al team |
| Día anterior | Probar con 2 usuarios: login, MFA, trial de Pro, conexión Git, commit y PR |
| Día anterior | Imprimir credenciales (`terraform output -json workshop_credentials`) |
| Al acabar | `terraform destroy` y, si se desactivaron, reactivar los security defaults |

Para quien se apunte tarde: añadirlo al final de la lista (para no renumerar a nadie) y volver a hacer `apply`.

## Agenda (4 h)

| Tiempo | Bloque | Ejercicio |
|---|---|---|
| 0:00-0:30 | Puesta a punto: usuario, MFA, trial de Pro y cuenta de GitHub | — |
| 0:30-1:00 | Fundamentos: repo, commit, rama, merge, PR | — |
| 1:00-1:30 | Configuración: conectar el workspace a GitHub | 1 y 2 |
| 1:30-2:00 | Las tripas: PBIP, TMDL, report.json | 3 |
| 2:00-2:10 | Descanso | |
| 2:10-2:50 | Ramas y pull requests | 4 y 5 |
| 2:50-3:10 | Variables: variable libraries para cambiar de entorno | Demo |
| 3:10-3:45 | Trabajo en equipo en `ws-gitws-team`, conflicto incluido | 6 |
| 3:45-4:00 | Deployment pipelines vs fabric-cicd, y cierre | Demo con FabricAsCode |

## Coste orientativo

F8 durante 5 horas (montaje, taller y margen), pausada el resto del tiempo. Lo cubren los
créditos MVP. El budget avisa al 50, 80 y 100 %.
