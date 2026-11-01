local UI = require("UI")
local T = require("Theme")
local Textos = require("Textos")
local Typography = require("Typography")
local Settings = {}
Settings.__index = Settings

function Settings.new(window)
    local self = setmetatable({Window = window, Controls = {}}, Settings)
    self.Defaults = {Animations = window.Runtime.Animations, Inspector = true, Decoration = 100, Language = window.Language,TextScale=window.TextScale or 1}
    window.Preferences = table.clone(self.Defaults)
    window.Runtime.Decoration = 1
    local button = UI.button(window.Sidebar, "SettingsShortcut", "", 12, 0, 204, 56)
    button.BackgroundColor3, button.BackgroundTransparency = T.Raised, .25
    UI.corner(button, 9)
    self.Border = UI.stroke(button, T.SoftLine)
    self.Tile = UI.frame(button, "Tile", 10, 13, 30, 30, T.AccentWash, 7)
    UI.stroke(self.Tile, T.AccentSoft).Transparency = .55
    self.Icon = UI.icon(self.Tile, "Stack", 7, 7, T.Accent)
    self.Label = UI.text(button, "Label", Textos.configuraciones, 50, 9, 104, 19, 12, T.Text, T.Medium)
    self.Hint = UI.text(button, "Hint", Textos.personaliza, 50, 28, 98, 15, 10, T.Muted)
    self.Hint.Visible = false
    self.Value = UI.text(button, "Value", "100%", 157, 10, 36, 18, 11, T.Secondary, T.Mono)
    self.Value.TextXAlignment = Enum.TextXAlignment.Right
    self.Track = UI.frame(button, "Meter", 50, 36, 142, 4, T.SoftLine, 2)
    self.Fill = UI.frame(self.Track, "Fill", 0, 0, 0, 4, T.Accent, 2)
    self.Fill.Size = UDim2.fromScale(1, 1)
    self.Button, window.SettingsButton = button, button
    UI.hover(window.Runtime, button, T.Raised, T.Hover)
    window.Runtime:Connect(button.Activated, function() self:Open() end)
    return self
end

function Settings:Fit(width, short)
    local button = self.Button
    local height = short and 52 or 56
    local cardWidth = width - 24
    local factor=self.Window.TextScale or 1
    button.Position = UDim2.new(0, 12, 1, -(height + 12))
    button.Size = UDim2.fromOffset(cardWidth, height)
    self.Tile.Position = UDim2.fromOffset(10, (height - 30) / 2)
    self.Label.Position = UDim2.fromOffset(50, 9)
    self.Label.Size = UDim2.fromOffset(cardWidth - 100, math.ceil(19*factor))
    self.Hint.Visible = false
    self.Value.Position = UDim2.fromOffset(cardWidth - 47, 10)
    self.Value.Size=UDim2.fromOffset(36,math.ceil(18*factor))
    self.Track.Position = UDim2.fromOffset(50, short and 34 or 36)
    self.Track.Size = UDim2.fromOffset(cardWidth - 62, 4)
    self.Window.Profile:Fit(cardWidth, short, height + 20)
    return height + 20 + self.Window.Profile.Frame.Size.Y.Offset + 8
end

function Settings:UpdateMeter()
    local value = self.Window.Preferences.Decoration
    self.Value.Text = tostring(math.floor(value + .5)) .. "%"
    self.Fill.Size = UDim2.fromScale(value / 100, 1)
end

function Settings:SyncSelection(tab)
    local active = self.Tab ~= nil and tab == self.Tab
    self.Button.BackgroundColor3 = active and T.AccentWash or T.Raised
    self.Border.Color = active and T.AccentSoft or T.SoftLine
end

