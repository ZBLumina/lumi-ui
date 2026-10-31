# Lumi UI 0.4.13 · Fondos botánicos

La interfaz adopta el prototipo «Panel Lumi de ajustes en tonos cálidos»: café con profundidad suave, cintas y hojas en los bordes, contornos miel, un título más presente y controles redondos. Conserva los tres paneles separados, la API, los valores, las acciones, las animaciones, el perfil y los selectores con miniaturas.

## Recursos y composición

Cuatro imágenes originales creadas con la herramienta integrada **imagegen**, publicadas en la revisión `76a9281b484b3e69f1e2627e132166f370acc240` del repositorio:

- `lumi-sidebar-botanico-v1.png`: fondo de navegación, 724×2172.
- `lumi-panel-botanico-v1.png`: fondo principal, 1254×1254.
- `lumi-inspector-botanico-v1.png`: fondo del inspector, 724×2172; deja libre la zona de propiedades.
- `lumi-flor-cabecera-v1.png`: cabecera transparente, 1536×1024.

Los prompts y los ajustes están en [PROTOTIPO.md](../../assets/decor/PROTOTIPO.md). Las imágenes de referencia no están integradas en los recursos. Los textos, botones, campos y deslizadores siguen siendo elementos nativos; no están dibujados dentro de las imágenes.

`src/Artwork.luau` centraliza las cuatro fuentes. `BrandArt` usa ImageLabel pasivos por debajo del contenido y el cargador cancelable de imágenes. Los archivos se descargan una vez y se guardan en la caché local. El registro de un mismo archivo reutiliza su URI para evitar copiar repetidamente su textura compartida.

Los fondos respetan las esquinas, las animaciones y la separación entre paneles. El principal puede aprovechar hasta 768 píxeles de alto cuando hay espacio. Fredoka tiene 40 píxeles en escritorio y 32 en teléfono. Los campos tienen 36 píxeles en escritorio y 44 en teléfono. La ilustración de cabecera se oculta en teléfono o cuando el texto necesita el ancho. Una imagen fallida deja visible el color café base.

## Verificación

- **68/68 pruebas existentes**, sin fallos, ejecutadas en el PID 25992. Los dos avisos de funciones que fallan intencionalmente son parte de la prueba.
- **96 distribuciones de controles** en 1920×1080, 1132×720, 900×720, 640×360, 420×700 y 320×500: nombres y descripciones legibles, campos contenidos y sin solapamientos, escala 1.
- Tras finalizar el proceso anterior, el usuario autorizó exclusivamente el **PID 12920**. Las comprobaciones finales y la captura se realizaron en ese cliente.
- **3846 textos/estados** revisados en español en el PID 12920.
- Flujo táctil simulado en el motor a **390×844**: menú, página, desplazamiento, miniatura, deslizador 20→80, minimizar y restaurar; diez eventos táctiles recibidos.
- Los tres fondos y las tres instancias de cabecera se cargaron en el cliente. Comprobados IsLoaded, precarga, opacidades, ausencia de captura de entrada y separación de la ilustración respecto al texto.
- Arrastre real con seguimiento del inspector, minimización y restauración por clic: conservan posición, sección, selección y valor.
- Paquete determinista comprobado con `npm run check`, sintaxis del generador y `git diff --check`.

La prueba táctil utiliza el motor de escritorio; no se ha ejecutado en un teléfono físico.
