local Data = require("IconsData")
local Images = require("ImageSource")
local Icons = {}
local scopes = setmetatable({}, {__mode = "k"})

function Icons.mount(runtime, root)
    scopes[root] = runtime
    runtime:OnCleanup(function() scopes[root] = nil end)
end

function Icons.bind(label, style)
    local key = type(style) == "string" and Data[style] and style or "Grid"
    local parent = label.Parent
    while parent do
        if scopes[parent] then return Images.Bind(scopes[parent], label, Data[key]) end
        parent = parent.Parent
    end
end

return Icons
