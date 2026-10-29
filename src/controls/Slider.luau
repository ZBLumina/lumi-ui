local UI = require("UI")
local T = require("Theme")
local Input = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Slider = {}

function Slider.new(section, options)
    local c = section:Row(options, "Slider", 90)
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
    c.Min, c.Max, c.Step = minimum, maximum, step
    c.Range = c:Format(minimum) .. " - " .. c:Format(maximum)
    c.Get = function() return value end
    function c:Fraction() return maximum == minimum and 0 or (value - minimum) / (maximum - minimum) end
    local box = UI.new("TextBox", c.Row, {
        Name = "ValueInput", Size = UDim2.fromOffset(76, 27), Position = UDim2.new(1, -92, 0, 12),
        BackgroundTransparency = 0, BackgroundColor3 = T.Raised, TextColor3 = T.Accent,
        Font = T.Mono, TextSize = 13, ClearTextOnFocus = false, Text = "", ZIndex = 2,
    })
    UI.corner(box, 5)
    local border = UI.stroke(box, T.Line)
    c.ValueInput = box
    local track = UI.new("Frame", c.Row, {Name = "Track", Position = UDim2.fromOffset(18, 62),
        Size = UDim2.new(1, -36, 0, 2), BackgroundTransparency = 0, BackgroundColor3 = T.Line})
    UI.corner(track, 2)
    local fill = UI.frame(track, "Fill", 0, 0, 0, 2, T.Accent, 1)
    local thumb = UI.frame(track, "Thumb", 0, -5, 6, 12, T.Text, 2)
    thumb.AnchorPoint = Vector2.new(0.5, 0)
    local hit = UI.button(c.Row, "SliderInput", "", 18, 52, 0, 23)
    hit.Size = UDim2.new(1, -36, 0, 23)
    hit.ZIndex = 2
    c.Input, c.Track = hit, track
    for i = 0, 4 do
        local tick = UI.frame(track, "Tick", 0, 8, 1, 3, T.Line)
        tick.Position = UDim2.new(i / 4, 0, 0, 8)
    end
    local low = UI.text(c.Row, "Minimum", UI.format(minimum), 18, 74, 90, 13, 9, T.Muted, T.Mono)
    local high = UI.text(c.Row, "Maximum", UI.format(maximum), 0, 74, 90, 13, 9, T.Muted, T.Mono)
    high.Position = UDim2.new(1, -108, 0, 74)
    high.TextXAlignment = Enum.TextXAlignment.Right
    low.Visible, high.Visible = options.ShowBounds ~= false, options.ShowBounds ~= false
    local function render()
        local fraction = c:Fraction()
        box.Text = c:Format(value) .. c.Suffix
        fill.Size = UDim2.new(fraction, 0, 1, 0)
        thumb.Position = UDim2.new(fraction, 0, 0, -5)
    end
    function c:Set(nextValue, silent)
        if rt.Destroyed then return false end
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
        c:Focus()
        local function update(position)
            local fraction = math.clamp((position.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
            c:Set(minimum + fraction * (maximum - minimum))
        end
        window:BeginPointer(input, update, function() rt:Tween(thumb, {BackgroundColor3 = T.Text}) end)
        thumb.BackgroundColor3 = T.Accent
        update(input.Position)
    end)
    local originalText
    rt:Connect(box.Focused, function()
        c:Focus()
        border.Color = T.Accent
        box.Text = string.format("%.15g", value)
        originalText = box.Text
    end)
    rt:Connect(box.FocusLost, function()
        local parsed = tonumber(box.Text)
        if parsed and box.Text ~= originalText then c:Set(parsed) end
        border.Color = T.Line
        render()
    end)
    rt:Connect(hit.SelectionGained, function() c:Focus(); thumb.BackgroundColor3 = T.Accent end)
    rt:Connect(hit.SelectionLost, function() thumb.BackgroundColor3 = T.Text end)
    rt:Connect(Input.InputBegan, function(input)
        if GuiService.SelectedObject ~= hit or Input:GetFocusedTextBox() then return end
        if input.KeyCode == Enum.KeyCode.Left then c:Set(value - step)
        elseif input.KeyCode == Enum.KeyCode.Right then c:Set(value + step) end
    end)
    render()
    return c
end

return Slider
