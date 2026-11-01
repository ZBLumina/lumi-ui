local UI = require("UI")
local T = require("Theme")
local Images = require("ImageSource")
local Thumbnail = {}

function Thumbnail.new(runtime, parent, source, x, y, width, height)
    local frame = UI.frame(parent, "ThumbnailFrame", x, y, width, height, T.Shell, 4)
    frame.ClipsDescendants = true
    -- A quiet placeholder remains underneath failed or loading images.
    local mark = UI.frame(frame, "Placeholder", 0, 0, 12, 8)
    mark.AnchorPoint, mark.Position = Vector2.new(.5, .5), UDim2.fromScale(.5, .5)
    UI.stroke(mark, T.Muted).Transparency = .55
    UI.frame(mark, "Horizon", 2, 5, 8, 1, T.Muted).BackgroundTransparency = .55
    local image = UI.new("ImageLabel", frame, {Name = "Thumbnail", Size = UDim2.fromScale(1, 1),
        Image = "", ScaleType = Enum.ScaleType.Crop})
    UI.corner(image, 4)
    return frame, Images.Bind(runtime, image, source)
end

return Thumbnail
