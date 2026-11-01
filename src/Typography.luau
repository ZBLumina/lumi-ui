local Typography = {}
local scopes = setmetatable({}, {__mode = "k"})
local BASE = "LumiBaseTextSize"

local function text(object)
    return object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")
end

local function factor(value)
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then return 1 end
    return math.clamp(value, 1, 1.3)
end

local function scope(object)
    while object do
        local found = scopes[object]
        if found and not found.Runtime.Destroyed then return found end
        object = object.Parent
    end
end

function Typography.get(root)
    local found = scope(root)
    return found and found.Factor or 1
end

function Typography.bind(object, parent)
    if not text(object) then return end
    local found = scope(parent or object.Parent)
    if not found then return end
    -- UI.new calls this after the font's optical adjustment, before parenting.
    local base = object:GetAttribute(BASE)
    if base == nil then base = object.TextSize; object:SetAttribute(BASE, base) end
    object.TextSize = base * found.Factor
end

function Typography.size(label, base)
    if not text(label) then return end
    assert(type(base) == "number" and base == base and base > 0 and base < math.huge, "[Lumi UI] Tamaño de texto no válido")
    label:SetAttribute(BASE, base)
    label.TextSize = base * Typography.get(label)
    return label.TextSize
end

function Typography.apply(root, value)
    local found = scopes[root]
    if not found or found.Runtime.Destroyed then return false end
    found.Factor = factor(value)
    root:SetAttribute("LumiTextScale", found.Factor)
    for _, object in ipairs(root:GetDescendants()) do Typography.bind(object, object.Parent) end
    return found.Factor
end

function Typography.mount(runtime, root, value)
    if scopes[root] then return Typography.apply(root, value) end
    scopes[root] = {Runtime = runtime, Factor = factor(value)}
    runtime:OnCleanup(function() scopes[root] = nil end)
    runtime:Connect(root.DescendantAdded, function(object) Typography.bind(object, object.Parent) end)
    return Typography.apply(root, value)
end

return Typography
