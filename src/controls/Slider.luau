local UI = require("UI")
local T = require("Theme")
local PropertyLayout = require("PropertyLayout")
local Input = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Slider = {}

function Slider.new(section, options)
    local c = section:Row(options, "Slider", 114)
    local rt, window = c.Runtime, section.Tab.Window
    local minimum, maximum = UI.number(options.Min, 0), UI.number(options.Max, 100)
    if minimum > maximum then minimum, maximum = maximum, minimum end
    local step = UI.number(options.Step, 1)
    if step <= 0 then step = 1 end
    local function normalize(n)
        n = math.clamp(UI.number(n, minimum), minimum, maximum)
        if minimum == maximum then return minimum end
        if n == minimum or n == maximum then return n end
        return math.clamp(minimum + math.floor((n - minimum) / step + 0.5) * step, minimum, maximum)
    end
    local value = normalize(options.Default)
    local precision = 8
    for decimals = 0, 8 do
        local scaled = step * 10 ^ decimals
        if math.abs(scaled - math.floor(scaled + 0.5)) < 0.000001 then precision = math.max(2, decimals); break end
    end
    function c:Format(number) return UI.format(number, precision) end
    c.Suffix = options.Suffix or ""
    -- Reserve the full formatted range once. Changing the current number must
    -- never move the drag lane or push neighbouring controls while dragging.
    local pattern = "%." .. tostring(precision) .. "f"
    c.ControlWidth = math.max(
        PropertyLayout.inputWidth(string.format(pattern, minimum) .. c.Suffix, T.Mono, 15, 96, 160),
        PropertyLayout.inputWidth(string.format(pattern, maximum) .. c.Suffix, T.Mono, 15, 96, 160))
    c.Min, c.Max, c.Step = minimum, maximum, step
    c.Range = c:Format(minimum) .. " - " .. c:Format(maximum)
    c.Get = function() return value end
    function c:Fraction() return maximum == minimum and 0 or (value - minimum) / (maximum - minimum) end
    local field = UI.frame(c.Row, "ValueField", 0, 0, 96, 36, T.Raised, 7)
    field.ClipsDescendants, field.ZIndex = true, 2
    local box = UI.new("TextBox", field, {
        Name = "ValueInput", Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(10, 0),
        TextColor3 = T.Accent,
        Font = T.Mono, TextSize = 13, ClearTextOnFocus = false, Text = "", ZIndex = 2,
    })
    local border = UI.stroke(field, T.Line)
    c.ValueInput = box
    local track = UI.new("Frame", c.Row, {Name = "Track", Position = UDim2.fromOffset(18, 62),
        Size = UDim2.new(1, -36, 0, 4), BackgroundTransparency = 0, BackgroundColor3 = T.Line})
    UI.corner(track, 2)
    local fill = UI.frame(track, "Fill", 0, 0, 0, 4, T.Accent, 2)
    local thumb = UI.frame(track, "Thumb", 0, 0, 14, 14, T.Text, 999)
    UI.stroke(thumb, T.AccentSoft).Transparency = 0.55
    thumb.AnchorPoint = Vector2.new(0.5, 0.5)
    local hit = UI.button(c.Row, "SliderInput", "", 18, 52, 0, 23)
    hit.Size = UDim2.new(1, -36, 0, 23)
    hit.ZIndex = 2
    c.Input, c.Track = hit, track
    for i = 0, 4 do
        local tick = UI.frame(track, "Tick", 0, 8, 1, 3, T.Line)
        tick.Position = UDim2.new(i / 4, 0, 0, 8)
    end
    local low = UI.text(c.Row, "Minimum", c:Format(minimum), 18, 74, 90, 14, 11, T.Muted, T.Mono)
    local high = UI.text(c.Row, "Maximum", c:Format(maximum), 0, 74, 90, 14, 11, T.Muted, T.Mono)
    high.Position = UDim2.new(1, -108, 0, 74)
    high.TextXAlignment = Enum.TextXAlignment.Right
    c.ShowBounds = options.ShowBounds ~= false
    low.Visible, high.Visible = c.ShowBounds, c.ShowBounds
    c.Layout = function(place)
        field.Position = UDim2.fromOffset(place.ControlX, place.ControlY)
        field.Size = UDim2.fromOffset(place.ControlWidth, place.ControlHeight)
        track.Position = UDim2.fromOffset(place.LaneX, place.TrackY - 2)
        track.Size = UDim2.fromOffset(place.LaneWidth, 4)
        hit.Position = UDim2.fromOffset(place.LaneX, place.HitY)
        hit.Size = UDim2.fromOffset(place.LaneWidth, place.HitHeight)
        low.Position, low.Size = UDim2.fromOffset(place.LaneX, place.BoundsY), UDim2.fromOffset(place.BoundsWidth, 14)
        high.Position = UDim2.fromOffset(place.LaneX + place.LaneWidth - place.BoundsWidth, place.BoundsY)
        high.Size = UDim2.fromOffset(place.BoundsWidth, 14)
    end
    local dragging, hovered, focused = false, false, false
    local function emphasize()
        local active = dragging or hovered or focused
        rt:Tween(thumb, {Size = UDim2.fromOffset(active and 16 or 14, active and 16 or 14),
            BackgroundColor3 = active and T.Accent or T.Text}, 0.10)
    end
    local function render(instant)
        local fraction = c:Fraction()
        box.Text = c:Format(value) .. c.Suffix
        local size = UDim2.new(fraction, 0, 1, 0)
        local position = UDim2.new(fraction, 0, 0.5, 0)
        if instant or dragging then
            rt:CancelTween(fill)
            rt:CancelTween(thumb, "position")
            fill.Size, thumb.Position = size, position
        else
            rt:Tween(fill, {Size = size}, 0.10)
            rt:Tween(thumb, {Position = position}, 0.10, "position")
        end
    end
    function c:Set(nextValue, silent)
        if rt.Destroyed or window._closing then return false end
        nextValue = normalize(nextValue)
        if nextValue == value then render(); return false end
        value = nextValue
        render()
        self:Refresh()
        if not silent then rt:Callback(options.Callback, value) end
        return true
    end
    rt:Connect(hit.InputBegan, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if window._closing then return end
        c:Focus()
        local function update(position)
            local fraction = math.clamp((position.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
            c:Set(minimum + fraction * (maximum - minimum))
        end
        window:BeginPointer(input, update, function() dragging = false; emphasize() end)
        dragging = true
        emphasize()
        update(input.Position)
    end)
    local originalText
    rt:Connect(box.Focused, function()
        c:Focus()
        rt:Tween(border, {Color = T.Accent}, 0.12)
        box.Text = string.format("%.15g", value)
        originalText = box.Text
    end)
    rt:Connect(box.FocusLost, function()
        local parsed = tonumber(box.Text)
        if parsed and box.Text ~= originalText then c:Set(parsed) end
        rt:Tween(border, {Color = T.Line}, 0.12)
        render()
    end)
    rt:Connect(hit.MouseEnter, function() hovered = true; emphasize() end)
    rt:Connect(hit.MouseLeave, function() hovered = false; emphasize() end)
    rt:Connect(hit.SelectionGained, function() focused = true; c:Focus(); emphasize() end)
    rt:Connect(hit.SelectionLost, function() focused = false; emphasize() end)
    rt:Connect(Input.InputBegan, function(input)
        if GuiService.SelectedObject ~= hit or Input:GetFocusedTextBox() then return end
        if input.KeyCode == Enum.KeyCode.Left then c:Set(value - step)
        elseif input.KeyCode == Enum.KeyCode.Right then c:Set(value + step) end
    end)
    render(true)
    return c
end

return Slider
