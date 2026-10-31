# v0.4.11 — Navegación separada, perfil e imágenes

La barra lateral será una tercera superficie con borde, sombra y hueco real de 12 px. El inspector conservará su seguimiento. El pie de navegación mostrará avatar, nombre visible y @usuario con un respaldo si no carga la imagen. La paleta pasa a grafito más profundo, conservando contraste y acento crema.

Los selectores admiten cadenas existentes y opciones `{Value, Label, Image}`. El valor de la API y la función asociada sigue siendo `Value`; las etiquetas y miniaturas son presentación. `AddImageDropdown` ofrece un alias explícito. Las fuentes de imagen admiten recursos nativos, `{Path}`, `{Url}` y `{Data, Name}` con PNG/JPEG integrado en base64, caché propia y carga cancelable. Un error conserva un marcador visual y no bloquea la selección.

En teléfono el contenido ocupa el ancho de la ventana. La navegación se abre mediante un botón de menú y se cierra al elegir una página. Los controles tienen zonas táctiles de al menos 44 px; los selectores con imágenes admiten desplazamiento. El perfil se consulta desde esa navegación. La cápsula también crece para permitir pulsarla con el dedo.

Se probarán geometría de tres superficies, perfil, compatibilidad de selectores existentes, selección visual, imágenes integradas/locales/remotas y sus fallos, cambios rápidos de fuente, limpieza y reinyección. La validación móvil distinguirá tamaños de pantalla y eventos táctiles simulados de una prueba en teléfono físico.

La referencia Neverlose se consulta sin ejecutarla. Sus iconos usan IDs de Roblox; las fuentes se descargan desde GitHub. No se incorporan sus módulos o lógica de juego.

## Verificación — 31 de octubre de 2026

Cliente real de Roblox mediante Potassium, PID 25992:

- **68/68 pruebas de funcionamiento**, con instancias y conexiones reales. Las cinco regresiones iniciales se observaron fallar en v0.4.10 (59/64). La comprobación previa de descripciones largas se mantuvo y corrigió mediante filas apiladas en modo teléfono.
- **96 distribuciones**: 16 controles en 1920×1080, 1132×720, 900×720, 640×360, 420×700 y 320×500, sin solapamiento de texto, campos ni carriles. En esos tamaños el contenido conserva escala 1.
- **3846 textos y estados** revisados por la auditoría de español.
- Avatar real cargado (`IsLoaded = true`); perfil personalizado con nombre visible distinto del usuario y respaldo de iniciales ante una imagen inválida.
- Las tres miniaturas PNG originales integradas se cargaron en el renderizador. Se comprobaron además archivo local, URL HTTPS del paquete de iconos facilitado y respuesta controlada ante Base64 inválido.
- Se comprobó la cancelación de una descarga real al seleccionar otra imagen; la miniatura más reciente prevalece. La cancelación de trabajo suspendido tiene una regresión con una coroutine y BindableEvent reales, observada fallar al retirar el retorno de la tarea del ámbito.
- Revisión independiente: corregidos el menú sobre navegación oculta, la altura del popup en 320×300 y la continuación de tareas de imagen obsoletas. Los dos primeros se observaron fallar antes de corregirse.
- **Táctil simulado en 390×844**: el motor recibió diez inicios táctiles. Pasaron menú, cambio de página, gesto vertical de desplazamiento, selección de miniatura, deslizador de 20 a 80, minimización y restauración conservando el valor.

La navegación adaptable también se activa cuando Roblox informa entrada táctil, para cubrir pantallas apaisadas. **No se ha probado en un teléfono físico ni con un ejecutor móvil.** Los archivos locales e integrados requieren las funciones de archivo y registro de imágenes del ejecutor; si faltan, aparece el marcador de respaldo. El perfil y la selección permanecen utilizables.

El modo teléfono reserva el espacio superior que informa Roblox para evitar colisiones del menú y de la cápsula con la barra del sistema. Esta regresión falló antes de la corrección (67/68). La navegación táctil tiene filas de 48 px.

Generación, coherencia de archivos, sintaxis del generador y diferencias comprobadas. La rama permanece en el PR de desarrollo; `main` conserva su versión publicada.
