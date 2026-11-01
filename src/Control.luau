local Runtime = require("Runtime")
local UI = require("UI")
local PropertyLayout = require("PropertyLayout")
local Control = {}

function Control.id(section, options, kind)
    local w = section.Tab.Window
    local explicit = options.Id ~= nil
    local id = explicit and tostring(options.Id) or section.Tab.Id .. "/" .. section.Id .. "/" .. tostring(options.Name or kind)
    assert(id ~= "", "[Lumi UI] El ID no puede estar vacío")
    if explicit then assert(not w.ControlsById[id], "[Lumi UI] ID de control duplicado: " .. id)
    else
        local base, suffix = id, 2
        while w.ControlsById[id] do id = base .. "#" .. suffix; suffix += 1 end
    end
    return id
end

function Control.attach(c, options, id)
    local w = c.Section.Tab.Window
    c.Id, c.Options, c.Enabled, c._destroyed = id, options, options.Enabled ~= false, false
    c.Persist = options.Persist ~= false and c.Kind ~= "Button" and options.ReadOnly ~= true
    local rt = Runtime.new()
    rt.Animations = w.Runtime.Animations
    rt.OnError = function(problem) if w.Runtime.OnError then w.Runtime.OnError(problem) end end
    c.ParentCleanup=w.Runtime:OnCleanup(function() c:Destroy() end)
    c.Runtime = rt
    w.ControlsById[id] = c
    function c:IsEnabled() return not self._destroyed and self.Enabled end
    function c:CanInteract() return self:IsEnabled() and not w._closing and not w.Minimized end
    function c:Changed()
        if self.Persist and not self._destroyed and w.Profiles and not w._applyingState then w.Profiles:Changed() end
    end
    function c:SetEnabled(enabled)
        if self._destroyed then return false end
        enabled = enabled == true
        local changed = self.Enabled ~= enabled
        self.Enabled = enabled
        self.Row.GroupTransparency = enabled and 0 or .48
        for _,object in ipairs(self.Row:GetDescendants()) do
            if object:IsA("GuiButton") then
                object.Active, object.Selectable, object.Interactable = enabled, enabled, enabled
            elseif object:IsA("TextBox") then
                object.Active, object.Selectable = enabled, enabled
                object.TextEditable = enabled and not self.ReadOnly
            end
        end
        if not enabled then
            if w.PopupOwner == self then w:ClosePopup() end
            if w.SelectedControl == self then w:EndPointer() end
            local focused = game:GetService("UserInputService"):GetFocusedTextBox()
            if focused and focused:IsDescendantOf(self.Row) then focused:ReleaseFocus(false) end
        end
        if changed then self:Changed() end
        return changed
    end
    function c:Update(patch)
        if self._destroyed or type(patch) ~= "table" then return false, "Actualización no válida" end
        if patch.Id and patch.Id ~= self.Id then return false, "El ID del control no se puede cambiar" end
        if patch.Name ~= nil and type(patch.Name) ~= "string" then return false, "Nombre no válido" end
        if patch.Description ~= nil and type(patch.Description) ~= "string" then return false, "Descripción no válida" end
        if patch.Callback ~= nil and patch.Callback ~= false and type(patch.Callback) ~= "function" then return false, "Callback no válido" end
        if patch.Value ~= nil and not self.Set then return false, "Este control no acepta valores" end
        if patch.Name then self.Name, options.Name, self.Label.Text = patch.Name, patch.Name, patch.Name end
        if patch.Description then self.Description, options.Description, self.DescriptionLabel.Text = patch.Description, patch.Description, patch.Description end
        if patch.Callback ~= nil then options.Callback = patch.Callback end
        if patch.Action and self.Kind == "Button" then
            options.Action, self.Input.Text = tostring(patch.Action), tostring(patch.Action)
            self.ControlWidth = PropertyLayout.inputWidth(self.Input.Text, self.Input.FontFace, self.Input.TextSize, 144, 280)
        end
        if patch.Placeholder and self.Kind == "Input" then self.Input.PlaceholderText = tostring(patch.Placeholder) end
        if patch.Value ~= nil then self:Set(patch.Value, patch.Silent == true) end
        if patch.Enabled ~= nil then self:SetEnabled(patch.Enabled) end
        if patch.Visible ~= nil then self.Row.Visible = patch.Visible == true end
        self:Relayout(); self:Refresh()
        return true
    end
    function c:Destroy()
        if self._destroyed then return end
        self._destroyed = true
        if not w.Runtime.Destroyed then w.Runtime:RemoveCleanup(self.ParentCleanup) end
        self.ParentCleanup=nil
        if w.PopupOwner == self then w:ClosePopup() end
        if w.SelectedControl == self then
            w:EndPointer(); w.SelectedControl = nil
            if not w._destroyed then w:SetDetails() end
        end
        w.ControlsById[self.Id] = nil
        for _,array in ipairs({self.Section.Controls, self.Section.Tab.Controls}) do
            local index = table.find(array, self)
            if index then table.remove(array, index) end
        end
        rt:Destroy()
        if not self._rowDestroying and self.Row.Parent then self.Row:Destroy() end
        if self.Persist and not w._destroyed and w.Profiles and not w._applyingState then w.Profiles:Changed() end
    end
    rt:Connect(c.Row.Destroying, function() c._rowDestroying=true; c:Destroy() end)
    return c
end

function Control.finish(c)
    local nativeGet, nativeSet, nativePress, nativeOpen = c.Get, c.Set, c.Press, c.Open
    c.Get = function(self) if not c._destroyed and nativeGet then return nativeGet(self) end end
    if nativeSet then c.Set = function(self, ...)
        if c._destroyed then return false end
        local changed = nativeSet(self, ...)
        if changed then c:Changed() end
        return changed
    end end
    if nativePress then c.Press = function(self, ...)
        if not c:CanInteract() then return false end
        return nativePress(self, ...)
    end end
    if nativeOpen then c.Open = function(self, ...)
        if not c:CanInteract() then return nil end
        return nativeOpen(self, ...)
    end end
    function c:Activate()
        if not self:CanInteract() then return false end
        if self.Kind == "Button" then return self:Press()
        elseif self.Kind == "Toggle" then return self:Set(not self:Get())
        elseif self.Kind == "Dropdown" then self:Open(); return true
        else
            local field = self.ValueInput or self.Input
            if field:IsA("TextBox") then field:CaptureFocus(); return true end
        end
        return false
    end
    c:SetEnabled(c.Enabled)
    return c
end

return Control
