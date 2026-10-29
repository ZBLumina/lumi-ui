-- Short, interruptible transitions. Original opacity is restored on interruption.
local Motion = {}
Motion.__index = Motion
Motion.Time = {Open = 0.22, Close = 0.16, Page = 0.14, Menu = 0.12, Dismiss = 0.08, Value = 0.10}

function Motion.new(runtime, root)
    local self = setmetatable({Runtime = runtime, Root = root, Snapshot = {}, Active = false, Generation = 0}, Motion)
    self.Value = Instance.new("NumberValue")
    runtime:Connect(self.Value.Changed, function() self:Apply(self.Value.Value) end)
    runtime:OnCleanup(function() self:Destroy() end)
    return self
end

function Motion:Apply(alpha)
    for _, item in ipairs(self.Snapshot) do
        item.Object[item.Property] = item.Base + (1 - item.Base) * alpha
    end
end

function Motion:Finish()
    self.Generation += 1
    self.Runtime:CancelDelay(self.Completion)
    self.Completion = nil
    self.Runtime:CancelTween(self.Value)
    self:Apply(0)
    table.clear(self.Snapshot)
    self.Active = false
end

function Motion:Fade(from, target, duration, complete)
    self:Finish()
    if self.Runtime.Destroyed then return end
    if self.Runtime.Animations == false then if complete then complete() end; return end
    local function capture(object, property)
        local base = object[property]
        if base < 1 then table.insert(self.Snapshot, {Object = object, Property = property, Base = base}) end
    end
    local objects = self.Root:GetDescendants()
    table.insert(objects, self.Root)
    for _, object in ipairs(objects) do
        if object:IsA("GuiObject") then capture(object, "BackgroundTransparency") end
        if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
            if object.Text ~= "" then capture(object, "TextTransparency") end
        elseif object:IsA("ImageLabel") or object:IsA("ImageButton") then capture(object, "ImageTransparency")
        elseif object:IsA("UIStroke") then capture(object, "Transparency") end
    end
    self.Active = true
    self.Value.Value = from
    self:Apply(from)
    local generation = self.Generation
    self.Runtime:Tween(self.Value, {Value = target}, duration)
    self.Completion = self.Runtime:Delay(duration, function()
        if self.Generation ~= generation then return end
        self.Completion = nil
        self.Runtime:CancelTween(self.Value)
        self:Apply(target)
        self.Active = false
        if target == 0 then table.clear(self.Snapshot) end
        if complete then complete() end
    end)
end

function Motion:Destroy()
    self:Finish()
    self.Value:Destroy()
end

return Motion
