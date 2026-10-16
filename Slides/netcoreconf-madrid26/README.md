# Y yo aquí creando workspaces a mano · Terraform al rescate

Slides de la sesión de Mar Lizana y Alfonso Ming en NetCoreConf Madrid '26 (23 de octubre).
Usan la plantilla oficial de NetCoreConf.

Esta carpeta es el **código fuente** de la presentación: 45 diapositivas en HTML, con animaciones.
Se editan y se presentan desde una presentación de Claude (Slides). Desde ahí se exportan a PowerPoint o PDF
(Compartir › Exportar).

## Contenido

| Ruta | Qué es |
|---|---|
| `deck.json` | Índice: orden de las diapositivas, secciones y tipografías (Poppins, Inter, JetBrains Mono) |
| `slides/<id>.html` | Una diapositiva por fichero. Las notas de ponente van en el `<aside>` del final |
| `assets/<id>.jpg` | Imágenes. Las diapositivas las referencian como `/_blob/<id>` |

| Asset | Imagen |
|---|---|
| `14b7ab1d…` | Fondo de portada y cierre (Madrid) |
| `8bbbd60b…` | Fondo blanco de contenido con el logo |
| `919f3cb7…` | Fondo degradado de separadores y demos |
| `ed4c6529…` | Patrocinadores |
| `0b05226c…` | Foto de Mar |
| `11e2d662…` | Foto de Alfonso |

## Estructura de la charla

1. Arranque en tono teletienda: el Word de despliegue y la cuenta de 12 workspaces
2. Bloque 1: qué es Infrastructure as Code
3. Bloque 2: qué es Terraform
4. Bloque 3: cómo funciona (estado, plan, apply, drift)
5. Bloque 4: Terraform + Fabric en la práctica, con las dos demos de este repo (`scripts/demo.ps1`)
6. Cierre: trampas, continente vs. contenido, qué hacer el lunes y recursos

La versión anterior en PowerPoint sigue en `../terraform-fabric-netcoreconf-madrid26.pptx`.
