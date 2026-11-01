-- Original PNG illustrations. Passive frames preserve the same layout anchors.
local UI = require("UI")
local Images = require("ImageSource")
local Artwork = require("Artwork")
local Art = {}

local function picture(runtime, parent, source, transparency)
    local image = UI.new("ImageLabel", parent, {
        Name = "ArtworkImage", Image = "", Size = UDim2.fromScale(1, 1),
        ScaleType = Enum.ScaleType.Fit, ImageTransparency = 1 - (1 - transparency) * (runtime.Decoration or 1),
        Active = false, Selectable = false,
    })
    image:SetAttribute("LumiArtworkOpacity", 1 - transparency)
    -- Use the existing cancellable cache/loader. Failed art stays transparent;
    -- no placeholder icon or error message is drawn over the workspace.
    Images.Bind(runtime, image, source)
    return image
end

function Art.header(runtime, parent)
    local art = UI.frame(parent, "LumiArcs", 0, 0, 0, 0)
    art.Size = UDim2.fromScale(1, 1)
    art.ClipsDescendants = true
    local image = picture(runtime, art, Artwork.Header, 0.64)
    image.Position = UDim2.fromOffset(8, 6)
    image.Size = UDim2.new(1, -16, 1, -12)
    image.ScaleType = Enum.ScaleType.Stretch
    return art
end

local function surface(runtime, parent, name, source, transparency)
    local art = UI.frame(parent, name, 0, 0, 0, 0)
    art.Size = UDim2.fromScale(1, 1)
    art.ClipsDescendants = true
    local image = picture(runtime, art, source, transparency)
    image.ScaleType = Enum.ScaleType.Crop
    UI.corner(image, 14)
    return art
end

function Art.sidebar(runtime, parent)
    return surface(runtime, parent, "BrandWaves", Artwork.Sidebar, 0.78)
end

function Art.panel(runtime, parent)
    return surface(runtime, parent, "PanelArtwork", Artwork.Panel, 0.82)
end

function Art.footer(runtime, parent)
    return surface(runtime, parent, "FooterWaves", Artwork.Inspector, 0.78)
end

return Art
