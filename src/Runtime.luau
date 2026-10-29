local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Runtime = {}
Runtime.__index = Runtime

function Runtime.new()
    return setmetatable({Connections = {}, Tweens = {}, Threads = {}, Cleanups = {}, Destroyed = false}, Runtime)
end

function Runtime:Connect(signal, callback)
    if self.Destroyed then return nil end
    local connection = signal:Connect(function(...)
        if not self.Destroyed then callback(...) end
    end)
    table.insert(self.Connections, connection)
    return connection
end

function Runtime:Tween(object, properties, duration)
    if self.Destroyed then return end
    local previous = self.Tweens[object]
    if previous then previous:Cancel() end
    local animation = TweenService:Create(object,
        TweenInfo.new(duration or 0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), properties)
    self.Tweens[object] = animation
    animation:Play()
end

function Runtime:Callback(callback, ...)
    if self.Destroyed or type(callback) ~= "function" then return end
    local args = table.pack(...)
    local thread
    thread = coroutine.create(function()
        if self.Destroyed then self.Threads[thread] = nil; return end
        local ok, problem = pcall(callback, table.unpack(args, 1, args.n))
        self.Threads[thread] = nil
        if not ok then warn("[Lumi UI] callback error: " .. tostring(problem)) end
    end)
    self.Threads[thread] = true
    task.spawn(thread)
end

function Runtime:OnCleanup(callback)
    table.insert(self.Cleanups, callback)
end

function Runtime:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    for _, connection in ipairs(self.Connections) do connection:Disconnect() end
    for _, animation in pairs(self.Tweens) do animation:Cancel() end
    table.clear(self.Tweens)
    local current = coroutine.running()
    for thread in pairs(self.Threads) do
        if thread ~= current and coroutine.status(thread) ~= "dead" then pcall(task.cancel, thread) end
    end
    table.clear(self.Threads)
    for _, cleanup in ipairs(self.Cleanups) do pcall(cleanup) end
    table.clear(self.Cleanups)
    if self.Root then self.Root:Destroy() end
end

function Runtime:Mount()
    local candidates = {}
    if type(gethui) == "function" then
        local ok, parent = pcall(gethui)
        if ok and typeof(parent) == "Instance" then table.insert(candidates, parent) end
    end
    table.insert(candidates, game:GetService("CoreGui"))
    if Players.LocalPlayer then
        local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if playerGui then table.insert(candidates, playerGui) end
    end
    local root = Instance.new("ScreenGui")
    root.Name = "LumiUI"
    root.ResetOnSpawn = false
    root.IgnoreGuiInset = true
    root.DisplayOrder = 100
    root.ZIndexBehavior = Enum.ZIndexBehavior.Global
    for _, parent in ipairs(candidates) do
        local ok = pcall(function() root.Parent = parent end)
        if ok then break end
    end
    assert(root.Parent, "[Lumi UI] No writable GUI parent")
    -- Remove the pre-modular pilot root when upgrading from v0.3.
    local legacy = root.Parent:FindFirstChild("LumiUIPilot_v01")
    if legacy then legacy:Destroy() end
    self.Root = root
    self:Connect(root.Destroying, function() self:Destroy() end)
    return root
end

return Runtime
