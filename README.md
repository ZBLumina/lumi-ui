# Lumi UI

Biblioteca modular de interfaces en Luau para Potassium. **v0.4.16 integra las ilustraciones como fondos suaves y añade seguimiento al arrastrar tanto la barra izquierda como el inspector.** Los títulos usan Fredoka SemiBold; el texto, Nunito Sans Regular/Medium; los rótulos pequeños espaciados, Montserrat Medium; la marca, Comfortaa SemiBold. Conserva la composición de tres paneles, la cabecera amplia, el perfil, los selectores con miniaturas, la cápsula superior y la adaptación táctil. Toda la interfaz y la demostración están en español. Las acciones de ejemplo modifican la interfaz y sus valores de prueba.

Las cinco variantes TTF y sus licencias OFL están en `assets/fonts`. El generador incorpora sus bytes en el script: no se descargan fuentes al abrirlo. Potassium las registra en su carpeta local `lumi-ui/fonts`; otros entornos sin registro de archivos usan fuentes nativas de respaldo. El ajuste de textos utiliza la FontFace real.

Las ilustraciones decorativas son PNG en `assets/decor`, con sus prompts de generación. `src/Artwork.luau` centraliza la cabecera transparente y los fondos de navegación, panel principal e inspector: `Header`, `Sidebar`, `Panel` e `Inspector`. Se descargan de una revisión fija del repositorio y se guardan en `lumi-ui/assets`. Usan el mismo cargador cancelable que las miniaturas, con reutilización de cada registro de archivo. Las imágenes no capturan entrada; si fallan permanece la superficie café. La cabecera reserva una zona transparente para el texto y se amplía si la descripción lo requiere. La ilustración se oculta en teléfono y en paneles estrechos. Las imágenes de referencia del usuario no forman parte del paquete.

Los textos propios de la biblioteca se concentran en `src/Textos.luau`: navegación, etiquetas, estados, ayudas, tipos de control, listas vacías y confirmaciones. La demostración también traduce todos sus títulos, descripciones y opciones. Se conservan los nombres de producto Lumi UI, Potassium y Luau, junto con los identificadores técnicos de la API. Los textos personalizados que proporciona quien usa la biblioteca se muestran tal como se reciben.

Los fondos y el seguimiento lateral se registran en [las notas de v0.4.16](docs/design/studio-v0416-fondos-seguimiento.md). La cabecera completa y su comprobación se registran en [las notas de v0.4.15](docs/design/studio-v0415-cabecera.md). La corrección de claridad y marca se registra en [las notas de v0.4.14](docs/design/studio-v0414-claridad.md). La decoración botánica y su comprobación se registran en [las notas de v0.4.13](docs/design/studio-v0413-imagenes.md).

## Probar la versión actual en Potassium

Esta versión se desarrolla en la rama del PR. Para probarla:

```luau
loadstring(game:HttpGet("https://raw.githubusercontent.com/ZBLumina/lumi-ui/feat/lumi-studio-v04/dist/LumiUI.pilot.luau"))()
```

La dirección que usa `main`, conservada en `examples/potassium-loader.luau`, sigue la versión publicada de esa rama. También puedes ejecutar el archivo completo `dist/LumiUI.pilot.luau` mediante Potassium.

## Usar la biblioteca

`dist/LumiUI.luau` devuelve la biblioteca sin crear la demostración. `dist/LumiUI.pilot.luau` incluye las páginas Inicio, Jugador y Aspecto.

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

Las páginas aceptan opcionalmente `Icon = "Grid"`, `"Sliders"` o `"Layers"`: cuadrícula, ajustes o capas. Son identificadores técnicos de iconos geométricos nativos. Si falta el valor o no se reconoce, se usa la cuadrícula. Los nombres aprovechan el ancho de la navegación y los títulos, el encabezado completo.

## Perfil y selectores con imágenes

El pie muestra el avatar y el nombre del jugador local, con `@usuario` cuando es distinto del nombre visible y hay espacio. Si la imagen falla, permanecen las iniciales. Se pueden personalizar mediante `CreateWindow({Profile = {DisplayName = "Nombre", Username = "usuario", Avatar = fuente}})`.

