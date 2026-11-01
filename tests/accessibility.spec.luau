-- Register in the runtime.spec.luau helper scope, before its case runner.
-- Real Roblox GUI/input only. Main owns bundle integration and the RED run.
do
    local GuiService = game:GetService("GuiService")
    local Input = game:GetService("UserInputService")
    local viewports = {Vector2.new(320, 500), Vector2.new(1920, 1080)}

    local function fit(owner, viewport)
        owner.Viewport.Size = UDim2.fromOffset(viewport.X, viewport.Y)
        settle()
        owner:Fit()
        owner:FinishEntrance()
        owner:FinishPages()
        settle()
    end

    local function near(actual, expected, message)
        assert(math.abs(actual - expected) <= 1, message .. ": expected about " .. expected .. ", got " .. actual)
    end

    local function inside(object, container, message)
        local start, size = object.AbsolutePosition, object.AbsoluteSize
        local edge, bounds = container.AbsolutePosition, container.AbsoluteSize
        assert(size.X > 0 and size.Y > 0, message .. " has no rendered area")
        assert(start.X >= edge.X - 1 and start.Y >= edge.Y - 1, message .. " escapes its top/left edge")
        assert(start.X + size.X <= edge.X + bounds.X + 1, message .. " escapes its right edge")
        assert(start.Y + size.Y <= edge.Y + bounds.Y + 1, message .. " escapes its bottom edge")
    end

    local function shown(object)
        if typeof(object) ~= "Instance" or not object.Parent then return false end
        local ancestor = object
        while ancestor do
            if ancestor:IsA("GuiObject") and not ancestor.Visible then return false end
            if ancestor:IsA("ScreenGui") and not ancestor.Enabled then return false end
            ancestor = ancestor.Parent
        end
        return true
    end

    local function rowsFit(controls, message)
        local previous
        for _, control in ipairs(controls) do
            local row = control.Row
            assert(row.AbsoluteSize.X > 0 and row.AbsoluteSize.Y > 0, message .. " row is not laid out")
            if previous then
                assert(row.AbsolutePosition.Y >= previous.AbsolutePosition.Y + previous.AbsoluteSize.Y - 1,
                    message .. " neighboring rows overlap")
            end
            for _, object in ipairs(row:GetDescendants()) do
                if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
                    if shown(object) and object.Text ~= "" then
                        inside(object, row, message .. " / " .. object.Name)
                        assert(object.TextFits, message .. " / " .. object.Name .. " clips or truncates its text")
                        assert(object.TextBounds.X <= object.AbsoluteSize.X + 1,
                            message .. " / " .. object.Name .. " text exceeds its width")
                        assert(object.TextBounds.Y <= object.AbsoluteSize.Y + 1,
                            message .. " / " .. object.Name .. " text exceeds its height")
                    end
                end
            end
            inside(control.Input, row, message .. " input")
            if control.ValueInput then inside(control.ValueInput, row, message .. " value input") end
            local caption = control.DescriptionLabel.Visible and control.DescriptionLabel or control.Label
            assert(caption.AbsolutePosition.Y >= control.Label.AbsolutePosition.Y, message .. " caption order reversed")
            if caption ~= control.Label then
                assert(caption.AbsolutePosition.Y >= control.Label.AbsolutePosition.Y + control.Label.AbsoluteSize.Y - 1,
                    message .. " title overlaps description")
            end
            -- A whole-row toggle hit target intentionally overlays its caption.
            local field = control.Kind == "Toggle" and control.Input.Switch
                or (control.Field or (control.ValueInput and control.ValueInput.Parent) or control.Input)
            inside(field, row, message .. " field")
            local beside = field.AbsolutePosition.X >= caption.AbsolutePosition.X + caption.AbsoluteSize.X - 1
            local below = field.AbsolutePosition.Y >= caption.AbsolutePosition.Y + caption.AbsoluteSize.Y - 1
            assert(beside or below, message .. " field overlaps caption")
            previous = row
        end
    end

    local function realKeys()
        local vim = game:GetService("VirtualInputManager")
        local previousSelection, previousEditor = GuiService.SelectedObject, Input:GetFocusedTextBox()
        local held = {}
        if previousEditor then previousEditor:ReleaseFocus() end
        GuiService.SelectedObject = nil
        table.insert(cleanups, function()
            for key in pairs(held) do vim:SendKeyEvent(false, key, false, game) end
            local editor = Input:GetFocusedTextBox()
            if editor then editor:ReleaseFocus() end
            GuiService.SelectedObject = previousSelection and previousSelection.Parent and previousSelection or nil
            if previousEditor and previousEditor.Parent then previousEditor:CaptureFocus() end
        end)
        local function change(key, down)
            if down then held[key] = true end
            vim:SendKeyEvent(down, key, false, game)
            if not down then held[key] = nil end
        end
        return function(key, reverse)
            if reverse then change(Enum.KeyCode.LeftShift, true) end
            change(key, true)
            -- Key events and text events are separate in Roblox's native input
            -- recorder. Keep the real key, then deliver its printable character
            -- only while the actual TextBox still owns editing focus.
            if Input:GetFocusedTextBox() and (key==Enum.KeyCode.Space or key==Enum.KeyCode.D) then
                vim:SendTextInputCharacterEvent(key==Enum.KeyCode.Space and " " or "d",game)
            end
            task.wait(.03)
            change(key, false)
            if reverse then change(Enum.KeyCode.LeftShift, false) end
            settle()
        end
    end

    local function traversal(owner, press)
        local targets = owner.Keyboard:GetTargets()
        assert(type(targets) == "table" and #targets > 0, "keyboard has no live targets")
        local first, visited = GuiService.SelectedObject, {}
        assert(first ~= nil, "traversal needs a selected starting target")
        for _ = 1, #targets do
            local selected = GuiService.SelectedObject
            assert(shown(selected) and selected:IsDescendantOf(owner.Root), "Tab selected hidden, destroyed or foreign GUI")
            equal(selected.Selectable, true, "Tab target is not selectable")
            assert(not visited[selected], "Tab repeats a target before completing its cycle")
            visited[selected] = true
            press(Enum.KeyCode.Tab)
        end
        equal(GuiService.SelectedObject, first, "Tab does not wrap through every live target")
        return visited
    end

    -- Catches ignored/compounding scales, stale dynamic font writes and fixed row heights.
    test("text scale grows real fonts and reflows rows at 320x500 and 1920x1080", function()
        for _, viewport in ipairs(viewports) do
            local group, owner, tab = section()
            owner:SetPreference("Animations", false)
            local button = group:AddButton({Id = "a11y-reflow", Name = "Restablecer las preferencias de esta ventana",
                Description = "Recupera los ajustes de esta sesión y conserva tus notas personales para continuar trabajando con comodidad.",
                Action = "Restablecer"})
            local following = group:AddToggle({Id = "a11y-following", Name = "Animaciones",
                Description = "Aperturas, transiciones y seguimiento suave."})
            fit(owner, viewport)
            button:Focus()
            settle()
            equal(owner.Preferences.TextScale, 1, "default text scale")
            local labels = {button.Label, button.DescriptionLabel, button.Input, tab.Title, tab.Subtitle,
                owner.DetailTitle, owner.DetailValue}
            local sizes = {}
            for index, label in ipairs(labels) do sizes[index] = label.TextSize end
            local baseHeight, baseScale = button.Row.AbsoluteSize.Y, owner.UIScale.Scale
            for _, factor in ipairs({1.15, 1.3, 1.15, 1.3}) do
                owner:SetPreference("TextScale", factor)
                settle()
                equal(owner.Preferences.TextScale, factor, "stored text scale")
                assert(math.abs(owner.UIScale.Scale - baseScale) < .001, "font enlargement shrank the whole GUI")
                for index, label in ipairs(labels) do
                    near(label.TextSize, sizes[index] * factor, label.Name .. " did not scale from its unscaled font")
                    assert(label.TextSize > sizes[index], label.Name .. " font did not increase")
                end
                assert(button.Row.AbsoluteSize.Y > baseHeight + 1, "larger text did not grow its row")
                rowsFit({button, following}, "scaled " .. viewport.X)
                inside(tab.Title, tab.Header, "scaled page title")
                assert(tab.Title.TextFits and tab.Subtitle.TextFits, "dynamic page fonts were clipped")
            end
            -- Relayout and inspector updates must keep the scale already applied.
            tab:Relayout()
            button:Focus()
            settle()
            near(tab.Title.TextSize, sizes[4] * 1.3, "relayout overwrote the scaled page title")
            near(owner.DetailTitle.TextSize, sizes[6] * 1.3, "inspector update overwrote its scaled title")
            near(owner.DetailValue.TextSize, sizes[7] * 1.3, "inspector update overwrote its scaled value")
            local later = group:AddButton({Id = "a11y-later", Name = button.Name, Description = button.Description,
                Action = "Restablecer"})
            settle()
            near(later.Label.TextSize, sizes[1] * 1.3, "new label missed the active scale before parenting")
            rowsFit({button, following, later}, "new scaled row")
            owner:SetPreference("TextScale", 1)
            settle()
            for index, label in ipairs(labels) do near(label.TextSize, sizes[index], "scale round trip drifted " .. label.Name) end
            near(button.Row.AbsoluteSize.Y, baseHeight, "scale reset did not restore row layout")
            owner:Destroy()
        end
    end)

    -- Catches localized expansion being clipped and one window changing another's typography.
    test("Spanish and Portuguese text stays inside scaled control rows without changing user values", function()
        local group, owner = section()
        owner:SetPreference("Animations", false)
        local controls = {
            group:AddButton({Id = "a11y-reset", Name = "Restablecer apariencia", Action = "Restablecer",
                Description = "Recupera los ajustes iniciales de esta ventana."}),
            group:AddToggle({Id = "a11y-motion", Name = "Animaciones",
                Description = "Aperturas, transiciones y seguimiento suave.", Default = true}),
            group:AddSlider({Id = "a11y-decoration", Name = "Intensidad de la decoración",
                Description = "Mantén las imágenes como un fondo sutil.", Min = 0, Max = 100, Default = 65, Suffix = "%"}),
            group:AddDropdown({Id = "a11y-mode", Name = "Modo de interacción", Values = {"Equilibrado", "Suave"}, Default = "Suave"}),
            group:AddInput({Id = "a11y-notes", Name = "Notas personales", Default = "ação áéíóú"}),
        }
        local otherGroup, other = section()
        local independent = otherGroup:AddButton({Id = "a11y-independent", Name = "Animaciones"})
        fit(other, Vector2.new(1920, 1080))
        local independentSize = independent.Label.TextSize
        owner:SetPreference("TextScale", 1.3)
        for _, viewport in ipairs(viewports) do
            fit(owner, viewport)
            for _, language in ipairs({"es", "pt", "es"}) do
                owner:SetLanguage(language)
                settle()
                equal(controls[3].Label.Text, language == "pt" and "Intensidade da decoração" or "Intensidad de la decoración",
                    "locale fixture did not actually change")
                equal(controls[5].Label.Text, language == "pt" and "Notas pessoais" or "Notas personales", "input caption language")
                rowsFit(controls, language .. " at " .. viewport.X .. " with 130% fonts")
                equal(controls[2]:Get(), true, "language or scale changed a toggle")
                equal(controls[3]:Get(), 65, "language or scale changed a slider")
                equal(controls[4]:Get(), "Suave", "language or scale changed the option value")
                equal(controls[5]:Get(), "ação áéíóú", "language or scale rewrote user text")
                equal(controls[5].Input.Text, controls[5]:Get(), "displayed user text changed")
                equal(other.Preferences.TextScale, 1, "font preference escaped its window")
                equal(independent.Label.TextSize, independentSize, "another window's font changed")
            end
        end
    end)

    -- Catches missing/double key handlers, stale targets and disabled user activation.
    test("real Tab and ShiftTab skip disabled destroyed hidden controls and activate live controls once", function()
        local press = realKeys()
        local group, owner, tab = section()
        owner:SetPreference("Animations", false)
        local calls, disabledCalls = 0, 0
        local button = group:AddButton({Id = "a11y-button", Name = "Ejecutar", Callback = function() calls += 1 end})
        local disabled = group:AddToggle({Id = "a11y-disabled", Name = "Desactivado", Default = false,
            Callback = function() disabledCalls += 1 end})
        local doomed = group:AddButton({Id = "a11y-destroyed", Name = "Eliminar", Callback = function() disabledCalls += 1 end})
        local hidden = group:AddButton({Id = "a11y-hidden", Name = "Oculto", Callback = function() disabledCalls += 1 end})
        local toggle = group:AddToggle({Id = "a11y-toggle", Name = "Animaciones", Default = false})
        local slider = group:AddSlider({Id = "a11y-slider", Name = "Intensidad", Min = 0, Max = 10, Step = 2, Default = 4})
        local dropdown = group:AddDropdown({Id = "a11y-dropdown", Name = "Modo de interacción", Values = {"A", "B"}})
        local note = group:AddInput({Id = "a11y-input", Name = "Notas personales", Default = "Texto"})
        local inactive = owner:AddTab("Ayuda")
        local inactiveControl = inactive:AddSection("Ocultos"):AddButton({Id = "a11y-inactive", Name = "Otra página"})
        disabled:SetEnabled(false)
        disabled:Set(true, true)
        equal(disabled:Get(), true, "disabled control rejected a programmatic Set")
        disabled:Activate()
        settle()
        equal(disabled:Get(), true, "disabled control accepted user Activate")
        equal(disabledCalls, 0, "disabled Activate invoked a callback")
        local destroyedInput = doomed.Input
        doomed:Destroy()
        hidden.Row.Visible = false
        fit(owner, Vector2.new(1920, 1080))
        assert(owner.Keyboard, "window keyboard controller is missing")
        owner.Keyboard:Focus(button)
        equal(GuiService.SelectedObject, button.Input, "Focus(control) did not select its input")
        assert(shown(button.FocusIndicator) and shown(button.SelectionWash), "keyboard focus has no visible row indicator")
        owner.Keyboard:Step(false)
        equal(GuiService.SelectedObject, toggle.Input, "Step did not skip unavailable controls")
        owner.Keyboard:Step(true)
        equal(GuiService.SelectedObject, button.Input, "reverse Step missed the preceding live control")
        press(Enum.KeyCode.Tab)
        equal(GuiService.SelectedObject, toggle.Input, "Tab did not skip unavailable controls")
        press(Enum.KeyCode.Tab, true)
        equal(GuiService.SelectedObject, button.Input, "ShiftTab did not reverse focus")
        press(Enum.KeyCode.Return)
        eventually(function() return calls == 1 end, "Enter did not activate exactly once")
        press(Enum.KeyCode.Space)
        eventually(function() return calls == 2 end, "Space did not activate exactly once")
        owner.Keyboard:Focus(toggle)
        press(Enum.KeyCode.Return)
        equal(toggle:Get(), true, "Enter did not toggle")
        press(Enum.KeyCode.Space)
        equal(toggle:Get(), false, "Space did not toggle once")
        owner.Keyboard:Focus(slider.Input)
        equal(GuiService.SelectedObject, slider.Input, "Focus(GuiObject) selected the wrong input")
        press(Enum.KeyCode.Right)
        equal(slider:Get(), 6, "Right did not advance exactly one slider step")
        press(Enum.KeyCode.Left)
        equal(slider:Get(), 4, "Left did not reverse exactly one slider step")
        owner.Keyboard:Focus(button)
        local visited = traversal(owner, press)
        for _, target in ipairs({button.Input, toggle.Input, slider.Input, slider.ValueInput, dropdown.Input, note.Input,
            tab.Button, inactive.Button, owner.HomeButton, owner.Search.Button, owner.MinimizeButton, owner.CloseButton,
            owner.Profile.Frame, owner.SettingsButton}) do
            assert(visited[target], target.Name .. " is unreachable with Tab")
        end
        for _, target in ipairs({disabled.Input, destroyedInput, hidden.Input, inactiveControl.Input, owner.MenuButton}) do
            assert(not visited[target], "Tab reached an unavailable target")
        end
        equal(calls, 2, "traversing focus activated a button")
        equal(disabledCalls, 0, "traversal activated an unavailable control")
        fit(owner, Vector2.new(320, 500))
        owner.Keyboard:Focus(owner.MenuButton)
        press(Enum.KeyCode.Return)
        equal(owner.NavigationOpen, true, "Enter on the mobile menu did not open navigation")
        owner.Keyboard:Focus(tab.Button)
        local mobile = traversal(owner, press)
        for _, target in ipairs({tab.Button, owner.NavigationCloseButton, owner.Profile.Frame, owner.SettingsButton}) do
            assert(mobile[target], target.Name .. " is unreachable in mobile navigation")
        end
        assert(not mobile[button.Input] and not mobile[owner.HomeButton], "mobile navigation exposed hidden panel targets")
        owner.Keyboard:Focus(owner.NavigationCloseButton)
        press(Enum.KeyCode.Space)
        equal(owner.NavigationOpen, false, "Space did not close mobile navigation")
    end)

    -- Catches the global navigator stealing editing/popup input or retaining dead selection/connections.
    test("typing and popup selection keep keyboard ownership and window cleanup releases selection", function()
        local press = realKeys()
        local replacementGroup, replacement = section()
        replacement:SetPreference("Animations", false)
        local survivorCalls = 0
        local survivor = replacementGroup:AddButton({Id = "a11y-survivor", Name = "Continuar",
            Callback = function() survivorCalls += 1 end})
        fit(replacement, Vector2.new(1920, 1080))
        local group, owner = section()
        owner:SetPreference("Animations", false)
        local calls = 0
        local button = group:AddButton({Id = "a11y-edit-action", Name = "Ejecutar", Callback = function() calls += 1 end})
        local slider = group:AddSlider({Id = "a11y-edit-slider", Name = "Intensidad", Min = 0, Max = 10, Default = 4})
        local note = group:AddInput({Id = "a11y-editor", Name = "Notas personales", MultiLine = true, Default = "abc"})
        local dropdown = group:AddDropdown({Id = "a11y-popup", Name = "Modo de interacción", Values = {"A", "B"}, Default = "A"})
        fit(owner, Vector2.new(1920, 1080))
        assert(owner.Keyboard, "window keyboard controller is missing")
        -- Keep a slider selected while the TextBox owns editing; its arrows must not fire.
        owner.Keyboard:Focus(slider.Input)
        note.Input:CaptureFocus()
        eventually(function() return Input:GetFocusedTextBox() == note.Input end, "real TextBox did not acquire editing focus")
        note.Input.CursorPosition, note.Input.SelectionStart = 4, -1
        press(Enum.KeyCode.Space)
        equal(note.Input.Text, "abc ", "Space was intercepted instead of typed")
        press(Enum.KeyCode.D)
        equal(note.Input.Text, "abc d", "normal typing was intercepted")
        press(Enum.KeyCode.Return)
        equal(note.Input.Text, "abc d\n", "Enter activated GUI instead of inserting a newline")
        press(Enum.KeyCode.Left)
        press(Enum.KeyCode.Right)
        equal(slider:Get(), 4, "editing arrows also changed the selected slider")
        local editingSelection = GuiService.SelectedObject
        press(Enum.KeyCode.Tab)
        equal(Input:GetFocusedTextBox(), note.Input, "Tab stole TextBox editing focus")
        equal(GuiService.SelectedObject, editingSelection, "Tab navigated the background while typing")
        press(Enum.KeyCode.Tab, true)
        equal(Input:GetFocusedTextBox(), note.Input, "ShiftTab stole TextBox editing focus")
        equal(GuiService.SelectedObject, editingSelection, "ShiftTab navigated the background while typing")
        press(Enum.KeyCode.RightShift)
        equal(owner:IsMinimized(), false, "window shortcut intercepted typing")
        equal(note:Get(), note.Input.Text, "typed text did not reach the control value")
        equal(calls, 0, "typing activated another control")
        note.Input:ReleaseFocus()
        dropdown:Open()
        settle()
        local popup = owner.OpenDropdown
        assert(popup ~= nil and owner.PopupOwner == dropdown, "dropdown did not acquire popup ownership")
        local option = popup.Options:FindFirstChild("Option2")
        assert(option and option:IsA("GuiButton"), "real dropdown option is missing")
        GuiService.SelectedObject = option
        owner.Keyboard:Step(false)
        equal(GuiService.SelectedObject, option, "Step stole a popup's selection")
        owner.Keyboard:Step(true)
        equal(GuiService.SelectedObject, option, "reverse Step stole a popup's selection")
        press(Enum.KeyCode.Tab)
        press(Enum.KeyCode.Tab, true)
        local selected = GuiService.SelectedObject
        assert(selected and selected:IsDescendantOf(popup), "global Tab traversal escaped the popup")
        equal(owner.PopupOwner, dropdown, "global keyboard handling replaced popup ownership")
        equal(dropdown:Get(), "A", "moving popup focus selected an option")
        equal(calls, 0, "popup navigation activated a background action")
        owner:ClosePopup()
        owner.Keyboard:Focus(button)
        equal(GuiService.SelectedObject, button.Input, "cleanup precondition has no selected GUI")
        local connections = {}
        for _, connection in pairs(owner.Runtime.Connections) do table.insert(connections, connection) end
        assert(#connections > 0, "window has no tracked engine connections")
        owner:Destroy()
        settle()
        equal(GuiService.SelectedObject, nil, "destroyed window retained SelectedObject")
        equal(Input:GetFocusedTextBox(), nil, "destroyed window retained editing focus")
        equal(owner.Root.Parent, nil, "window cleanup left GUI mounted")
        for _, connection in ipairs(connections) do equal(connection.Connected, false, "window leaked an input/lifecycle connection") end
        -- A surviving window must still receive keys after the latest owner is gone.
        replacement.Keyboard:Focus(survivor)
        press(Enum.KeyCode.Return)
        eventually(function() return survivorCalls == 1 end, "keyboard was not released to the surviving window")
        equal(calls, 0, "a destroyed window still handled Enter")
    end)
end
