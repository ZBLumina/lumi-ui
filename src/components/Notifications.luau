local Runtime = require("Runtime")
local UI = require("UI")
local T = require("Theme")
local Fonts = require("Fonts")
local Icons = require("Icons")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Notifications = {}
Notifications.__index = Notifications
local Handle = {}
Handle.__index = Handle
local colors = {Info = T.Secondary, Success = T.Green, Error = T.Danger, Loading = T.Accent}
local marks = {Info = "i", Success = "✓", Error = "!", Loading = ""}
local GAP, INSET, CONTENT_X = 8, 12, 42

local function alive(self)
    local window = self.Window
    return not self.Destroyed and not self.Runtime.Destroyed and not window.Runtime.Destroyed
        and not window._destroyed and not window._closing
end

local function pause(handle)
    if handle._deadline then handle._remaining = math.max(0, handle._deadline - os.clock()) end
    handle.Runtime:CancelDelay(handle._timer)
    handle._timer, handle._deadline = nil, nil
end

local function spin(handle, enabled)
    local rt = handle.Runtime
    if not enabled or handle.Manager.Window.Runtime.Animations == false then
        if handle._spin then
            handle._spin:Disconnect()
            local index = table.find(rt.Connections, handle._spin)
            if index then table.remove(rt.Connections, index) end
            handle._spin = nil
        end
        handle.Spinner.Rotation = 0
    elseif not handle._spin then
        handle._spin = rt:Connect(RunService.Heartbeat, function(delta)
            if alive(handle.Manager) then handle.Spinner.Rotation = (handle.Spinner.Rotation + delta * 240) % 360 end
        end)
    end
end

local function show(handle, visible)
    if not visible then
        pause(handle)
        spin(handle, false)
    elseif handle.Duration > 0 and not handle._timer then
        local remaining = handle._remaining
        handle._deadline = os.clock() + remaining
        handle._timer = handle.Runtime:Delay(remaining, function() handle:Dismiss() end)
    end
    handle.Visible, handle.Frame.Visible = visible, visible
    spin(handle, visible and handle.Kind == "Loading")
end

function Handle:Update(patch)
    local manager = self.Manager
    if self.Dismissed or not alive(manager) or type(patch) ~= "table" then return false end
    if patch.Title ~= nil then self.Title = tostring(patch.Title) end
    if patch.Message ~= nil then self.Message = tostring(patch.Message) end
    if colors[patch.Kind] then self.Kind = patch.Kind end
    if patch.Duration ~= nil then
        pause(self)
        self.Duration = math.max(0, UI.number(patch.Duration, self.Duration))
        self._remaining = self.Duration
    end
    if patch.Action ~= nil then
        local action = patch.Action
        self.Action = type(action) == "table" and type(action.Callback) == "function"
            and {Text = tostring(action.Text or "Continuar"), Callback = action.Callback} or nil
    end
    self.TitleLabel.Text, self.MessageLabel.Text = self.Title, self.Message
    self.TitleLabel.Visible, self.Body.Visible = self.Title ~= "", self.Message ~= ""
    self.ActionButton.Text = self.Action and self.Action.Text or ""
    self.ActionButton.Visible = self.Action ~= nil
    self.Mark.Text, self.Mark.TextColor3 = marks[self.Kind], colors[self.Kind]
    self.Stripe.BackgroundColor3 = colors[self.Kind]
    self.Spinner.Visible, self.Mark.Visible = self.Kind == "Loading", self.Kind ~= "Loading"
    spin(self, self.Visible and self.Kind == "Loading")
    manager:Fit()
    return true
end

function Handle:Dismiss()
    return self.Manager:_Remove(self)
end

function Notifications.new(window)
    local self = setmetatable({Window = window, Runtime = Runtime.new(), Items = {}, Destroyed = false,
        _revision = 0, _fitting = false}, Notifications)
    if not alive(self) then self:Destroy(); return self end
    local layer = UI.new("Frame", window.Viewport, {
        Name = "Notifications", Size = UDim2.fromScale(1, 1), ZIndex = 120, ClipsDescendants = true,
    })
    self.Frame, self.Runtime.Root = layer, layer
    window.Runtime:OnCleanup(function() self:Destroy() end)
    self.Runtime:Connect(layer.Destroying, function()
        self.Runtime.Root = nil
        self:Destroy()
    end)
    return self
end

