# Lumi UI

Biblioteca modular de interfaces en Luau para Potassium. **v0.4.20 incorpora traducción local entre español y portugués y un atajo para minimizar/restaurar, con iconos de MingCute y cabecera despejada.** La barra izquierda de 228 px organiza nueve accesos en Principal, Espacio y Herramientas; el perfil y Configuraciones permanecen al pie. La barra superior incluye Inicio, ruta y búsqueda funcional. Los títulos usan Fredoka SemiBold; el texto, Nunito Sans Regular/Medium; los rótulos pequeños espaciados, Montserrat Medium; la marca, Comfortaa SemiBold. Combina bases de carbón cálido con superficies café y acentos crema. Conserva los tres paneles separados, los fondos suaves, el seguimiento lateral, los selectores con miniaturas y la cápsula superior. La interfaz y la demostración inician en español; Configuraciones permite elegir portugués. Las acciones de ejemplo modifican la interfaz y sus valores de prueba.

Las cinco variantes TTF y sus licencias OFL están en `assets/fonts`. El generador incorpora sus bytes en el script: no se descargan fuentes al abrirlo. Potassium las registra en su carpeta local `lumi-ui/fonts`; otros entornos sin registro de archivos usan fuentes nativas de respaldo. El ajuste de textos utiliza la FontFace real.

Los fondos decorativos son PNG en `assets/decor`, con sus prompts de generación. `src/Artwork.luau` centraliza los fondos suaves de navegación, panel principal e inspector: `Sidebar`, `Panel` e `Inspector`. Se descargan de una revisión fija del repositorio y se guardan en `lumi-ui/assets`. Las imágenes no capturan entrada y mantienen la superficie de carbón si fallan. La planta central se retiró: títulos y descripciones disponen del ancho completo y la cabecera ya no reserva espacio para una ilustración. Las imágenes de referencia del usuario no forman parte del paquete.

Los textos fuente se concentran en `src/Textos.luau` y el catálogo portugués en `src/translations/Portuguese.luau`: navegación, etiquetas, estados, ayudas, tipos de control, listas vacías y confirmaciones. La demostración también traduce todos sus títulos, descripciones y opciones. Se conservan los nombres de producto Lumi UI, Potassium y Luau, junto con los identificadores técnicos de la API. Los textos personalizados que no figuran en el catálogo se muestran tal como se reciben. Las notas, nombres de cuenta y consultas no se traducen.

Idiomas y atajo se registran en [las notas de v0.4.20](docs/design/studio-v0420-idiomas-atajo.md). Los iconos y la cabecera se registran en [las notas de v0.4.19](docs/design/studio-v0419-mingcute.md). La barra completa se registra en [las notas de v0.4.18](docs/design/studio-v0418-barra-completa.md). La navegación superior se registra en [las notas de v0.4.17](docs/design/studio-v0417-navegacion.md). Los fondos y el seguimiento lateral se registran en [las notas de v0.4.16](docs/design/studio-v0416-fondos-seguimiento.md). La cabecera completa y su comprobación se registran en [las notas de v0.4.15](docs/design/studio-v0415-cabecera.md). La corrección de claridad y marca se registra en [las notas de v0.4.14](docs/design/studio-v0414-claridad.md). La decoración botánica y su comprobación se registran en [las notas de v0.4.13](docs/design/studio-v0413-imagenes.md).

## Probar la versión actual en Potassium

Esta versión se desarrolla en la rama del PR. Para probarla:

```luau
loadstring(game:HttpGet("https://raw.githubusercontent.com/ZBLumina/lumi-ui/feat/lumi-studio-v04/dist/LumiUI.pilot.luau"))()
```

La dirección que usa `main`, conservada en `examples/potassium-loader.luau`, sigue la versión publicada de esa rama. También puedes ejecutar el archivo completo `dist/LumiUI.pilot.luau` mediante Potassium.

## Usar la biblioteca

`dist/LumiUI.luau` devuelve la biblioteca sin crear la demostración. `dist/LumiUI.pilot.luau` incluye Inicio, Jugador, Aspecto, Espacios, Interacción, Ajustes, Registros, Notas y Ayuda.

