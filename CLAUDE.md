# Contexto del proyecto (para agentes: Claude Code, Copilot, etc.)

FabricAsCode: Microsoft Fabric como codigo con Terraform (capacity, workspaces, grupos de
Entra y roles), Fabric CLI (`fab`) para las operaciones y fabric-cicd para el contenido.
Repo en castellano. Material de las charlas de Mar Lizana (@akanemar) y Alfonso Ming.

Si existe `CLAUDE.local.md` (no se commitea), leelo tambien: tiene el entorno real,
lo desplegado y los pendientes.

## Estructura

- `main.tf`, `variables.tf`, `outputs.tf`: capacity (opcional con `existing_capacity_id`),
  template elegido (`medallion-cicd` o `workshop`), repo de contenido y budget.
- `modules/workspace-with-roles`: un workspace, 4 grupos de Entra y 4 roles. El grupo Admin
  lleva `admin_group_members`.
- `modules/templates/medallion-cicd`: capas x entornos.
- `modules/templates/workshop`: por alumno `userN-<prefijo>` y `ws-<prefijo>-userN`; mas `ws-<prefijo>-team`.
- `environments/*.tfvars`: un fichero por escenario. `scripts/demo.ps1`: la demo en Windows PowerShell.
- `backend.tf.example`: estado remoto en Azure Storage.

## Ficheros locales que NO se commitean

`scripts/demo.config.ps1` (IDs), `personal.auto.tfvars` (correos), `backend.hcl`,
`CLAUDE.local.md`, `*.tfstate`, `credenciales*.json`. Secretos (secret del SP, PAT): solo en
variables de entorno o en los secrets de GitHub.

## Windows PowerShell 5.1

- Argumentos con punto entrecomillados: `"-target=module.capacity"`.
- Secretos desde el portapapeles: `(Get-Clipboard).Trim()`. Terminal nueva: `. .\scripts\demo.ps1 env`.
- Con la capacity pausada el provider de Fabric no deja hacer plan/apply/destroy.

## Lecciones aprendidas

- Ficheros que van al repo de contenido: siempre LF. Bash en el runner no admite CRLF.
- `fab` en GitHub Actions: sin keyring, `fab config set encryption_fallback_enabled true` y `FAB_SPN_*`.
- Re-run de un workflow usa el commit antiguo: para probar un arreglo, "Run workflow" de nuevo.

## Convenciones

- Nombres: `<proyecto>-<capa>-<entorno>` para workspaces; `sg-fbc-<proyecto>-<capa>-<entorno>-<rol>` para grupos.
- Commits en castellano, sin tildes en el codigo HCL.
- No ejecutar `apply` ni `destroy` sin ensenar antes el plan.
