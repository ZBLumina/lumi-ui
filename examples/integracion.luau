-- Ejemplo completo y mínimo de integración. Cambia la clave para tu proyecto.
local Lumi=loadstring(game:HttpGet("https://raw.githubusercontent.com/ZBLumina/lumi-ui/feat/lumi-studio-v04/dist/LumiUI.luau"))()
local ventana=Lumi:CreateWindow({Title="Lumi",Config={Key="mi-proyecto",AutoLoad=true,AutoSave=true}})
local inicio=ventana:AddTab("Inicio",{Id="inicio"})
local general=inicio:AddSection("General",{Id="general"})
local intensidad=general:AddSlider({Id="general.intensidad",Name="Intensidad",Min=0,Max=100,Default=65,Suffix="%",
    Callback=function(valor)print("[Mi proyecto] intensidad",valor)end})
general:AddButton({Id="general.probar",Name="Acción de prueba",Action="Probar",Callback=function()
    intensidad:Update({Value=80,Description="Ajusta la intensidad de la vista previa."})
    ventana:Notify({Title="Vista previa lista",Kind="Success",Duration=4,
        Action={Text="Ver ajustes",Callback=function()ventana:OpenSettings()end}})
end})
ventana:ShowSettingsInNavigation("Espacio","Ajustes")
local ok,problema=ventana:Ready()
if not ok then
    warn(problema)
    ventana:Notify({Title="No se pudo cargar",Message="Revisa el almacenamiento e inténtalo de nuevo.",Kind="Error"})
end
-- ventana:GetControl("general.intensidad"):SetEnabled(false)
-- ventana:GetControl("general.intensidad"):Destroy()
return ventana
