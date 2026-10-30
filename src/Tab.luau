local UI = require("UI")
local T = require("Theme")
local Section = require("Section")
local Motion = require("Motion")
local Textos = require("Textos")
local Text = game:GetService("TextService")
local Tab = {}
Tab.__index = Tab

function Tab.new(window, name, options)
    local index = #window.Tabs + 1
    local self = setmetatable({Name = tostring(name), Description = options.Description or Textos.descripcionPagina,
        Window = window, Sections = {}, Controls = {}}, Tab)
    local button = UI.button(window.Navigation, tostring(name) .. "TabButton", "", 0, 0, 160, 42)
    button.Size = UDim2.new(1, 0, 0, 42)
    button.LayoutOrder = index
    UI.corner(button, 6)
    self.Button = button
    self.Icon, self.IconParts = UI.icon(button, options.Icon, 14, 13, T.Secondary)
    self.Number = UI.text(button, "Number", "00", 0, 0, 24, 42, 11, T.Muted, T.Mono)
    self.Number.Position = UDim2.new(1, -32, 0, 0)
    self.Number.TextXAlignment = Enum.TextXAlignment.Right
    self.Label = UI.text(button, "Label", name, 40, 0, 85, 42, 14, T.Secondary, T.Medium)
    self.Outline = UI.stroke(button, T.AccentSoft)
    self.Outline.Transparency, self.Outline.Enabled = 0.66, false
    self.Indicator = UI.frame(button, "Selected", 1, 14, 2, 14, T.Accent, 1)
    self.Indicator.Visible = false
    local page = UI.new("ScrollingFrame", window.Workspace, {
        Name = tostring(name) .. "Page", Size = UDim2.fromScale(1, 1), ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.Line, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    })
    self.Page = page
    self.Motion = Motion.new(window.Runtime, page)
    self.Padding = UI.new("UIPadding", page, {PaddingLeft = UDim.new(0, 26), PaddingRight = UDim.new(0, 26), PaddingTop = UDim.new(0, 22), PaddingBottom = UDim.new(0, 22)})
    UI.list(page, 14)
    local header = UI.frame(page, "PageHeader", 0, 0, 644, 88)
    header.Size = UDim2.new(1, 0, 0, 88)
    header.LayoutOrder = 0
    self.Header = header
    UI.text(header, "Eyebrow", options.Eyebrow or string.format(Textos.espacioMayus .. " / %02d", index), 0, 0, 540, 13, 11, T.Muted, T.Medium).Size = UDim2.new(1, 0, 0, 13)
    self.Title = UI.text(header, "Title", name, 0, 21, 570, 39, 32, T.Text, T.Medium)
    self.Subtitle = UI.text(header, "Subtitle", self.Description, 0, 66, 620, 18, 13, T.Secondary)
    for _, label in ipairs({self.Title, self.Subtitle}) do
        label.TextWrapped, label.TextTruncate = true, Enum.TextTruncate.None
        label.TextYAlignment = Enum.TextYAlignment.Top
    end
    self.Summary = UI.frame(header, "PageSummary", 0, 22, 72, 44)
    self.Summary.Position = UDim2.new(1, -72, 0, 20)
    self.Count = UI.text(self.Summary, "Count", "00", 0, 0, 72, 26, 24, T.Accent, T.Mono)
    self.Count.TextXAlignment = Enum.TextXAlignment.Right
    UI.text(self.Summary, "Caption", Textos.controles, 0, 29, 72, 15, 11, T.Muted, T.Mono).TextXAlignment = Enum.TextXAlignment.Right
    window.Runtime:Connect(button.Activated, function() window:SelectTab(self) end)
    window.Runtime:Connect(button.MouseEnter, function()
        if window._closing then return end
        window:FinishEntrance()
        if window.ActiveTab ~= self then
            button.BackgroundColor3 = T.Surface
            window.Runtime:Tween(button, {BackgroundTransparency = 0}, 0.12)
        end
    end)
    window.Runtime:Connect(button.MouseLeave, function()
        if window.ActiveTab ~= self and not window._closing then window.Runtime:Tween(button, {BackgroundTransparency = 1}, 0.12) end
    end)
    window.Runtime:Connect(page:GetPropertyChangedSignal("CanvasPosition"), function() window:ClosePopup() end)
    window.Runtime:Connect(button:GetPropertyChangedSignal("AbsoluteSize"), function() self:Relayout() end)
    window.Runtime:Connect(header:GetPropertyChangedSignal("AbsoluteSize"), function() self:Relayout() end)
    table.insert(window.Tabs, self)
    self:Relayout()
    if index == 1 then window:SelectTab(self) end
    return self
end

function Tab:GetContentWidth()
    -- Logical dimensions stay current even when Roblox defers AbsoluteSize
    -- updates for invisible or clipped descendants.
    local page = self.Window.Workspace.Size.X.Offset * self.Page.Size.X.Scale + self.Page.Size.X.Offset
    local left, right = self.Padding.PaddingLeft, self.Padding.PaddingRight
    return math.max(1, math.floor(page * (1 - left.Scale - right.Scale) - left.Offset - right.Offset))
end

function Tab:Relayout()
    local counts = (self.Window.SidebarWidth or 184) >= 170 and #self.Controls < 1000
    self.Number.Visible = counts
    self.Label.Size = UDim2.new(1, counts and -76 or -48, 1, 0)
    local width = self:GetContentWidth()
    local summary = width >= 360
    self.Summary.Visible = summary
    local titleWidth = math.max(1, width - (summary and 88 or 0))
    local function height(label, available, minimum)
        local bounds = Text:GetTextSize(label.Text, label.TextSize, label.Font, Vector2.new(math.max(1, available - 1), 100000))
        return math.max(minimum, math.ceil(bounds.Y) + 2)
    end
    local titleHeight = height(self.Title, titleWidth, 39)
    local subtitleY = 21 + titleHeight + 6
    local subtitleHeight = height(self.Subtitle, width, 18)
    self.Title.Size = UDim2.new(1, summary and -88 or 0, 0, titleHeight)
    self.Subtitle.Position = UDim2.fromOffset(0, subtitleY)
    self.Subtitle.Size = UDim2.new(1, 0, 0, subtitleHeight)
    self.Header.Size = UDim2.new(1, 0, 0, math.max(88, subtitleY + subtitleHeight + 4))
    for _, section in ipairs(self.Sections) do section:Relayout() end
    for _, control in ipairs(self.Controls) do control:Relayout() end
end

function Tab:UpdateSummary()
    local count = #self.Controls
    self.Number.Text = string.format("%02d", count)
    self.Count.Text = string.format("%02d", count)
    self:Relayout()
end

function Tab:SetActive(active, duration)
    local rt = self.Window.Runtime
    self.Button.BackgroundColor3 = T.AccentWash
    rt:Tween(self.Button, {BackgroundTransparency = active and 0 or 1}, duration)
    rt:Tween(self.Label, {TextColor3 = active and T.Accent or T.Secondary}, duration)
    rt:Tween(self.Number, {TextColor3 = active and T.Secondary or T.Muted}, duration)
    for _, part in ipairs(self.IconParts) do
        rt:Tween(part, part:IsA("UIStroke") and {Color = active and T.Accent or T.Secondary}
            or {BackgroundColor3 = active and T.Accent or T.Secondary}, duration)
    end
    self.Outline.Enabled, self.Indicator.Visible = active, active
end

function Tab:AddSection(name, options)
    return Section.new(self, name, options or {})
end

return Tab
