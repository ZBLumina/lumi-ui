# Lumi UI 0.4.12 · Identidad visual

Alcance: una pasada visual sobre la composición actual. Se conservan API, contenido, valores, interacciones, animaciones, distribución de paneles y adaptación táctil.

## Dirección

Superficies de café y grafito cálido; texto marfil, secundarios arena y acentos miel. La separación entre superficies sigue siendo discreta y legible. El contraste del texto prevalece sobre la decoración.

Fredoka SemiBold para títulos principales; Nunito Sans Regular/Medium para lectura, controles y cifras; Montserrat Medium para rótulos superiores espaciados; Comfortaa SemiBold para la marca. Fuentes estáticas originales de Google Fonts, con licencia OFL, incorporadas al script y registradas localmente cuando el ejecutor lo permite. Las medidas se calculan con la misma FontFace que se dibuja. Hay una alternativa nativa si el entorno no admite fuentes locales.

Ondas y arcos originales, finos y de bajo contraste, en espacios de cabecera. Un destello de cuatro puntas acompaña la marca. Son geometría de interfaz, sin imágenes de las referencias, descargas ni capturas incrustadas. Se ocultan los adornos de la cabecera en teléfono y cuando el texto necesita ese espacio. Nunito Sans recibe dos píxeles adicionales para conservar el tamaño de lectura; las filas siguen ajustándose a las medidas reales.

## Implementación y comprobación

1. Incorporar las cinco variantes tipográficas, sus licencias y una generación reproducible del paquete. Cargar y medir las fuentes en Roblox antes de usarlas.
2. Actualizar únicamente tokens visuales, roles tipográficos y ornamentos. Conservar la geometría de interacción y las reglas de ajuste de textos.
3. Ejecutar la batería existente en Potassium, comprobar las fuentes reales, revisar el texto y la geometría en seis tamaños y observar el resultado renderizado. Copiar los artefactos verificados a `outputs` y actualizar la misma rama de previsualización.

Las nueve imágenes del usuario son referencias visuales, nunca recursos del paquete.

## Resultado verificado

- Potassium, cliente Roblox PID 25992: **68/68 pruebas existentes**, sin fallos. Dos avisos corresponden a errores intencionales de funciones de prueba. La aserción del inspector conserva su umbral y ahora mide FontFace en lugar del antiguo Enum.Font.
- **96 distribuciones de controles**, sin recortes de nombres/descripciones ni solapamientos: 1920×1080, 1132×720, 900×720, 640×360, 420×700 y 320×500. Escala de lectura 1.
- **3846 textos/estados** revisados por la comprobación de español.
- Flujo táctil simulado en el motor, 390×844: menú, cambio de página, desplazamiento, miniatura, deslizador 20→80, minimizar y restaurar; diez eventos táctiles recibidos. Esto no sustituye una prueba en un teléfono físico.
- Las cinco FontFace cargadas en Roblox tienen las familias y pesos especificados. Las cabeceras y la marca caben en seis tamaños. Los ornamentos no capturan entrada y la cabecera ornamental se oculta en teléfono.
- Respaldo nativo probado con las funciones de archivos/registro de fuentes deshabilitadas en el ámbito de la comprobación.
- Contraste calculado de los tokens de lectura sobre siete superficies: mínimo **5,07:1**; texto del botón principal **9,05:1**.
- TTF estáticas con pesos, tablas, acentos españoles y sumas verificadas; archivos y licencias incorporados al paquete. Comfortaa es la fuente estática oficial sin modificar. Revisión independiente de código sin hallazgos P1/P2.

No se modifican nombres de opciones, valores, funciones asociadas, entradas, seguimiento, minimización, API ni navegación. Los únicos cambios en el ajuste de controles son las medidas necesarias para dibujar la nueva tipografía.
