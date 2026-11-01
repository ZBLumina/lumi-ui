local Input = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Keyboard = {}
Keyboard.__index = Keyboard
local live = {}

local function available(self)
    local w = self.Window
    return not self.Destroyed and not w.Runtime.Destroyed and not w._destroyed and not w._closing
        and not w.Minimized and w.Root.Parent ~= nil and w.Root.Enabled and w.Main.Visible
end

local function shown(object, root)
    if typeof(object) ~= "Instance" or not object:IsA("GuiObject") or not object:IsDescendantOf(root) then return false end
    local ancestor = object
    while ancestor ~= root do
        if ancestor:IsA("GuiObject") and not ancestor.Visible then return false end
        ancestor = ancestor.Parent
    end
    return root.Enabled
end

local function owner()
    local selected = GuiService.SelectedObject
    for index = #live, 1, -1 do
        local self = live[index]
        if available(self) and (not selected or selected:IsDescendantOf(self.Window.Root)) then return self end
    end
end

local function reveal(self, object)
    local w, ancestor = self.Window, object.Parent
    local scale = math.max(.01, w.Scale or 1)
    while ancestor and ancestor ~= w.Root do
        if ancestor:IsA("ScrollingFrame") then
            local height = ancestor.AbsoluteWindowSize.Y / scale
            local top = (object.AbsolutePosition.Y - ancestor.AbsolutePosition.Y) / scale + ancestor.CanvasPosition.Y
            local bottom = top + object.AbsoluteSize.Y / scale
            local y = ancestor.CanvasPosition.Y
            if top < y then y = top - 8 elseif bottom > y + height then y = bottom - height + 8 end
            local limit = math.max(0, ancestor.AbsoluteCanvasSize.Y / scale - height)
            ancestor.CanvasPosition = Vector2.new(ancestor.CanvasPosition.X, math.clamp(y, 0, limit))
        end
        ancestor = ancestor.Parent
    end
end

function Keyboard:GetTargets()
    local w, result, seen = self.Window, {}, {}
    self.Actions, self.Controls = {}, {}
    if not available(self) or w.PopupOwner or w.OpenDropdown then return result end
    local function add(object, action, control, scope)
        if not shown(object, w.Root) or seen[object] or not object.Active then return end
        if object:IsA("GuiButton") and not object.Interactable then return end
        seen[object], object.Selectable = true, true
        self.Actions[object], self.Controls[object] = action, control
        if action and object:IsA("GuiButton") and not self.Native[object]
            and not (control and control.Kind == "Slider") then
            local native = {Count = 0}
            self.Native[object] = native
            local runtime = scope or (control and control.Runtime) or w.Runtime
            runtime:Connect(object.Activated, function(input)
                if input and input.UserInputType == Enum.UserInputType.Keyboard then
                    native.Count += 1
                    native.Input = input
                end
            end)
        end
        table.insert(result, object)
    end
    add(w.HomeButton, function() w:GoHome() end)
    add(w.MenuButton, function() w:ToggleNavigation() end)
    add(w.Search and w.Search.Button, function() w.Search:Open() end)
    add(w.MinimizeButton, function() w:Minimize() end)
    add(w.CloseButton, function() w:Close() end)
    add(w.NavigationCloseButton, function() w:ToggleNavigation(false) end)
    for _, tab in ipairs(w.Tabs) do add(tab.Button, function() w:SelectTab(tab) end) end
    add(w.Profile and w.Profile.Frame, function() w:OpenProfile() end)
    add(w.SettingsButton, function() w:OpenSettings() end)
    for _, control in ipairs(w.ActiveTab and w.ActiveTab.Controls or {}) do
        if not control._destroyed and control.Enabled ~= false and not control.Runtime.Destroyed
            and w.ControlsById[control.Id] == control then
            local function activate() control:Activate() end
            add(control.Input, activate, control)
            add(control.ValueInput, activate, control)
        end
    end
    if w.Notifications and type(w.Notifications.GetTargets) == "function" then
        -- Notification records share the same native-first activation path.
        for _, target in ipairs(w.Notifications:GetTargets()) do
            if type(target) == "table" and type(target.Activate) == "function" then
                add(target.Object, function() target:Activate() end,nil,target.Runtime)
            else
                add(target)
            end
        end
    end
    return result
end

