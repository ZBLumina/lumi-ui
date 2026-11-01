-- Inject before cleanupCase in runtime.spec.luau, after its shared helpers.
-- Only the storage provider is substituted; windows, state and controls are real.
do
    local HttpService = game:GetService("HttpService")
    local sampleText = "Mi perfil áéíóú / ação 🙂\nsegunda línea"

    local function primaryPath(key)
        return "lumi-ui/config/" .. key .. "/profiles.json"
    end

    local function memoryStorage()
        local memory = {Files = {}, Folders = {}, Accesses = {}, Writes = {}, ReadErrors = {}}
        local function access(operation, path)
            table.insert(memory.Accesses, {Operation = operation, Path = path})
            assert(type(path) == "string", "storage path must be a string")
            assert(path == "lumi-ui" or path:sub(1, 8) == "lumi-ui/", "storage escaped lumi-ui")
            assert(not path:find("\\", 1, true) and not path:find(":", 1, true), "absolute storage path")
            assert(not path:find("//", 1, true), "empty storage path segment")
            for segment in path:gmatch("[^/]+") do
                assert(segment ~= "." and segment ~= "..", "storage traversal")
            end
        end
        memory.Adapter = {
            Read = function(path)
                access("Read", path)
                if memory.ReadErrors[path] or memory.ReadErrors.All then
                    error("[profiles test] provider read rejected", 0)
                end
                return memory.Files[path]
            end,
            Write = function(path, text)
                access("Write", path)
                assert(type(text) == "string", "storage must receive serialized text")
                table.insert(memory.Writes, {Path = path, Text = text})
                if path == memory.FaultPath and memory.WriteFault then
                    -- One rejected operation; subsequent rollback writes can succeed.
                    local fault = memory.WriteFault
                    memory.WriteFault = nil
                    if fault == "throw" then error("[profiles test] provider write rejected", 0) end
                    if fault == "false" then return false, "[profiles test] provider write rejected" end
                    if fault == "drop" then return end
                    if fault == "corrupt" then memory.Files[path] = "{"; return end
                end
                memory.Files[path] = text
            end,
            Exists = function(path)
                access("Exists", path)
                return memory.Files[path] ~= nil or memory.Folders[path] == true
            end,
            MakeFolder = function(path)
                access("MakeFolder", path)
                memory.Folders[path] = true
            end,
        }
        return memory
    end

    local function succeeded(ok, problem, operation)
        equal(ok, true, operation .. " failed: " .. tostring(problem))
    end

    local function rejected(ok, problem, operation)
        equal(ok, false, operation .. " must not report success")
        assert(type(problem) == "string" and #problem > 0, operation .. " must explain the failure")
    end

    local function createFixture(memory, key, autoLoad, autoSave)
        local owner = Lumi:CreateWindow({Title = "Profile tests", Animations = false, ToggleKey = false,
            Config = {Key = key, AutoLoad = autoLoad == true, AutoSave = autoSave == true, Storage = memory.Adapter}})
        table.insert(windows, owner)
        local first = owner:AddTab("Inicio", {Id = "profiles-main"})
        local group = first:AddSection("Perfiles", {Id = "profiles-section"})
        local fixture = {Window = owner, First = first, Calls = {}}
        local function callback(id)
            return function(value)
                table.insert(fixture.Calls, {Id = id, Value = value})
            end
        end
        fixture.Toggle = group:AddToggle({Id = "profiles-toggle", Name = "Activado", Default = false,
            Callback = callback("profiles-toggle")})
        fixture.Gain = group:AddSlider({Id = "profiles-gain", Name = "Intensidad", Min = 0, Max = 10,
            Step = .25, Default = 1.25, Callback = callback("profiles-gain")})
        fixture.Mode = group:AddDropdown({Id = "profiles-mode", Name = "Modo", Default = 10,
            Values = {{Value = 10, Label = "Alpha"}, {Value = 20, Label = "Beta"}},
            Callback = callback("profiles-mode")})
        fixture.Note = group:AddInput({Id = "profiles-note", Name = "Notas personales", Default = "initial",
            MultiLine = true, Callback = callback("profiles-note")})
        fixture.Button = group:AddButton({Id = "profiles-button", Name = "Acción",
            Callback = callback("profiles-button")})
        fixture.ReadOnly = group:AddInput({Id = "profiles-readonly", Name = "Material", ReadOnly = true,
            Default = "original", Callback = callback("profiles-readonly")})
        fixture.Transient = group:AddToggle({Id = "profiles-transient", Name = "Temporal", Persist = false,
            Default = false, Callback = callback("profiles-transient")})
        fixture.Second = owner:AddTab("Ayuda", {Id = "profiles-other"})
        return fixture
    end

    local function savedValues(fixture)
        fixture.Toggle:Set(true, true)
        fixture.Gain:Set(3.25, true)
        fixture.Gain:SetEnabled(false)
        fixture.Mode:Set(20, true)
        fixture.Note:Set(sampleText, true)
    end

    local function initialValues(fixture)
        fixture.Toggle:Set(false, true)
        fixture.Gain:SetEnabled(true)
        fixture.Gain:Set(1.25, true)
        fixture.Mode:Set(10, true)
        fixture.Note:Set("initial", true)
    end

    local function assertValues(fixture, toggle, gain, note, mode, enabled)
        equal(fixture.Toggle:Get(), toggle, "native toggle value")
        equal(fixture.Gain:Get(), gain, "native slider value")
        equal(fixture.Note:Get(), note, "native input value")
        equal(fixture.Mode:Get(), mode, "native numeric dropdown value")
        equal(fixture.Gain:IsEnabled(), enabled, "native slider enabled state")
        assert(fixture.Note.Input:IsA("TextBox") and fixture.Note.Input:IsDescendantOf(fixture.Window.Root),
            "profile test must exercise the mounted TextBox")
        equal(fixture.Note.Input.Text, note, "rendered input text")
        equal(tonumber(fixture.Gain.ValueInput.Text), gain, "rendered slider text")
        equal(fixture.Mode.Input.Selection.Text, mode == 20 and "Beta" or "Alpha", "rendered dropdown label")
        equal(fixture.Toggle.Input.Switch.Thumb.Position.X.Offset, toggle and 23 or 3, "rendered toggle thumb")
    end

    local function assertState(state, toggle, gain, note, mode, enabled)
        equal(state.Version, 1, "serialized state version")
        assert(type(state.Window) == "table" and type(state.Controls) == "table", "missing state schema")
        for _, entry in ipairs({
            {"profiles-toggle", "Toggle", toggle, true},
            {"profiles-gain", "Slider", gain, enabled},
            {"profiles-mode", "Dropdown", mode, true},
            {"profiles-note", "Input", note, true},
        }) do
            local control = state.Controls[entry[1]]
            assert(type(control) == "table", "missing persisted control " .. entry[1])
            equal(control.Kind, entry[2], entry[1] .. " Kind")
            equal(control.Value, entry[3], entry[1] .. " typed Value")
            equal(control.Enabled, entry[4], entry[1] .. " Enabled")
        end
        equal(state.Controls["profiles-button"], nil, "buttons must not persist")
        equal(state.Controls["profiles-readonly"], nil, "readonly inputs must not persist")
        equal(state.Controls["profiles-transient"], nil, "Persist=false controls must not persist")
    end

    local function serializedStates(text)
        assert(type(text) == "string" and #text > 0, "profile file must contain real JSON")
        local decoded = HttpService:JSONDecode(text)
        local states = {}
        -- The on-disk envelope is private; the Version=1 window state is public.
        local function visit(value)
            if type(value) ~= "table" then return end
            if value.Version == 1 and type(value.Window) == "table" and type(value.Controls) == "table" then
                table.insert(states, value)
                return
            end
            for _, child in pairs(value) do visit(child) end
        end
        visit(decoded)
        assert(#states > 0, "JSON contains no Version=1 window state")
        return states
    end

    local function stateWithGain(text, gain)
        for _, state in ipairs(serializedStates(text)) do
            local control = state.Controls["profiles-gain"]
            if control and control.Value == gain then return state end
        end
        error("serialized profile missing literal slider value " .. tostring(gain), 2)
    end

    local function backups(memory, key)
        local found = {}
        local prefix = "lumi-ui/config/" .. key .. "/"
        for path, text in pairs(memory.Files) do
            if path ~= primaryPath(key) and path:sub(1, #prefix) == prefix then
                local ok = pcall(serializedStates, text)
                if ok then found[path] = text end
            end
        end
        assert(next(found) ~= nil, "saving over a valid store must leave a valid serialized backup")
        return found
    end

    local function assertFiles(memory, expected, message)
        for path, text in pairs(expected) do equal(memory.Files[path], text, message .. ": " .. path) end
    end

    local function primaryWrites(memory, key)
        local count = 0
        for _, write in ipairs(memory.Writes) do
            if write.Path == primaryPath(key) then count += 1 end
        end
        return count
    end

    local function viewportPosition(owner)
        local center = owner.Main.AbsolutePosition + owner.Main.AbsoluteSize / 2 - owner.Viewport.AbsolutePosition
        local viewport = owner.Viewport.AbsoluteSize
        assert(viewport.X > 0 and viewport.Y > 0, "window needs a laid out viewport")
        return center.X / viewport.X, center.Y / viewport.Y
    end

    local function near(actual, expected, tolerance, message)
        assert(type(actual) == "number" and math.abs(actual - expected) <= tolerance,
            message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    end

    test("profiles round-trip named typed state, language, page, viewport position and native controls", function()
        local memory, key = memoryStorage(), "profiles-roundtrip"
        local fixture = createFixture(memory, key)
        local owner = fixture.Window
        owner:Ready()
        savedValues(fixture)
        owner:SetLanguage("pt")
        owner:SetPreference("Inspector", false)
        owner:SetPreference("Decoration", 37)
        owner:SelectTab(fixture.Second)
        owner:FinishEntrance()
        settle()
        local viewport = owner.Viewport.AbsoluteSize
        owner:SetCenter(Vector2.new(viewport.X * .52, viewport.Y * .53))
        settle()
        local x, y = viewportPosition(owner)
        local ok, problem = owner:SaveProfile("Trabalho")
        succeeded(ok, problem, "save Trabalho")
        equal(owner:GetActiveProfile(), "Trabalho", "saved active name")
        local state = stateWithGain(memory.Files[primaryPath(key)], 3.25)
        assertState(state, true, 3.25, sampleText, 20, false)
        equal(state.Window.Page, "profiles-other", "stable page ID")
        equal(state.Window.Preferences.Language, "pt", "serialized language")
        equal(state.Window.Preferences.Inspector, false, "serialized false preference")
        equal(state.Window.Preferences.Decoration, 37, "serialized numeric preference")
        near(state.Window.Position.X, x, .0001, "serialized horizontal viewport ratio")
        near(state.Window.Position.Y, y, .0001, "serialized vertical viewport ratio")

        initialValues(fixture)
        owner:SetLanguage("es")
        owner:SetPreference("Inspector", true)
        owner:SetPreference("Decoration", 100)
        owner:SelectTab(fixture.First)
        owner:SetCenter(owner.Viewport.AbsoluteSize / 2)
        ok, problem = owner:SaveProfile("Base")
        succeeded(ok, problem, "save Base")
        local names = owner:ListProfiles()
        equal(type(names), "table", "ListProfiles result")
        equal(#names, 2, "two distinct named profiles")
        assert(table.find(names, "Trabalho") and table.find(names, "Base"), "ListProfiles lost a name")
        assertState(stateWithGain(memory.Files[primaryPath(key)], 1.25), false, 1.25, "initial", 10, true)
        fixture.ReadOnly:Set("live readonly text", true)
        fixture.Transient:Set(true, true)
        settle()
        table.clear(fixture.Calls)

        ok, problem = owner:LoadProfile("Trabalho")
        succeeded(ok, problem, "load Trabalho")
        eventually(function() return #fixture.Calls == 4 end, "profile load did not invoke the four value callbacks")
        settle()
        assertValues(fixture, true, 3.25, sampleText, 20, false)
        equal(owner:GetActiveProfile(), "Trabalho", "loaded active name")
        equal(owner:GetLanguage(), "pt", "restored language")
        equal(owner.Preferences.Inspector, false, "restored Inspector preference")
        equal(owner.Preferences.Decoration, 37, "restored Decoration preference")
        equal(owner.ActiveTab, fixture.Second, "restored actual page")
        equal(fixture.Second.Page.Visible, true, "restored page visibility")
        equal(fixture.First.Page.Visible, false, "previous page visibility")
        equal(fixture.ReadOnly:Get(), "live readonly text", "load overwrote a readonly value")
        equal(fixture.Transient:Get(), true, "load overwrote Persist=false")
        local restoredX, restoredY = viewportPosition(owner)
        near(restoredX, x, 2 / owner.Viewport.AbsoluteSize.X, "restored horizontal position")
        near(restoredY, y, 2 / owner.Viewport.AbsoluteSize.Y, "restored vertical position")
        local expected = {["profiles-toggle"] = true, ["profiles-gain"] = 3.25,
            ["profiles-mode"] = 20, ["profiles-note"] = sampleText}
        local seen = {}
        for _, call in ipairs(fixture.Calls) do
            assert(expected[call.Id] ~= nil and not seen[call.Id], "unexpected or duplicate load callback")
            equal(call.Value, expected[call.Id], "typed load callback argument")
            seen[call.Id] = true
        end
        assertState(owner:GetState(), true, 3.25, sampleText, 20, false)

        initialValues(fixture)
        settle()
        table.clear(fixture.Calls)
        ok, problem = owner:LoadProfile("Trabalho", {Silent = true})
        succeeded(ok, problem, "silent load")
        settle()
        assertValues(fixture, true, 3.25, sampleText, 20, false)
        equal(#fixture.Calls, 0, "Silent=true invoked callbacks")
    end)

    test("profiles autoload the persisted active name only after a new same-Key window is Ready", function()
        local memory, key = memoryStorage(), "profiles-ready"
        local first = createFixture(memory, key)
        first.Window:Ready()
        local ok, problem = first.Window:SaveProfile("Base")
        succeeded(ok, problem, "save inactive profile")
        savedValues(first)
        first.Window:SetLanguage("pt")
        first.Window:SelectTab(first.Second)
        ok, problem = first.Window:SaveProfile("Ativo")
        succeeded(ok, problem, "save active profile")
        first.Window:Destroy()

        local second = createFixture(memory, key, true)
        settle()
        assertValues(second, false, 1.25, "initial", 10, true)
        equal(second.Window:GetLanguage(), "es", "autoload ran during construction")
        table.clear(second.Calls)
        second.Window:Ready()
        eventually(function() return second.Window:GetActiveProfile() == "Ativo" and second.Note:Get() == sampleText end,
            "Ready did not restore the previously active named profile")
        settle()
        assertValues(second, true, 3.25, sampleText, 20, false)
        equal(second.Window:GetLanguage(), "pt", "same-Key autoload language")
        equal(second.Window.ActiveTab, second.Second, "same-Key autoload page")
        equal(#second.Calls, 4, "autoload must honor normal callback behavior")
        second.Window:Ready()
        settle()
        equal(#second.Calls, 4, "repeated Ready loaded twice")

        local isolated = createFixture(memory, "profiles-other-key", true)
        isolated.Window:Ready()
        settle()
        assertValues(isolated, false, 1.25, "initial", 10, true)
    end)

    test("profiles reject missing names without changing the current native controls or active name", function()
        local memory, key = memoryStorage(), "profiles-missing"
        local fixture = createFixture(memory, key)
        fixture.Window:Ready()
        savedValues(fixture)
        local ok, problem = fixture.Window:SaveProfile("Existing")
        succeeded(ok, problem, "save Existing")
        local text = memory.Files[primaryPath(key)]
        table.clear(fixture.Calls)
        ok, problem = fixture.Window:LoadProfile("Missing")
        rejected(ok, problem, "missing profile load")
        settle()
        assertValues(fixture, true, 3.25, sampleText, 20, false)
        equal(fixture.Window:GetActiveProfile(), "Existing", "missing load changed active profile")
        equal(memory.Files[primaryPath(key)], text, "missing load rewrote the store")
        equal(#fixture.Calls, 0, "missing load invoked callbacks")
    end)

    for _, fault in ipairs({"corrupt", "read-error"}) do
        test("profiles " .. fault .. " cannot replace a valid backup or the current UI", function()
            local memory, key = memoryStorage(), "profiles-" .. fault
            local fixture = createFixture(memory, key)
            local owner = fixture.Window
            owner:Ready()
            local ok, problem = owner:SaveProfile("Existing")
            succeeded(ok, problem, "seed valid store")
            savedValues(fixture)
            ok, problem = owner:SaveProfile("Existing")
            succeeded(ok, problem, "seed valid backup")
            local validBackups = backups(memory, key)
            local previous = memory.Files[primaryPath(key)]
            if fault == "corrupt" then memory.Files[primaryPath(key)] = "{ invalid JSON"
            else memory.ReadErrors.All = true end
            local writesBefore = #memory.Writes
            table.clear(fixture.Calls)
            ok, problem = owner:LoadProfile("Existing")
            rejected(ok, problem, fault .. " load")
            settle()
            assertValues(fixture, true, 3.25, sampleText, 20, false)
            equal(owner:GetActiveProfile(), "Existing", "failed load changed active name")
            equal(#fixture.Calls, 0, "failed load invoked callbacks")
            ok, problem = owner:SaveProfile("Must not appear")
            rejected(ok, problem, fault .. " save")
            equal(#memory.Writes, writesBefore, "unreadable data was treated as an empty store")
            assertFiles(memory, validBackups, "failure overwrote the valid backup")
            assertValues(fixture, true, 3.25, sampleText, 20, false)
            memory.ReadErrors.All = nil
            memory.Files[primaryPath(key)] = previous
            equal(#owner:ListProfiles(), 1, "failed save created a phantom profile")
            ok, problem = owner:LoadProfile()
            succeeded(ok, problem, "load active profile after provider recovery")
        end)
    end

    for _, fault in ipairs({"throw", "false", "drop", "corrupt"}) do
        test("profiles rejected " .. fault .. " writes report failure and retain the previous serialized profile", function()
            local memory, key = memoryStorage(), "profiles-write-" .. fault
            local fixture = createFixture(memory, key)
            local owner = fixture.Window
            owner:Ready()
            savedValues(fixture)
            local ok, problem = owner:SaveProfile("Previous")
            succeeded(ok, problem, "seed Previous")
            -- A different second commit ensures a real previous-state backup.
            initialValues(fixture)
            ok, problem = owner:SaveProfile("Previous")
            succeeded(ok, problem, "seed backup")
            backups(memory, key)
            local previous = memory.Files[primaryPath(key)]
            savedValues(fixture)
            memory.FaultPath, memory.WriteFault = primaryPath(key), fault
            ok, problem = owner:SaveProfile("Rejected")
            rejected(ok, problem, fault .. " save/readback")
            equal(memory.WriteFault, nil, "injected primary write failure was not reached")
            equal(memory.Files[primaryPath(key)], previous, "failed commit did not retain the previous file")
            assertState(stateWithGain(memory.Files[primaryPath(key)], 1.25), false, 1.25, "initial", 10, true)
            backups(memory, key)
            equal(owner:GetActiveProfile(), "Previous", "failed save published a new active name")
            equal(#owner:ListProfiles(), 1, "failed save published an uncommitted profile")
            settle()
            assertValues(fixture, true, 3.25, sampleText, 20, false)
            ok, problem = owner:LoadProfile()
            succeeded(ok, problem, "load previous committed profile")
            settle()
            assertValues(fixture, false, 1.25, "initial", 10, true)
        end)
    end

    test("profiles autosave debounces a burst into one verified final native state", function()
        local memory, key = memoryStorage(), "profiles-debounce"
        local fixture = createFixture(memory, key, false, true)
        local owner = fixture.Window
        owner:Ready()
        local ok, problem = owner:SaveProfile("Daily")
        succeeded(ok, problem, "seed autosave profile")
        settle()
        task.wait(.65)
        local before = primaryWrites(memory, key)
        fixture.Gain:Set(2)
        fixture.Gain:Set(4)
        fixture.Gain:Set(7.75)
        fixture.Note:Set("latest edited text")
        fixture.Toggle:Set(true)
        fixture.Mode:Set(20)
        equal(primaryWrites(memory, key), before, "autosave wrote synchronously instead of debouncing")
        eventually(function() return primaryWrites(memory, key) > before end, "autosave never committed the edits")
        task.wait(.65)
        equal(primaryWrites(memory, key), before + 1, "one burst produced multiple primary commits")
        assertState(stateWithGain(memory.Files[primaryPath(key)], 7.75), true, 7.75, "latest edited text", 20, true)
        assertValues(fixture, true, 7.75, "latest edited text", 20, true)
        equal(owner:GetActiveProfile(), "Daily", "autosave changed the profile name")
    end)

    test("profiles autosave ignores construction, Ready autoload and explicit loading callbacks", function()
        local memory, key = memoryStorage(), "profiles-loading"
        local seed = createFixture(memory, key)
        seed.Window:Ready()
        savedValues(seed)
        local ok, problem = seed.Window:SaveProfile("Loaded")
        succeeded(ok, problem, "seed Loaded")
        seed.Window:Destroy()
        local stored, writes = memory.Files[primaryPath(key)], primaryWrites(memory, key)
        local fixture = createFixture(memory, key, true, true)
        task.wait(.65)
        equal(memory.Files[primaryPath(key)], stored, "construction overwrote the saved profile")
        equal(primaryWrites(memory, key), writes, "construction triggered autosave before Ready")
        fixture.Window:Ready()
        eventually(function() return fixture.Note:Get() == sampleText end, "autoload did not apply the saved controls")
        task.wait(.65)
        assertValues(fixture, true, 3.25, sampleText, 20, false)
        equal(#fixture.Calls, 4, "autoload callbacks were suppressed to hide an autosave loop")
        equal(primaryWrites(memory, key), writes, "autoload changes scheduled autosave")
        equal(memory.Files[primaryPath(key)], stored, "autoload rewrote the persisted state")

        -- Loading supersedes an edit that has not yet reached the debounce timer.
        fixture.Gain:Set(9.5)
        ok, problem = fixture.Window:LoadProfile()
        succeeded(ok, problem, "explicit active-profile load")
        task.wait(.65)
        assertValues(fixture, true, 3.25, sampleText, 20, false)
        equal(primaryWrites(memory, key), writes, "load or its pending edit triggered autosave")
        equal(memory.Files[primaryPath(key)], stored, "loading replaced a committed profile")
    end)

    test("profiles keys and profile names cannot choose arbitrary filesystem paths", function()
        for _, key in ipairs({"../../outside", "..\\..\\outside", "C:\\outside", "/outside"}) do
            local memory = memoryStorage()
            -- Rejecting an unsafe key or normalizing it to a safe directory is valid.
            local created, fixture = pcall(createFixture, memory, key)
            if created then
                fixture.Window:Ready()
                local ok, problem = fixture.Window:SaveProfile("../../named-profile")
                if ok then
                    local found = false
                    for path, text in pairs(memory.Files) do
                        if path:match("^lumi%-ui/config/[^/]+/profiles%.json$") then
                            serializedStates(text)
                            found = true
                        end
                    end
                    assert(found, "successful save did not use config/<safeKey>/profiles.json")
                else rejected(ok, problem, "unsafe-key save") end
            else
                assert(#tostring(fixture) > 0, "unsafe-key rejection needs an error")
            end
            -- Check recorded attempts as well: swallowing a provider error does
            -- not make an out-of-bounds filesystem operation acceptable.
            for _, operation in ipairs(memory.Accesses) do
                local path = operation.Path
                assert(path == "lumi-ui" or path:sub(1, 8) == "lumi-ui/", "key escaped storage root")
                assert(not path:find("\\", 1, true) and not path:find(":", 1, true), "key produced an absolute path")
                for segment in path:gmatch("[^/]+") do
                    assert(segment ~= "." and segment ~= "..", "key produced a traversal attempt")
                end
                if operation.Operation == "Read" or operation.Operation == "Write" then
                    assert(path:match("^lumi%-ui/config/[^/]+/[^/]+$"), "profile name created an arbitrary path")
                end
            end
        end
    end)
end