```luau
local Lumi = loadstring(game:HttpGet("https://raw.githubusercontent.com/ZBLumina/lumi-ui/feat/lumi-studio-v04/dist/LumiUI.luau"))()
local ventana = Lumi:CreateWindow({Title = "Lumi"})
local inicio = ventana:AddTab("Inicio", {Description = "Tu espacio de trabajo."})
local general = inicio:AddSection("General")

local activo = general:AddToggle({Name = "Activar espacio", Default = false,
    Callback = function(valor) print(valor and "Activado" or "Desactivado") end})
local intensidad = general:AddSlider({Name = "Intensidad", Min = 0, Max = 100,
    Default = 65, Step = 1, Suffix = "%", Callback = function(valor) print(valor) end})
general:AddDropdown({Name = "Modo", Values = {"Equilibrado", "Suave", "Preciso"},
    Default = "Equilibrado", Callback = function(valor) print(valor) end})
general:AddButton({Name = "Acción de prueba", Action = "Probar",
    Callback = function() print("Acción completada") end})

activo:Set(true)          -- Actualiza el estado y después llama a la función.
intensidad:Set(40, true)  -- El segundo argumento omite la función asociada.
intensidad:Focus()        -- Selecciona el control en el inspector.
print(intensidad:Get())
-- ventana:Close()        -- Cierre animado; se puede repetir de forma segura.
-- ventana:Minimize()     -- Oculta los paneles y muestra la cápsula superior.
-- ventana:Restore()      -- Recupera la misma ventana y sus valores.
-- ventana:IsMinimized()  -- Devuelve el estado lógico de minimización.
-- ventana:Destroy()      -- Limpieza inmediata; se puede repetir.
-- Lumi:Destroy()         -- Cierra todas las ventanas de esta biblioteca.
```

Todos los controles aceptan `Name`, `Description` y `Callback`. Los controles con valor ofrecen `Get()`, `Set(valor, omitirFuncion?)` y `Focus()`. Los botones ofrecen `Press()` y un estado legible mediante `Get()`: «Listo», «1 ejecución», «2 ejecuciones»… Los selectores también ofrecen `Open()` y `Close()`.

Las páginas aceptan `Group = "Principal"`, `"Espacio"` o `"Herramientas"` para organizar la navegación, y `NavigationLabel` para abreviar el acceso sin cambiar el título. Los grupos se crean según se necesitan. Los iconos disponibles incluyen `Grid`, `Sliders`, `Layers`, `User`, `Cube`, `Stack`, `Document`, `Bookmark`, `Help` y `Settings`. Son alias de iconos MingCute Core Regular. Si falta el valor o no se reconoce, se usa la cuadrícula. Los nombres aprovechan el ancho de la navegación y los títulos, el encabezado completo.

## Iconos locales de MingCute

