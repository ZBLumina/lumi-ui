# Lumi UI v0.4.8 — Composición y jerarquía

La referencia aportada inspira un espacio real de 12 px entre el panel principal y el inspector. Ambos conservan bordes redondeados, sombra suave propia y el mismo desplazamiento, escala y ciclo de vida. La envolvente transparente mantiene el centrado y los límites de la ventana completa. En pantallas compactas se oculta el inspector y el espacio vuelve al contenido.

Se descarta una línea interior porque mantendría una sola superficie. También se descartan dos ventanas independientes: complicarían el arrastre y podrían quedar fuera de pantalla. Decisión de implementación delegada: conservar `Main` como envolvente y añadir `Panel` como superficie principal.

El título de página crece de 27 a 32 px; los títulos de sección, de 13 a 15; las propiedades, de 14 a 15. El inspector gana anchura y sus valores parten de 32 px, ajustándose mediante medición real. El encabezado superior refuerza su lectura sin competir con el título. Se conservan español, paleta cálida, controles medidos y movimientos breves.

Verificación: probar separación, desplazamiento y límites; apertura/cierre conjunto; menús y controles en seis tamaños; ajuste de textos; español; limpieza y reinyección en Roblox/Potassium. Se mantiene la API de construcción y no se añade lógica de juego.

## Ajustes de acabado

El inspector mide 224 px y se alinea con los extremos del panel principal. Su cabecera, el nombre de la propiedad, la vista del valor y los metadatos tienen ritmos separados. Los valores parten de 32 px y se reducen solo cuando la medición exige ajustarlos. Los títulos y subtítulos de página permiten varias líneas y hacen crecer el encabezado.

Los menús flotantes se limitan al ancho de la superficie principal. El inspector conserva la captura de entrada sobre su superficie; el hueco transparente no consume entrada del mundo. La apertura, el cierre y las sombras pertenecen a una sola transformación, sin temporizadores ni conexiones globales adicionales.

Durante la comprobación se detectó un error previo al destruir el `ScreenGui` externamente: el contenedor de Potassium bloqueaba `Parent` durante una segunda llamada a `Destroy`. El aviso `Destroying` ahora libera primero la referencia del ámbito y deja al motor terminar esa destrucción.

## Evidencia en cliente real — 30 de octubre de 2026

- Potassium, cliente PID 30380: **50/50 pruebas correctas**, incluidos límites, cierre conjunto, encabezados estrechos y captura del inspector. Solo aparecen las dos advertencias intencionales de aislamiento de errores.
- Las pruebas nuevas se observaron fallar antes de aplicar sus correcciones: separación y cierre 46/48; encabezados 48/49; captura 49/50. La expectativa previa de desvanecimiento ahora observa `Panel` porque `Main` es la envolvente transparente; sigue exigiendo un desvanecimiento intermedio real.
- Se comprobaron los 15 controles en seis tamaños: 1920×1080, 1132×720, 900×720, 640×360, 420×700 y 320×500. Los 90 casos mantienen textos y campos contenidos y separados.
- La auditoría de español revisó 3473 textos y estados, incluidas listas vacías, valores de reserva y contadores singular/plural.
- Los títulos y subtítulos de las tres páginas caben completos en los seis tamaños. Los nombres, descripciones y valores del inspector caben para los 15 controles.
- Los eventos nativos verificaron interruptor, deslizador arrastrado al 75%, foco del campo y confirmación de 42 con Intro, selector, acción, navegación, lista vacía, restablecimiento y desplazamiento conjunto de 42×18 px. Para el campo numérico se asignó el texto por script después de obtener foco real; no se afirma entrada física de dígitos.
- Generación determinista, comprobación de archivos, sintaxis del generador y revisión de espacios correctas. Revisión independiente: se corrigió la captura de entrada del inspector mediante una regresión RED→GREEN.
- El botón de cierre real liberó ambas superficies y sus conexiones; la recarga final dejó una sola interfaz v0.4.8 montada.

No se probaron dispositivos táctiles ni mando físico. Esta revisión permanece en la rama de desarrollo del PR; `main` conserva su versión publicada.
