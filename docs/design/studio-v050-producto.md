# Lumi UI 0.5.0

Se incorporan las cinco mejoras elegidas: perfiles, avisos, legibilidad, API de integración y pulido. Se conserva la composición de tres paneles, la identidad L con punto, MingCute, las fuentes de Lumi y la combinación de carbón, café y crema. La cabecera permanece despejada.

## Comportamiento

- Configuraciones permite guardar y cargar perfiles con nombre. La demostración usa autoguardado y carga después de construir los controles. Recupera valores tipados, página, posición relativa, español o portugués y preferencias visuales.
- El almacenamiento es local y optativo. Las escrituras se verifican mediante relectura y conservan una versión anterior. Los archivos corruptos o ilegibles no se interpretan como un perfil vacío. Un fallo de cierre o reinyección mantiene la ventana anterior y sus datos editables para reintentar.
- Los avisos ofrecen carga, éxito, error, cierre y acción. Hay un máximo de tres visibles; los demás esperan. Las acciones se ejecutan una vez y se limpian al cerrar.
- El texto se amplía de 100 a 130 %. Filas, títulos, límites de slider, navegación y pie ajustan su espacio. El inspector permite desplazamiento para evitar superponer propiedades y ayuda.
- Tab y Mayús+Tab recorren controles disponibles; Intro y Espacio activan; las flechas ajustan sliders. Se respetan los campos en edición y los menús abiertos.
- Los controles tienen ID estable, búsqueda por ID, actualización, desactivación y destrucción propia. Un control desactivado acepta sincronización por código y bloquea la entrada del usuario. Un ID duplicado no crea una fila huérfana. Destruir elimina sus conexiones, tareas y registro.

## Integración

`examples/integracion.luau` y README documentan `Config`, `Ready`, perfiles, `Notify`, `GetControl`, `Update`, `SetEnabled` y `Destroy`. Los campos de perfil no se guardan dentro de sí mismos. Los nombres y notas del usuario se conservan sin traducción. La interfaz y los avisos tienen catálogo local es/pt.

Los archivos viven bajo `lumi-ui/config/<Key>`. No hay sincronización remota. El ejecutor debe proporcionar acceso a archivos; ante su ausencia se mantiene la GUI y se informa de la limitación. El respaldo requiere recuperación manual. El `Destroy()` explícito cancela guardados pendientes; `Close()` y la reinyección los guardan o conservan la ventana si fallan.

## Verificación en Roblox

- PID activa 30204: **123/123 regresiones nativas** correctas. Se conservan las 93 originales y se añaden controles, accesibilidad, perfiles, avisos e integración.
- Se ejecutaron casos con valores tipados, JSON corrupto, errores de lectura, rechazo, escritura descartada o alterada, respaldo, autoguardado, selección de perfil, callbacks y limpieza.
- La revisión independiente detectó pérdida de cambios en reinyección fallida, reintento de la primera escritura, retención de hooks y una acción de reintento en avisos de éxito. Se corrigieron; las tres últimas regresiones fallaron antes y pasaron después. La reinyección se comprobó además cargando dos veces la biblioteca en el cliente real.
- Dos ejecuciones y archivos reales recuperaron dos perfiles, un valor pendiente, notas con acentos, portugués, texto al 130 %, decoración y posición de ventana.
- **1.080 distribuciones de controles**, en 24 combinaciones: español/portugués, 100/130 % y seis viewports entre 320×500 y 1920×1080. Sin colisiones entre títulos, descripciones y campos, ni límites de slider recortados. Se comprobaron también cabeceras y pie.
- 90 revisiones del inspector al 130 %, con los 45 controles de la demostración en ambos idiomas: descripciones, valores, propiedades y ayuda legibles y sin superposición. La medición reserva un píxel horizontal para evitar saltos de línea por redondeo nativo.
- Toques nativos simulados con texto al 130 % en 390×844 y 320×500: menú, desplazamiento de los grupos, Ayuda, cuenta, Configuraciones, indicador de decoración, minimizar, restaurar y conservar notas. Cada tamaño se verificó de forma independiente. **No se probó un teléfono físico.**
- `npm run build`, `npm run check`, sintaxis de los generadores y `git diff --check` correctos.
