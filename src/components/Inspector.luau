local UI = require("UI")
local T = require("Theme")
local Motion = require("Motion")
local Shadow = require("components/Shadow")
local Fonts = require("Fonts")
local BrandArt = require("components/BrandArt")
local Textos = require("Textos")
local Inspector = {}
Inspector.__index = Inspector

function Inspector.new(window)
    local self = setmetatable({Window = window, Bars = {}, BarState = {}}, Inspector)
    local frame = UI.frame(window.Main, "Inspector", 876, 0, 224, 688, T.Sidebar, 14)
    frame.Active = true
    window.Inspector = frame
    self.Shadow = Shadow.new(frame, 14)
    UI.stroke(frame, T.Line)
    BrandArt.footer(window.Runtime, frame)
    UI.micro(frame, "InspectorHeading", "INSPECTOR", 18, 20, 188, 16)
    UI.line(frame, 18, 47, 188)
    window.DetailTitle = UI.text(frame, "DetailTitle", Textos.tuEspacio, 18, 67, 188, 52, 21, T.Text, T.Title)
    window.DetailTitle.TextWrapped = true
    window.DetailTitle.TextYAlignment = Enum.TextYAlignment.Top
    window.DetailTitle.TextTruncate = Enum.TextTruncate.None
    window.DetailDescription = UI.text(frame, "Description", Textos.descripcionInspector, 18, 126, 188, 44, 12, T.Secondary)
    window.DetailDescription.TextWrapped = true
    window.DetailDescription.TextTruncate = Enum.TextTruncate.None
    window.DetailDescription.TextYAlignment = Enum.TextYAlignment.Top

    local preview = UI.frame(frame, "ValuePreview", 18, 190, 188, 176, T.Surface, 10)
    preview.BackgroundTransparency = 0.10
    UI.stroke(preview, T.SoftLine)
    window.DetailKind = UI.text(preview, "Kind", Textos.seleccion, 14, 14, 160, 16, 11, T.Muted, T.Medium)
    window.DetailValue = UI.text(preview, "Value", Textos.listo, 14, 40, 160, 40, 32, T.Accent, T.Title)
    self.Meta = UI.text(preview, "ValueContext", Textos.espacioMayus, 14, 152, 160, 15, 11, T.Muted, T.Mono)

    self.Numeric = UI.frame(preview, "NumericRange", 14, 96, 160, 37)
    for i = 1, 29 do
        local height = (i - 1) % 7 == 0 and 23 or 14
        self.Bars[i] = UI.frame(self.Numeric, "Tick", (i - 1) * 159 / 28, 29 - height, 1, height, T.Line)
    end
    self.Marker = UI.frame(self.Numeric, "Position", 0, 1, 2, 32, T.Accent, 1)
    self.Marker.AnchorPoint = Vector2.new(0.5, 0)
    self.Low = UI.text(preview, "LowerBound", "", 14, 152, 80, 15, 11, T.Muted, T.Mono)
    self.High = UI.text(preview, "UpperBound", "", 94, 152, 80, 15, 11, T.Muted, T.Mono)
    self.High.TextXAlignment = Enum.TextXAlignment.Right

    self.Boolean = UI.frame(preview, "BooleanState", 14, 104, 160, 26)
    self.States = {}
    for index, name in ipairs({"OFF", "ON"}) do
        local tile = UI.frame(self.Boolean, name, (index - 1) * 84, 0, 76, 26, T.Surface, 4)
        local border = UI.stroke(tile, T.SoftLine)
        local label = UI.text(tile, "Label", index == 2 and Textos.si or Textos.no, 0, 0, 76, 26, 11, T.Muted, T.Mono)
        label.TextXAlignment = Enum.TextXAlignment.Center
        self.States[index] = {Tile = tile, Border = border, Label = label}
    end

    self.Options = UI.frame(preview, "DiscreteOptions", 14, 112, 160, 8)
    self.OptionMarks = {}
    for i = 1, 12 do self.OptionMarks[i] = UI.frame(self.Options, "Option" .. i, 0, 0, 1, 4, T.Line, 1) end
    self.ChoiceHint = UI.text(preview, "ChoiceHint", "", 14, 103, 160, 26, 11, T.Secondary, T.Mono)
    self.Action = UI.frame(preview, "ActionGlyph", 14, 104, 160, 26)
    UI.text(self.Action, "Label", Textos.ejecucion, 0, 0, 116, 26, 11, T.Secondary, T.Mono)
    UI.frame(self.Action, "Stem", 124, 13, 18, 1, T.AccentSoft)
    UI.frame(self.Action, "Upper", 136, 10, 7, 1, T.AccentSoft).Rotation = 45
    UI.frame(self.Action, "Lower", 136, 16, 7, 1, T.AccentSoft).Rotation = -45

    UI.micro(frame, "Properties", Textos.propiedades, 18, 390, 188, 16)
    window.DetailRows = {}
    for i, name in ipairs({"Page", "Section", "Type", "Range"}) do
        local y = 417 + (i - 1) * 34
        UI.text(frame, name .. "Key", Textos.claves[i], 18, y, 50, 24, 12, T.Muted)
        window.DetailRows[i] = UI.text(frame, name .. "Value", "--", 74, y, 132, 24, 12, T.Secondary)
        window.DetailRows[i].TextXAlignment = Enum.TextXAlignment.Right
        UI.line(frame, 18, y + 29, 188)
    end
    self.Hint = UI.text(frame, "Hint", Textos.pistaInicial, 18, 0, 188, 32, 12, T.Secondary)
    self.Hint.Position = UDim2.new(0, 18, 1, -56)
    self.Hint.TextWrapped = true
    self.Hint.TextTruncate = Enum.TextTruncate.None
    window.Bars = self.Bars
    self:Clear()
    return self
