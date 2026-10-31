-- Original, still line art. Decorative frames never capture input or affect lists.
local UI = require("UI")
local T = require("Theme")
local Art = {}

local function curve(parent, a, b, c, d, color, transparency, thickness)
    local previous = a
    for i = 1, 20 do
        local t, s = i / 20, 1 - i / 20
        local point = a * s ^ 3 + b * (3 * s ^ 2 * t) + c * (3 * s * t ^ 2) + d * t ^ 3
        local delta = point - previous
        local line = UI.frame(parent, "Arc", 0, 0, delta.Magnitude + 0.6, thickness or 1, color, 1)
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.Position = UDim2.fromOffset((point.X + previous.X) / 2, (point.Y + previous.Y) / 2)
        line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
        line.BackgroundTransparency = transparency
        previous = point
    end
end

function Art.header(parent)
    local art = UI.frame(parent, "LumiArcs", 0, 0, 136, 78)
    art.AnchorPoint, art.Position = Vector2.new(1, 0), UDim2.new(1, 0, 0, 0)
    art.ClipsDescendants = true
    curve(art, Vector2.new(1, 77), Vector2.new(29, 26), Vector2.new(113, 81), Vector2.new(143, 4), T.Ornament, 0.53, 1)
    curve(art, Vector2.new(14, 82), Vector2.new(42, 37), Vector2.new(117, 75), Vector2.new(130, 12), T.Accent, 0.73, 1)
    curve(art, Vector2.new(43, 84), Vector2.new(73, 50), Vector2.new(110, 66), Vector2.new(114, 25), T.Ornament, 0.80, 2)
    UI.sparkle(art, 104, 7, 13, T.Accent, 0.30)
    UI.sparkle(art, 85, 25, 5, T.Accent, 0.55)
    return art
end

function Art.sidebar(parent)
    local art = UI.frame(parent, "BrandWaves", 20, 87, 144, 26)
    art.ClipsDescendants = true
    curve(art, Vector2.new(-4, 6), Vector2.new(42, 35), Vector2.new(89, -9), Vector2.new(151, 12), T.Accent, 0.65, 1)
    curve(art, Vector2.new(-4, 12), Vector2.new(52, 39), Vector2.new(102, -3), Vector2.new(151, 19), T.Ornament, 0.78, 1)
    return art
end

function Art.footer(parent)
    local art = UI.frame(parent, "FooterWaves", 18, 0, 188, 32)
    art.Position = UDim2.new(0, 18, 1, -106)
    art.ClipsDescendants = true
    curve(art, Vector2.new(-5, 25), Vector2.new(60, -9), Vector2.new(106, 43), Vector2.new(193, 5), T.Ornament, 0.81, 1)
    curve(art, Vector2.new(-5, 31), Vector2.new(73, 0), Vector2.new(120, 47), Vector2.new(193, 15), T.Accent, 0.90, 1)
    return art
end

return Art