function Keyboard:Focus(target)
    local w = self.Window
    if not available(self) or w.PopupOwner or w.OpenDropdown then return false end
    local object = type(target) == "table" and (target.Input or target.ValueInput) or target
    if not table.find(self:GetTargets(), object) then return false end
    local editor = Input:GetFocusedTextBox()
    if editor and editor ~= object then editor:ReleaseFocus(false) end
    w:FinishEntrance()
    w:FinishPages()
    GuiService.SelectedObject = object
    local control = self.Controls[object]
    if control then w:Focus(control) end
    reveal(self, object)
    return true
end

function Keyboard:Step(reverse)
    if not available(self) or self.Window.PopupOwner or self.Window.OpenDropdown or Input:GetFocusedTextBox() then return false end
    local targets = self:GetTargets()
    if #targets == 0 then return false end
    local index = table.find(targets, GuiService.SelectedObject)
    if not index then index = reverse and 1 or 0 end
    return self:Focus(targets[(index - 1 + (reverse and -1 or 1)) % #targets + 1])
end

function Keyboard.new(window)
    local self = setmetatable({Window = window, Actions = {}, Controls = {}, Keys = {},
        Native = setmetatable({}, {__mode = "k"}), Destroyed = false}, Keyboard)
    local rt = window.Runtime
    table.insert(live, self)
    rt:OnCleanup(function()
        self.Destroyed = true
        local selected, editor = GuiService.SelectedObject, Input:GetFocusedTextBox()
        if selected and selected:IsDescendantOf(window.Root) then GuiService.SelectedObject = nil end
        if editor and editor:IsDescendantOf(window.Root) then editor:ReleaseFocus(false) end
        local index = table.find(live, self)
        if index then table.remove(live, index) end
        table.clear(self.Actions); table.clear(self.Controls); table.clear(self.Keys); table.clear(self.Native)
    end)
    rt:Connect(GuiService:GetPropertyChangedSignal("SelectedObject"), function()
        local selected = GuiService.SelectedObject
        if not available(self) or window.PopupOwner or window.OpenDropdown or not shown(selected, window.Root) then return end
        self:GetTargets()
        local control = self.Controls[selected]
        if control then window:Focus(control) end
    end)
    rt:Connect(Input.TextBoxFocused, function(editor)
        if not available(self) or window.PopupOwner or window.OpenDropdown or not editor:IsDescendantOf(window.Root) then return end
        -- Editing owns Space/Enter; a separately selected button must not consume them.
        local selected = GuiService.SelectedObject
        if selected and selected:IsDescendantOf(window.Root) then GuiService.SelectedObject = nil end
        table.clear(self.Keys)
    end)
    rt:Connect(window.Root.DescendantRemoving, function(object)
        local selected = GuiService.SelectedObject
        if selected and (selected == object or selected:IsDescendantOf(object)) then GuiService.SelectedObject = nil end
    end)
    rt:Connect(Input.InputEnded, function(input)
        local press = self.Keys[input.KeyCode]
        self.Keys[input.KeyCode] = nil
        if type(press) ~= "table" then return end
        -- Let the engine's release/Activated callbacks finish before supplying a fallback.
        rt:Delay(0, function()
            if not available(self) or Input:GetFocusedTextBox() or window.PopupOwner or window.OpenDropdown
                or GuiService.SelectedObject ~= press.Object then return end
            local native = press.Native
            if native and (native.Count ~= press.Count or native.Input == press.Input) then return end
            self:GetTargets()
            local action = self.Actions[press.Object]
            if action then action() end
        end)
    end)
    rt:Connect(Input.WindowFocusReleased, function() table.clear(self.Keys) end)
    rt:Connect(Input.InputBegan, function(input)
        local key = input.KeyCode
        if input.UserInputType ~= Enum.UserInputType.Keyboard or self.Keys[key] or owner() ~= self
            or Input:GetFocusedTextBox() or window.PopupOwner or window.OpenDropdown then return end
        if key == Enum.KeyCode.Tab then
            self.Keys[key] = true
            self:Step(Input:IsKeyDown(Enum.KeyCode.LeftShift) or Input:IsKeyDown(Enum.KeyCode.RightShift))
        elseif key == Enum.KeyCode.Return or key == Enum.KeyCode.KeypadEnter or key == Enum.KeyCode.Space then
            self:GetTargets()
            local selected = GuiService.SelectedObject
            if self.Actions[selected] then
                local native = self.Native[selected]
                self.Keys[key] = {Object = selected, Input = input, Native = native, Count = native and native.Count}
            end
        end
    end)
    return self
end

return Keyboard
