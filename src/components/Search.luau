local UI = require("UI")
local T = require("Theme")
local Runtime = require("Runtime")
local Motion = require("Motion")
local Input = game:GetService("UserInputService")
local Search = {}
Search.__index = Search
local liveSearches = {}

local accents = {
    ["á"] = "a", ["Á"] = "a", ["é"] = "e", ["É"] = "e",
    ["í"] = "i", ["Í"] = "i", ["ó"] = "o", ["Ó"] = "o",
    ["ú"] = "u", ["Ú"] = "u", ["ü"] = "u", ["Ü"] = "u",
    ["ñ"] = "n", ["Ñ"] = "n",
    ["\204\129"] = "", ["\204\136"] = "", ["\204\131"] = "",
}

local function normalize(value)
    local text = tostring(value or ""):gsub("[\194-\244][\128-\191]*", accents):lower()
    return (text:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function expanded(window)
    return not window.Runtime.Destroyed and not window._destroyed and not window._closing
        and not window.Minimized and window.Panel.Visible
        and (not window.Presentation or window.Presentation.State == "expanded")
end

local function reveal(window, tab, control)
    if window.Runtime.Destroyed or window._closing or window.ActiveTab ~= tab then return end
    local page, row = tab.Page, control.Row
    if not page.Parent or not row.Parent then return end
    local scale = window.Scale
    local height = page.AbsoluteWindowSize.Y / scale
    if height <= 0 then return end
    local top = (row.AbsolutePosition.Y - page.AbsolutePosition.Y) / scale + page.CanvasPosition.Y
    local bottom = top + row.AbsoluteSize.Y / scale
    local position = page.CanvasPosition.Y
    if top < position or bottom - top > height then position = top - 8
    elseif bottom > position + height then position = bottom - height + 8 end
    local limit = math.max(0, page.AbsoluteCanvasSize.Y / scale - height)
    page.CanvasPosition = Vector2.new(page.CanvasPosition.X, math.clamp(position, 0, limit))
end

function Search.new(window)
    local self = setmetatable({Window = window}, Search)
    table.insert(liveSearches, self)
    window.Runtime:OnCleanup(function()
        local index = table.find(liveSearches, self)
        if index then table.remove(liveSearches, index) end
    end)
    local button = UI.button(window.Chrome, "Search", "", 0, 0, 220, 28)
    button.BackgroundTransparency, button.BackgroundColor3 = 0, T.Surface
    UI.corner(button, 6)
    UI.stroke(button, T.SoftLine)
    self.Button = button
    self.Icon = UI.icon(button, "Search", 10, 6, T.Muted)
    self.Label = UI.text(button, "Label", "Buscar en Lumi...", 34, 0, 128, 28, 11, T.Muted)
    self.Hint = UI.text(button, "Shortcut", "Ctrl K", 170, 0, 42, 28, 9, T.Muted, T.Mono)
    self.Hint.TextXAlignment = Enum.TextXAlignment.Center
    UI.hover(window.Runtime, button, T.Surface, T.Raised)
    window.Runtime:Connect(button.Activated, function()
        if window.PopupOwner == self then self:Close(true) else self:Open() end
    end)
    window.Runtime:Connect(Input.InputBegan, function(input)
        if input.KeyCode ~= Enum.KeyCode.K then return end
        if not Input:IsKeyDown(Enum.KeyCode.LeftControl) and not Input:IsKeyDown(Enum.KeyCode.RightControl) then return end
        local focused = Input:GetFocusedTextBox()
        if focused and not focused:IsDescendantOf(window.Root) then return end
        if not focused then
            local target
            for index = #liveSearches, 1, -1 do
                if expanded(liveSearches[index].Window) then target = liveSearches[index]; break end
            end
            if target ~= self then return end
        end
        self:Open()
    end)
    return self
end

function Search:Fit(width, height, mobile)
    local full = not mobile and width >= 560
    local size = mobile and 44 or (full and 28 or 30)
    local left = width - (mobile and 144 or (full and 316 or 116))
    self.Button.Position = UDim2.fromOffset(left, mobile and 6 or (height - size) / 2)
    self.Button.Size = UDim2.fromOffset(full and 220 or size, size)
    self.Icon.Position = UDim2.fromOffset(full and 10 or (size - 16) / 2, (size - 16) / 2)
    self.Label.Visible, self.Hint.Visible = full, full
    self.Label.Size = UDim2.new(1, -92, 1, 0)
    self.Hint.Position, self.Hint.Size = UDim2.new(1, -50, 0, 0), UDim2.new(0, 42, 1, 0)
    return left
end

function Search:Find(query)
    local needle, results = normalize(query), {}
    local function matches(text)
        return needle == "" or normalize(text):find(needle, 1, true) ~= nil
    end
    for _, tab in ipairs(self.Window.Tabs) do
        if matches(tab.Name .. " " .. tostring(tab.NavigationLabel or "") .. " " .. tostring(tab.Description or "")) then
            table.insert(results, {Tab = tab, Label = tab.Name, Description = tostring(tab.Description or "")})
        end
        if needle ~= "" then
            for _, control in ipairs(tab.Controls) do
                local section = control.Section and control.Section.Name or ""
                local description = tostring(control.Description or "")
                if matches(control.Name .. " " .. description .. " " .. section .. " " .. tab.Name) then
                    local context = tab.Name .. (section ~= "" and " / " .. section or "")
                    table.insert(results, {Tab = tab, Control = control, Label = control.Name,
                        Description = context .. (description ~= "" and " · " .. description or "")})
                end
            end
        end
    end
    if not (self.Window.Settings and self.Window.Settings.Tab) then
        local description = "Ajustes de la interfaz de Lumi."
        if matches("Configuraciones " .. description) then
            table.insert(results, {Settings = true, Label = "Configuraciones", Description = description})
        end
    end
    return results
end

function Search:Close(animated)
    local window = self.Window
    if window.PopupOwner ~= self then return end
    local focused = Input:GetFocusedTextBox()
    if focused and focused:IsDescendantOf(window.OpenDropdown) then focused:ReleaseFocus(false) end
    window:ClosePopup(animated)
end

function Search:Choose(entry)
    local window = self.Window
    if window.Runtime.Destroyed or window._destroyed or window._closing or type(entry) ~= "table" then return end
    if entry.Settings then
        self:Close()
        window:OpenSettings()
        return
    end
    local tab, control = entry.Tab, entry.Control
    if not table.find(window.Tabs, tab) then return end
    if control and not table.find(tab.Controls, control) then return end
    self:Close()
    window:SelectTab(tab)
    if control then
        control:Focus()
        window.Runtime:Delay(0, function() reveal(window, tab, control) end)
    end
end

function Search:Open(initialQuery)
    local window = self.Window
    if not expanded(window) then return end
    if window.PopupOwner == self and window.OpenDropdown then
        local query = window.OpenDropdown:FindFirstChild("Query")
        if query then
            if initialQuery ~= nil then query.Text = tostring(initialQuery) end
            query:CaptureFocus()
            query.CursorPosition = #query.Text + 1
            return window.OpenDropdown
        end
    end
    window:FinishEntrance()
    window:ClosePopup()
    local width = math.min(420, window.Panel.Size.X.Offset - 16)
    local y = (window.ChromeHeight or window.Chrome.Size.Y.Offset) + 6
    local height = math.min(350, window.Height - y - 12)
    if width <= 0 or height <= 0 then return end
    local relative = (self.Button.AbsolutePosition - window.Main.AbsolutePosition) / window.Scale
    local x = math.clamp(relative.X, window.ContentX + 8, window.PanelWidth - width - 8)
    local popupRuntime = Runtime.new()
    popupRuntime.Animations = window.Runtime.Animations
    local menu = UI.frame(window.Main, "SearchPopover", x, y, width, height, T.Raised, 7)
    menu.ZIndex = 101
    UI.stroke(menu, T.Line)
    local motion = Motion.new(popupRuntime, menu)
    local queryHeight = window.Mobile and 44 or 36
    local query = UI.new("TextBox", menu, {Name = "Query", Position = UDim2.fromOffset(10, 8),
        Size = UDim2.new(1, -20, 0, queryHeight), BackgroundColor3 = T.Surface, BackgroundTransparency = 0,
        Text = tostring(initialQuery or ""), PlaceholderText = "Buscar en Lumi...", PlaceholderColor3 = T.Muted,
        TextColor3 = T.Text, Font = T.Font, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false, MultiLine = false, ZIndex = 102})
    UI.corner(query, 5)
    UI.stroke(query, T.SoftLine)
    UI.new("UIPadding", query, {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})
    local resultTop = queryHeight + 16
    local scroller = UI.new("ScrollingFrame", menu, {Name = "Results", Position = UDim2.fromOffset(6, resultTop),
        Size = UDim2.new(1, -12, 1, -(resultTop + 6)), CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2,
        ScrollBarImageColor3 = T.Muted, ZIndex = 102})
    UI.list(scroller, 2)
    local empty = UI.text(scroller, "Empty", "No se encontraron resultados.", 10, 0, width - 32, 44, 12, T.Muted)
    empty.Size = UDim2.new(1, -20, 0, 44)
    empty.TextWrapped = true
    local results, items, selected = {}, {}, 1
    local rowHeight = window.Mobile and 56 or 48
    local function ownsPopup()
        return not popupRuntime.Destroyed and window.PopupOwner == self and window.OpenDropdown == menu
    end
    local function releaseFocus()
        if Input:GetFocusedTextBox() == query then query:ReleaseFocus(false) end
    end
    window.OpenDropdown, window.PopupOwner = menu, self
    window.Blocker.Visible = true
    window._popupMotion = motion
    window._popupCleanup = function() popupRuntime:Destroy() end
    popupRuntime:OnCleanup(releaseFocus)
    popupRuntime:Connect(menu.Destroying, releaseFocus)

    local function highlight(scroll)
        for index, item in ipairs(items) do
            item.Mark.Visible = index == selected and index <= #results
            item.Label.TextColor3 = index == selected and T.Accent or T.Text
        end
        if scroll and #results > 0 then
            local viewport = scroller.AbsoluteWindowSize.Y / window.Scale
            local top = (selected - 1) * (rowHeight + 2)
            local position = scroller.CanvasPosition.Y
            if top < position then position = top
            elseif top + rowHeight > position + viewport then position = top + rowHeight - viewport end
            scroller.CanvasPosition = Vector2.new(0, math.max(0, position))
        end
    end
    local function update()
        if not ownsPopup() then return end
        motion:Finish()
        results = self:Find(query.Text)
        while #results > 60 do table.remove(results) end
        selected = 1
        empty.Visible = #results == 0
        scroller.CanvasPosition = Vector2.zero
        for index, entry in ipairs(results) do
            local item = items[index]
            if not item then
                local button = UI.button(scroller, "Result" .. index, "", 0, 0, 0, rowHeight)
                button.Size, button.LayoutOrder = UDim2.new(1, -3, 0, rowHeight), index
                button.BackgroundColor3, button.BackgroundTransparency, button.ZIndex = T.Raised, 0, 103
                UI.corner(button, 4)
                local mark = UI.frame(button, "Selected", 2, 10, 2, rowHeight - 20, T.Accent, 1)
                local label = UI.text(button, "Label", "", 10, 4, width - 44, 21, 13, T.Text)
                label.Size = UDim2.new(1, -20, 0, 21)
                local description = UI.text(button, "Description", "", 10, 26, width - 44, rowHeight - 28, 10, T.Muted)
                description.Size = UDim2.new(1, -20, 0, rowHeight - 28)
                item = {Button = button, Label = label, Description = description, Mark = mark}
                items[index] = item
                UI.hover(popupRuntime, button, T.Raised, T.Hover)
                popupRuntime:Connect(button.Activated, function()
                    if ownsPopup() and results[index] then self:Choose(results[index]) end
                end)
            end
            item.Button.Visible = true
            item.Label.Text, item.Description.Text = entry.Label, entry.Description
        end
        for index = #results + 1, #items do items[index].Button.Visible = false end
        highlight(false)
    end
    popupRuntime:Connect(query:GetPropertyChangedSignal("Text"), update)
    popupRuntime:Connect(query.FocusLost, function(enterPressed)
        if enterPressed and ownsPopup() and results[selected] then self:Choose(results[selected]) end
    end)
    popupRuntime:Connect(Input.InputBegan, function(input)
        if not ownsPopup() or Input:GetFocusedTextBox() ~= query then return end
        if input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.Down then
            if #results == 0 then return end
            selected = math.clamp(selected + (input.KeyCode == Enum.KeyCode.Up and -1 or 1), 1, #results)
            highlight(true)
        elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
            if results[selected] then self:Choose(results[selected]) end
        end
    end)
    update()
    menu.Position = UDim2.fromOffset(x, y + 4)
    popupRuntime:Tween(menu, {Position = UDim2.fromOffset(x, y)}, Motion.Time.Menu, "position")
    motion:Fade(0.45, 0, Motion.Time.Menu)
    query:CaptureFocus()
    query.CursorPosition = #query.Text + 1
    return menu
end

return Search
