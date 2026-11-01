-- Inject before cleanupCase in runtime.spec.luau; use its real client helpers.
-- No mocks or implementation hooks. Native input QA also covers touch/keyboard.
do
    local function shown(owner, handle)
        local frame = handle.Frame
        if typeof(frame) ~= "Instance" or not frame:IsA("GuiObject") then return false end
        if not frame:IsDescendantOf(owner.Root) then return false end
        local current = frame
        while current do
            if current:IsA("GuiObject") and not current.Visible then return false end
            if current:IsA("ScreenGui") and not current.Enabled then return false end
            current = current.Parent
        end
        return frame.AbsoluteSize.X > 0 and frame.AbsoluteSize.Y > 0
    end

    local function textIn(frame, value)
        local candidates = frame:GetDescendants()
        table.insert(candidates, frame)
        for _, object in ipairs(candidates) do
            if (object:IsA("TextLabel") or object:IsA("TextButton")) and object.Text == value then
                return object
            end
        end
        error("notification did not render text: " .. value, 2)
    end

    local function actionIn(handle, caption)
        local object = textIn(handle.Frame, caption)
        while object and object ~= handle.Frame and not object:IsA("GuiButton") do
            object = object.Parent
        end
        assert(object and object:IsA("GuiButton"), "notification action must be a real GuiButton")
        assert(object.Active, "notification action is inactive")
        return object
    end

    local function clickAt(position)
        local input = game:GetService("VirtualInputManager")
        input:SendMouseMoveEvent(position.X, position.Y, game)
        input:SendMouseButtonEvent(position.X, position.Y, 0, true, game, 0)
        task.wait(0.01)
        input:SendMouseButtonEvent(position.X, position.Y, 0, false, game, 0)
    end

    local function notifications(owner)
        assert(type(owner.Notify) == "function", "Window.Notify is missing")
        assert(type(owner.Notifications) == "table", "Window.Notifications is missing")
        assert(type(owner.Notifications.Items) == "table", "Notifications.Items must be a list")
        return owner.Notifications
    end

    local function removed(handle)
        return handle.Dismissed == true
            and (handle.Frame == nil or handle.Frame.Parent == nil)
    end

    -- Catches ignored patches, a timeout on Duration=0, and a missing new timer.
    test("loading notifications update in place and success expires", function()
        local owner = window()
        local manager = notifications(owner)
        owner:FinishEntrance()
        local loading = owner:Notify({
            Title = "Guardando cambios", Message = "Espera un momento.", Kind = "Loading", Duration = 0,
        })
        local ordinary = owner:Notify({Title = "Aviso de la sesión", Message = "Duración predeterminada."})
        settle()
        assert(shown(owner, loading), "loading notification did not mount visible GUI")
        assert(shown(owner, ordinary), "default notification did not mount visible GUI")
        equal(loading.Dismissed, false, "new loading handle is already dismissed")
        equal(type(loading.Update), "function", "notification.Update")
        equal(type(loading.Dismiss), "function", "notification.Dismiss")
        textIn(loading.Frame, "Guardando cambios")
        textIn(loading.Frame, "Espera un momento.")
        task.wait(0.2)
        equal(ordinary.Dismissed, false, "default duration expired immediately")
        -- Outlive the default four-second timer with a genuine indefinite item.
        task.wait(4.1)
        settle()
        equal(ordinary.Dismissed, true, "default duration did not expire after four seconds")
        eventually(function() return removed(ordinary) end, "default notification retained its GUI")
        equal(loading.Dismissed, false, "Duration=0 expired with the default timer")
        assert(shown(owner, loading), "indefinite loading notification disappeared")

        loading:Update({Message = "Terminando de guardar."})
        settle()
        textIn(loading.Frame, "Guardando cambios")
        textIn(loading.Frame, "Terminando de guardar.")
        equal(loading.Dismissed, false, "partial update dismissed an indefinite notification")
        loading:Update({Title = "Cambios guardados", Message = "Todo está listo.", Kind = "Success", Duration = 0.4})
        settle()
        assert(shown(owner, loading), "success update did not leave visible GUI")
        textIn(loading.Frame, "Cambios guardados")
        textIn(loading.Frame, "Todo está listo.")
        eventually(function() return removed(loading) end, "success update did not auto-dismiss")
        eventually(function() return #manager.Items == 0 end, "expired notifications remain in Items")
    end)

    -- Catches duplicate action dispatch while the dismissal is still settling.
    test("notification action invokes its callback once and dismisses", function()
        local owner = window()
        local manager = notifications(owner)
        owner:FinishEntrance()
        local calls = 0
        local handle = owner:Notify({
            Title = "Cambios aplicados", Message = "Puedes recuperar el valor anterior.",
            Kind = "Success", Duration = 0,
            Action = {Text = "Deshacer", Callback = function() calls += 1 end},
        })
        settle()
        assert(shown(owner, handle), "action notification is not visible")
        local action = actionIn(handle, "Deshacer")
        local position = action.AbsolutePosition + action.AbsoluteSize / 2 + game:GetService("GuiService"):GetGuiInset()
        clickAt(position)
        clickAt(position)
        eventually(function() return calls > 0 end, "real notification action did not invoke its callback")
        eventually(function() return removed(handle) end, "action did not dismiss its notification")
        handle:Dismiss()
        handle:Dismiss()
        settle()
        equal(calls, 1, "repeated activation or dismissal dispatched the action again")
        equal(#manager.Items, 0, "action notification remains in Items")
    end)

    -- Catches queued notices or delayed completions surviving their window.
    test("closing a window clears visible and queued notification work", function()
        local owner = window()
        local manager = notifications(owner)
        owner:FinishEntrance()
        local handles, frames, connections = {}, {}, {}
        for index = 1, 7 do
            table.insert(handles, owner:Notify({
                Title = "Tarea pendiente " .. index, Message = "Esperando el cierre de la sesión.",
                Kind = index == 1 and "Loading" or "Info", Duration = index == 1 and 0 or 0.8,
            }))
        end
        settle()
        assert(shown(owner, handles[1]), "cleanup fixture has no visible notification")
        for _, handle in ipairs(handles) do
            if typeof(handle.Frame) == "Instance" then table.insert(frames, handle.Frame) end
        end
        for _, connection in ipairs(owner.Runtime.Connections) do table.insert(connections, connection) end
        owner:Close()
        owner:Close()
        eventually(function() return owner.Runtime.Destroyed == true end, "Close did not destroy the real Runtime")
        equal(owner.Root.Parent, nil, "closed window retained its root")
        for _, handle in ipairs(handles) do
            equal(handle.Dismissed, true, "closing left a visible or queued handle alive")
        end
        for _, frame in ipairs(frames) do equal(frame.Parent, nil, "notification GUI survived Close") end
        for _, connection in ipairs(connections) do equal(connection.Connected, false, "connection survived Close") end
        equal(next(owner.Runtime.Threads), nil, "closed Runtime retained pending work")
        equal(#manager.Items, 0, "closed window retained notification items")
        -- Let every original timeout pass; none may promote queued GUI later.
        task.wait(1)
        settle()
        equal(#manager.Items, 0, "a pending timer repopulated the closed notification stack")
        equal(next(owner.Runtime.Threads), nil, "delayed notification work survived Close")
        for _, handle in ipairs(handles) do assert(removed(handle), "a notification reappeared after Close") end
    end)

    -- Catches a fourth visible item, overflow/overlap, clipped multiline copy,
    -- and a queue that never promotes (or silently drops) pending handles.
    test("notification queue stays bounded at 320x500 with multiline messages", function()
        local owner = window()
        local manager = notifications(owner)
        owner.Viewport.Size = UDim2.fromOffset(320, 500)
        settle(); owner:Fit(); owner:FinishEntrance(); settle()
        local multiline = "No se pudieron guardar los cambios.\nComprueba la conexión.\nPuedes intentarlo de nuevo."
        local handles, seen = {}, {}
        for index = 1, 7 do
            table.insert(handles, owner:Notify({
                Title = index == 1 and "Revisa la conexión" or "Aviso pendiente " .. index,
                Message = index == 1 and multiline or "La sesión sigue disponible.",
                Kind = index == 1 and "Error" or "Info", Duration = 0,
            }))
        end
        settle()
        local function visibleBatch()
            local batch = {}
            local origin, size = owner.Viewport.AbsolutePosition, owner.Viewport.AbsoluteSize
            for _, handle in ipairs(handles) do
                if shown(owner, handle) then
                    equal(handle.Dismissed, false, "dismissed notification is still visible")
                    local frame = handle.Frame
                    local left, top = frame.AbsolutePosition.X - origin.X, frame.AbsolutePosition.Y - origin.Y
                    local right, bottom = left + frame.AbsoluteSize.X, top + frame.AbsoluteSize.Y
                    assert(left >= -0.5 and top >= -0.5, "notification escaped the top/left viewport")
                    assert(right <= size.X + 0.5 and bottom <= size.Y + 0.5, "notification escaped the bottom/right viewport")
                    for _, other in ipairs(batch) do
                        local a, b = frame.AbsolutePosition, other.Frame.AbsolutePosition
                        local x = math.min(a.X + frame.AbsoluteSize.X, b.X + other.Frame.AbsoluteSize.X) - math.max(a.X, b.X)
                        local y = math.min(a.Y + frame.AbsoluteSize.Y, b.Y + other.Frame.AbsoluteSize.Y) - math.max(a.Y, b.Y)
                        assert(x <= 0.5 or y <= 0.5, "visible notifications overlap")
                    end
                    table.insert(batch, handle)
                end
            end
            assert(#batch <= 3, "more than three notifications are visible")
            return batch
        end

        local remaining = #handles
        while remaining > 0 do
            eventually(function() return #visibleBatch() > 0 end, "queued notification never became visible")
            local batch = visibleBatch()
            for _, handle in ipairs(batch) do
                assert(not seen[handle], "a dismissed notification was promoted again")
                seen[handle] = true
                if handle == handles[1] then
                    local message = textIn(handle.Frame, multiline)
                    assert(message.TextWrapped, "multiline notification message does not wrap")
                    assert(message.TextFits, "multiline notification message is clipped")
                    assert(message.AbsoluteSize.Y > message.TextSize * 2, "multiline message has only a single-line slot")
                    local a, b = message.AbsolutePosition, handle.Frame.AbsolutePosition
                    assert(a.X >= b.X - 0.5 and a.Y >= b.Y - 0.5, "message escapes its notification")
                    assert(a.X + message.AbsoluteSize.X <= b.X + handle.Frame.AbsoluteSize.X + 0.5,
                        "message escapes the notification width")
                    assert(a.Y + message.AbsoluteSize.Y <= b.Y + handle.Frame.AbsoluteSize.Y + 0.5,
                        "message escapes the notification height")
                end
                handle:Dismiss()
                remaining -= 1
            end
            eventually(function()
                for _, handle in ipairs(batch) do if not removed(handle) then return false end end
                return true
            end, "dismissed batch did not release its GUI")
            settle()
        end
        equal(#visibleBatch(), 0, "drained queue left visible notifications")
        equal(#manager.Items, 0, "drained queue retained notification items")
        for _, handle in ipairs(handles) do assert(seen[handle], "queued notification was dropped without being shown") end
    end)
end
