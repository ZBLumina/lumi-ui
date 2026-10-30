# Lumi UI

Biblioteca modular de interfaces en Luau para Potassium. **La versión v0.4.7 presenta toda la interfaz y su demostración en español**, con superficies de carbón cálido, acentos crema, controles precisos, animaciones sutiles y un inspector contextual. Las acciones de ejemplo modifican la interfaz y sus valores de prueba.

Los textos propios de la biblioteca se concentran en `src/Textos.luau`: navegación, etiquetas, estados, ayudas, tipos de control, listas vacías y confirmaciones. La demostración también traduce todos sus títulos, descripciones y opciones. Se conservan los nombres de producto Lumi UI, Potassium y Luau, junto con los identificadores técnicos de la API. Los textos personalizados que proporciona quien usa la biblioteca se muestran tal como se reciben.

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
-- ventana:Destroy()      -- Limpieza inmediata; se puede repetir.
-- Lumi:Destroy()         -- Cierra todas las ventanas de esta biblioteca.
```

Todos los controles aceptan `Name`, `Description` y `Callback`. Los controles con valor ofrecen `Get()`, `Set(valor, omitirFuncion?)` y `Focus()`. Los botones ofrecen `Press()` y un estado legible mediante `Get()`: «Listo», «1 ejecución», «2 ejecuciones»… Los selectores también ofrecen `Open()` y `Close()`.

Las páginas aceptan opcionalmente `Icon = "Grid"`, `"Sliders"` o `"Layers"`: cuadrícula, ajustes o capas. Son identificadores técnicos de iconos geométricos nativos. Si falta el valor o no se reconoce, se usa la cuadrícula. Los contadores se ocultan en barras laterales estrechas para conservar el espacio de los nombres.

## Distribución e interacción

- Los campos y botones comparten una altura visual de 32 px y se alinean por el extremo derecho. Los nombres usan 14 px y las descripciones 12 px. El texto largo hace crecer la fila; cuando falta espacio, el campo pasa debajo del texto.
- Los deslizadores separan la cabecera, la zona de arrastre y los límites. El campo numérico reserva espacio según su rango y sufijo para mantener estable el carril durante el arrastre. Los límites invertidos se normalizan, los valores se ajustan al rango y ambos extremos siguen siendo alcanzables. Si mínimo y máximo coinciden, el valor permanece fijo. `Step` vale 1 si no se especifica.
- Pulsa el valor numérico para escribirlo. Los deslizadores seleccionados también admiten las flechas izquierda y derecha. Las listas largas permiten desplazamiento; las listas vacías conservan `nil`. Los valores no válidos no cambian la selección.
- Los menús se cierran al pulsar fuera, usar Escape, cambiar de página, desplazar el contenido, mover la ventana o perder el foco.
- El lienzo de escritorio mide 1100 × 688. Las ventanas que no pueden alojarlo adaptan sus dimensiones y ocultan el inspector antes de reducir la escala. El contenido compacto se desplaza. Los tamaños extremadamente pequeños todavía pueden reducir la escala.

El inspector distingue rangos numéricos, estados, opciones discretas y acciones. Ajusta el tamaño de sus valores según el ancho real del texto. La sombra combina una caída ambiental suave con una sombra de contacto y acompaña las esquinas, el tamaño y las animaciones del panel.

Las transiciones usan una desaceleración breve: apertura de 220 ms, cierre de 160 ms, cambio de página de 140 ms y menús de aparición rápida. Los valores cambian inmediatamente y el arrastre sigue al cursor. `Window:Close()` anima el cierre; `Window:Destroy()` limpia inmediatamente. `CreateWindow({Animations = false})` desactiva la interpolación y los pequeños pulsos de los botones.

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
  components/         inspector y sombra
  controls/           botón, interruptor, deslizador y selector
```

La generación también produce `tests/runtime.bundle.luau`, excluido de Git. Ejecútalo completo en un cliente de Roblox mediante Potassium. Usa instancias y conexiones reales, crea ventanas temporales y las limpia. Las dos advertencias de las funciones que fallan intencionalmente forman parte de la prueba de aislamiento de errores.

La verificación de esta traducción se registra en [las notas de español](docs/design/studio-v047-espanol.md). Los registros históricos de [distribución](docs/design/studio-v046-layout.md), [sombra](docs/design/studio-v045-shadow.md) y [movimiento](docs/design/studio-v043-motion.md) documentan las mejoras previas.

Cuando Potassium esté disponible, puedes ejecutar `examples/verificar-espanol.luau` después de la demostración para revisar los textos de las páginas, los estados, los menús y los valores predeterminados. La comprobación de esta versión dentro de Roblox sigue pendiente; los resultados previos de ejecución no equivalen a verificar esta traducción.