Se incluyen 18 iconos de [MingCute](https://github.com/mingcute-design/mingcute-icons), serie Core Regular, bajo Apache-2.0. `assets/icons/mingcute` contiene los SVG originales, PNG de 96×96 con fondo transparente, licencia, atribución y un manifiesto con la revisión y ruta de cada fuente. Los PNG se incorporan como Base64 al generar ambos scripts, junto con la licencia.

Al ejecutar Lumi en Potassium, el cargador convierte esos bytes en archivos dentro de `lumi-ui/assets` y los registra con `getcustomasset` o `getsynasset`. Cada dibujo se muestra en un único ImageLabel, con suavizado y color aplicado mediante ImageColor3. Los iconos no dependen de Roblox IDs ni de peticiones HTTP al abrir la interfaz. También se usan imágenes para flechas, búsqueda, selección, menú, cerrar y minimizar. La marca L con punto se conserva.

Para añadir otro icono al paquete: guarda el SVG oficial en `assets/icons/mingcute/svg`, registra su alias y procedencia en `manifest.json`, ejecuta `npm ci`, `npm run icons:render` y `npm run build`. Puedes usar el alias resultante con `ventana:AddTab("Página", {Icon = "Alias"})`. No basta con introducir una URL SVG en ImageLabel: este paquete proporciona la conversión a PNG y el registro local. En un ejecutor sin acceso a archivos o registro de imágenes locales, los nombres y controles continúan disponibles, pero estos iconos pueden quedar ocultos.

## Configuraciones y búsqueda

La tarjeta inferior abre Configuraciones. Su porcentaje y barra reflejan la intensidad de la decoración; Ajustes en el grupo Espacio abre la misma página. Sus preferencias actúan sobre la ventana: animaciones, intensidad de la decoración y visibilidad del inspector cuando hay espacio. Restablecer recupera los valores iniciales. Se conservan al cambiar de página y minimizar; pertenecen a la sesión de esa ventana.

```luau
window:OpenSettings()
window:SetPreference("Animations", false)
window:SetPreference("Decoration", 70) -- 0 a 100; multiplica la decoración de fondo.
window:SetPreference("Inspector", true)
window:GoHome()
```

Pulsa la búsqueda o Ctrl+K para localizar páginas y controles por nombre y descripción, con o sin tildes. Elegir un control abre su página, lo desplaza a la vista y lo selecciona sin cambiar su valor. Las flechas recorren resultados; Intro abre el seleccionado y Escape cierra. En teléfono y paneles estrechos la búsqueda usa un botón compacto. La ruta y los botones de ventana conservan su propio espacio.

## Idiomas y atajo de ventana

Configuraciones ofrece solo español y portugués. El catálogo se incluye en el script, conserva el texto fuente y traduce la presentación sin enviar datos. La búsqueda encuentra los nombres traducidos. No es un traductor automático de notas o texto libre. Las preferencias pertenecen a la sesión y a cada ventana.

```luau
local ventana = Lumi:CreateWindow({Title = "Lumi", Language = "es"})
ventana:SetLanguage("pt")
ventana:SetLanguage("es")
print(ventana:GetLanguage())
-- También: ventana:SetPreference("Language", "pt")
```

Mayús derecha minimiza o restaura la última ventana de Lumi; se ignora mientras escribes o si Roblox ya procesó la tecla. Puedes sustituirla con `CreateWindow({ToggleKey = Enum.KeyCode.F8})` o desactivarla con `ToggleKey = false`. En teléfono se conservan los botones de menú y la cápsula superior.

## Campos de texto y herramientas

`AddInput` permite campos de una línea o multilínea, con texto de solo lectura cuando corresponde. El texto largo tiene un área desplazable y el cursor permanece visible al escribir. Los valores pertenecen a la sesión: no se guardan en disco.

```luau
local notas = general:AddInput({Name = "Notas", MultiLine = true, Height = 180,
    Placeholder = "Escribe aquí...", Default = "", MaxLength = 2000,
    Callback = function(texto) print(texto) end})
local registros = general:AddInput({Name = "Actividad", MultiLine = true,
    ReadOnly = true, Default = "Sesión iniciada."})
ventana:ShowSettingsInNavigation("Espacio", "Ajustes")
ventana:OpenProfile()
```

La demostración incluye herramientas de distribución, controles de movimiento, registros locales de navegación, un bloc de notas y ayuda. Registros no recopila datos del juego ni transmite información. Las notas se conservan al navegar, cambiar de idioma y minimizar hasta cerrar o recargar la demostración.

## Perfil y selectores con imágenes

La tarjeta del perfil abre una página con los datos de la cuenta y muestra una flecha. El pie muestra el avatar y el nombre del jugador local, con `@usuario` cuando es distinto del nombre visible y hay espacio. Si la imagen falla, permanecen las iniciales. Se pueden personalizar mediante `CreateWindow({Profile = {DisplayName = "Nombre", Username = "usuario", Avatar = fuente}})`.

`AddDropdown` conserva las listas de cadenas y admite opciones con `Value`, `Label`, `Image` y una `Description` opcional. `AddImageDropdown` es un alias explícito. `Get()` y la función asociada reciben `Value`; `GetLabel()` devuelve la etiqueta de presentación.

```luau
general:AddImageDropdown({Name = "Tipo de cielo", Default = "dia", Values = {
    {Value = "dia", Label = "Despejado", Image = {Path = "mis-imagenes/dia.png"}},
    {Value = "tarde", Label = "Atardecer", Image = {Url = "https://mi-dominio.com/tarde.png"}},
}})
```

Las fuentes admiten URI de Roblox, ID numérico, `{Path = "archivo.png"}`, URL HTTPS o `{Data = "BASE64...", Name = "imagen.png"}`. `Lumi:ResolveImage(fuente)` devuelve una URI o `nil, error`. PNG y JPEG locales, remotos e integrados se registran mediante `getcustomasset` o `getsynasset`, sin publicar imágenes en Roblox. Las descargas y los datos integrados usan una caché propia en `lumi-ui/assets`; las URLs repetidas reutilizan el archivo. Las cargas tardías no reemplazan una selección nueva ni modifican una ventana destruida. Sin soporte del ejecutor o ante un fallo se mantiene un marcador y la selección sigue funcionando.

La demostración incluye tres ilustraciones de cielo originales en base64 y sus PNG en `assets/demo/`. No necesita descargar esas imágenes al ejecutarse. No modifica el cielo del juego.

La referencia [Neverlose](https://github.com/B5RLAS/Neverlose/blob/main/NeverLose.lua) usa IDs de Roblox para iconos y URLs para fuentes. No se ejecuta ni incorpora su código de juego. Sus imágenes PNG de GitHub pueden utilizarse como cualquier URL, por ejemplo del [paquete de iconos indicado](https://github.com/B5RLAS/otizimiconpack/tree/main/UmbrellaMenu/icons), si quien integra la biblioteca decide usarlas. Lumi utiliza ahora iconos de MingCute; la marca L con punto mantiene su dibujo propio.

## Distribución e interacción

- Los campos y botones comparten una altura visual de 32 px y se alinean por el extremo derecho. Los nombres usan 15 px y las descripciones 12 px. El texto largo hace crecer la fila; cuando falta espacio, el campo pasa debajo del texto. Los títulos de página usan 32 px y sus encabezados crecen para mostrar títulos y subtítulos completos.
- Los deslizadores separan la cabecera, la zona de arrastre y los límites. El campo numérico reserva espacio según su rango y sufijo para mantener estable el carril durante el arrastre. Los límites invertidos se normalizan, los valores se ajustan al rango y ambos extremos siguen siendo alcanzables. Si mínimo y máximo coinciden, el valor permanece fijo. `Step` vale 1 si no se especifica.
- Pulsa el valor numérico para escribirlo. Los deslizadores seleccionados también admiten las flechas izquierda y derecha. Las listas largas permiten desplazamiento; las listas vacías conservan `nil`. Los valores no válidos no cambian la selección.
- Los menús se cierran al pulsar fuera, usar Escape, cambiar de página, desplazar el contenido, mover la ventana o perder el foco.
- El lienzo de escritorio alcanza 1100 × 808 y separa navegación, contenido e inspector con huecos de 12 px. La altura se adapta al espacio disponible. Las ventanas que no pueden alojarlo ocultan el inspector. En anchos menores de 700 px o clientes con entrada táctil, la navegación se abre con el botón de menú y el contenido dispone del ancho de la ventana, con un máximo de 768 px de alto. Elegir una página cierra la navegación. Los botones y campos táctiles tienen 44 px de altura, los selectores visuales 56 px por opción y el contenido se desplaza. Los tamaños extremadamente pequeños todavía pueden reducir la escala.

El inspector distingue rangos numéricos, estados, opciones discretas y acciones. Ajusta el tamaño de sus valores según el ancho real del texto. La sombra combina una caída ambiental suave con una sombra de contacto y acompaña las esquinas, el tamaño y las animaciones del panel.

Las transiciones usan una desaceleración breve: apertura de 220 ms, cierre de 160 ms, cambio de página de 140 ms y menús de aparición rápida. Los valores cambian inmediatamente y el arrastre sigue al cursor. `Window:Close()` anima el cierre; `Window:Destroy()` limpia inmediatamente. `CreateWindow({Animations = false})` desactiva la interpolación y los pequeños pulsos de los botones.

Al arrastrar la cabecera, la barra izquierda y el inspector acompañan el movimiento con un retraso de 140 ms, sin rebote y con desplazamiento limitado. Se mantiene una separación mínima de 6 px a ambos lados durante el movimiento y vuelve a los 12 px de reposo. La barra izquierda conserva el efecto en escritorio compacto aunque el inspector esté oculto. En teléfono la navegación permanece estable. La geometría y los cambios de posición por código se ajustan inmediatamente.

El botón de minimizar, junto al cierre, oculta los tres paneles con una transición de 180 ms y deja una cápsula centrada arriba. Pulsa la cápsula para restaurar la misma posición, página, selección y valores. Minimizar cierra los menús y libera el foco de edición y el puntero. El cambio de tamaño, las pulsaciones rápidas, el cierre y la recarga cancelan las transiciones anteriores. `Animations = false` hace inmediatos el seguimiento, la minimización y la restauración.

## Ejecución y limpieza

El estado se actualiza antes de ejecutar la función asociada, que se protege para que sus errores no rompan el control. La destrucción cancela las funciones suspendidas que inició Lumi. El trabajo que una función del usuario inicie por su cuenta sigue siendo responsabilidad de quien lo creó.

Cada carga reemplaza la biblioteca anterior mediante un registro del entorno de ejecución. Las ventanas de una misma biblioteca son independientes. El montaje intenta usar `gethui()`, después `CoreGui` y, por último, un `PlayerGui` existente. La limpieza desconecta las conexiones y cancela las animaciones activas. No se descargan módulos durante la ejecución.

Limitación conocida: si cambias un selector por código mientras su menú está abierto, el valor y el campo se actualizan, pero la marca de selección del menú se renueva al volver a abrirlo.

## Desarrollo

Se requiere Node.js 18 o posterior. La generación de los scripts usa los PNG ya incluidos y no requiere paquetes. Solo para volver a convertir los SVG se necesita `npm ci` y `npm run icons:render`, con resvg-js como dependencia de desarrollo.

```sh
npm run build
npm run check
```

Edita `src/` y genera los archivos; `dist/` contiene resultados generados. Las importaciones usan identificadores literales relativos a `src/`, como `require("controls/Slider")`. El generador resuelve los módulos de forma local y rechaza las dependencias inexistentes o circulares.

```text
src/
  init.luau           API y registro de recarga
  Runtime.luau        montaje, conexiones, animaciones y limpieza
  Theme.luau          colores y tipografías
  Textos.luau         textos de la interfaz en español
  UI.luau             elementos de interfaz e iconos de imagen
  Icons.luau          registro de PNG integrados de MingCute
  Window.luau         ventana, entrada y escalado
  Tab.luau            navegación y páginas
  Section.luau        grupos y filas
  PropertyLayout.luau distribución medida de textos y campos
  ImageSource.luau    resolución, caché y carga cancelable de imágenes
  components/         inspector, perfil, búsqueda, configuraciones y presentación
  controls/           botón, interruptor, deslizador y selector
```

La generación también produce `tests/runtime.bundle.luau`, excluido de Git. Ejecútalo completo en un cliente de Roblox mediante Potassium. Usa instancias y conexiones reales, crea ventanas temporales y las limpia. Las dos advertencias de las funciones que fallan intencionalmente forman parte de la prueba de aislamiento de errores.

La identidad visual y su comprobación se registran en [las notas de v0.4.12](docs/design/studio-v0412-identidad.md). La composición, el perfil, las imágenes y la verificación móvil se registran en [las notas de v0.4.11](docs/design/studio-v0411-perfil-imagenes.md). Los registros históricos de [composición](docs/design/studio-v048-composicion.md), [español](docs/design/studio-v047-espanol.md), [distribución](docs/design/studio-v046-layout.md), [sombra](docs/design/studio-v045-shadow.md) y [movimiento](docs/design/studio-v0410-movimiento.md) documentan las mejoras previas.

Puedes ejecutar `examples/verificar-espanol.luau` después de la demostración para revisar los textos de las páginas, los estados, los menús y los valores predeterminados. La traducción se comprobó en un cliente real mediante Potassium, junto con los controles, el arrastre, el cierre y la reinyección.

`Window.Main` conserva la envolvente transparente que centra y mueve todo el conjunto. `Window.Sidebar`, `Window.Panel` y `Window.Inspector` exponen las tres superficies. En modo teléfono el panel principal recupera el ancho; `ToggleNavigation()` alterna la navegación. El inspector se oculta cuando no hay espacio.
