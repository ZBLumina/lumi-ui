local UI = require("UI")
local T = require("Theme")
local Shadow = {}

-- Ambient softness plus a tighter contact edge. Native antialiased silhouettes
-- avoid stretching a small bitmap and scale with the window automatically.
local profiles = {
    {Name = "Ambient", Spread = 44, Inset = 8, Sigma = 14, Opacity = 0.34, Offset = 8, Samples = 32},
    {Name = "Contact", Spread = 9, Inset = 2, Sigma = 2.5, Opacity = 0.18, Offset = 1.5, Samples = 12},
}

function Shadow.new(parent, radius)
    local shadow = UI.new("Frame", parent, {
        Name = "Shadow", Size = UDim2.fromScale(1, 1), ZIndex = 0, Active = false,
    })
    for _, profile in ipairs(profiles) do
        local previous = 0
        for index = 1, profile.Samples do
            local pad = profile.Spread - (index - 1) * (profile.Spread + profile.Inset) / (profile.Samples - 1)
            local opacity = profile.Opacity / (1 + math.exp(1.7 * pad / profile.Sigma))
            -- Alpha-over correction makes the accumulated opacity follow the
            -- curve. Inset samples prevent a flat band below an offset shadow.
            local alpha = (opacity - previous) / (1 - previous)
            local layer = UI.frame(shadow, profile.Name .. index, -pad, profile.Offset - pad,
                0, 0, T.Shadow, math.max(0, radius + pad))
            layer.Size = UDim2.new(1, 2 * pad, 1, 2 * pad)
            layer.BackgroundTransparency = 1 - alpha
            previous = opacity
        end
    end
    return shadow
end

return Shadow
