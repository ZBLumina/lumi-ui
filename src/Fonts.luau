-- Static OFL fonts are embedded by the builder; no runtime HTTP requests.
local Data = require("FontsData")
local Text = game:GetService("TextService")
local Http = game:GetService("HttpService")
local Fonts = {}
local CACHE = "lumi-ui/fonts"
local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local sextets = {}
for i = 1, #alphabet do sextets[alphabet:byte(i)] = i - 1 end

local function decode(data)
    local result = table.create(math.ceil(#data / 4))
    for i = 1, #data, 4 do
        local a, b = sextets[data:byte(i)], sextets[data:byte(i + 1)]
        local c, d = sextets[data:byte(i + 2)], sextets[data:byte(i + 3)]
        local value = a * 262144 + b * 4096 + (c or 0) * 64 + (d or 0)
        local bytes = string.char(math.floor(value / 65536))
        if c then bytes ..= string.char(math.floor(value / 256) % 256) end
        if d then bytes ..= string.char(value % 256) end
        result[(i + 3) / 4] = bytes
    end
    return table.concat(result)
end

local function register(path)
    for _, loader in ipairs({getcustomasset or false, getsynasset or false}) do
        if type(loader) == "function" then
            local ok, uri = pcall(loader, path)
            if ok and type(uri) == "string" and uri ~= "" then return uri end
        end
    end
    error("El ejecutor no admite fuentes locales", 0)
end

local function save(path, bytes)
    -- Content-addressed app files only. Repair an interrupted cache write.
    if not isfile(path) or readfile(path) ~= bytes then writefile(path, bytes) end
end

local function loadFace(entry)
    assert(type(isfile) == "function" and type(readfile) == "function" and type(writefile) == "function", "Fuentes locales no disponibles")
    for _, folder in ipairs({"lumi-ui", CACHE}) do
        if type(isfolder) == "function" and not isfolder(folder) then makefolder(folder) end
    end
    local path = CACHE .. "/" .. entry.File .. "-" .. entry.Hash
    local bytes = decode(entry.Data)
    assert(bytes:sub(1, 4) == "\0\1\0\0", "Fuente TTF no válida")
    save(path .. ".ttf", bytes)
    local family = Http:JSONEncode({name = entry.Name, faces = {{
        name = entry.Face, weight = entry.Weight, style = "normal", assetId = register(path .. ".ttf"),
    }}})
    save(path .. ".json", family)
    local weight = entry.Weight == 600 and Enum.FontWeight.SemiBold or entry.Weight == 500 and Enum.FontWeight.Medium or Enum.FontWeight.Regular
    local face = Font.new(register(path .. ".json"), weight, Enum.FontStyle.Normal)
    -- Warm the family once, before any window/layout is constructed. Subsequent
    -- text bounds use the same loaded face as the labels, including accents.
    local info = Text:GetFamilyInfoAsync(face.Family)
    assert(info.Name == entry.Name, "No se pudo cargar la familia tipográfica")
    local params = Instance.new("GetTextBoundsParams")
    params.Text, params.Font, params.Size, params.Width = "Introducción · ÁÉÍÓÚ ñ ü", face, 15, 1000
    local ok, bounds = pcall(Text.GetTextBoundsAsync, Text, params)
    params:Destroy()
    assert(ok and bounds.X > 0 and bounds.Y > 0, "No se pudo medir la fuente")
    return face
end

local fallback = {
    Title = Font.fromEnum(Enum.Font.FredokaOne),
    Body = Font.fromEnum(Enum.Font.Gotham),
    BodyMedium = Font.fromEnum(Enum.Font.GothamMedium),
    Micro = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Medium),
    Brand = Font.fromEnum(Enum.Font.GothamMedium),
}
Fonts.Loaded = {}
local missing = {}
for _, role in ipairs({"Title", "Body", "BodyMedium", "Micro", "Brand"}) do
    local ok, face = pcall(loadFace, Data[role])
    Fonts[role], Fonts.Loaded[role] = ok and face or fallback[role], ok
    if not ok then table.insert(missing, Data[role].Name) end
end
if #missing > 0 then warn("[Lumi UI] Fuentes nativas de respaldo: " .. table.concat(missing, ", ")) end

-- A bounded cache avoids repeated service calls while fitting the same labels.
local measurements, count = {}, 0
function Fonts.bounds(text, size, face, width)
    text, width = tostring(text), math.max(1, math.floor(width or 100000))
    if typeof(face) == "EnumItem" then face = Font.fromEnum(face) end
    local key = face.Family .. ":" .. face.Weight.Value .. ":" .. face.Style.Value .. ":" .. size .. ":" .. width .. ":" .. text
    if measurements[key] then return measurements[key] end
    local params = Instance.new("GetTextBoundsParams")
    params.Text, params.Font, params.Size, params.Width = text, face, size, width
    local ok, bounds = pcall(Text.GetTextBoundsAsync, Text, params)
    params:Destroy()
    if not ok then
        -- Keep the UI usable when a native fallback cannot be preloaded.
        bounds = Text:GetTextSize(text, size, Enum.Font.GothamMedium, Vector2.new(width, 100000))
    end
    if count >= 2048 then table.clear(measurements); count = 0 end
    measurements[key], count = bounds, count + 1
    return bounds
end

function Fonts.tracked(text)
    text = tostring(text)
    local glyphs = {}
    for first, last in utf8.graphemes(tostring(text)) do
        table.insert(glyphs, text:sub(first, last))
    end
    return table.concat(glyphs, utf8.char(0x2009))
end

return Fonts
