local UI = require("UI")
local T = require("Theme")
local Runtime = require("Runtime")
local Motion = require("Motion")
local Dropdown = {}

function Dropdown.new(section, options)
    local c = section:Row(options, "Dropdown", 58)
    local rt, window = c.Runtime, section.Tab.Window
    local values = {}
    for _, value in ipairs(type(options.Values) == "table" and options.Values or {}) do table.insert(values, value) end
    local selected = table.find(values, options.Default) and options.Default or values[1]
    c.Range = tostring(#values) .. (#values == 1 and " option" or " options")
    local selector = UI.button(c.Row, "DropdownInput", "", 0, 14, 220, 31)
    selector.Position = UDim2.new(1, -236, 0, 14)
    selector.BackgroundTransparency = 0
    selector.BackgroundColor3 = T.Raised
    selector.ZIndex = 2
    UI.corner(selector, 5)
    local border = UI.stroke(selector, T.Line)
    local label = UI.text(selector, "Selection", selected == nil and "No options" or selected, 12, 0, 178, 31, 13, T.Secondary)
    UI.chevron(selector, 197, 15)
    c.Input, c.Values = selector, values
    c.Layout = function(narrow)
        selector.Position = narrow and UDim2.fromOffset(16, 54) or UDim2.new(1, -236, 0, 14)
        selector.Size = narrow and UDim2.new(1, -32, 0, 31) or UDim2.fromOffset(220, 31)
        label.Size = UDim2.new(1, -42, 1, 0)
        selector.ChevronA.Position = UDim2.new(1, -23, 0, 15)
        selector.ChevronB.Position = UDim2.new(1, -19, 0, 15)
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
        label.Text = tostring(selected)
        self:Refresh()
        if changed and not silent then rt:Callback(options.Callback, selected) end
        return changed
    end
    function c:Close(animated)
        if window.PopupOwner == self then window:ClosePopup(animated) end
    end
    function c:Open()
        if rt.Destroyed or window._closing or not section.Tab.Page.Visible then return end
        window:FinishEntrance()
        window:ClosePopup()
        self:Focus()
        rt:Tween(border, {Color = T.Accent}, 0.12)
        rt:Tween(selector.ChevronA, {Rotation = -45}, 0.12)
        rt:Tween(selector.ChevronB, {Rotation = 45}, 0.12)
        local popupRuntime = Runtime.new()
        popupRuntime.Animations = rt.Animations
        local scale = window.Scale
        local relative = (selector.AbsolutePosition - window.Main.AbsolutePosition) / scale
        local width = selector.AbsoluteSize.X / scale
        local wanted = math.min(234, math.max(1, #values) * 32 + 38)
        local below = window.Height - relative.Y - 37 - 12
        local above = relative.Y - 12
        local upward = below < wanted and above > below
        local height = math.min(wanted, math.max(60, upward and above or below))
        local x = math.clamp(relative.X, 8, window.Width - width - 8)
        local y = upward and relative.Y - height - 5 or relative.Y + 36
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
                rt:Tween(selector.ChevronA, {Rotation = 45}, 0.12)
                rt:Tween(selector.ChevronB, {Rotation = -45}, 0.12)
            end
        end
        UI.text(menu, "Caption", "SELECT OPTION", 11, 4, 198, 25, 9, T.Muted, T.Mono)
        local scroller = UI.new("ScrollingFrame", menu, {Name = "Options", Position = UDim2.fromOffset(5, 31),
            Size = UDim2.new(1, -10, 1, -36), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 2, ScrollBarImageColor3 = T.Muted, ZIndex = 102})
        UI.list(scroller, 0)
        if #values == 0 then UI.text(scroller, "Empty", "No options available", 7, 0, 192, 32, 11, T.Muted) end
        for index, value in ipairs(values) do
            local item = UI.button(scroller, "Option" .. tostring(index), "", 0, 0, 0, 32)
            item.Size = UDim2.new(1, -3, 0, 32)
            item.LayoutOrder = index
            item.BackgroundTransparency = 0
            item.BackgroundColor3 = value == selected and T.AccentWash or T.Raised
            item.ZIndex = 103
            UI.corner(item, 4)
            UI.text(item, "Label", value, 8, 0, 167, 32, 13, value == selected and T.Accent or T.Text).Size = UDim2.new(1, -38, 0, 32)
            if value == selected then UI.check(item, width - 39, 13) end
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
    return c
end

return Dropdown
