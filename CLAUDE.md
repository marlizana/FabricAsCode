# Contexto del proyecto (para agentes: Claude Code, Copilot, etc.)

Repo de Mar Lizana (Microsoft MVP, @akanemar) para sus charlas y su workshop sobre
Microsoft Fabric como código. Escrito en castellano; las charlas de DataPopkorn van en inglés.
Ultima actualizacion: 7/10/2026.

## Charlas que usan este repo

| Fecha | Evento | Sesion | Estado |
|---|---|---|---|
| 23/10/2026 | NetCoreConf Madrid | «Y yo aqui creando workspaces a mano: Terraform al rescate para Fabric» (40 min, tono teletienda, Terraform desde cero) | Aceptada |
| 2/11/2026 | DataPopkorn | Fabric as Code · Git Basics for Microsoft Fabric · Your Delta Table Is Not a Table (3 x 5 min, en ingles, grabadas) | Aceptadas |
| 5-7/11/2026 | DataSaturday Madrid | Workshop 4 h «Dime que commiteas y te dire quien eres» (Git para gente de Power BI) | Aceptado |
| 5-7/11/2026 | DataSaturday Madrid | Cuando usar que. Principios de arquitectura en Fabric (50 min) | En evaluacion |
| 13-14/11/2026 | W4TT Anfitrionas | Your Delta Table Is Not a Table (20 min, con Diana) | En evaluacion |

## Entorno (sin secretos)

- Tenant: `akanemar.onmicrosoft.com` (tenant ID `bc6b1bb6-0e6c-4cc2-a2f4-b3603c4dd6a8`).
  Owner: `mar.lizana@akanemar.onmicrosoft.com`.
- Suscripcion: `sub-creditos-mvp` (`c52466ac-5cb2-4bd7-87e3-770ee8c4c12f`), pagada con creditos
  de patrocinio MVP (12.000 US$, caducan 15/8/2027). Region con cuota de Fabric: **spaincentral**
  (West Europe no tiene cuota con el patrocinio).
- Service principal: `sp-fabricascode` (client ID `36341d06-ef04-4823-8fe8-075ee14b0908`,
  object ID `82b7adf0-484b-4a8c-aaca-7589ee1e81ee`).
  - Azure: Contributor + User Access Administrator en la suscripcion.
  - Entra: Groups Administrator + User Administrator.
  - Fabric tenant settings, via el grupo `sg-fabric-automation`: Service principals can call
    Fabric public APIs, can create workspaces..., y **Create workspaces**.
- Los secretos (secret del SP, PAT de GitHub con scopes `repo` + `workflow`) solo viven en
  variables de entorno y en los secrets de GitHub. Nunca en ficheros.
- Mar trabaja en Windows, Windows PowerShell 5.1 (conda base) en VS Code. Ojo:
  - Los argumentos con punto hay que entrecomillarlos: `"-target=module.capacity"`.
  - `Read-Host -MaskInput` no existe en 5.1, y pegar en `-AsSecureString` solo coge 1 caracter.
    Usar `(Get-Clipboard).Trim()`.
  - No hay `make` ni bash: usar `scripts/demo.ps1`.
  - Terminal nueva = variables perdidas: `. .\scripts\demo.ps1 env` (con punto). Sin `GITHUB_TOKEN`
    el plan cree que el repo privado no existe y propone recrearlo (17 to add): NO aplicar.
  - Con la capacity pausada, el provider de Fabric no deja hacer plan/apply/destroy:
    `reanuda` → plan/apply → `pausa`.

## Que hay desplegado ahora (estado local `default`, tfvars `environments/akanemar-demo.tfvars`)

- Capacity F2 `fbcakanemardemoxnns` (RG `rg-fbc-fbcakanemardemo`). **Pausarla siempre al acabar.**
- 9 workspaces `demo-{bronze,silver,gold}-{dev,test,prod}`, 36 grupos `sg-fbc-demo-*`, budget 150 €/mes.
- Repo de contenido `marlizana/fabricascode-demo-content` (workflows fabric-cicd y fabric-ops).
- Plan para la demo: la capacity, el repo y el budget se quedan. Los workspaces y grupos se
  destruyen y recrean en directo con `-target=module.medallion_cicd`.

## Ramas y PRs

- `feat/demo-ready` (PR #1): contenido de ejemplo, Fabric CLI, budget, entornos y capas como
  variables, `project_name` sin default, `scripts/demo.ps1`, `examples/01-hola-workspace`,
  `environments/netcoreconf.tfvars` (estado separado, terraform workspace `netcoreconf`).
- `feat/workshop-template` (PR #2, encima de #1): template `workshop`. Por asistente: usuario de
  Entra, workspace y repo privado. Mas un entorno `gitws-team` compartido. Ver `docs/workshop.md`.

## Documentos de apoyo (Claude)

- Guiones de grabacion DataPopkorn: https://claude.ai/code/artifact/2b5739de-9d11-43de-82f6-cacb33aded40
- Guion NetCoreConf (escaleta, demo con demo.ps1, desajustes deck/repo, checklist): https://claude.ai/code/artifact/c62b2ba9-8527-4669-a14c-9103d2f1cc84
- NetCoreConf es con Alfonso Ming (SRE @ SCRM). Deck: Slides/terraform-fabric-netcoreconf-madrid26.pptx (44 slides).

## Pendiente

- [x] Popkorn: secrets/variables en el repo de contenido, fabric-cicd a test y prod (run #8, 7/10)
      y notebooks ejecutados en test con fab-ops `run` (run #4, 7/10).
- [ ] Popkorn: grabar Fabric as Code (7/10), Git Basics y Delta (8/10), enviar (9/10).
- [ ] NetCoreConf: decidir backend remoto del estado (slide 32), version del provider (~> 1.14) y si se publica el repo (QR slide 43).
- [ ] NetCoreConf: estrenar `demo.ps1` (aun no ejecutado en Windows), slides desde
      `Slides/terraform-fabric-netcoreconf-madrid26.pptx`, ensayos 9/10, 15/10 y 21/10.
- [ ] Workshop: decidir licencias Pro (trial autoservicio), MFA (security defaults) y si el repo
      team es publico. Mail a asistentes 27/10, apply 2/11, prueba con 2 usuarios 4/11.
- [ ] Limpieza: quitar el acceso elevado (Gmail y mar.lizana) y el Global Admin de la cuenta de Gmail.
- [ ] 12/10: borrar la F2 olvidada en `sub-mvp-01` (otra suscripcion, MSDN) cuando se reactive.

## Lecciones aprendidas

- Ficheros que van al repo de contenido: siempre LF (`.gitattributes` + `replace()` en main.tf). Bash en el runner no admite CRLF.
- `fab` en GitHub Actions: sin keyring, hay que `fab config set encryption_fallback_enabled true` y autenticar con `FAB_SPN_*`.
- Re-run de un workflow usa el commit antiguo: para probar un arreglo, "Run workflow" de nuevo.

## Convenciones

- Nombres: `<proyecto>-<capa>-<entorno>` para workspaces; `sg-fbc-<proyecto>-<capa>-<entorno>-<rol>` para grupos.
- Commits en castellano, sin tildes en el codigo HCL.
- No ejecutar `apply` ni `destroy` sin ensenar antes el plan a Mar.
