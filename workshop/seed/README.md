# Workshop: Git para gente de Power BI

Este es **tu** repositorio. Solo lo ves tú (y las facilitadoras). Rompe lo que quieras:
para eso está Git.

## Tus credenciales

- Usuario de Fabric: el que te hemos dado en papel (`gitws-NN@akanemar.onmicrosoft.com`)
- Workspace de Fabric: se llama igual que este repo
- Repo colaborativo: `gitws-team` (ahí trabajamos todas juntas al final)

## Ejercicios

### 1 · Conecta tu workspace a este repo
1. En Fabric abre tu workspace → **Workspace settings → Git integration**.
2. Elige **GitHub**, conecta tu cuenta y selecciona este repo, rama `main`, carpeta `/`.
3. Fíjate en lo que aparece en GitHub después del primer commit.

### 2 · Tu primer commit desde Fabric
1. Crea un lakehouse y un informe (vale el de ejemplo).
2. En **Source control**, escribe un mensaje que diga *qué* has cambiado y *por qué*.
3. Haz commit. Mira en GitHub qué ficheros se han creado.

### 3 · Las tripas: PBIP y TMDL
1. Abre en GitHub la carpeta `.SemanticModel/definition`. Cada tabla es un fichero `.tmdl`.
2. Cambia en Fabric el formato de una medida y haz commit.
3. Mira el diff en GitHub: ese es el cambio, y nada más.

### 4 · Ramas
1. En Fabric, **Source control → Branch out** a una rama `feature/<tu-nombre>`.
2. Cambia algo en el informe y haz commit en la rama.
3. En GitHub abre una **pull request** hacia `main` y mírala antes de mergear.

### 5 · Deshacer sin rezar
1. En GitHub, revierte el último commit (**Revert**).
2. En Fabric, **Update all** y comprueba que el informe vuelve a como estaba.

### 6 · Trabajo en equipo (repo `gitws-team`)
1. Conecta el workspace `gitws-team` al repo `gitws-team`. Una sola persona lo hace.
2. Cada una crea su rama, cambia **su** página del informe y abre una PR.
3. Revisamos y mergeamos juntas. `main` está protegida: sin PR aprobada no entra nada.
4. Provocamos un conflicto a propósito y lo resolvemos.

## Glosario de supervivencia

| Palabra | Lo que significa |
|---|---|
| commit | Una foto de tus cambios con un mensaje |
| rama (branch) | Una línea de trabajo paralela que no molesta a `main` |
| pull request | "Quiero meter mi rama en main, ¿lo revisas?" |
| merge | Juntar una rama con otra |
| conflicto | Dos personas cambiaron la misma línea: Git te pregunta cuál vale |