function Settings:Set(name, value)
    local w = self.Window
    if w._destroyed or w._closing or self.Defaults[name] == nil then return false end
    if name == "Language" then return w:SetLanguage(value) end
    if name == "Decoration" then value = math.clamp(UI.number(value, 100), 0, 100)
    elseif name=="TextScale" then value=math.clamp(UI.number(value,1),1,1.3)
    else value = value == true end
    if w.Preferences[name] == value then return false end
    w:FinishEntrance(); w:FinishPages()
    w.Presentation:FinishTransition()
    w.Preferences[name] = value
    if name == "Animations" then
        w.Runtime.Animations = value
        for _,c in pairs(w.ControlsById) do c.Runtime.Animations=value end
        w.Presentation:StopFollow()
    elseif name == "Inspector" then
        w._lastViewport = nil
        w:Fit()
    elseif name == "Decoration" then
        w.Runtime.Decoration = value / 100
        for _, image in ipairs(w.Root:GetDescendants()) do
            if image:IsA("ImageLabel") then
                local opacity = image:GetAttribute("LumiArtworkOpacity")
                if opacity then image.ImageTransparency = 1 - opacity * w.Runtime.Decoration end
            end
        end
    elseif name=="TextScale" then
        w.TextScale=value
        Typography.apply(w.Root,value)
        w._lastViewport=nil;w:Fit()
    end
    if self.Controls[name] then self.Controls[name]:Set(name=="TextScale" and value*100 or value, true) end
    self:UpdateMeter()
    if w.Profiles and not w._applyingState then w.Profiles:Changed() end
    return true
end

function Settings:Reset()
    for _, name in ipairs({"Animations", "Inspector", "Decoration", "Language","TextScale"}) do self:Set(name, self.Defaults[name]) end
end

