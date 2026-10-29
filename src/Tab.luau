local UI = require("UI")
local T = require("Theme")
local Section = require("Section")
local Tab = {}
Tab.__index = Tab

function Tab.new(window, name, options)
    local index = #window.Tabs + 1
    local self = setmetatable({Name = tostring(name), Description = options.Description or "A considered space for precise adjustments.",
        Window = window, Sections = {}, Controls = {}}, Tab)
    local button = UI.button(window.Navigation, tostring(name) .. "TabButton", "", 0, 0, 160, 42)
    button.Size = UDim2.new(1, 0, 0, 42)
    button.LayoutOrder = index
    UI.corner(button, 6)
    self.Button = button
    self.Number = UI.text(button, "Number", string.format("%02d", index), 12, 0, 24, 42, 10, T.Muted, T.Mono)
    self.Label = UI.text(button, "Label", name, 43, 0, 104, 42, 13, T.Secondary, T.Medium)
    self.Label.Size = UDim2.new(1, -50, 1, 0)
    self.Indicator = UI.frame(button, "Selected", 1, 14, 2, 14, T.Accent, 1)
    self.Indicator.Visible = false
    local page = UI.new("ScrollingFrame", window.Workspace, {
        Name = tostring(name) .. "Page", Size = UDim2.fromScale(1, 1), ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.Line, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    })
    self.Page = page
    UI.new("UIPadding", page, {PaddingLeft = UDim.new(0, 26), PaddingRight = UDim.new(0, 26), PaddingTop = UDim.new(0, 22), PaddingBottom = UDim.new(0, 22)})
    UI.list(page, 14)
    local header = UI.frame(page, "PageHeader", 0, 0, 644, 76)
    header.Size = UDim2.new(1, 0, 0, 76)
    header.LayoutOrder = 0
    UI.text(header, "Eyebrow", options.Eyebrow or "LUMI / WORKSPACE", 0, 0, 540, 13, 9, T.Muted, T.Medium)
    UI.text(header, "Title", name, 0, 20, 570, 30, 23, T.Text, T.Medium).Size = UDim2.new(1, 0, 0, 30)
    UI.text(header, "Subtitle", self.Description, 0, 54, 620, 17, 12, T.Secondary).Size = UDim2.new(1, 0, 0, 17)
    window.Runtime:Connect(button.Activated, function() window:SelectTab(self) end)
    window.Runtime:Connect(button.MouseEnter, function()
        if window.ActiveTab ~= self then button.BackgroundTransparency = 0; button.BackgroundColor3 = T.Surface end
    end)
    window.Runtime:Connect(button.MouseLeave, function()
        if window.ActiveTab ~= self then button.BackgroundTransparency = 1 end
    end)
    window.Runtime:Connect(page:GetPropertyChangedSignal("CanvasPosition"), function() window:ClosePopup() end)
    table.insert(window.Tabs, self)
    if index == 1 then window:SelectTab(self) end
    return self
end

function Tab:AddSection(name, options)
    return Section.new(self, name, options or {})
end

return Tab
