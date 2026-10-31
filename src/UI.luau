local T = require("Theme")
local Fonts = require("Fonts")
local UI = {}

function UI.new(class, parent, properties)
    local object = Instance.new(class)
    if object:IsA("GuiObject") then
        object.BorderSizePixel = 0
        object.BackgroundTransparency = 1
        object.ZIndex = parent and parent:IsA("GuiObject") and parent.ZIndex or 1
    end
    if object:IsA("GuiButton") then object.AutoButtonColor = false end
    for key, value in pairs(properties or {}) do
        if key == "Font" and typeof(value) == "Font" then object.FontFace = value
        else object[key] = value end
    end
    -- Nunito's smaller cap height needs a little more size at the same viewing
    -- distance. Layout reads the resulting TextSize, never the old metrics.
    if properties and properties.TextSize and (properties.Font == T.Font or properties.Font == T.Medium or properties.Font == T.Mono) then
        object.TextSize += 2
    end
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

function UI.micro(parent, name, text, x, y, width, height, size, color)
    return UI.text(parent, name, Fonts.tracked(text), x, y, width, height, size or 11, color or T.Muted, T.Micro)
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
    UI.frame(mark, "Dot", size * 0.65, size * 0.20, size * 0.18, size * 0.18, color or T.Accent, 999)
    return mark
end

function UI.sparkle(parent, x, y, size, color, transparency)
    local spark = UI.frame(parent, "Spark", x, y, size, size)
    -- The concave outline is an astroid, drawn as small native strips.
    local strips = math.max(8, math.ceil(size))
    for i = 1, strips do
        local offset = math.abs((i - 0.5) / strips * 2 - 1)
        local height = math.max(0.8, (1 - offset ^ (2 / 3)) ^ (3 / 2) * size)
        local part = UI.frame(spark, "Ray", (i - 1) * size / strips, (size - height) / 2, size / strips + 0.1, height, color or T.Accent)
        part.BackgroundTransparency = transparency or 0
    end
    return spark
end

-- Native geometric icons; no font glyphs or external asset dependency.
function UI.icon(parent, style, x, y, color)
    local icon = UI.frame(parent, "Icon", x, y, 16, 16)
    local parts = {}
    local function line(name, px, py, width, height)
        local part = UI.frame(icon, name, px, py, width, height, color or T.Secondary, 1)
        table.insert(parts, part)
    end
    if style == "Sliders" then
        for i, offset in ipairs({4, 10, 7}) do
            line("Track", 1, (i - 1) * 6 + 2, 14, 1)
            line("Handle", offset, (i - 1) * 6, 2, 5)
        end
    elseif style == "Layers" then
        for i = 0, 2 do
            local layer = UI.frame(icon, "Layer", 1 + i * 2, 1 + i * 3, 10, 7, nil, 1)
            table.insert(parts, UI.stroke(layer, color or T.Secondary))
        end
    else
        for i = 0, 3 do line("Cell", (i % 2) * 9, math.floor(i / 2) * 9, 6, 6) end
    end
    return icon, parts
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
