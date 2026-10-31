local Window = require("Window")
local Images = require("ImageSource")
local environment = type(getgenv) == "function" and getgenv() or _G
local previous = environment.__LumiUI
if type(previous) == "table" and type(previous.Destroy) == "function" then previous:Destroy() end

local Lumi = {Version = "0.4.12", _windows = {}, _destroyed = false}

function Lumi:CreateWindow(options)
    assert(not self._destroyed, "[Lumi UI] La biblioteca está cerrada; vuelve a cargarla para continuar")
    local window = Window.new(options or {})
    table.insert(self._windows, window)
    return window
end

function Lumi:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    for _, window in ipairs(self._windows) do window:Destroy() end
    table.clear(self._windows)
    if environment.__LumiUI == self then environment.__LumiUI = nil end
end

function Lumi:ResolveImage(source) return Images.Resolve(source) end

environment.__LumiUI = Lumi
return Lumi
