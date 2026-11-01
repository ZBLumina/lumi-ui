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

function Runtime:CancelTween(object, channel)
    local channels = self.Tweens[object]
    if not channels then return end
    channel = channel or "style"
    if channels[channel] then channels[channel]:Cancel(); channels[channel] = nil end
    if next(channels) == nil then self.Tweens[object] = nil end
end

function Runtime:Tween(object, properties, duration, channel)
    if self.Destroyed then return end
    channel = channel or "style"
    self:CancelTween(object, channel)
    if self.Animations == false or duration == 0 then
        for property, value in pairs(properties) do object[property] = value end
        return
    end
    local animation = TweenService:Create(object,
        TweenInfo.new(duration or 0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), properties)
    self.Tweens[object] = self.Tweens[object] or {}
    self.Tweens[object][channel] = animation
    animation:Play()
    return animation
end

function Runtime:Delay(duration, callback)
    if self.Destroyed then return end
    local thread
    thread = coroutine.create(function()
        if self.Destroyed then self.Threads[thread] = nil; return end
        local ok, problem = pcall(callback)
        self.Threads[thread] = nil
        if not ok then warn("[Lumi UI] error en la tarea programada: " .. tostring(problem)) end
    end)
    self.Threads[thread] = true
    task.delay(duration, thread)
    return thread
end

function Runtime:CancelDelay(thread)
    if thread and self.Threads[thread] and thread ~= coroutine.running() then
        self.Threads[thread] = nil
        if coroutine.status(thread) ~= "dead" then pcall(task.cancel, thread) end
    end
end

function Runtime:Callback(callback, ...)
    if self.Destroyed or type(callback) ~= "function" then return end
    local args = table.pack(...)
    local thread
    thread = coroutine.create(function()
        if self.Destroyed then self.Threads[thread] = nil; return end
        local ok, problem = pcall(callback, table.unpack(args, 1, args.n))
        self.Threads[thread] = nil
        if not ok then
            warn("[Lumi UI] error en la función: " .. tostring(problem))
            if type(self.OnError)=="function" then pcall(self.OnError,problem) end
        end
    end)
    self.Threads[thread] = true
    task.spawn(thread)
    return thread
end

function Runtime:OnCleanup(callback)
    table.insert(self.Cleanups, callback)
    return callback
end

function Runtime:RemoveCleanup(callback)
    local index=table.find(self.Cleanups,callback)
    if index then table.remove(self.Cleanups,index) end
end

function Runtime:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    for _, connection in ipairs(self.Connections) do connection:Disconnect() end
    for _, channels in pairs(self.Tweens) do
        for _, animation in pairs(channels) do animation:Cancel() end
    end
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
    assert(root.Parent, "[Lumi UI] No se encontró un contenedor disponible para la interfaz")
    -- Remove the pre-modular pilot root when upgrading from v0.3.
    local legacy = root.Parent:FindFirstChild("LumiUIPilot_v01")
    if legacy then legacy:Destroy() end
    self.Root = root
    self:Connect(root.Destroying, function()
        -- The engine already owns this destruction. Avoid re-entering Destroy
        -- while the executor's container has locked the root's Parent.
        self.Root = nil
        self:Destroy()
    end)
    return root
end

return Runtime
