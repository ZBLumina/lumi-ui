-- Resolve may yield; Bind owns asynchronous delivery, never image visibility.
local ImageSource = {}
local Binding = {}
Binding.__index = Binding
local CACHE = "lumi-ui/assets"
local registered = {}
local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local sextets = {}
for index = 1, #alphabet do sextets[alphabet:byte(index)] = index - 1 end

local function hash(value)
    local first, second = 2166136261, 5381
    for index = 1, #value do
        local byte = value:byte(index)
        first = bit32.bxor(first, byte)
        -- Split FNV multiplication to keep every intermediate exactly representable.
        first = (first * 403 + bit32.lshift(first, 24)) % 4294967296
        second = (second * 33 + byte) % 4294967296
    end
    return string.format("%08x%08x", first, second)
end

local function decode(data)
    data = data:gsub("%s", "")
    if data == "" or #data % 4 ~= 0 then return nil, "Base64 no válido" end
    local output = {}
    for index = 1, #data, 4 do
        local a, b = sextets[data:byte(index)], sextets[data:byte(index + 1)]
        local third, fourth = data:byte(index + 2), data:byte(index + 3)
        local c, d = sextets[third], sextets[fourth]
        local last = index + 3 == #data
        if not a or not b or (not c and third ~= 61) or (not d and fourth ~= 61)
            or (third == 61 and (fourth ~= 61 or b % 16 ~= 0))
            or (fourth == 61 and c and c % 4 ~= 0)
            or (not last and (third == 61 or fourth == 61)) then
            return nil, "Base64 no válido"
        end
        local value = a * 262144 + b * 4096 + (c or 0) * 64 + (d or 0)
        local bytes = string.char(math.floor(value / 65536))
        if c then bytes ..= string.char(math.floor(value / 256) % 256) end
        if d then bytes ..= string.char(value % 256) end
        table.insert(output, bytes)
    end
    return table.concat(output)
end

local function extension(data)
    if data:sub(1, 8) == "\137PNG\r\n\26\n" then return "png" end
    if data:sub(1, 3) == "\255\216\255" then return "jpg" end
    return nil
end

local function exists(path)
    if type(isfile) ~= "function" then return nil, "El ejecutor no permite comprobar archivos" end
    local ok, found = pcall(isfile, path)
    if not ok or type(found) ~= "boolean" then return nil, "No se pudo comprobar el archivo" end
    return found
end

local function canRegister()
    return type(getcustomasset) == "function" or type(getsynasset) == "function"
end

local function register(path)
    -- Reuse a local asset URI across simultaneous consumers. Registering the
    -- same file repeatedly can rewrite its mapped copy while Roblox reads it.
    if registered[path] then return registered[path] end
    for _, loader in ipairs({getcustomasset or false, getsynasset or false}) do
        if type(loader) == "function" then
            local ok, uri = pcall(loader, path)
            if ok and type(uri) == "string" and uri ~= "" then registered[path] = uri; return uri end
        end
    end
    return nil, "No se pudo registrar la imagen local con el ejecutor"
end

local function prepareCache()
    for _, folder in ipairs({"lumi-ui", CACHE}) do
        local found = false
        if type(isfolder) == "function" then
            local ok
            ok, found = pcall(isfolder, folder)
            if not ok or type(found) ~= "boolean" then return nil, "No se pudo comprobar la carpeta de imágenes" end
        end
        if not found then
            local occupied, problem = exists(folder)
            if occupied == nil then return nil, problem end
            if occupied then return nil, "La carpeta de imágenes está ocupada por un archivo" end
            if type(makefolder) == "function" then
                local ok = pcall(makefolder, folder)
                if not ok and type(isfolder) == "function" then
                    local checked, created = pcall(isfolder, folder)
                    if not checked or not created then return nil, "No se pudo crear la carpeta de imágenes" end
                end
            elseif type(isfolder) == "function" then
                return nil, "El ejecutor no permite crear la carpeta de imágenes"
            end
            -- Without folder helpers, writefile may still support an existing directory.
        end
    end
    return true
end

local function save(data, key)
    if not canRegister() then return nil, "El ejecutor no permite imágenes locales" end
    local suffix = extension(data)
    if not suffix then return nil, "La imagen debe contener datos PNG o JPEG" end
    local path = CACHE .. "/" .. key .. "." .. suffix
    local found, problem = exists(path)
    if found == nil then return nil, problem end
    if not found then
        if type(writefile) ~= "function" then return nil, "El ejecutor no permite guardar imágenes" end
        local ready
        ready, problem = prepareCache()
        if not ready then return nil, problem end
        -- Recheck after folder creation: another resolution may have populated the cache.
        found, problem = exists(path)
        if found == nil then return nil, problem end
        if not found then
            local ok = pcall(writefile, path, data)
            if not ok then return nil, "No se pudo guardar la imagen" end
            found, problem = exists(path)
            if found == nil then return nil, problem end
            if not found then return nil, "El ejecutor no guardó la imagen" end
        end
    end
    return register(path)
end

