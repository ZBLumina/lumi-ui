local Http = game:GetService("HttpService")
local Profiles = {}
Profiles.__index = Profiles
local DEBOUNCE = .3

local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function validName(name)
    return type(name) == "string" and #name <= 128 and name:find("%S") ~= nil
end

local function validateState(state)
    assert(type(state) == "table" and state.Version == 1, "El estado del perfil no tiene una versión válida.")
    local view = state.Window
    assert(type(view) == "table" and type(view.Position) == "table" and type(view.Preferences) == "table"
        and type(state.Controls) == "table", "El estado del perfil está incompleto.")
    assert(finite(view.Position.X) and finite(view.Position.Y) and view.Position.X >= 0 and view.Position.X <= 1
        and view.Position.Y >= 0 and view.Position.Y <= 1, "La posición del perfil no es válida.")
    assert(view.Page == nil or type(view.Page) == "string", "La página del perfil no es válida.")
    for name, value in pairs(view.Preferences) do
        local valid = (name == "Language" and (value == "es" or value == "pt"))
            or ((name == "Animations" or name == "Inspector") and type(value) == "boolean")
            or (name == "Decoration" and finite(value) and value >= 0 and value <= 100)
            or (name == "TextScale" and finite(value) and value >= 1 and value <= 1.3)
        assert(valid, "El perfil contiene una preferencia no válida.")
    end
    for id, control in pairs(state.Controls) do
        assert(type(id) == "string" and #id > 0 and type(control) == "table"
            and type(control.Enabled) == "boolean", "El perfil contiene un control no válido.")
        local value, kind = control.Value, control.Kind
        local valid = (kind == "Toggle" and type(value) == "boolean")
            or (kind == "Slider" and finite(value)) or (kind == "Input" and type(value) == "string")
            or (kind == "Dropdown" and (value == nil or type(value) == "string"
                or type(value) == "boolean" or finite(value)))
        assert(valid, "El perfil contiene un valor no válido.")
    end
end

local function decode(text)
    local document = Http:JSONDecode(text)
    assert(type(document) == "table" and document.Version == 1 and type(document.Profiles) == "table",
        "El archivo de perfiles no tiene un formato válido.")
    for name, state in pairs(document.Profiles) do
        assert(validName(name), "El archivo contiene un nombre de perfil no válido.")
        validateState(state)
    end
    assert(document.Active == nil or (validName(document.Active) and document.Profiles[document.Active] ~= nil),
        "El perfil activo no existe en el archivo.")
    return document
end

local function checked(callback, ...)
    local ok, value, problem = pcall(callback, ...)
    if not ok then error(tostring(value), 0) end
    if value == false then error(tostring(problem or "El proveedor rechazó la operación."), 0) end
    return value
end

local function nativeStorage()
    if type(readfile) ~= "function" or type(writefile) ~= "function" or type(isfile) ~= "function"
        or type(makefolder) ~= "function" then return nil end
    return {
        Read = readfile,
        Write = writefile,
        Exists = function(path)
            return isfile(path) or (type(isfolder) == "function" and isfolder(path))
        end,
        MakeFolder = function(path)
            if type(isfolder) ~= "function" or not isfolder(path) then return makefolder(path) end
        end,
    }
end

function Profiles.new(window, config)
    local self = setmetatable({Window = window, Configured = config ~= nil, Enabled = false,
        AutoLoad = false, AutoSave = false, ReadyDone = false, Destroyed = false, Loading = false,
        Busy = false, Dirty = false, Revision = 0}, Profiles)
    if type(config) == "table" then
        local key = config.Key
        if type(key) ~= "string" or #key == 0 or #key > 128 or not key:match("^[A-Za-z0-9_-]+$") then
            self.Error = "La clave de configuración solo admite letras, números, guiones y guiones bajos."
        else
            self.Directory = "lumi-ui/config/" .. key
            self.Path = self.Directory .. "/profiles.json"
            self.BackupPath = self.Path .. ".bak"
            self.Storage = config.Storage
            if self.Storage == nil then self.Storage = nativeStorage() end
            local available = type(self.Storage) == "table"
            for _, name in ipairs({"Read", "Write", "Exists", "MakeFolder"}) do
                available = available and type(self.Storage[name]) == "function"
            end
            self.Enabled = available
            if not available then self.Error = "El almacenamiento local de perfiles no está disponible." end
        end
        self.AutoLoad, self.AutoSave = config.AutoLoad == true, config.AutoSave == true
    else
        self.Error = "El guardado de perfiles no está habilitado."
    end
    window.Runtime:OnCleanup(function() self:Destroy() end)
    return self
