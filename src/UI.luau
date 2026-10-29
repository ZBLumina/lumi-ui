local T = require("Theme")
local UI = {}

function UI.new(class, parent, properties)
    local object = Instance.new(class)
    if object:IsA("GuiObject") then
        object.BorderSizePixel = 0
        object.BackgroundTransparency = 1
        object.ZIndex = parent and parent:IsA("GuiObject") and parent.ZIndex or 1
    end
    if object:IsA("GuiButton") then object.AutoButtonColor = false end
    for key, value in pairs(properties or {}) do object[key] = value end
    object.Parent = parent
    return object
end

function UI.frame(parent, name, x, y, width, height, color, radius)
    local frame = UI.new("Frame", parent, {
        Name = name, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(width, height),
        BackgroundColor3 = color or T.Surface, BackgroundTransparency = color and 0 or 1,
    })
    if radius then UI.corner(frame, radius) end
    return frame
end

function UI.corner(parent, radius)
    return UI.new("UICorner", parent, {CornerRadius = UDim.new(0, radius or 6)})
end

function UI.stroke(parent, color)
    return UI.new("UIStroke", parent, {Color = color or T.Line, Thickness = 1, Transparency = 0.16, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
end

function UI.text(parent, name, text, x, y, width, height, size, color, font)
    return UI.new("TextLabel", parent, {
        Name = name, Text = tostring(text or ""), Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(width, height), TextSize = math.max(size or 13, 11),
        TextColor3 = color or T.Text, Font = font or T.Font,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    })
end

function UI.button(parent, name, text, x, y, width, height)
    return UI.new("TextButton", parent, {
        Name = name, Text = text or "", Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(width, height), Font = T.Medium, TextSize = 13,
        TextColor3 = T.Text, Active = true,
    })
end

function UI.line(parent, x, y, width, color)
    return UI.frame(parent, "Rule", x, y, width, 1, color or T.SoftLine)
end

function UI.list(parent, gap)
    return UI.new("UIListLayout", parent, {Padding = UDim.new(0, gap or 0), SortOrder = Enum.SortOrder.LayoutOrder})
end

function UI.mark(parent, x, y, size, color)
    local mark = UI.frame(parent, "LumiMark", x, y, size, size)
    UI.frame(mark, "Stem", size * 0.18, size * 0.16, size * 0.18, size * 0.68, color or T.Accent, 2)
    UI.frame(mark, "Base", size * 0.18, size * 0.66, size * 0.58, size * 0.18, color or T.Accent, 2)
    local spark = UI.frame(mark, "Spark", size * 0.61, size * 0.17, size * 0.22, size * 0.22, color or T.Accent, 2)
    spark.Rotation = 45
    return mark
end

function UI.chevron(parent, x, y, color)
    local first = UI.frame(parent, "ChevronA", x, y, 6, 1, color or T.Secondary)
    local second = UI.frame(parent, "ChevronB", x + 4, y, 6, 1, color or T.Secondary)
    first.Rotation = 45
    second.Rotation = -45
end

function UI.check(parent, x, y, color)
    local a = UI.frame(parent, "CheckA", x, y + 3, 5, 2, color or T.Accent)
    local b = UI.frame(parent, "CheckB", x + 3, y + 1, 9, 2, color or T.Accent)
    a.Rotation = 45
    b.Rotation = -45
end

function UI.hover(runtime, button, normal, hover)
    runtime:Connect(button.MouseEnter, function() runtime:Tween(button, {BackgroundColor3 = hover or T.Hover}) end)
    runtime:Connect(button.MouseLeave, function() runtime:Tween(button, {BackgroundColor3 = normal or T.Raised}) end)
    runtime:Connect(button.SelectionGained, function() runtime:Tween(button, {BackgroundColor3 = hover or T.Hover}) end)
    runtime:Connect(button.SelectionLost, function() runtime:Tween(button, {BackgroundColor3 = normal or T.Raised}) end)
end

function UI.number(value, fallback)
    local n = tonumber(value)
    if n == nil or n ~= n or math.abs(n) == math.huge then return fallback end
    return n
end

function UI.format(value, precision)
    return string.format("%." .. tostring(precision or 2) .. "f", value):gsub("0+$", ""):gsub("%.$", "")
end

return UI