local function download(url)
    if type(url) ~= "string" or not url:lower():match("^https://[^%s]+$") then
        return nil, "La URL de imagen debe usar HTTPS"
    end
    if not canRegister() then return nil, "El ejecutor no permite imágenes locales" end
    -- Only hashes reach filenames; URL credentials and query strings stay out of errors.
    local key = "url-" .. hash(url)
    for _, suffix in ipairs({"png", "jpg"}) do
        local path = CACHE .. "/" .. key .. "." .. suffix
        local found, problem = exists(path)
        if found == nil then return nil, problem end
        if found then return register(path) end
    end
    if type(writefile) ~= "function" then return nil, "El ejecutor no permite guardar imágenes" end
    local ok, data = pcall(function() return game:HttpGet(url) end)
    if not ok or type(data) ~= "string" or data == "" then return nil, "No se pudo descargar la imagen" end
    return save(data, key)
end

local function resolve(source)
    if source == nil or source == "" then return nil, nil end
    if type(source) == "number" then
        if source <= 0 or source > 9007199254740991 or source % 1 ~= 0 then
            return nil, "El identificador de imagen debe ser un entero positivo"
        end
        return "rbxassetid://" .. string.format("%.0f", source), nil
    end
    if type(source) == "string" then
        if source:match("^rbx%a+://.+") then return source, nil end
        return download(source)
    end
    if type(source) ~= "table" then return nil, "Fuente de imagen no válida" end
    local fields = (source.Path ~= nil and 1 or 0) + (source.Url ~= nil and 1 or 0) + (source.Data ~= nil and 1 or 0)
    if fields ~= 1 then return nil, "Usa una sola fuente de imagen: Path, Url o Data" end
    if source.Path ~= nil then
        if type(source.Path) ~= "string" or source.Path == "" then return nil, "La ruta de imagen no es válida" end
        if not canRegister() then return nil, "El ejecutor no permite imágenes locales" end
        if type(isfile) == "function" then
            local found, problem = exists(source.Path)
            if found == nil then return nil, problem end
            if not found then return nil, "No se encontró la imagen local" end
        end
        return register(source.Path)
    end
    if source.Url ~= nil then return download(source.Url) end
    if type(source.Data) ~= "string" then return nil, "Los datos de imagen deben ser Base64" end
    local data, problem = decode(source.Data)
    if not data then return nil, problem end
    -- Name is descriptive only. Bytes determine identity and extension, never a user path.
    return save(data, "data-" .. hash(data))
end

function ImageSource.Resolve(source): (string?, string?)
    local ok, uri, problem = pcall(resolve, source)
    if not ok then return nil, "No se pudo resolver la imagen" end
    return uri, problem
end

function Binding:_Current(generation)
    return not self.Destroyed and self.Runtime and not self.Runtime.Destroyed
        and self.Label ~= nil and self.Generation == generation
end

function Binding:_Apply(generation, uri, problem)
    if not self:_Current(generation) then return end
    self.Error = problem
    local ok = pcall(function() self.Label.Image = uri or "" end)
    if not ok and self:_Current(generation) then self.Error = "No se pudo actualizar la imagen" end
end

function Binding:Set(source)
    if not self:_Current(self.Generation) then return self end
    if self.Task then self.Runtime:CancelDelay(self.Task); self.Task = nil end
    self.Generation += 1
    local generation = self.Generation
    self:_Apply(generation, nil, nil)
    local ok, task = pcall(self.Runtime.Callback, self.Runtime, function()
        if not self:_Current(generation) then return end
        local uri, problem = ImageSource.Resolve(source)
        self:_Apply(generation, uri, problem)
    end)
    if ok then self.Task = task end
    if not ok and self:_Current(generation) then self.Error = "No se pudo programar la carga de imagen" end
    return self
end

function Binding:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    self.Generation += 1
    if self.Task and self.Runtime then self.Runtime:CancelDelay(self.Task) end
    self.Task = nil
    if self.Connection then pcall(function() self.Connection:Disconnect() end) end
    self.Connection, self.Label, self.Runtime = nil, nil, nil
end

function ImageSource.Bind(runtime, imageLabel, source)
    local binding = setmetatable({Runtime = runtime, Label = imageLabel, Generation = 0, Destroyed = false}, Binding)
    if type(runtime) ~= "table" or type(runtime.Callback) ~= "function" or runtime.Destroyed or imageLabel == nil then
        binding.Error = "No hay un runtime o una etiqueta disponibles para la imagen"
        binding:Destroy()
        return binding
    end
    local ok, connection = pcall(function()
        return imageLabel.Destroying:Connect(function() binding:Destroy() end)
    end)
    if ok then binding.Connection = connection end
    if type(runtime.OnCleanup) == "function" then
        local registered = pcall(runtime.OnCleanup, runtime, function() binding:Destroy() end)
        if not registered then
            binding.Error = "No se pudo registrar la limpieza de la imagen"
            binding:Destroy()
            return binding
        end
    end
    return binding:Set(source)
end

return ImageSource