end

function Profiles:_cancel()
    self.Window.Runtime:CancelDelay(self.Pending)
    self.Pending = nil
end

function Profiles:_operation(loading, callback)
    if self.Destroyed or self.Window._destroyed or self.Window.Runtime.Destroyed then
        return false, "La ventana está cerrada."
    end
    if not self.Enabled then return false, self.Error end
    if self.Busy then return false, "Ya hay una operación de perfiles en curso." end
    self.Busy, self.Loading = true, loading
    local called, ok, problem = pcall(callback)
    self.Busy, self.Loading = false, false
    if not called then problem, ok = tostring(ok), false end
    if ok ~= true then
        problem = tostring(problem or "No se pudo completar la operación de perfiles.")
        self.LastError = problem
        return false, problem
    end
    self.LastError = nil
    return true
end

function Profiles:_exists(path)
    -- Exists=false means absence, whereas false from Read/Write means rejection.
    local ok, value = pcall(self.Storage.Exists, path)
    if not ok then error(tostring(value), 0) end
    assert(type(value) == "boolean", "El proveedor no pudo comprobar el archivo.")
    return value
end

function Profiles:_text(path)
    if not self:_exists(path) then return nil end
    local text = checked(self.Storage.Read, path)
    assert(type(text) == "string", "No se pudo leer un archivo existente; se conservan los datos anteriores.")
    return text
end

function Profiles:_read()
    local text = self:_text(self.Path)
    if text == nil then
        assert(not self:_exists(self.BackupPath), "Falta el archivo de perfiles; se conserva el respaldo existente.")
        return {Version = 1, Profiles = {}}, nil
    end
    -- Only this live store may retry bytes left by its own failed first write.
    -- Pre-existing corrupt files and externally changed bytes still fail closed.
    if text==self.InitialResidue and not pcall(decode,text) and not self:_exists(self.BackupPath) then
        return {Version=1,Profiles={}},nil
    end
    -- Never convert corrupt or unreadable data to an empty store, or promote a
    -- backup implicitly: a failed load must leave both the UI and backup intact.
    return decode(text), text
end

function Profiles:_write(path, text)
    checked(self.Storage.Write, path, text)
    local observed = checked(self.Storage.Read, path)
    assert(observed == text, "La relectura no coincide con el archivo escrito.")
end

function Profiles:_restore(previous, backup)
    local errors = {}
    for _, item in ipairs({{self.Path, previous}, {self.BackupPath, backup}}) do
        if item[2] ~= nil then
            local ok, problem = pcall(self._write, self, item[1], item[2])
            if not ok then table.insert(errors, tostring(problem)) end
        end
    end
    if #errors > 0 then return " No se pudo verificar la restauración: " .. table.concat(errors, "; ") end
    return ""
end

function Profiles:_commit(document, previous)
    -- Encode and validate before any directory or file writes.
    local text = Http:JSONEncode(document)
    decode(text)
    local backup = self:_text(self.BackupPath)
    if backup ~= nil and not pcall(decode, backup) then backup = nil end
    for _, folder in ipairs({"lumi-ui", "lumi-ui/config", self.Directory}) do
        if not self:_exists(folder) then checked(self.Storage.MakeFolder, folder) end
    end
    if previous ~= nil then
        local ok, problem = pcall(self._write, self, self.BackupPath, previous)
        if not ok then error(tostring(problem) .. self:_restore(nil, backup), 0) end
    end
    local ok, problem = pcall(self._write, self, self.Path, text)
    if not ok then
        local recovery=self:_restore(previous or Http:JSONEncode({Version=1,Profiles={}}), backup)
        if previous==nil then
            local read,residue=pcall(self._text,self,self.Path)
            if read and type(residue)=="string" and not pcall(decode,residue) then self.InitialResidue=residue end
        end
        error(tostring(problem) .. recovery,0)
    end
    self.InitialResidue=nil
    return backup
end

function Profiles:Save(name)
    return self:_operation(false, function()
        local document, previous = self:_read()
        if name == nil then name = self.Active or document.Active or "Predeterminado" end
        assert(validName(name), "El nombre del perfil debe contener entre 1 y 128 caracteres.")
        self:_cancel()
        local revision = self.Revision
        local state = self.Window:GetState()
        validateState(state)
        document.Profiles[name], document.Active = state, name
        self:_commit(document, previous)
        self.Active = name
        if revision == self.Revision then self.Dirty = false end
        self:_clearSaveError()
        return true
    end)
end