end

function Inspector:Clear()
    self.Control = nil
    self.Numeric.Visible, self.Boolean.Visible, self.Options.Visible = false, false, false
    self.ChoiceHint.Visible, self.Action.Visible = false, false
    self.Low.Visible, self.High.Visible, self.Meta.Visible = false, false, true
    self.Meta.Text = Textos.espacioMayus
    self.Window.DetailKind.Text = Textos.seleccion
    for _, label in ipairs(self.Window.DetailRows) do label.Text = "--" end
    self.Hint.Text = Textos.pistaInicial
end

function Inspector:SetValue(text)
    local label = self.Window.DetailValue
    label.Text = tostring(text)
    local size = 32
    while size > 15 do
        local bounds = Fonts.bounds(label.Text, size, label.FontFace)
        if bounds.X <= label.Size.X.Offset - 2 then break end
        size -= 1
    end
    label.TextSize = size
end

function Inspector:Update(control)
    local window, rt = self.Window, self.Window.Runtime
    local same = self.Control == control
    self.Control = control
    local value
    if control.Get then value = control:Get() end
    local shown = value == nil and Textos.sinSeleccion or tostring(value)
    if type(value) == "boolean" then shown = value and Textos.activado or Textos.desactivado end
    if type(value) == "number" then shown = (control.Format and control:Format(value) or UI.format(value)) .. (control.Suffix or "") end
    if control.GetLabel and value ~= nil then shown = control:GetLabel() end
    if control.Kind == "Input" then
        local count = 0
        for _ in utf8.graphemes(tostring(value or "")) do count += 1 end
        shown = Textos.cantidadCaracteres(count)
    end
    window.DetailTitle.Text, window.DetailDescription.Text = control.Name, control.Description or ""
    window.DetailKind.Text = Textos.etiquetaTipo(control.Kind)
    self:SetValue(shown)
    window.DetailRows[1].Text, window.DetailRows[2].Text = control.Section.Tab.Name, control.Section.Name
    window.DetailRows[3].Text, window.DetailRows[4].Text = Textos.nombreTipo(control.Kind), control.Range or "--"
    local numeric, boolean, choice = control.Kind == "Slider", control.Kind == "Toggle", control.Kind == "Dropdown"
    self.Numeric.Visible, self.Boolean.Visible = numeric, boolean
    self.Low.Visible, self.High.Visible, self.Meta.Visible = numeric, numeric, not numeric
    self.Options.Visible, self.ChoiceHint.Visible = false, false
    self.Action.Visible = control.Kind == "Button"
    local duration = same and Motion.Time.Value or 0
    if numeric then
        local fraction = control:Fraction()
        self.Low.Text = control:Format(control.Min)
        self.High.Text = control.Min == control.Max and Textos.fijo or control:Format(control.Max)
        rt:Tween(self.Marker, {Position = UDim2.fromScale(fraction, 0)}, duration, "position")
        for i, bar in ipairs(self.Bars) do
            local on = (i - 1) / (#self.Bars - 1) <= fraction
            if self.BarState[i] ~= on then
                self.BarState[i] = on
                rt:Tween(bar, {BackgroundColor3 = on and T.AccentSoft or T.Line}, duration)
            end
        end
        self.Hint.Text = control.Min == control.Max and Textos.pistaFijo or Textos.pistaDeslizador
    elseif boolean then
        self.Meta.Text = Textos.estado
        for i, state in ipairs(self.States) do
            local active = value == (i == 2)
            rt:Tween(state.Tile, {BackgroundColor3 = active and T.AccentWash or T.Surface}, duration)
            rt:Tween(state.Border, {Color = active and T.AccentSoft or T.SoftLine}, duration)
            rt:Tween(state.Label, {TextColor3 = active and T.Accent or T.Muted}, duration)
        end
        self.Hint.Text = Textos.pistaEstado
    elseif choice then
        local count = #control.Values
        local index = table.find(control.Values, value)
        self.Meta.Text = index and string.format(Textos.opcionActual, index, count) or Textos.sinOpciones
        self.Options.Visible = count > 0 and count <= #self.OptionMarks
        self.ChoiceHint.Visible = not self.Options.Visible
        self.ChoiceHint.Text = count == 0 and Textos.listaVacia or Textos.unaOpcion
        for i, mark in ipairs(self.OptionMarks) do
            mark.Visible = i <= count
            if self.Options.Visible then
                local width = (160 - (count - 1) * 4) / count
                mark.Position = UDim2.fromOffset((i - 1) * (width + 4), 0)
                mark.Size = UDim2.fromOffset(width, 4)
                rt:Tween(mark, {BackgroundColor3 = i == index and T.Accent or T.Line}, duration)
            end
        end
        self.Hint.Text = count == 0 and Textos.pistaVacia or Textos.pistaOpcion
    elseif control.Kind == "Input" then
        self.Meta.Text = control.ReadOnly and Textos.soloLectura or Textos.texto
        self.Hint.Text = control.ReadOnly and Textos.pistaSoloLectura
            or (control.MultiLine and Textos.pistaTextoMultilinea or Textos.pistaTexto)
    else
        self.Meta.Text = Textos.alPulsar
        self.Hint.Text = Textos.pistaAccion
    end
end

return Inspector