function Notifications:Push(options)
    options = type(options) == "table" and options or {}
    local handle = setmetatable({Manager = self, Runtime = Runtime.new(), Dismissed = false, Visible = false,
        Title = "Aviso", Message = "", Kind = "Info", Duration = 4, _remaining = 4}, Handle)
    if not alive(self) then
        handle.Dismissed = true
        handle.Runtime:Destroy()
        return handle
    end
    local rt = handle.Runtime
    rt.Animations = self.Window.Runtime.Animations
    local frame = UI.new("Frame", self.Frame, {
        Name = "Notification", Size = UDim2.fromOffset(320, 80), Visible = false,
        BackgroundColor3 = T.Surface, BackgroundTransparency = 0, ClipsDescendants = true, ZIndex = 120,
    })
    handle.Frame, rt.Root = frame, frame
    -- Bind embedded icons to this toast, rather than retaining them in the window scope.
    Icons.mount(rt, frame)
    UI.corner(frame, 10)
    UI.stroke(frame, T.Line)
    handle.Stripe = UI.frame(frame, "Kind", 0, 8, 3, 32, T.Secondary, 2)
    handle.Mark = UI.text(frame, "Status", "i", 13, 14, 18, 20, 14, T.Secondary, T.Medium)
    handle.Mark.TextXAlignment = Enum.TextXAlignment.Center
    handle.Spinner = UI.frame(frame, "Loading", 14, 16, 16, 16)
    for index, point in ipairs({Vector2.new(6, 0), Vector2.new(12, 6), Vector2.new(6, 12), Vector2.new(0, 6)}) do
        local dot = UI.frame(handle.Spinner, "Dot", point.X, point.Y, 4, 4, T.Accent, 2)
        dot.BackgroundTransparency = (index - 1) * 0.2
    end
    handle.TitleLabel = UI.text(frame, "Title", "", CONTENT_X, INSET, 200, 24, 13, T.Text, T.Medium)
    handle.TitleLabel.TextWrapped = true
    handle.TitleLabel.TextYAlignment = Enum.TextYAlignment.Top
    handle.Body = UI.new("ScrollingFrame", frame, {
        Name = "MessageArea", BackgroundTransparency = 1, BorderSizePixel = 0,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.None,
        ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.Line, Active = true, Selectable = false, ClipsDescendants = true,
    })
    handle.MessageLabel = UI.text(handle.Body, "Message", "", 0, 0, 200, 20, 12, T.Secondary)
    handle.MessageLabel.TextWrapped = true
    handle.MessageLabel.TextTruncate = Enum.TextTruncate.None
    handle.MessageLabel.TextYAlignment = Enum.TextYAlignment.Top
    handle.CloseButton = UI.button(frame, "CloseNotification", "", 0, 4, 44, 44)
    handle.CloseButton:SetAttribute("LumiLabel", "Cerrar aviso")
    UI.icon(handle.CloseButton, "Close", 14, 14, T.Muted)
    handle.ActionButton = UI.button(frame, "NotificationAction", "", CONTENT_X, 0, 200, 44)
    handle.ActionButton.BackgroundColor3, handle.ActionButton.BackgroundTransparency = T.Raised, 0
    handle.ActionButton.TextTruncate = Enum.TextTruncate.AtEnd
    UI.corner(handle.ActionButton, 7)
    UI.hover(rt, handle.ActionButton, T.Raised, T.Hover)
    rt:Connect(handle.CloseButton.Activated, function()
        if alive(self) and handle.Visible then handle:Dismiss() end
    end)
    rt:Connect(handle.ActionButton.Activated, function() self:Activate(handle) end)
    rt:Connect(frame.Destroying, function()
        rt.Root = nil
        self:_Remove(handle)
    end)
    for _, label in ipairs({handle.TitleLabel, handle.MessageLabel, handle.ActionButton}) do
        for _, property in ipairs({"Text", "TextSize", "FontFace"}) do
            rt:Connect(label:GetPropertyChangedSignal(property), function() self:Fit() end)
        end
    end
    table.insert(self.Items, handle)
    handle:Update(options)
    return handle
end

function Notifications:_Remove(handle)
    if handle.Manager ~= self or handle.Dismissed then return false end
    handle.Dismissed, handle.Visible = true, false
    handle._timer, handle._deadline, handle.Action = nil, nil, nil
    local index = table.find(self.Items, handle)
    if index then table.remove(self.Items, index) end
    handle.Runtime:Destroy()
    self:Fit()
    return true
end

-- Window.NotifyAction may delegate here; GUI activation follows the same guard.
function Notifications:Activate(handle)
    if type(handle) ~= "table" or handle.Manager ~= self or handle.Dismissed
        or not handle.Visible or handle._actionUsed or not alive(self) or not handle.Action then return false end
    handle._actionUsed = true
    local callback = handle.Action.Callback
    handle:Dismiss()
    -- The action belongs to the window: dismissing its toast must not cancel it,
    -- while closing the window must still cancel a suspended user callback.
    self.Window.Runtime:Callback(callback)
    return true
end