function Profiles:_load(name, options, allowEmpty)
    local document, previous = self:_read()
    if name == nil then name = self.Active or document.Active end
    if name == nil and allowEmpty then return true end
    assert(validName(name) and document.Profiles[name] ~= nil, "No se encontró el perfil solicitado.")
    local state = document.Profiles[name]
    local before = self.Window:GetState()
    self:_cancel()
    -- Persist a changed selection before applying it, so a storage failure
    -- cannot replace the live controls or publish an uncommitted active name.
    local changedActive = document.Active ~= name
    local backup
    if changedActive then
        document.Active = name
        backup = self:_commit(document, previous)
    end
    local called, ok, problem = pcall(self.Window.ApplyState, self.Window, state, options)
    if not called or ok ~= true then
        local issue = tostring(called and problem or ok)
        local restored, applied = pcall(self.Window.ApplyState, self.Window, before, {Silent = true})
        if not restored or applied ~= true then issue ..= " No se pudo restaurar el estado de la ventana." end
        if changedActive then issue ..= self:_restore(previous, backup) end
        error(issue, 0)
    end
    self.Active, self.Dirty = name, false
    self:_clearSaveError()
    return true
end

function Profiles:Load(name, options)
    return self:_operation(true, function() return self:_load(name, options, false) end)
end

function Profiles:List()
    local names = {}
    local ok, problem = self:_operation(false, function()
        local document = self:_read()
        for name in pairs(document.Profiles) do table.insert(names, name) end
        table.sort(names)
        return true
    end)
    if not ok then return {}, problem end
    return names
end

function Profiles:GetActive()
    return self.Active
end

function Profiles:Ready()
    if self.Destroyed then return false, "La ventana está cerrada." end
    if self.ReadyDone then
        if self.ReadyError then return false, self.ReadyError end
        return true
    end
    self.ReadyDone = true
    if not self.Configured then return true end
    if not self.Enabled then self.ReadyError = self.Error; return false, self.Error end
    if not self.AutoLoad then return true end
    local ok, problem = self:_operation(true, function() return self:_load(nil, nil, true) end)
    self.ReadyError = problem
    return ok, problem
end

function Profiles:_clearSaveError()
    local notice = self.SaveErrorNotice
    self.SaveErrorNotice, self.SaveErrorNotified = nil, false
    if notice and type(notice.Dismiss) == "function" then pcall(notice.Dismiss, notice) end
end

function Profiles:_saveFailed(problem)
    -- Keep every full diagnostic, but show one generic notice per failure episode.
    warn("[Lumi UI] No se pudo guardar el perfil: " .. tostring(problem))
    local window = self.Window
    if self.SaveErrorNotified or self.Destroyed or window._destroyed or window._closing
        or window.Runtime.Destroyed or type(window.Notify) ~= "function" then return end
    self.SaveErrorNotified = true
    local notice
    local ok, result = pcall(window.Notify, window, {
        Title = "No se pudo guardar el perfil",
        Message = "Tus cambios siguen en esta ventana. Puedes volver a intentarlo.",
        Kind = "Error", Duration = 6,
        Action = {Text = "Reintentar", Callback = function()
            if self.SaveErrorNotice ~= notice or self.Destroyed or window._destroyed or window._closing
                or window.Runtime.Destroyed then return end
            -- An explicit retry may show its own failure; background edits cannot
            -- repeatedly enqueue the same error while the provider is unavailable.
            self:_clearSaveError()
            local saved, issue = self:Flush()
            if not saved then self:_saveFailed(issue) end
        end},
    })
    if ok then
        notice, self.SaveErrorNotice = result, result
    else
        warn("[Lumi UI] No se pudo mostrar el aviso de guardado: " .. tostring(result))
    end
end

function Profiles:Changed()
    if self.Destroyed or not self.Enabled or not self.AutoSave or not self.ReadyDone or self.Loading
        or self.Window._destroyed or self.Window._closing or self.Window._applyingState
        or self.Window.Runtime.Destroyed then return false end
    self.Dirty = true
    self.Revision += 1
    self:_cancel()
    self.Pending = self.Window.Runtime:Delay(DEBOUNCE, function()
        self.Pending = nil
        local ok, problem = self:Flush()
        if not ok then self:_saveFailed(problem) end
    end)
    return true
end

function Profiles:Flush()
    self:_cancel()
    if self.Destroyed then return false, "La ventana está cerrada." end
    if not self.Dirty then return true end
    return self:Save(self.Active)
end

function Profiles:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    self:_cancel()
    self.Dirty = false
    self:_clearSaveError()
end

return Profiles
