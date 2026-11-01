# Lumi UI 0.4.19 · MingCute y cabecera despejada

Se retira la planta central y su reserva de espacio. Los títulos y descripciones aprovechan el ancho completo; una cabecera corta ocupa 124 px en escritorio y 104 px en teléfono, creciendo cuando el texto lo requiere. Los fondos sutiles de los paneles se conservan, junto con la paleta de carbón cálido, café y crema.

Los iconos geométricos de la navegación se sustituyen por imágenes de MingCute Core Regular. El mismo conjunto proporciona Inicio, búsqueda, perfil, ajustes, registros, notas, ayuda, capas, flechas, marca de selección, cerrar, minimizar y menú. Los iconos de navegación tienen 20 px. La marca propia L con punto conserva su forma.

## Recursos y funcionamiento

18 SVG oficiales se conservan en `assets/icons/mingcute/svg`, con revisión fija, rutas de procedencia y manifiesto. `npm run icons:render` convierte los SVG a PNG blancos transparentes de 96×96 mediante resvg-js 2.6.2. El generador incorpora los PNG como Base64 en el script y añade la licencia Apache-2.0 y la atribución.

`Icons.luau` reutiliza `ImageSource.Resolve` para guardar y registrar cada PNG dentro de `lumi-ui/assets`; un ImageLabel muestra cada dibujo completo. ImageColor3 aplica los estados crema y secundarios. No se usan Roblox IDs ni HTTP para cargar los iconos. Los entornos sin registro de archivos locales mantienen los nombres y controles, aunque pueden ocultar los iconos.

Fuentes: [MingCute](https://github.com/mingcute-design/mingcute-icons), revisión `4b85ae197f6c10c8740f2b03a0be0f0864fc18ec`; [licencia](https://github.com/mingcute-design/mingcute-icons/blob/4b85ae197f6c10c8740f2b03a0be0f0864fc18ec/LICENSE); [conversor resvg-js](https://github.com/thx/resvg-js).

## Comprobación

Las nuevas regresiones fallaron antes de implementar: los iconos aún eran geometría y la planta permanecía montada. Tras el cambio pasan 89/89 pruebas nativas en Roblox, PID 24604. La prueba de iconos espera la carga real de los PNG y comprueba su estado de selección, transparencia de fondo y entrada pasiva. La prueba de cabecera comprueba la ausencia de imágenes y la separación respecto al contenido.

Las dos regresiones anteriores de intensidad decorativa se aplican ahora al fondo lateral conservado; mantienen sus mismas expectativas de opacidad y de persistencia durante minimizar/restaurar.
