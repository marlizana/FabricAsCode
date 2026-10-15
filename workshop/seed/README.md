# Workshop: Git para gente de Power BI

Este es el repo **común** del taller: aquí están los ejercicios y aquí trabajaremos todas
juntas al final. Tu repo personal lo creas tú en el ejercicio 1, en tu cuenta de GitHub.

## Tus credenciales

- Usuario de Fabric: el que te hemos dado en papel (`userN-gitws@akanemar.onmicrosoft.com`)
- Workspace de Fabric: `ws-gitws-userN` (solo lo ves tú)
- Repo personal: el que creas en el ejercicio 1
- Repo colaborativo: `gitws-team`, este. Te invitamos en el descanso: acepta la invitación que llega por correo

## Ejercicios

### 1 · Tu repo y tu workspace, conectados
1. En GitHub: **New repository** → nombre `workshop-git` → **Private** → marca *Add a README* → **Create**.
2. En GitHub: **Settings → Developer settings → Fine-grained tokens → Generate new token**.
   Solo ese repo, permiso **Contents: Read and write**, caducidad 7 días. Copia el token.
3. En Fabric abre `ws-gitws-userN` → **Workspace settings → Git integration → GitHub**.
   **Add account** con el token y la URL de tu repo; rama `main`, carpeta `/`.

### 2 · Tu primer commit desde Fabric
1. Crea un lakehouse y un informe (vale el de ejemplo).
2. En **Source control**, escribe un mensaje que diga *qué* has cambiado y *por qué*.
3. Haz commit. Mira en GitHub qué ficheros se han creado.

### 3 · Las tripas: PBIP y TMDL
1. Abre en GitHub la carpeta `.SemanticModel/definition`. Cada tabla es un fichero `.tmdl`.
2. Cambia en Fabric el formato de una medida y haz commit.
3. Mira el diff en GitHub: ese es el cambio, y nada más.

### 4 · Tu primera pull request (antes del descanso)
1. En Fabric, **Source control → Branch out** a una rama `feature/<tu-nombre>`.
   Si Branch out a un workspace nuevo da error de permisos: **Checkout new branch** en tu propio workspace.
2. Cambia algo en el informe y haz commit en la rama.
3. En GitHub abre una **pull request** hacia `main`, lee el diff, apruébala y haz merge (es tu repo).
4. Vuelve al workspace de `main` y pulsa **Update all**: ahí está tu cambio.

### 5 · Trabajo en equipo (repo `gitws-team`)
`ws-gitws-team` ya está conectado a la rama `main` de este repo. `main` está protegida: sin PR aprobada no entra nada.
1. Crea un segundo token, esta vez **classic**: **Settings → Developer settings → Tokens (classic)**,
   scope **public_repo**, caducidad 7 días. El fine-grained del ejercicio 1 no sirve: GitHub no deja
   usarlos en repos de otra persona en los que eres colaboradora.
2. En `ws-gitws-team`, **Branch out** a tu rama (`team/<tu-nombre>`) con ese token y cambia **tu** página del informe.
3. Commit y pull request hacia `main`.
4. Revisa la PR de quien tengas al lado: lee el diff y apruébala. Con la aprobación, mergea la tuya.
5. Provocamos un conflicto a propósito y lo resolvemos juntas.

### 6 · Deshacer sin romper nada (repo `gitws-team`)
1. En GitHub abre **tu** pull request del ejercicio 5, ya mergeada, y pulsa **Revert**.
2. Se crea una PR nueva que deshace la anterior: pide que te la aprueben y mergéala.
3. En `ws-gitws-team`, **Source control → Updates → Update all**: tu página vuelve a como estaba.
4. Mira el historial de `main`: el cambio y su revert siguen ahí. No se ha borrado nada.

Plan B si no llegaste a mergear en el ejercicio 5: haz el Revert de tu PR del ejercicio 4 en tu repo `workshop-git`.

## Glosario de supervivencia

| Palabra | Lo que significa |
|---|---|
| commit | Una foto de tus cambios con un mensaje |
| rama (branch) | Una línea de trabajo paralela que no molesta a `main` |
| pull request | "Quiero meter mi rama en main, ¿lo revisas?" |
| merge | Juntar una rama con otra |
| conflicto | Dos personas cambiaron la misma línea: Git te pregunta cuál vale |
