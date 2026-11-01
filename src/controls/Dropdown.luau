local UI = require("UI")
local T = require("Theme")
local Runtime = require("Runtime")
local Motion = require("Motion")
local Textos = require("Textos")
local Thumbnail = require("components/Thumbnail")
local Dropdown = {}

function Dropdown.new(section, options)
    local c = section:Row(options, "Dropdown", 64)
    local rt, window = c.Runtime, section.Tab.Window
    local values, entries = {}, {}
    local pictures, detailed = false, false
    for _, raw in ipairs(type(options.Values) == "table" and options.Values or {}) do
        local entry = type(raw) == "table" and raw or {Value = raw, Label = tostring(raw)}
        local value = entry.Value
        if value ~= nil and not table.find(values, value) then
            table.insert(values, value)
            table.insert(entries, {Value = value, Label = tostring(entry.Label or value), Image = entry.Image,
                Description = entry.Description and tostring(entry.Description)})
            pictures = pictures or entry.Image ~= nil
            detailed = detailed or entry.Description ~= nil
        end
    end
    local selected = table.find(values, options.Default) and options.Default or values[1]
    c.Range = Textos.cantidadOpciones(#values)
    local selector = UI.button(c.Row, "DropdownInput", "", 0, 14, 220, 31)
    selector.Position = UDim2.new(1, -236, 0, 14)
    selector.BackgroundTransparency = 0
    selector.BackgroundColor3 = T.Raised
    selector.ZIndex = 2
    UI.corner(selector, 7)
    local border = UI.stroke(selector, T.Line)
    local label = UI.text(selector, "Selection", selected == nil and Textos.vacio or selected, 12, 0, 178, 31, 13, T.Secondary)
    label:SetAttribute("LumiUserText",options.TranslateValues==false)
    local preview, binding
    if pictures then
        preview, binding = Thumbnail.new(rt, selector, nil, 6, 5, 32, 22)
        c.ControlWidth = 244
    end
    UI.chevron(selector, 197, 15)
    c.Input, c.Values = selector, values
    c.Options, c.HasImages = entries, pictures
    c.TranslateValues=options.TranslateValues~=false
    local function selectedEntry()
        local index = table.find(values, selected)
        return index and entries[index]
    end
    function c:GetLabel()
        local entry = selectedEntry()
        return entry and entry.Label or Textos.vacio
    end
    local function present()
        label.Text = c:GetLabel()
        local entry = selectedEntry()
        if binding then binding:Set(entry and entry.Image) end
    end
    c.Layout = function(place)
        selector.Position = UDim2.fromOffset(place.ControlX, place.ControlY)
        selector.Size = UDim2.fromOffset(place.ControlWidth, place.ControlHeight)
        local textX = pictures and 46 or 12
        label.Position = UDim2.fromOffset(textX, 0)
        label.Size = UDim2.new(1, -(textX + 30), 1, 0)
        if preview then preview.Position = UDim2.fromOffset(6, (place.ControlHeight - 22) / 2) end
        local center = place.ControlHeight / 2
        selector.Chevron.Position = UDim2.new(1, -28, 0, center - 8)
    end
    c.Get = function() return selected end
    function c:Fraction()
        local index = table.find(values, selected)
        return index and index / #values or 0
    end
    function c:Set(value, silent)
        if rt.Destroyed or window._closing or not table.find(values, value) then return false end
        local changed = value ~= selected
        selected = value
        present()
        self:Refresh()
        if changed and not silent then rt:Callback(options.Callback, selected) end
        return changed
    end
    function c:Close(animated)
        if window.PopupOwner == self then window:ClosePopup(animated) end
    end
    function c:Open()
        if rt.Destroyed or window._closing or window.Minimized or not window.Panel.Visible or not section.Tab.Page.Visible then return end
        window:FinishEntrance()
        window:ClosePopup()
        self:Focus()
        rt:Tween(border, {Color = T.Accent}, 0.12)
        rt:Tween(selector.Chevron, {Rotation = 180}, 0.12)
        local popupRuntime = Runtime.new()
        popupRuntime.Animations = rt.Animations
        local scale = window.Scale
        local relative = (selector.AbsolutePosition - window.Main.AbsolutePosition) / scale
        local panelWidth = window.PanelWidth
        local textFactor=window.TextScale or 1
        local rowHeight = (pictures or detailed) and math.max(window.Mobile and 56 or 52,math.ceil(44*textFactor)+8)
            or math.max(window.Mobile and 44 or 32,math.ceil(24*textFactor)+8)
        local width = math.min(window.Panel.Size.X.Offset - 16, math.max(pictures and 244 or 180, selector.AbsoluteSize.X / scale))
        local wanted = math.min(266, math.max(1, #values) * rowHeight + 38)
        local inputHeight = selector.AbsoluteSize.Y / scale
        local below = window.Height - relative.Y - inputHeight - 12
        local above = relative.Y - 12
        local upward = below < wanted and above > below
        local height = math.min(wanted, window.Height - 16, math.max(60, upward and above or below))
        local x = math.clamp(relative.X, window.ContentX + 8, panelWidth - width - 8)
        local y = upward and relative.Y - height - 5 or relative.Y + inputHeight + 5
        y = math.clamp(y, 8, window.Height - height - 8)
        local menu = UI.frame(window.Main, "DropdownPopover", x, y, width, height, T.Raised, 7)
        menu.ZIndex = 101
        UI.stroke(menu, T.Line)
        local motion = Motion.new(popupRuntime, menu)
        window.OpenDropdown, window.PopupOwner = menu, self
        window._popupMotion = motion
        window.Blocker.Visible = true
        window._popupCleanup = function()
            popupRuntime:Destroy()
            if not rt.Destroyed then
                rt:Tween(border, {Color = T.Line}, 0.12)
                rt:Tween(selector.Chevron, {Rotation = 0}, 0.12)
            end
        end
        UI.text(menu, "Caption", Textos.elegirOpcion, 11, 4, 198, 25, 9, T.Muted, T.Mono).Size = UDim2.new(1, -22, 0, 25)
        local scroller = UI.new("ScrollingFrame", menu, {Name = "Options", Position = UDim2.fromOffset(5, 31),
            Size = UDim2.new(1, -10, 1, -36), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 2, ScrollBarImageColor3 = T.Muted, ZIndex = 102})
        UI.list(scroller, 0)
        if #values == 0 then
            UI.text(scroller, "Empty", Textos.noHayOpciones, 7, 0, 192, 32, 11, T.Muted).Size = UDim2.new(1, -14, 0, 32)
        end
        for index, value in ipairs(values) do
            local entry = entries[index]
            local item = UI.button(scroller, "Option" .. tostring(index), "", 0, 0, 0, rowHeight)
            item.Size = UDim2.new(1, -3, 0, rowHeight)
            item.LayoutOrder = index
            item.BackgroundTransparency = 0
            item.BackgroundColor3 = value == selected and T.AccentWash or T.Raised
            item.ZIndex = 103
            UI.corner(item, 4)
            if pictures then Thumbnail.new(popupRuntime, item, entry.Image, 7, (rowHeight - 32) / 2, 48, 32) end
            local textX = pictures and 64 or 8
            local textHeight = entry.Description and math.ceil(19*textFactor) or rowHeight
            local optionLabel=UI.text(item, "Label", entry.Label, textX, entry.Description and 7 or 0, 167, textHeight, 13,
                value == selected and T.Accent or T.Text)
            optionLabel.Size = UDim2.new(1, -(textX + 30), 0, textHeight)
            optionLabel:SetAttribute("LumiUserText",options.TranslateValues==false)
            if entry.Description then UI.text(item, "Description", entry.Description, textX, 8+textHeight, 120, math.ceil(17*textFactor), 11, T.Muted).Size = UDim2.new(1, -(textX + 30), 0, math.ceil(17*textFactor)) end
            if value == selected then UI.check(item, width - 39, rowHeight / 2 - 3) end
            UI.hover(popupRuntime, item, value == selected and T.AccentWash or T.Raised, T.Hover)
            popupRuntime:Connect(item.Activated, function()
                if window.PopupOwner ~= c or window.OpenDropdown ~= menu then return end
                c:Set(value)
                c:Close(true)
            end)
        end
        menu.Position = UDim2.fromOffset(x, math.clamp(y + (upward and -4 or 4), 8, window.Height - height - 8))
        popupRuntime:Tween(menu, {Position = UDim2.fromOffset(x, y)}, Motion.Time.Menu, "position")
        motion:Fade(0.45, 0, Motion.Time.Menu)
    end
    UI.hover(rt, selector, T.Raised, T.Hover)
    rt:Connect(selector.Activated, function()
        if window.PopupOwner == c then c:Close(true) else c:Open() end
    end)
    rt:Connect(selector.SelectionGained, function() c:Focus(); border.Color = T.Accent end)
    rt:Connect(selector.SelectionLost, function() if window.PopupOwner ~= c then border.Color = T.Line end end)
    present()
    return c
end

return Dropdown
