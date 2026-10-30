-- Demostración: las acciones modifican esta interfaz y sus valores de ejemplo.
local window = Lumi:CreateWindow({Title = "lumi"})
local overview = window:AddTab("Inicio", {Icon = "Grid", Description = "Ajustes claros, con todo a mano.", Eyebrow = "ESTUDIO / INTRODUCCIÓN"})
local player = window:AddTab("Jugador", {Icon = "Sliders", Description = "Prueba controles de estado y valores numéricos."})
local visuals = window:AddTab("Aspecto", {Icon = "Layers", Description = "Prueba los ajustes visuales de la interfaz."})

local interaction = overview:AddSection("Interacción", {Tag = "VISTA PREVIA"})
local enabled = interaction:AddToggle({Name = "Activar espacio", Description = "Conserva activa esta sesión.", Default = true,
    Callback = function(value) print("[Lumi] espacio " .. (value and "activado" or "desactivado")) end})
local intensity = interaction:AddSlider({Name = "Intensidad", Description = "Ajusta la intensidad de la vista previa.", Min = 0, Max = 100, Default = 65, Suffix = "%",
    Callback = function(value) print("[Lumi] intensidad", value) end})
local mode = interaction:AddDropdown({Name = "Modo de interacción", Description = "Elige cómo prefieres trabajar.", Values = {"Equilibrado", "Suave", "Preciso"}, Default = "Equilibrado",
    Callback = function(value) print("[Lumi] modo", value) end})
local tools = overview:AddSection("Sesión", {Tag = "SESIÓN LOCAL"})
tools:AddButton({Name = "Acción de prueba", Description = "Ejecuta una acción de demostración.", Action = "Probar",
    Callback = function() print("[Lumi] acción de prueba completada") end})
tools:AddButton({Name = "Restablecer valores", Description = "Recupera los tres valores iniciales.", Action = "Restablecer", Variant = "Secondary",
    Callback = function() enabled:Set(true, true); intensity:Set(65, true); mode:Set("Equilibrado", true); intensity:Focus() end})

local values = player:AddSection("Controles de entrada", {Tag = "PRUEBAS"})
values:AddToggle({Name = "Entrada activa", Description = "Un estado de ejemplo para probar el interruptor.", Default = false})
values:AddSlider({Name = "Respuesta", Description = "Ajusta este valor numérico.", Min = 1, Max = 10, Default = 4})
values:AddDropdown({Name = "Perfil", Description = "Una lista con una sola opción.", Values = {"Vista local"}})
local safety = player:AddSection("Límites", {Tag = "VALOR FIJO"})
safety:AddSlider({Name = "Rango fijo", Description = "Los límites iguales conservan un único valor.", Min = 10, Max = 10, Default = 100})
safety:AddButton({Name = "Probar entrada", Description = "Ejecuta una acción de ejemplo.", Action = "Probar", Variant = "Secondary"})

local presentation = visuals:AddSection("Presentación", {Tag = "INTERFAZ"})
presentation:AddToggle({Name = "Capa de prueba", Description = "Cambia este estado para ver su aspecto.", Default = false})
presentation:AddDropdown({Name = "Estilo", Description = "Compara las opciones disponibles.", Values = {"Lumi", "Mínimo", "Compacto"}})
presentation:AddSlider({Name = "Detalle", Description = "Arrastra o escribe un valor exacto.", Min = 0, Max = 1, Step = 0.05, Default = 0.7})
local lists = visuals:AddSection("Opciones", {Tag = "MENÚS"})
lists:AddDropdown({Name = "Lista vacía", Description = "Una colección sin opciones.", Values = {}})
lists:AddDropdown({Name = "Material", Description = "Una lista de opciones con desplazamiento.", Values = {"Lino", "Arena", "Pergamino", "Arcilla", "Topo", "Nogal", "Carbón", "Grafito", "Ceniza", "Crema", "Marfil", "Avena"}})

intensity:Focus()
print("[Lumi UI] Demostración en español v" .. Lumi.Version .. " cargada")
return Lumi