`AddDropdown` conserva las listas de cadenas y admite opciones con `Value`, `Label`, `Image` y una `Description` opcional. `AddImageDropdown` es un alias explícito. `Get()` y la función asociada reciben `Value`; `GetLabel()` devuelve la etiqueta de presentación.

```luau
general:AddImageDropdown({Name = "Tipo de cielo", Default = "dia", Values = {
    {Value = "dia", Label = "Despejado", Image = {Path = "mis-imagenes/dia.png"}},
    {Value = "tarde", Label = "Atardecer", Image = {Url = "https://mi-dominio.com/tarde.png"}},
}})
```

Las fuentes admiten URI de Roblox, ID numérico, `{Path = "archivo.png"}`, URL HTTPS o `{Data = "BASE64...", Name = "imagen.png"}`. `Lumi:ResolveImage(fuente)` devuelve una URI o `nil, error`. PNG y JPEG locales, remotos e integrados se registran mediante `getcustomasset` o `getsynasset`, sin publicar imágenes en Roblox. Las descargas y los datos integrados usan una caché propia en `lumi-ui/assets`; las URLs repetidas reutilizan el archivo. Las cargas tardías no reemplazan una selección nueva ni modifican una ventana destruida. Sin soporte del ejecutor o ante un fallo se mantiene un marcador y la selección sigue funcionando.

La demostración incluye tres ilustraciones de cielo originales en base64 y sus PNG en `assets/demo/`. No necesita descargar esas imágenes al ejecutarse. No modifica el cielo del juego.

La referencia [Neverlose](https://github.com/B5RLAS/Neverlose/blob/main/NeverLose.lua) usa IDs de Roblox para iconos y URLs para fuentes. No se ejecuta ni incorpora su código de juego. Sus imágenes PNG de GitHub pueden utilizarse como cualquier URL, por ejemplo del [paquete de iconos indicado](https://github.com/B5RLAS/otizimiconpack/tree/main/UmbrellaMenu/icons), si quien integra la biblioteca decide usarlas. Lumi conserva sus iconos geométricos propios.

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

Se requiere Node.js 18 o posterior. No hay dependencias de npm.

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
  UI.luau             elementos gráficos nativos
  Window.luau         ventana, entrada y escalado
  Tab.luau            navegación y páginas
  Section.luau        grupos y filas
  PropertyLayout.luau distribución medida de textos y campos
  ImageSource.luau    resolución, caché y carga cancelable de imágenes
  components/         inspector, perfil, miniaturas, sombra y presentación
  controls/           botón, interruptor, deslizador y selector
```

La generación también produce `tests/runtime.bundle.luau`, excluido de Git. Ejecútalo completo en un cliente de Roblox mediante Potassium. Usa instancias y conexiones reales, crea ventanas temporales y las limpia. Las dos advertencias de las funciones que fallan intencionalmente forman parte de la prueba de aislamiento de errores.

La identidad visual y su comprobación se registran en [las notas de v0.4.12](docs/design/studio-v0412-identidad.md). La composición, el perfil, las imágenes y la verificación móvil se registran en [las notas de v0.4.11](docs/design/studio-v0411-perfil-imagenes.md). Los registros históricos de [composición](docs/design/studio-v048-composicion.md), [español](docs/design/studio-v047-espanol.md), [distribución](docs/design/studio-v046-layout.md), [sombra](docs/design/studio-v045-shadow.md) y [movimiento](docs/design/studio-v0410-movimiento.md) documentan las mejoras previas.

Puedes ejecutar `examples/verificar-espanol.luau` después de la demostración para revisar los textos de las páginas, los estados, los menús y los valores predeterminados. La traducción se comprobó en un cliente real mediante Potassium, junto con los controles, el arrastre, el cierre y la reinyección.

`Window.Main` conserva la envolvente transparente que centra y mueve todo el conjunto. `Window.Sidebar`, `Window.Panel` y `Window.Inspector` exponen las tres superficies. En modo teléfono el panel principal recupera el ancho; `ToggleNavigation()` alterna la navegación. El inspector se oculta cuando no hay espacio.
