local UI = require("UI")
local T = require("Theme")
local Navigation = {}
Navigation.__index = Navigation
local names = {PRINCIPAL = "Principal", ESPACIO = "Espacio", HERRAMIENTAS = "Herramientas"}

function Navigation.new(window)
    local self = setmetatable({Window = window, Groups = {}, Order = {}}, Navigation)
    UI.list(window.Navigation, 0)
    self:GetGroup("Principal")
    return self
end

function Navigation:GetGroup(name)
    name = tostring(name or "Principal")
    name = names[string.upper(name)] or name
    if self.Groups[name] then return self.Groups[name] end
    local first = #self.Order == 0
    local frame = UI.frame(self.Window.Navigation, name .. "Group", 0, 0, 0, 0)
    frame.Size, frame.AutomaticSize = UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y
    frame.LayoutOrder = #self.Order + 1
    UI.list(frame, 0)
    local header = UI.frame(frame, "Heading", 0, 0, 0, first and 24 or 42)
    header.Size = UDim2.new(1, 0, 0, first and 24 or 42)
    header.LayoutOrder = 0
    local divider = UI.line(header, 8, 4, 0, T.SoftLine)
    divider.Size, divider.Visible = UDim2.new(1, -16, 0, 1), not first
    divider.BackgroundTransparency = .2
    local label = UI.micro(header, "Label", string.upper(name), 10, first and 2 or 20, 180, 16, 10)
    label.Size = UDim2.new(1, -20, 0, 16)
    local content = UI.frame(frame, "Pages", 0, 0, 0, 0)
    content.Size, content.AutomaticSize = UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y
    content.LayoutOrder = 1
    UI.list(content, 4)
    local group = {Name = name, Frame = frame, Content = content, Label = label, Divider = divider, Count = 0}
    self.Groups[name] = group
    table.insert(self.Order, group)
    return group
end

function Navigation:Reveal(tab)
    local w = self.Window
    if not tab or not tab.Button.Visible or not w.Sidebar.Visible then return end
    w.Runtime:Delay(0, function()
        if w.ActiveTab ~= tab or not tab.Button.Parent or not w.Sidebar.Visible then return end
        local page, button = w.Navigation, tab.Button
        local scale = w.Scale
        local top = (button.AbsolutePosition.Y - page.AbsolutePosition.Y) / scale + page.CanvasPosition.Y
        local height = page.AbsoluteSize.Y / scale
        local bottom = top + button.AbsoluteSize.Y / scale
        local y = page.CanvasPosition.Y
        if top < y then y = top elseif bottom > y + height then y = bottom - height end
        page:ResetScrollVelocity()
        page.CanvasPosition = Vector2.new(0, math.clamp(y, 0, math.max(0, page.AbsoluteCanvasSize.Y / scale - height)))
    end)
end

return Navigation
