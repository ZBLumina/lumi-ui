-- Appended to the real library by scripts/build.mjs. Run runtime.bundle.luau
-- in a Roblox client; this suite intentionally has no Instance/service mocks.
local RunService = game:GetService("RunService")
assert(RunService:IsClient(), "[LUMI TEST] Run this bundle in a Roblox client")

local cases = {}
local failures = {}
local passed = 0
local windows = {}
local cleanups = {}

local function equal(actual, expected, message)
    assert(actual == expected, (message or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function eventually(predicate, message)
    local deadline = os.clock() + 3
    repeat
        if predicate() then return end
        task.wait()
    until os.clock() >= deadline
    error(message or "timed out waiting for runtime", 2)
end

local function settle()
    -- Flush spawned callbacks and deferred destruction without synthesizing input.
    for _ = 1, 3 do task.wait() end
end

local function test(name, body)
    table.insert(cases, {Name = name, Body = body})
end

local function window()
    local result = Lumi:CreateWindow({Title = "Lumi runtime tests"})
    table.insert(windows, result)
    return result
end

local function section()
    local owner = window()
    local tab = owner:AddTab("Tests")
    return tab:AddSection("Runtime assertions"), owner, tab
end

local function visible(object)
    if typeof(object) ~= "Instance" or object.Parent == nil then return false end
    local current = object
    while current do
        if current:IsA("GuiObject") and not current.Visible then return false end
        if current:IsA("ScreenGui") and not current.Enabled then return false end
        current = current.Parent
    end
    return true
end

local function finite(value, message)
    assert(type(value) == "number" and value == value and math.abs(value) < math.huge, message or "expected finite number")
end

local function trackedConnections(owner)
    assert(type(owner.Runtime) == "table", "window.Runtime must expose its scope")
    equal(owner.Runtime.Destroyed, false, "new scope Destroyed")
    assert(type(owner.Runtime.Connections) == "table", "Runtime.Connections must be a table")
    local snapshot = {}
    for _, connection in pairs(owner.Runtime.Connections) do
        equal(typeof(connection), "RBXScriptConnection", "tracked connection type")
        table.insert(snapshot, connection)
    end
    assert(#snapshot > 0, "window must track its live engine connections")
    local connected = false
    for _, connection in ipairs(snapshot) do connected = connected or connection.Connected end
    assert(connected, "window must have live tracked connections before destruction")
    return snapshot
end

local function disconnected(owner, snapshot)
    eventually(function() return owner.Runtime.Destroyed == true end, "scope did not become Destroyed")
    for _, connection in ipairs(snapshot) do equal(connection.Connected, false, "leaked connection") end
    equal(owner.Root.Parent, nil, "destroyed root parent")
end

test("public windows, tabs, sections and control handles mount real GUI", function()
    local group, owner, tab = section()
    equal(typeof(owner.Root), "Instance", "Root type")
    assert(owner.Root:IsA("ScreenGui") and owner.Root.Parent ~= nil, "Root must be a mounted ScreenGui")
    assert(typeof(owner.Main) == "Instance" and owner.Main:IsA("GuiObject"), "Main must be a GuiObject")
    assert(owner.Main:IsDescendantOf(owner.Root), "Main must belong to Root")
    equal(owner.Tabs[1], tab, "public Tabs entry")
    local controls = {
        group:AddButton({Name = "Action", Action = "Run"}),
        group:AddToggle({Name = "Enabled", Default = false}),
        group:AddSlider({Name = "Level", Min = 0, Max = 10, Default = 4}),
        group:AddDropdown({Name = "Mode", Values = {"Alpha", "Beta"}, Default = "Alpha"}),
    }
    for index, control in ipairs(controls) do
        assert(typeof(control.Row) == "Instance" and control.Row:IsA("GuiObject"), "control.Row must be real GUI")
        assert(control.Row:IsDescendantOf(owner.Root), "control Row must belong to the window")
        for _, method in ipairs({"Get", "Focus"}) do
            equal(type(control[method]), "function", "control." .. method)
        end
        equal(type(control[index == 1 and "Press" or "Set"]), "function", "control action/setter")
        control:Focus()
        assert(visible(control.Row), "focused control must be on the visible page")
    end
end)

test("equal slider bounds remain a fixed value", function()
    local group = section()
    local slider = group:AddSlider({Name = "Fixed", Min = 10, Max = 10, Default = 100})
    equal(slider:Get(), 10, "fixed default")
    slider:Set(-50, true)
    equal(slider:Get(), 10, "fixed Set below range")
    slider:Set(500, true)
    equal(slider:Get(), 10, "fixed Set above range")
end)

test("reversed slider bounds normalize and setters clamp", function()
    local group = section()
    local slider = group:AddSlider({Name = "Reversed", Min = 20, Max = -5, Default = 6})
    equal(slider:Get(), 6, "reversed default")
    slider:Set(100, true)
    equal(slider:Get(), 20, "normalized upper bound")
    slider:Set(-100, true)
    equal(slider:Get(), -5, "normalized lower bound")
end)

test("slider defaults clamp at both endpoints", function()
    local group = section()
    equal(group:AddSlider({Name = "Low", Min = 0, Max = 10, Default = -50}):Get(), 0, "low default")
    equal(group:AddSlider({Name = "High", Min = 0, Max = 10, Default = 50}):Get(), 10, "high default")
end)

test("nonfinite slider defaults and setters fall back to finite bounded values", function()
    local group = section()
    for index, invalid in ipairs({0 / 0, math.huge, -math.huge}) do
        local slider = group:AddSlider({Name = "Nonfinite " .. index, Min = 3, Max = 9, Default = invalid})
        finite(slider:Get(), "nonfinite default escaped sanitization")
        assert(slider:Get() >= 3 and slider:Get() <= 9, "default fallback must remain bounded")
        slider:Set(7, true)
        slider:Set(invalid, true)
        finite(slider:Get(), "nonfinite Set escaped sanitization")
        assert(slider:Get() >= 3 and slider:Get() <= 9, "Set fallback must remain bounded")
    end
    for index, bounds in ipairs({{0 / 0, 9}, {3, math.huge}, {-math.huge, math.huge}}) do
        local slider = group:AddSlider({Name = "Invalid bounds " .. index, Min = bounds[1], Max = bounds[2], Default = 4})
        finite(slider:Get(), "nonfinite bounds must have a safe fallback")
        slider:Set(5, true)
        finite(slider:Get(), "Set after invalid bounds must stay finite")
    end
end)

test("dropdown invalid defaults select the first option and singletons work", function()
    local group = section()
    local dropdown = group:AddDropdown({Name = "Invalid default", Values = {"Alpha", "Beta"}, Default = "Missing"})
    equal(dropdown:Get(), "Alpha", "invalid default fallback")
    dropdown:Set("Beta", true)
    equal(dropdown:Get(), "Beta", "valid dropdown Set")
    equal(group:AddDropdown({Name = "Single", Values = {"Only"}, Default = "Missing"}):Get(), "Only", "singleton default")
end)

test("empty dropdown stays nil and can open and close safely", function()
    local group = section()
    local dropdown = group:AddDropdown({Name = "Empty", Values = {}, Default = "Missing"})
    equal(dropdown:Get(), nil, "empty default")
    pcall(function() dropdown:Set("Missing") end)
    equal(dropdown:Get(), nil, "empty invalid Set")
    dropdown:Open()
    dropdown:Close()
    equal(dropdown:Get(), nil, "empty menu operations")
end)

test("invalid dropdown setters preserve state and do not invoke callbacks", function()
    local group = section()
    local calls = 0
    local dropdown = group:AddDropdown({Name = "Reject", Values = {"Alpha", "Beta"}, Default = "Alpha",
        Callback = function() calls += 1 end})
    settle()
    local before = calls
    -- Either false/no-op or an explicit validation error is a valid rejection.
    pcall(function() dropdown:Set("Missing") end)
    equal(dropdown:Get(), "Alpha", "invalid Set changed selection")
    pcall(function() dropdown:Set(nil) end)
    equal(dropdown:Get(), "Alpha", "nil Set changed selection")
    settle()
    equal(calls, before, "invalid Set fired a callback")
end)

local setterCases = {
    {Name = "toggle", Add = "AddToggle", Options = {Name = "Toggle callbacks", Default = false}, Initial = false, Value = true},
    {Name = "slider", Add = "AddSlider", Options = {Name = "Slider callbacks", Min = 0, Max = 10, Default = 2}, Initial = 2, Value = 8},
    {Name = "dropdown", Add = "AddDropdown", Options = {Name = "Dropdown callbacks", Values = {"Alpha", "Beta"}, Default = "Alpha"}, Initial = "Alpha", Value = "Beta"},
}

for _, definition in ipairs(setterCases) do
    test(definition.Name .. " updates state before callback and supports silent Set", function()
        local group = section()
        local calls = {}
        local control
        local options = table.clone(definition.Options)
        options.Callback = function(value)
            table.insert(calls, {Argument = value, State = control and control:Get()})
        end
        control = group[definition.Add](group, options)
        equal(control:Get(), definition.Initial, "initial state")
        settle()
        local before = #calls
        control:Set(definition.Value)
        equal(control:Get(), definition.Value, "Set must update state immediately")
        eventually(function() return #calls > before end, "setter callback was not delivered")
        equal(#calls, before + 1, "one callback per changed value")
        equal(calls[before + 1].Argument, definition.Value, "callback argument")
        equal(calls[before + 1].State, definition.Value, "state visible inside callback")
        control:Set(definition.Initial, true)
        equal(control:Get(), definition.Initial, "silent state update")
        settle()
        equal(#calls, before + 1, "silent Set must suppress callback")
    end)
end

test("callback errors are isolated and later actions still work", function()
    local group = section()
    local calls = 0
    local toggle = group:AddToggle({Name = "Error callback", Default = false, Callback = function()
        calls += 1
        error("[LUMI TEST] intentional callback failure")
    end})
    settle()
    local before = calls
    toggle:Set(true)
    equal(toggle:Get(), true, "state survives callback error")
    eventually(function() return calls == before + 1 end, "failing callback did not run")
    toggle:Set(false)
    eventually(function() return calls == before + 2 end, "callbacks stopped after an error")
    equal(toggle:Get(), false, "later setter still works")
    local presses = 0
    local button = group:AddButton({Name = "Working action", Callback = function() presses += 1 end})
    equal(type(button.Press), "function", "button.Press")
    button:Press()
    eventually(function() return presses == 1 end, "action did not run after another callback failed")
end)

test("yielding callbacks do not block the setter", function()
    local group = section()
    local gate = Instance.new("BindableEvent")
    local release = false
    table.insert(cleanups, function() release = true; gate:Fire() end)
    table.insert(cleanups, function() gate:Destroy() end)
    local entered, finished, returned = false, false, false
    local toggle = group:AddToggle({Name = "Yielding callback", Default = false, Callback = function()
        entered = true
        if not release then gate.Event:Wait() end
        finished = true
    end})
    local setter = task.spawn(function() toggle:Set(true); returned = true end)
    table.insert(cleanups, function()
        if coroutine.status(setter) ~= "dead" then task.cancel(setter) end
    end)
    eventually(function() return entered end, "yielding callback did not enter")
    eventually(function() return returned end, "Set blocked on its yielding callback")
    equal(toggle:Get(), true, "yielding callback state")
    equal(finished, false, "callback should wait at the real BindableEvent")
    release = true
    gate:Fire()
    eventually(function() return finished end, "callback did not resume")
end)

test("active tab changes close the actual popup and change visible content", function()
    local group, owner, first = section()
    local dropdown = group:AddDropdown({Name = "Popup", Values = {"Alpha", "Beta"}})
    local second = owner:AddTab("Other")
    local other = second:AddSection("Other section"):AddToggle({Name = "Other toggle"})
    owner:SelectTab(first)
    assert(visible(dropdown.Row), "first tab must be visible")
    assert(not visible(other.Row), "inactive tab must be hidden")
    settle()
    dropdown:Open()
    local popup = owner.OpenDropdown
    assert(typeof(popup) == "Instance" and popup:IsA("GuiObject"), "Open must expose the actual menu Instance")
    assert(popup:IsDescendantOf(owner.Root) and visible(popup), "Open must show a menu in this window")
    equal(owner.PopupOwner, dropdown, "popup owner")
    settle()
    assert(popup.AbsoluteSize.X > 0 and popup.AbsoluteSize.Y > 0, "popup must have real layout bounds")
    local blocker = owner.Blocker
    if typeof(blocker) == "Instance" then
        assert(popup.ZIndex > blocker.ZIndex, "popup must render above its dismiss blocker")
    end
    dropdown:Close()
    assert(not visible(popup), "Close left the menu visible")
    equal(owner.OpenDropdown, nil, "Close retained active menu")
    equal(owner.PopupOwner, nil, "Close retained owner")
    dropdown:Open()
    popup = owner.OpenDropdown
    assert(typeof(popup) == "Instance" and visible(popup), "dropdown did not reopen")
    owner:SelectTab(second)
    assert(not visible(popup), "tab switch left the actual menu visible")
    equal(owner.OpenDropdown, nil, "tab switch retained active menu")
    equal(owner.PopupOwner, nil, "tab switch retained popup owner")
    assert(not visible(dropdown.Row), "previous page remained visible")
    assert(visible(other.Row), "selected page must become visible")
end)

for _, external in ipairs({false, true}) do
    test(external and "external Root destruction cleans global connections" or "Destroy is idempotent and disconnects global scopes", function()
        local _, owner = section()
        local ticks = 0
        equal(type(owner.Runtime.Connect), "function", "Runtime.Connect")
        local heartbeat = owner.Runtime:Connect(RunService.Heartbeat, function() ticks += 1 end)
        equal(typeof(heartbeat), "RBXScriptConnection", "real global service connection")
        eventually(function() return ticks > 0 end, "tracked Heartbeat connection never fired")
        local snapshot = trackedConnections(owner)
        if external then owner.Root:Destroy() else owner:Destroy() end
        disconnected(owner, snapshot)
        local stopped = ticks
        owner:Destroy()
        owner:Destroy()
        settle()
        equal(ticks, stopped, "global callback survived window destruction")
        disconnected(owner, snapshot)
    end)
end

test("destroying one window preserves another window scope", function()
    local _, first = section()
    local secondGroup, second = section()
    local toggle = secondGroup:AddToggle({Name = "Survivor", Default = false})
    local firstConnections = trackedConnections(first)
    local secondConnections = trackedConnections(second)
    first:Destroy()
    disconnected(first, firstConnections)
    equal(second.Runtime.Destroyed, false, "another scope was destroyed")
    equal(second.Root.Parent ~= nil, true, "another window was unmounted")
    local live = false
    for _, connection in ipairs(secondConnections) do live = live or connection.Connected end
    assert(live, "another window's connections were disconnected")
    toggle:Set(true, true)
    equal(toggle:Get(), true, "another window stopped responding")
end)

test("false toggle remains Disabled in the inspector", function()
    local group, owner = section()
    local toggle = group:AddToggle({Name = "Disabled control", Default = false})
    toggle:Focus()
    equal(owner.DetailValue.Text, "Disabled", "false is a value, not missing state")
    toggle:Set(true, true)
    equal(owner.DetailValue.Text, "Enabled", "selected inspector stays synchronized")
end)

test("initial centering uses root-local coordinates even under gethui insets", function()
    local owner = window()
    settle()
    local center = owner.Main.AbsolutePosition + owner.Main.AbsoluteSize / 2 - owner.Viewport.AbsolutePosition
    local viewport = owner.Viewport.AbsoluteSize
    assert(math.abs(center.X - viewport.X / 2) < 2, "window is not horizontally centered")
    assert(math.abs(center.Y - viewport.Y / 2) < 2, "window is not vertically centered")
end)

test("explicit focus is not overwritten by deferred first-control selection", function()
    local group, owner = section()
    group:AddToggle({Name = "First"})
    local slider = group:AddSlider({Name = "Selected", Default = 65})
    slider:Focus()
    settle()
    equal(owner.DetailTitle.Text, "Selected", "deferred focus replaced explicit focus")
end)

test("slider endpoints remain reachable when step does not divide the range", function()
    local group = section()
    local slider = group:AddSlider({Name = "Endpoints", Min = 0, Max = 1, Step = 0.3, Default = 1})
    equal(slider:Get(), 1, "maximum default")
    slider:Set(0, true)
    equal(slider:Get(), 0, "minimum")
    slider:Set(1, true)
    equal(slider:Get(), 1, "maximum Set")
end)

test("reloading the complete library destroys old windows and connections", function()
    local group, old = section()
    group:AddToggle({Name = "Before reload"})
    local snapshot = trackedConnections(old)
    local parent = old.Root.Parent
    Lumi = ReloadLumi()
    disconnected(old, snapshot)
    local current = window()
    local count = 0
    for _, child in ipairs(parent:GetChildren()) do
        if child.Name == "LumiUI" then count += 1 end
    end
    equal(count, 1, "reinjection must leave one new root")
    local toggle = current:AddTab("Reloaded"):AddSection("Fresh state"):AddToggle({Default = false})
    toggle:Set(true, true)
    equal(toggle:Get(), true, "new library controls still respond")
end)

test("compact fit remains bounded and leaves the workspace accessible", function()
    local owner = window()
    owner.Viewport.Size = UDim2.fromOffset(800, 600)
    settle()
    owner:Fit()
    settle()
    equal(owner.Inspector.Visible, false, "compact inspector must collapse")
    assert(owner.Main.AbsoluteSize.X <= 784 and owner.Main.AbsoluteSize.Y <= 584, "compact window overflows available viewport")
    assert(owner.Workspace.AbsoluteSize.X > 500, "compact workspace is too narrow")
    assert(owner.Chrome.Rule.AbsoluteSize.X <= owner.Chrome.AbsoluteSize.X + 1, "chrome divider overflows compact width")
end)

test("precise slider focus and blur without editing preserve state and callback count", function()
    local group = section()
    local calls = 0
    local slider = group:AddSlider({Name = "Precision", Min = -1, Max = 1, Step = 0.001, Default = 0.123,
        Callback = function() calls += 1 end})
    settle()
    local original = slider:Get()
    slider.ValueInput:CaptureFocus()
    settle()
    slider.ValueInput:ReleaseFocus()
    settle()
    equal(slider:Get(), original, "focus rounded a precise slider")
    equal(calls, 0, "focus must not invoke a change callback")
end)

test("destroy cancels suspended library-owned callbacks", function()
    local group, owner = section()
    local gate = Instance.new("BindableEvent")
    table.insert(cleanups, function() gate:Destroy() end)
    local entered, resumed = false, false
    local toggle = group:AddToggle({Callback = function()
        entered = true
        gate.Event:Wait()
        resumed = true
    end})
    toggle:Set(true)
    eventually(function() return entered end)
    owner:Destroy()
    gate:Fire()
    settle()
    equal(resumed, false, "callback resumed after destruction")
end)

test("obsolete library handles cannot create orphan windows", function()
    local old = Lumi
    Lumi = ReloadLumi()
    local ok, orphan = pcall(function() return old:CreateWindow({Title = "Obsolete"}) end)
    if ok and orphan then table.insert(windows, orphan) end
    equal(ok, false, "destroyed library allowed construction")
end)

test("short compact viewports retain usable text and scroll the workspace", function()
    local group, owner = section()
    local toggle = group:AddToggle({Name = "Readable control", Description = "Readable description"})
    owner.Viewport.Size = UDim2.fromOffset(640, 360)
    settle()
    owner:Fit()
    settle()
    assert(toggle.Label.TextSize * owner.Scale >= 11, "compact body text shrinks below 11 pixels")
    assert(owner.Main.AbsoluteSize.X <= 624 and owner.Main.AbsoluteSize.Y <= 344, "small viewport overflow")
    assert(owner.Workspace.AbsoluteSize.Y > 180, "workspace has no usable scrolling region")
end)

local function cleanupCase()
    local errors = {}
    -- Release yielding callbacks before disposing their real BindableEvents.
    for _, cleanup in ipairs(cleanups) do
        local ok, problem = pcall(cleanup)
        if not ok then table.insert(errors, tostring(problem)) end
    end
    table.clear(cleanups)
    for _, owner in ipairs(windows) do
        local ok, problem = pcall(function() owner:Destroy() end)
        if not ok then table.insert(errors, tostring(problem)) end
        -- Still remove the actual UI if the library's Destroy itself failed.
        pcall(function() owner.Root:Destroy() end)
        pcall(function() owner.Runtime:Destroy() end)
    end
    table.clear(windows)
    return errors
end

for _, case in ipairs(cases) do
    local ok, problem = xpcall(case.Body, debug.traceback)
    local cleanupErrors = cleanupCase()
    if #cleanupErrors > 0 then
        ok = false
        problem = tostring(problem or "") .. "\ncleanup: " .. table.concat(cleanupErrors, "; ")
    end
    if ok then
        passed += 1
        print("[LUMI TEST] PASS " .. case.Name)
    else
        table.insert(failures, case.Name .. ": " .. tostring(problem))
        warn("[LUMI TEST] FAIL " .. failures[#failures])
    end
end

-- Also clear the library registry and any windows retained by the library.
local cleanupOK, cleanupProblem = pcall(function() Lumi:Destroy(); Lumi:Destroy() end)
if not cleanupOK then table.insert(failures, "library cleanup: " .. tostring(cleanupProblem)) end
print(string.format("[LUMI TEST] summary: %d/%d passed, %d failures", passed, #cases, #failures))
if #failures > 0 then error("[LUMI TEST] failures:\n" .. table.concat(failures, "\n"), 0) end
return Lumi
