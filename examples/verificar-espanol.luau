-- Comprobación opcional para Potassium. Ejecuta primero LumiUI.pilot.luau.
local entorno = type(getgenv) == "function" and getgenv() or _G
local Lumi = entorno.__LumiUI
assert(Lumi and Lumi.Version == "0.4.16", "[Lumi] Carga primero la demostración v0.4.16")
local ventana = Lumi._windows[1]
assert(ventana and not ventana._destroyed, "[Lumi] La ventana de demostración debe estar abierta")

local expresiones = {"workspace", "overview", "visuals", "player", "properties", "controls", "ready", "enabled", "disabled",
    "completed", "run action", "no options", "no selection", "select option", "session action", "binary state", "fixed",
    "on demand", "single selection", "empty collection", "interface library", "ui library", "pilot", "studio"}
local revisiones = 0
local function revisar(raiz)
    for _, objeto in ipairs(raiz:GetDescendants()) do
        if objeto:IsA("TextLabel") or objeto:IsA("TextButton") or objeto:IsA("TextBox") then
            local texto = string.lower(objeto.Text)
            for _, expresion in ipairs(expresiones) do
                assert(not texto:find("%f[%a]" .. expresion .. "%f[%A]"), "[Lumi] Texto pendiente de traducir: " .. objeto.Text)
            end
            assert(objeto.Text ~= "ON" and objeto.Text ~= "OFF", "[Lumi] Indicador pendiente de traducir")
            revisiones += 1
        end
    end
end

for _, pagina in ipairs(ventana.Tabs) do
    ventana:SelectTab(pagina)
    for _, control in ipairs(pagina.Controls) do
        control:Focus()
        if control.Kind == "Toggle" then
            local original = control:Get()
            control:Set(not original, true)
            revisar(ventana.Root)
            control:Set(original, true)
        elseif control.Kind == "Dropdown" then
            control:Open()
            revisar(ventana.Root)
            control:Close()
        end
        revisar(ventana.Root)
    end
end

local temporal = Lumi:CreateWindow({Animations = false})
local correcto, problema = xpcall(function()
    local grupo = temporal:AddTab("Prueba"):AddSection("General")
    local boton = grupo:AddButton({})
    grupo:AddToggle({})
    grupo:AddSlider({})
    grupo:AddDropdown({})
    revisar(temporal.Root)
    assert(boton:Get() == "Listo", "[Lumi] Estado inicial del botón sin traducir")
    boton:Press()
    assert(boton:Get() == "1 ejecución", "[Lumi] Contador singular incorrecto")
    revisar(temporal.Root)
    boton:Press()
    assert(boton:Get() == "2 ejecuciones", "[Lumi] Contador plural incorrecto")
    revisar(temporal.Root)
    task.wait(0.8)
    assert(boton.Input.Text == "Ejecutar", "[Lumi] El texto de reserva del botón no está traducido")
end, debug.traceback)
temporal:Destroy()
ventana:SelectTab(ventana.Tabs[1])
ventana.Tabs[1].Controls[2]:Focus()
if not correcto then error(problema) end
print("[Lumi] Comprobación de español terminada: " .. revisiones .. " textos revisados")
