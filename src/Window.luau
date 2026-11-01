local Runtime = require("Runtime")
local UI = require("UI")
local T = require("Theme")
local Tab = require("Tab")
local Motion = require("Motion")
local Inspector = require("components/Inspector")
local Shadow = require("components/Shadow")
local Presentation = require("components/WindowPresentation")
local Profile = require("components/Profile")
local Textos = require("Textos")
local BrandArt = require("components/BrandArt")
local Fonts = require("Fonts")
local Settings = require("components/Settings")
local Search = require("components/Search")
local Navigation = require("components/Navigation")
local Icons = require("Icons")
local Locale = require("Locale")
local Input = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Window = {}
Window.__index = Window
local DESKTOP_HEIGHT = 688
local PREFERRED_HEIGHT = 808
local INSPECTOR_WIDTH, PANEL_GAP = 224, 12
local liveWindows = {}

function Window.new(options)
    local rt = Runtime.new()
    rt.Animations = options.Animations ~= false
    local root = rt:Mount()
    Icons.mount(rt, root)
    local self = setmetatable({Runtime = rt, Root = root, Tabs = {}, _destroyed = false,
        Width = 1100, Height = DESKTOP_HEIGHT, Scale = 1, OpenDropdown = nil, Minimized = false}, Window)
    self.Language = options.Language == "pt" and "pt" or "es"
    self.ToggleKey = options.ToggleKey == nil and Enum.KeyCode.RightShift or options.ToggleKey
    if self.ToggleKey ~= false and (typeof(self.ToggleKey) ~= "EnumItem" or self.ToggleKey.EnumType ~= Enum.KeyCode) then
        self.ToggleKey = Enum.KeyCode.RightShift
    end
    -- A transparent assembly anchors the three independently painted surfaces.
    local main = UI.frame(root, "Main", 0, 0, 1100, DESKTOP_HEIGHT)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.fromScale(0.5, 0.5)
    self.Main = main
    self.UIScale = UI.new("UIScale", main, {Scale = 1})
    local panel = UI.frame(main, "Panel", 0, 0, 864, DESKTOP_HEIGHT, T.Shell, 14)
    panel.Active = true
    self.Panel = panel
    self.Shadow = Shadow.new(panel, 14)
    UI.stroke(panel, T.Line)
    BrandArt.panel(rt, panel)
    self.TopEdge = UI.frame(panel, "TopEdge", 12, 0, 840, 1, T.Secondary)
    self.TopEdge.BackgroundTransparency = 0.88

    local sidebar = UI.frame(main, "Sidebar", 0, 0, 228, 660, T.Sidebar, 14)
    self.Sidebar = sidebar
    sidebar.Active = true
    self.SidebarShadow = Shadow.new(sidebar, 14)
    UI.stroke(sidebar, T.Line)
    BrandArt.sidebar(rt, sidebar)
    local brandTile = UI.frame(sidebar, "BrandTile", 21, 24, 30, 30, T.AccentWash, 7)
    UI.stroke(brandTile, T.AccentSoft).Transparency = 0.65
    UI.mark(brandTile, 5, 5, 20)
    UI.text(sidebar, "Brand", options.Title or "lumi", 60, 21, 110, 32, 27, T.Text, T.Brand)
    sidebar.Brand:SetAttribute("LumiUserText", true)
    UI.micro(sidebar, "BrandSub", Textos.interfaz, 21, 65, 145, 14)
    UI.micro(sidebar, "Group", Textos.principal, 22, 115, 140, 16)
    sidebar.Group.Visible = false
    self.Navigation = UI.new("ScrollingFrame", sidebar, {
        Name = "Navigation", Position = UDim2.fromOffset(12, 153), Size = UDim2.new(1, -24, 1, -258),
        ScrollBarThickness = 2, ScrollBarImageColor3 = T.Muted, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    self.NavigationUI = Navigation.new(self)
    self.NavigationGroups = self.NavigationUI.Groups
    self.Profile = Profile.new(self, options)
    self.SidebarFooter = self.Profile.Frame
    self.Settings = Settings.new(self)
    local navClose = UI.button(sidebar, "CloseNavigation", "", 0, 6, 44, 44)
    UI.icon(navClose, "Close", 14, 14, T.Secondary)
    rt:Connect(navClose.Activated, function() self:ToggleNavigation(false) end)
    self.NavigationCloseButton = navClose

    local chrome = UI.frame(panel, "Chrome", 184, 0, 680, 48)
    self.Chrome = chrome
    local drag = UI.button(chrome, "TitleDrag", "", 0, 0, 862, 48)
    self.Breadcrumb = UI.text(drag, "Breadcrumb", Textos.espacio .. " / " .. Textos.inicio, 26, 0, 400, 48, 13, T.Secondary, T.Medium)
    local home = UI.button(chrome, "Home", "", 14, 7, 30, 30)
    home.ZIndex = 2
    UI.corner(home, 5)
    UI.icon(home, "Home", 7, 7, T.Secondary)
    UI.hover(rt, home, T.Shell, T.Hover)
    rt:Connect(home.Activated, function() self:GoHome() end)
    self.HomeButton = home
    UI.chevron(drag, 49, 22, T.Muted, true)
    local close = UI.button(chrome, "Close", "", 872, 9, 30, 30)
    UI.corner(close, 5)
    UI.icon(close, "Close", 7, 7, T.Secondary)
    UI.hover(rt, close, T.Shell, T.Hover)
    rt:Connect(close.Activated, function() self:Close() end)
    self.CloseButton = close
    local minimize = UI.button(chrome, "Minimize", "", 600, 9, 30, 30)
    UI.corner(minimize, 5)
    UI.icon(minimize, "Minus", 7, 7, T.Secondary)
    UI.hover(rt, minimize, T.Shell, T.Hover)
    rt:Connect(minimize.Activated, function() self:Minimize() end)
    self.MinimizeButton = minimize
    local menu = UI.button(chrome, "NavigationMenu", "", 8, 6, 44, 44)
    UI.icon(menu, "Menu", 14, 14, T.Secondary)
    self.MenuButton = menu
    rt:Connect(menu.Activated, function() self:ToggleNavigation() end)
    UI.line(chrome, 0, 47, 916)
    self.Search = Search.new(self)

    self.Workspace = UI.frame(panel, "Workspace", 184, 48, 680, 584, T.Workspace)
    self.Workspace.BackgroundTransparency = 1
    self.Workspace.ClipsDescendants = true
    self.Context = Inspector.new(self)

    local status = UI.frame(panel, "Statusbar", 184, 632, 680, 28, T.Shell)
    UI.corner(status, 12)
    self.Statusbar = status
    UI.line(status, 0, 0, 916)
    local version = UI.text(status, "Version", "LUAU  /  LUMI 0.4.20", 730, 0, 160, 28, 11, T.Muted, T.Mono)
    version.TextXAlignment = Enum.TextXAlignment.Right
    self.StatusVersion = version
    self.Blocker = UI.button(root, "PopoverDismiss", "", 0, 0, 0, 0)
    self.Blocker.Size = UDim2.fromScale(1, 1)
    self.Blocker.ZIndex = 90
    self.Blocker.Visible = false
    rt:Connect(self.Blocker.Activated, function() self:ClosePopup(true) end)

    rt:Connect(drag.InputBegan, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        self:ClosePopup()
        local start, origin = input.Position, self.Center
        self:BeginPointer(input, function(position)
            local delta = Vector2.new(position.X - start.X, position.Y - start.Y)
            self:SetCenter(origin + delta, true)
        end, function() self.Presentation:SettleFollow() end)
    end)
    rt:Connect(Input.InputChanged, function(input)
        if not self._pointer then return end
        if input == self._pointer or (self._pointer.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then
            self._pointerUpdate(input.Position)
        end
    end)
    rt:Connect(Input.InputEnded, function(input)
        if input == self._pointer or (input.UserInputType == Enum.UserInputType.MouseButton1 and self._pointer and self._pointer.UserInputType == Enum.UserInputType.MouseButton1) then self:EndPointer() end
    end)
    rt:Connect(Input.WindowFocusReleased, function() self:EndPointer(); self:ClosePopup() end)
    rt:Connect(Input.InputBegan, function(input, processed)
        if input.KeyCode == Enum.KeyCode.Escape then self:ClosePopup(true); self:EndPointer() end
        if processed or Input:GetFocusedTextBox() or input.KeyCode ~= self.ToggleKey then return end
        for index = #liveWindows, 1, -1 do
            local target = liveWindows[index]
            if not target._closing and not target._destroyed and target.ToggleKey == self.ToggleKey then
                if target == self then
                    if self.Minimized then self:Restore() else self:Minimize() end
                end
                break
            end
        end
    end)
    local viewport = UI.new("Frame", root, {Name = "Viewport", Size = UDim2.fromScale(1, 1)})
    self.Viewport = viewport
    self.Motion = Motion.new(rt, main)
    self.Presentation = Presentation.new(self)
    rt:Connect(viewport:GetPropertyChangedSignal("AbsoluteSize"), function() self:Fit() end)
    rt:OnCleanup(function()
        self._destroyed = true
        local index = table.find(liveWindows, self)
        if index then table.remove(liveWindows, index) end
        self:EndPointer()
        self:ClosePopup()
    end)
    self:Fit()
    table.insert(liveWindows, self)
    self.Locale = Locale.new(self, self.Language)
    task.defer(function()
        if self._destroyed or self._closing or self._entranceInterrupted or rt.Animations == false then return end
        self.UIScale.Scale = self.Scale * 0.99
        rt:Tween(self.UIScale, {Scale = self.Scale}, Motion.Time.Open)
        self.Motion:Fade(0.8, 0, Motion.Time.Open)
    end)
    return self
end

function Window:FinishEntrance(interrupt)
    if interrupt ~= false then self._entranceInterrupted = true end
    if self.Presentation and self.Presentation.State ~= "expanded" then return end
    if self._closing or not self.Motion.Active then return end
    self.Motion:Finish()
    self.Runtime:CancelTween(self.UIScale)
    self.UIScale.Scale = self.Scale
end

function Window:Fit()
    if self._destroyed or self._closing then return end
    local size = self.Viewport.AbsoluteSize
    if size.X <= 0 or size.Y <= 0 then return end
    if self._lastViewport == size then return end
    local resized = self._lastViewport ~= nil
    self._lastViewport = size
    self:FinishEntrance(resized)
    self:ClosePopup()
    local compact = size.X < 1132 or size.Y < DESKTOP_HEIGHT + 32
    self.Width = compact and math.max(280, math.min(1100, size.X - 32)) or 1100
    self.Mobile = size.X < 700 or Input.TouchEnabled
    local inset = GuiService:GetGuiInset()
    self.SafeTop = self.Mobile and math.max(8, inset.Y + 8) or 8
    local verticalMargin = self.Mobile and self.SafeTop + 8 or 32
    self.Height = math.max(280, math.min(self.Mobile and 768 or PREFERRED_HEIGHT, size.Y - verticalMargin))
    if not self.Mobile then self.NavigationOpen = false end
    self.SidebarWidth = self.Mobile and self.Width or 228
    local sideWidth = self.SidebarWidth
    self.Inspector.Visible = not compact and not self.Mobile and self.Preferences.Inspector
    self.PanelWidth = self.Width - (self.Inspector.Visible and INSPECTOR_WIDTH + PANEL_GAP or 0)
    self.ContentX = self.Mobile and 0 or sideWidth + PANEL_GAP
    self.Main.Size = UDim2.fromOffset(self.Width, self.Height)
    self.Panel.Position = UDim2.fromOffset(self.ContentX, 0)
    self.Panel.Size = UDim2.fromOffset(self.PanelWidth - self.ContentX, self.Height)
    self.Panel.Visible = not (self.Mobile and self.NavigationOpen)
    self.Sidebar.Visible = not self.Mobile or self.NavigationOpen == true
    self.TopEdge.Size = UDim2.fromOffset(self.Panel.Size.X.Offset - 24, 1)
    self.Sidebar.Size = UDim2.fromOffset(sideWidth, self.Height)
    self.Sidebar.Brand.Size = UDim2.fromOffset(sideWidth - (self.Mobile and 124 or 70), 30)
    self.Sidebar.BrandSub.Size = UDim2.fromOffset(sideWidth - 40, 14)
    self.Sidebar.BrandSub.Text = Fonts.tracked(sideWidth < 170 and Textos.biblioteca or Textos.interfaz)
    local short = self.Height < 480
    local navTop = short and 88 or 106
    self.Sidebar.BrandSub.Position = UDim2.fromOffset(21, short and 60 or 65)
    self.Sidebar.BrandWaves.Visible = not short
    self.Sidebar.Group.Position = UDim2.fromOffset(22, short and 84 or 115)
    self.Navigation.Position = UDim2.fromOffset(12, navTop)
    local footerHeight = self.Settings:Fit(sideWidth, short)
    self.Navigation.Size = UDim2.new(1, -24, 1, -(navTop + footerHeight))
    self.NavigationCloseButton.Position = UDim2.fromOffset(sideWidth - 52, 6)
    self.NavigationCloseButton.Visible = self.Mobile
    self.MenuButton.Visible = self.Mobile
    local chromeWidth = self.Panel.Size.X.Offset
    local chromeHeight = self.Mobile and 56 or 44
    local buttonSize = self.Mobile and 44 or 30
    self.Chrome.Position = UDim2.fromOffset(0, 0)
    self.Chrome.Size = UDim2.fromOffset(chromeWidth, chromeHeight)
    self.CloseButton.Position = UDim2.fromOffset(chromeWidth - (self.Mobile and 48 or 44), self.Mobile and 6 or 7)
    self.MinimizeButton.Position = UDim2.fromOffset(chromeWidth - (self.Mobile and 96 or 80), self.Mobile and 6 or 7)
    self.CloseButton.Size = UDim2.fromOffset(buttonSize, buttonSize)
    self.MinimizeButton.Size = UDim2.fromOffset(buttonSize, buttonSize)
    self.CloseButton.Icon.Position = UDim2.fromOffset((buttonSize - 16) / 2, (buttonSize - 16) / 2)
    self.MinimizeButton.Icon.Position = self.CloseButton.Icon.Position
    local searchX = self.Search:Fit(chromeWidth, chromeHeight, self.Mobile)
    local dragX = self.Mobile and 56 or 0
    local dragWidth = math.max(1, searchX - dragX - 8)
    self.Chrome.TitleDrag.Position = UDim2.fromOffset(dragX, 0)
    self.Chrome.TitleDrag.Size = UDim2.fromOffset(dragWidth, chromeHeight)
    self.HomeButton.Visible = not self.Mobile
    self.Chrome.TitleDrag.Chevron.Visible = not self.Mobile
    self.Breadcrumb.Position = UDim2.fromOffset(self.Mobile and 8 or 64, 0)
    self.Breadcrumb.Size = UDim2.fromOffset(math.max(1, dragWidth - (self.Mobile and 12 or 76)), chromeHeight)
    self.Workspace.Position = UDim2.fromOffset(0, chromeHeight)
    self.Workspace.Size = UDim2.fromOffset(chromeWidth, self.Height - chromeHeight - (self.Mobile and 0 or 28))
    self.Inspector.Position = UDim2.fromOffset(self.PanelWidth + PANEL_GAP, 0)
    self.Inspector.Size = UDim2.fromOffset(INSPECTOR_WIDTH, self.Height)
    self.Statusbar.Visible = not self.Mobile
    self.Statusbar.Position = UDim2.fromOffset(0, self.Height - 28)
    self.Statusbar.Size = UDim2.fromOffset(chromeWidth, 28)
    self.Chrome.Rule.Size = UDim2.fromOffset(chromeWidth, 1)
    self.Chrome.Rule.Position = UDim2.fromOffset(0, chromeHeight - 1)
    self.Statusbar.Rule.Size = UDim2.fromOffset(chromeWidth, 1)
    self.StatusVersion.Position = UDim2.fromOffset(chromeWidth - 186, 0)
    self.StatusVersion.Visible = chromeWidth >= 650
    self.Scale = math.min(1, math.max(0.1, (size.X - 32) / self.Width), math.max(0.1, (size.Y - verticalMargin) / self.Height))
    self.UIScale.Scale = self.Scale
    for _, tab in ipairs(self.Tabs) do tab:Relayout() end
    self:SetCenter(self.Center or size / 2)
    self.Presentation:Fit()
end

function Window:SetCenter(center, follow)
    if not follow then self.Presentation:FinishTransition() end
    local previous = self.Center
    local size = self.Viewport.AbsoluteSize
    local half = Vector2.new(self.Width * self.Scale / 2, self.Height * self.Scale / 2)
    local x = math.clamp(center.X, half.X + 8, math.max(half.X + 8, size.X - half.X - 8))
    local top = self.SafeTop or 8
    local y = math.clamp(center.Y, half.Y + top, math.max(half.Y + top, size.Y - half.Y - 8))
    self.Center = Vector2.new(x, y)
    self.Main.Position = UDim2.fromOffset(x, y)
    if follow and previous then self.Presentation:Follow(self.Center - previous)
    else self.Presentation:StopFollow() end
end

function Window:BeginPointer(input, update, finish)
    if self._destroyed or self._closing or self.Minimized then return end
    self:FinishEntrance()
    self:EndPointer()
    self._pointer, self._pointerUpdate, self._pointerFinish = input, update, finish
end

function Window:EndPointer()
    local finish = self._pointerFinish
    self._pointer, self._pointerUpdate, self._pointerFinish = nil, nil, nil
    if finish then finish() end
end

function Window:ClosePopup(animated)
    if self._retiringPopup then
        local retiring = self._retiringPopup
        self._retiringPopup = nil
        retiring.Popup:Destroy()
        retiring.Cleanup()
    end
    local popup = self.OpenDropdown
    local cleanup, motion = self._popupCleanup, self._popupMotion
    self.OpenDropdown = nil
    self._popupCleanup, self._popupMotion = nil, nil
    self.PopupOwner = nil
    if self.Blocker then self.Blocker.Visible = false end
    if not popup then return end
    local selected = GuiService.SelectedObject
    if selected and selected:IsDescendantOf(popup) then GuiService.SelectedObject = nil end
    for _, item in ipairs(popup:GetDescendants()) do
        if item:IsA("GuiButton") then item.Selectable = false; item.Active = false end
    end
    if animated and self.Runtime.Animations ~= false and not self._destroyed and not self._closing and motion then
        -- Remove interaction immediately while its short visual exit finishes.
        local shield = UI.button(popup, "Dismissed", "", 0, 0, 0, 0)
        shield.Size, shield.ZIndex = UDim2.fromScale(1, 1), 150
        shield.Selectable = false
        local retiring = {Popup = popup, Cleanup = cleanup}
        self._retiringPopup = retiring
        motion:Fade(0, 1, Motion.Time.Dismiss, function()
            if self._retiringPopup ~= retiring then return end
            self._retiringPopup = nil
            popup:Destroy()
            cleanup()
        end)
    else
        popup:Destroy()
        if cleanup then cleanup() end
    end
end

Window._closeDropdown = Window.ClosePopup

function Window:Focus(control)
    if self._destroyed or self._closing then return end
    local changed = self.SelectedControl ~= control
    if self.SelectedControl and self.SelectedControl.FocusIndicator then
        self.SelectedControl.FocusIndicator.Visible = false
        self.SelectedControl.SelectionWash.Visible = false
    end
    self.SelectedControl = control
    if control.SelectionWash then control.SelectionWash.Visible = true end
    if control.FocusIndicator then
        control.FocusIndicator.Visible = true
        if changed then
            control.FocusIndicator.Size = UDim2.fromOffset(1, 0)
            self.Runtime:Tween(control.FocusIndicator, {Size = UDim2.new(0, 1, 1, -28)}, 0.12)
        end
    end
    self.Context:Update(control)
end

function Window:SetDetails(title, description, status)
    if self._destroyed then return end
    self.Context:Clear()
    self.DetailTitle.Text, self.DetailDescription.Text = title or Textos.detalles, description or ""
    self.Context:SetValue(status or Textos.listo)
end

function Window:AddTab(name, options)
    assert(not self._destroyed, "[Lumi UI] La ventana está cerrada")
    return Tab.new(self, name, options or {})
end

function Window:OpenSettings() return self.Settings:Open() end

function Window:SetLanguage(language)
    if not self.Locale:Set(language) then return false end
    self.Language, self.Preferences.Language = language, language
    if self.Settings.Controls.Language then self.Settings.Controls.Language:Set(language, true) end
    return true
end

function Window:GetLanguage() return self.Language end

function Window:GetNavigationGroup(name) return self.NavigationUI:GetGroup(name) end

function Window:ShowSettingsInNavigation(group, label) return self.Settings:ShowNavigation(group, label) end

function Window:OpenProfile() return self.Profile:Open() end

function Window:SetPreference(name, value) return self.Settings:Set(name, value) end

function Window:GoHome()
    for _, tab in ipairs(self.Tabs) do
        if tab ~= self.Settings.Tab and tab ~= self.Profile.Tab then self:SelectTab(tab); return tab end
    end
    return self.Settings.Tab
end

function Window:SelectTab(tab)
    if self._destroyed or self._closing or not table.find(self.Tabs, tab) then return end
    self:ToggleNavigation(false)
    if self.ActiveTab then self:FinishEntrance() end
    self:EndPointer()
    self:ClosePopup()
    if self.ActiveTab == tab then return end
    local previous = self.ActiveTab
    self.ActiveTab = tab
    self.Settings:SyncSelection(tab)
    tab:Relayout()
    for _, item in ipairs(self.Tabs) do
        item.Motion:Finish()
        self.Runtime:CancelTween(item.Page, "position")
        item.Page.Position = UDim2.fromOffset(0, 0)
        local active = item == tab
        item.Page.Visible = active
        local duration = previous and 0.12 or 0
        item:SetActive(active, duration)
    end
    if previous then
        tab.Page.Position = UDim2.fromOffset(0, 4)
        self.Runtime:Tween(tab.Page, {Position = UDim2.fromOffset(0, 0)}, Motion.Time.Page, "position")
        tab.Motion:Fade(0.35, 0, Motion.Time.Page)
    end
    self.Breadcrumb.Text = Textos.espacio .. " / " .. tab.Name
    self.NavigationUI:Reveal(tab)
    if self.SelectedControl and self.SelectedControl.FocusIndicator then
        self.SelectedControl.FocusIndicator.Visible = false
        self.SelectedControl.SelectionWash.Visible = false
    end
    self.SelectedControl = nil
    if tab.Controls[1] then self:Focus(tab.Controls[1]) else self:SetDetails(tab.Name, tab.Description, Textos.listo) end
end

function Window:ReleaseInput()
    local focused = Input:GetFocusedTextBox()
    if focused and focused:IsDescendantOf(self.Root) then focused:ReleaseFocus() end
    local selected = GuiService.SelectedObject
    if selected and selected:IsDescendantOf(self.Root) then GuiService.SelectedObject = nil end
end

function Window:FinishPages()
    for _, tab in ipairs(self.Tabs) do
        tab.Motion:Finish()
        self.Runtime:CancelTween(tab.Page, "position")
        tab.Page.Position = UDim2.fromOffset(0, 0)
    end
end

function Window:Minimize() return self.Presentation:Minimize() end
function Window:Restore() return self.Presentation:Restore() end
function Window:IsMinimized() return self.Minimized end

function Window:ToggleNavigation(open)
    if not self.Mobile or self._destroyed or self._closing or self.Minimized then return false end
    if open == nil then open = not self.NavigationOpen end
    if (self.NavigationOpen == true) == (open == true) then return false end
    self:FinishEntrance(); self:EndPointer(); self:ClosePopup(); self:ReleaseInput()
    self.NavigationOpen = open == true
    self.Sidebar.Visible, self.Panel.Visible = self.NavigationOpen, not self.NavigationOpen
    if self.NavigationOpen then self.NavigationUI:Reveal(self.ActiveTab) end
    return true
end

function Window:Close()
    if self._destroyed or self._closing then return end
    self:FinishEntrance()
    self.Presentation:FinishTransition()
    self:EndPointer()
    self.Presentation:StopFollow()
    self._closing = true
    self:ClosePopup()
    self:ReleaseInput()
    if self.Runtime.Animations == false then self:Destroy(); return end
    self:FinishPages()
    if self.Minimized then self.Presentation:CloseMinimized(); return end
    local shield = UI.button(self.Main, "ClosingShield", "", 0, 0, 0, 0)
    shield.Size, shield.ZIndex = UDim2.fromScale(1, 1), 200
    shield.Selectable = false
    self.Runtime:Tween(self.UIScale, {Scale = self.Scale * 0.99}, Motion.Time.Close)
    self.Motion:Fade(0, 1, Motion.Time.Close, function() self:Destroy() end)
end

function Window:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    self.Runtime:Destroy()
end

return Window
