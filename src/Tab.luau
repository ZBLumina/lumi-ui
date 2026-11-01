local UI = require("UI")
local T = require("Theme")
local Section = require("Section")
local Motion = require("Motion")
local Textos = require("Textos")
local Fonts = require("Fonts")
local BrandArt = require("components/BrandArt")
local Tab = {}
Tab.__index = Tab

function Tab.new(window, name, options)
    local index = #window.Tabs + 1
    local self = setmetatable({Name = tostring(name), Description = options.Description or Textos.descripcionPagina,
        Window = window, Sections = {}, Controls = {}}, Tab)
    local group = window:GetNavigationGroup(options.Group)
    group.Count += 1
    self.NavigationGroup = group
    self.NavigationLabel = options.NavigationLabel or name
    local button = UI.button(group.Content, tostring(name) .. "TabButton", "", 0, 0, 160, 42)
    button.Size = UDim2.new(1, 0, 0, 42)
    button.LayoutOrder = group.Count
    UI.corner(button, 6)
    self.Button = button
    self.Icon, self.IconParts = UI.icon(button, options.Icon, 14, 13, T.Secondary)
    self.Label = UI.text(button, "Label", self.NavigationLabel, 40, 0, 85, 42, 14, T.Secondary, T.Medium)
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
    self.Art = BrandArt.header(window.Runtime, header)
    UI.micro(header, "Eyebrow", options.Eyebrow or string.format(Textos.espacioMayus .. " / %02d", index), 0, 0, 540, 14).Size = UDim2.new(1, 0, 0, 14)
    self.Title = UI.text(header, "Title", name, 0, 21, 570, 39, 32, T.Text, T.Title)
    self.Subtitle = UI.text(header, "Subtitle", self.Description, 0, 66, 620, 18, 13, T.Secondary)
    for _, label in ipairs({self.Title, self.Subtitle}) do
        label.TextWrapped, label.TextTruncate = true, Enum.TextTruncate.None
        label.TextYAlignment = Enum.TextYAlignment.Top
    end
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

function Tab:SetNavigation(groupName, label)
    local group = self.Window:GetNavigationGroup(groupName)
    group.Count += 1
    self.NavigationGroup = group
    self.Button.Parent, self.Button.LayoutOrder = group.Content, group.Count
    self.NavigationLabel = label or self.Name
    self.Label.Text = self.NavigationLabel
    return self
end

function Tab:Relayout()
    local rowHeight = self.Window.Mobile and 48 or 42
    self.Button.Size = UDim2.new(1, 0, 0, rowHeight)
    self.Icon.Position = UDim2.fromOffset(14, (rowHeight - 16) / 2)
    self.Indicator.Position = UDim2.fromOffset(1, (rowHeight - 14) / 2)
    local padding = self.Window.Mobile and 16 or 26
    self.Padding.PaddingLeft, self.Padding.PaddingRight = UDim.new(0, padding), UDim.new(0, padding)
    self.Label.Size = UDim2.new(1, -48, 1, 0)
    local width = self:GetContentWidth()
    local hero = not self.Window.Mobile and width >= 500
    local textWidth = hero and math.floor(width * 0.56) or width
    self.Title.TextSize = self.Window.Mobile and 32 or 40
    self.Subtitle.TextSize = self.Window.Mobile and 15 or 16
    local function height(label, available, minimum)
        local bounds = Fonts.bounds(label.Text, label.TextSize, label.FontFace, available - 1)
        return math.max(minimum, math.ceil(bounds.Y) + 2)
    end
    local titleHeight = height(self.Title, textWidth, self.Window.Mobile and 39 or 48)
    local subtitleY = 21 + titleHeight + 8
    local subtitleHeight = height(self.Subtitle, textWidth, 18)
    self.Header.Eyebrow.Size = UDim2.fromOffset(textWidth, 14)
    self.Title.Size = UDim2.fromOffset(textWidth, titleHeight)
    self.Subtitle.Position = UDim2.fromOffset(0, subtitleY)
    self.Subtitle.Size = UDim2.fromOffset(textWidth, subtitleHeight)
    -- The PNG leaves its upper-left 56% x 55% clear. Grow long captions inside
    -- that area instead of hiding the full-width composition on desktop.
    local headerHeight = hero and math.max(180, math.ceil((subtitleY + subtitleHeight + 6) / 0.55))
        or math.max(self.Window.Mobile and 104 or 124, subtitleY + subtitleHeight + 4)
    self.Header.Size = UDim2.new(1, 0, 0, headerHeight)
    self.Art.Visible = hero
    for _, section in ipairs(self.Sections) do section:Relayout() end
    for _, control in ipairs(self.Controls) do control:Relayout() end
end

function Tab:SetActive(active, duration)
    local rt = self.Window.Runtime
    self.Button.BackgroundColor3 = T.AccentWash
    rt:Tween(self.Button, {BackgroundTransparency = active and 0 or 1}, duration)
    rt:Tween(self.Label, {TextColor3 = active and T.Accent or T.Secondary}, duration)
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