function Settings:RefreshProfiles()
    if not self.ProfileGroup or self.Window._destroyed then return end
    local w = self.Window
    local names, problem = w:ListProfiles()
    local active = w:GetActiveProfile()
    local old = self.ProfileSelect and self.ProfileSelect:Get()
    local selection = table.find(names, active) and active or (table.find(names, old) and old or names[1])
    -- A selector owns its popup and connections. Replacing it releases those
    -- resources while retaining the public identifier and keyboard position.
    if self.ProfileSelect then self.ProfileSelect:Destroy() end
    self.ProfileSelect = self.ProfileGroup:AddDropdown({Id="lumi.profile-select",Persist=false,
        Name="Perfil guardado",Description="Elige los valores que quieres recuperar.",Values=names,Default=selection,TranslateValues=false,
        Callback=function(value)self.ProfileName:Set(value,true)end})
    self.ProfileSelect.Row.LayoutOrder=2
    local enabled = w.Profiles and w.Profiles.Enabled == true
    self.ProfileSave:SetEnabled(enabled)
    self.ProfileLoad:SetEnabled(enabled and #names>0 and not problem)
    self.ProfileSelect:SetEnabled(enabled and #names>0 and not problem)
    self.ProfileStatus:Set(not enabled and "El guardado no está disponible en esta sesión."
        or (problem and "No se pudo leer el archivo de perfiles."
        or (#names==0 and "Aún no hay perfiles guardados." or "Tus perfiles están disponibles en este equipo.")),true)
end

function Settings:ProfileAction(action)
    local w=self.Window
    local saving=action=="save"
    local name=saving and self.ProfileName:Get():match("^%s*(.-)%s*$") or self.ProfileSelect:Get()
    local toast=w:Notify({Title=saving and "Guardando perfil" or "Cargando perfil",Kind="Loading",Duration=0})
    local ok = saving and w:SaveProfile(name) or false
    if not saving then ok=w:LoadProfile(name) end
    local action=false
    if not ok then action={Text="Reintentar",Callback=function()self:ProfileAction(saving and "save" or "load")end} end
    toast:Update({Title=ok and (saving and "Perfil guardado" or "Perfil cargado")
        or (saving and "No se pudo guardar" or "No se pudo cargar"),
        Message=ok and "Tus preferencias están listas." or "Revisa el almacenamiento e inténtalo de nuevo.",
        Kind=ok and "Success" or "Error",Duration=ok and 3 or 7,
        Action=action})
    self:RefreshProfiles()
end

function Settings:Ensure()
    local w = self.Window
    if w._destroyed or w._closing then return nil end
    if not self.Tab then
        local tab = w:AddTab(Textos.configuraciones, {Id="lumi.settings",Icon = "Settings",
            Description = "Personaliza tu espacio de Lumi.", Eyebrow = "LUMI / TU ESPACIO"})
        self.Tab = tab
        tab.Button.Visible = false
        local group = tab:AddSection("Interfaz", {Tag = "A TU MEDIDA"})
        self.Controls.Language = group:AddDropdown({Id="lumi.language",Persist=false,Name = "Idioma", Description = "Elige el idioma de la interfaz.",
            Values = {{Value = "es", Label = "Español"}, {Value = "pt", Label = "Português"}}, Default = w.Language,
            Callback = function(value) w:SetLanguage(value) end})
        self.Controls.TextScale=group:AddSlider({Id="lumi.text-scale",Persist=false,Name="Tamaño del texto",Description="Amplía las letras y conserva el espacio de los controles.",
            Min=100,Max=130,Step=5,Suffix="%",Default=w.Preferences.TextScale*100,Callback=function(value)self:Set("TextScale",value/100)end})
        self.Controls.Animations = group:AddToggle({Id="lumi.animations",Persist=false,Name = "Animaciones",
            Description = "Aperturas, transiciones y seguimiento suave.", Default = w.Preferences.Animations,
            Callback = function(value) self:Set("Animations", value) end})
        self.Controls.Decoration = group:AddSlider({Id="lumi.decoration",Persist=false,Name = "Intensidad de la decoración",
            Description = "Mantén las imágenes como un fondo sutil.", Min = 0, Max = 100,
            Default = w.Preferences.Decoration, Suffix = "%",
            Callback = function(value) self:Set("Decoration", value) end})
        self.Controls.Inspector = group:AddToggle({Id="lumi.inspector",Persist=false,Name = "Mostrar inspector",
            Description = "Presenta los detalles del control seleccionado.", Default = w.Preferences.Inspector,
            Callback = function(value) self:Set("Inspector", value) end})
        self.ProfileGroup=tab:AddSection("Perfiles",{Id="profiles",Tag="GUARDADO LOCAL"})
        self.ProfileName=self.ProfileGroup:AddInput({Id="lumi.profile-name",Persist=false,Name="Nombre del perfil",
            Description="Guarda varios espacios con tus propios nombres.",Default=w:GetActiveProfile() or "Predeterminado",MaxLength=128})
        self.ProfileSave=self.ProfileGroup:AddButton({Id="lumi.profile-save",Name="Guardar perfil",Action="Guardar",
            Description="Conserva valores, idioma, posición y apariencia.",Callback=function()self:ProfileAction("save")end})
        self.ProfileSave.Row.LayoutOrder=3
        self.ProfileLoad=self.ProfileGroup:AddButton({Id="lumi.profile-load",Name="Cargar perfil",Action="Cargar",Variant="Secondary",
            Description="Recupera el perfil seleccionado.",Callback=function()self:ProfileAction("load")end})
        self.ProfileLoad.Row.LayoutOrder=4
        self.ProfileStatus=self.ProfileGroup:AddInput({Id="lumi.profile-status",Name="Almacenamiento",ReadOnly=true,Translate=true,MultiLine=true,Height=80})
        self.ProfileStatus.Row.LayoutOrder=5
        self:RefreshProfiles()
        tab:AddSection("Preferencias", {Tag = "ESTA VENTANA"}):AddButton({Id="lumi.reset-appearance",Name = "Restablecer apariencia",
            Description = "Recupera los ajustes iniciales de esta ventana.", Action = "Restablecer", Variant = "Secondary",
            Callback = function() self:Reset() end})
        tab:AddSection("Ayuda y atajos", {Tag = "ACCESIBILIDAD"}):AddInput({Name = "Atajo de ventana",
            Description = "Minimiza o restaura sin interrumpir la escritura.", ReadOnly = true, Translate = true,
            Default = w.ToggleKey == Enum.KeyCode.RightShift and "Mayús derecha" or (w.ToggleKey and w.ToggleKey.Name or "Desactivado")})
        tab.Sections[#tab.Sections]:AddInput({Name="Navegación con teclado",ReadOnly=true,Translate=true,MultiLine=true,Height=90,
            Default="Tab y Mayús+Tab cambian el foco. Intro o Espacio activan. Las flechas ajustan los deslizadores."})
    end
    return self.Tab
end

function Settings:ShowNavigation(group, label)
    local tab = self:Ensure()
    self:RefreshProfiles()
    if not tab then return nil end
    tab:SetNavigation(group or "Espacio", label or "Ajustes")
    tab.Button.Visible = true
    return tab
end

function Settings:Open()
    local w = self.Window
    if w._destroyed or w._closing or w.Minimized then return nil end
    local tab = self:Ensure()
    w:SelectTab(tab)
    self:RefreshProfiles()
    self:SyncSelection(tab)
    return tab
end

return Settings
