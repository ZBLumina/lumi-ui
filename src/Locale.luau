local Portuguese = require("translations/Portuguese")
local Fonts = require("Fonts")
local Locale = {}
Locale.__index = Locale
local thin = utf8.char(0x2009)

function Locale:Translate(source)
    if self.Language ~= "pt" or type(source) ~= "string" then return source end
    local tracked = source:find(thin, 1, true) ~= nil
    local plain = tracked and source:gsub(thin, "") or source
    local function phrase(text)
        if Portuguese[text] then return Portuguese[text] end
        local n = text:match("^(%d+) ejecución$") or text:match("^(%d+) ejecuciones$")
        if n then return n .. (n == "1" and " execução" or " execuções") end
        n = text:match("^(%d+) carácter$") or text:match("^(%d+) caracteres$")
        if n then return n .. (n == "1" and " caractere" or " caracteres") end
        n = text:match("^(%d+) opción$") or text:match("^(%d+) opciones$")
        if n then return n .. (n == "1" and " opção" or " opções") end
        n = text:match("^Hasta (%d+) caracteres$")
        if n then return "Até " .. n .. " caracteres" end
        local a,b = text:match("^OPCIÓN (%d+) / (%d+)$")
        if a then return "OPÇÃO " .. a .. " / " .. b end
        return text
    end
    local translated = phrase(plain)
    if translated == plain then
        translated = plain:gsub("[^/\n·]+", function(piece)
            local lead, body, trail = piece:match("^(%s*)(.-)(%s*)$")
            return lead .. phrase(body) .. trail
        end)
    end
    return tracked and Fonts.tracked(translated) or translated
end

function Locale:Layout()
    if self.Pending or self.Runtime.Destroyed then return end
    self.Pending = self.Runtime:Delay(0, function()
        self.Pending = nil
        local w = self.Window
        if w._destroyed or w._closing then return end
        for _,tab in ipairs(w.Tabs) do tab:Relayout() end
    end)
end

function Locale:Render(record, changed)
    local object, property = record.Object, record.Property
    if not object.Parent then return end
    local current = object[property]
    if changed then
        if current == record.Output then return end
        record.Source = current
    end
    local skip = object:GetAttribute("LumiUserText") == true
        or (object:IsA("TextBox") and property == "Text" and object:GetAttribute("LumiTranslateText") ~= true)
    local output = skip and record.Source or self:Translate(record.Source)
    record.Output = output
    if current ~= output then object[property] = output; self:Layout() end
end

function Locale:Bind(object)
    if self.Records[object] or not (object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")) then return end
    local records = {}
    self.Records[object] = records
    for _,property in ipairs(object:IsA("TextBox") and {"Text", "PlaceholderText"} or {"Text"}) do
        local record = {Object = object, Property = property, Source = object[property], Output = object[property]}
        table.insert(records, record)
        self.Runtime:Connect(object:GetPropertyChangedSignal(property), function() self:Render(record, true) end)
        self:Render(record, false)
    end
    self.Runtime:Connect(object:GetAttributeChangedSignal("LumiTranslateText"), function()
        for _,record in ipairs(records) do self:Render(record, false) end
    end)
    self.Runtime:Connect(object:GetAttributeChangedSignal("LumiUserText"), function()
        for _,record in ipairs(records) do self:Render(record, false) end
    end)
    self.Runtime:Connect(object.Destroying, function() self.Records[object] = nil end)
end

function Locale.new(window, language)
    local self = setmetatable({Window = window, Runtime = window.Runtime, Language = language, Records = {}}, Locale)
    for _,object in ipairs(window.Root:GetDescendants()) do self:Bind(object) end
    self.Runtime:Connect(window.Root.DescendantAdded, function(object) self:Bind(object) end)
    self.Runtime:OnCleanup(function() table.clear(self.Records) end)
    return self
end

function Locale:Set(language)
    if language ~= "es" and language ~= "pt" then return false end
    if self.Runtime.Destroyed or self.Window._closing or language == self.Language then return false end
    self.Window:FinishEntrance(); self.Window:FinishPages()
    self.Language = language
    for _,records in pairs(self.Records) do
        for _,record in ipairs(records) do self:Render(record, false) end
    end
    self:Layout()
    return true
end

return Locale