local function measure(handle, width, maximum)
    local title, message, action = handle.TitleLabel, handle.MessageLabel, handle.ActionButton
    local contentWidth = math.max(1, width - CONTENT_X - INSET)
    local titleWidth = math.max(1, width - CONTENT_X - 48)
    local line = Fonts.bounds("Ag", title.TextSize, title.FontFace, titleWidth).Y
    local titleHeight = handle.Title ~= "" and math.ceil(math.min(
        Fonts.bounds(title.Text, title.TextSize, title.FontFace, titleWidth).Y + 2, line * 2 + 2)) or 0
    local actionHeight = handle.Action and math.max(44, math.ceil(action.TextSize + 16)) or 0
    local top = math.max(44, INSET + titleHeight)
    local bodyHeight = handle.Message ~= "" and math.ceil(
        Fonts.bounds(message.Text, message.TextSize, message.FontFace, math.max(1, contentWidth - 6)).Y + 2) or 0
    local footer = INSET + (actionHeight > 0 and actionHeight + GAP or 0)
    -- Cap exceptional text with a real scrolling message area, without shrinking fonts.
    local bodyView = math.min(bodyHeight, math.max(0, maximum - top - footer))
    return {Handle = handle, Width = width, Height = math.min(maximum, top + bodyView + footer),
        TitleWidth = titleWidth, TitleHeight = titleHeight, ContentWidth = contentWidth,
        Top = top, BodyHeight = bodyHeight, BodyView = bodyView, ActionHeight = actionHeight}
end

function Notifications:Fit()
    if not alive(self) then return end
    self._revision += 1
    if self._fitting then return end
    self._fitting = true
    self.Runtime:Delay(0, function()
        repeat
            local revision = self._revision
            local size = self.Window.Viewport.AbsoluteSize
            local inset = GuiService:GetGuiInset()
            local top = math.max(INSET, inset.Y + 8)
            local available = math.max(0, size.Y - top - INSET)
            local budget = math.min(available, math.max(120, math.floor(size.Y * 0.55)))
            local width = math.max(1, math.min(360, size.X - INSET * 2))
            local plan, height = {}, 0
            if size.X > INSET * 2 and budget >= 80 then
                for _, handle in ipairs(table.clone(self.Items)) do
                    if #plan == 3 then break end
                    local entry = measure(handle, width, budget)
                    if not alive(self) or revision ~= self._revision then break end
                    if handle.Dismissed then break end
                    local nextHeight = height + (#plan > 0 and GAP or 0) + entry.Height
                    if nextHeight > budget then break end
                    table.insert(plan, entry)
                    height = nextHeight
                end
            end
            -- Fonts.bounds may yield. Discard measurements after an update, resize,
            -- dismissal or destruction instead of applying a stale GUI plan.
            if not alive(self) then break end
            if revision == self._revision then
                local selected = {}
                local y = size.Y - INSET - height
                for _, entry in ipairs(plan) do
                    local handle = entry.Handle
                    selected[handle] = true
                    handle.Frame.Position = UDim2.fromOffset(size.X - INSET - width, y)
                    handle.Frame.Size = UDim2.fromOffset(width, entry.Height)
                    handle.Stripe.Size = UDim2.fromOffset(3, math.max(0, entry.Height - 16))
                    handle.TitleLabel.Size = UDim2.fromOffset(entry.TitleWidth, entry.TitleHeight)
                    handle.CloseButton.Position = UDim2.fromOffset(width - 48, 4)
                    handle.Body.Position = UDim2.fromOffset(CONTENT_X, entry.Top)
                    handle.Body.Size = UDim2.fromOffset(entry.ContentWidth, entry.BodyView)
                    handle.Body.CanvasSize = UDim2.fromOffset(0, entry.BodyHeight)
                    handle.MessageLabel.Size = UDim2.fromOffset(math.max(1, entry.ContentWidth - 6), entry.BodyHeight)
                    handle.ActionButton.Position = UDim2.fromOffset(CONTENT_X, entry.Height - INSET - entry.ActionHeight)
                    handle.ActionButton.Size = UDim2.fromOffset(entry.ContentWidth, entry.ActionHeight)
                    y += entry.Height + GAP
                end
                -- Hide outgoing slots before promoting queued handles; even during
                -- reflow there must never be four visible cards.
                for _, handle in ipairs(self.Items) do if not selected[handle] then show(handle, false) end end
                for _, entry in ipairs(plan) do show(entry.Handle, true) end
            end
        until revision == self._revision
        self._fitting = false
    end)
end

function Notifications:GetTargets()
    local targets = {}
    if not alive(self) then return targets end
    for _, handle in ipairs(self.Items) do
        if handle.Visible and not handle.Dismissed then
            if handle.Action then
                table.insert(targets, {
                    Object = handle.ActionButton,
                    Runtime = handle.Runtime,
                    Activate = function(_target) return self:Activate(handle) end,
                })
            end
            table.insert(targets, {
                Object = handle.CloseButton,
                Runtime = handle.Runtime,
                Activate = function(_target)
                    if alive(self) and handle.Visible then return handle:Dismiss() end
                    return false
                end,
            })
        end
    end
    return targets
end

function Notifications:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    for index = #self.Items, 1, -1 do self:_Remove(self.Items[index]) end
    self.Runtime:Destroy()
end

return Notifications
