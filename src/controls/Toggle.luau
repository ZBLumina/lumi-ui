local UI = require("UI")
local T = require("Theme")
local Toggle = {}

function Toggle.new(section, options)
    local c = section:Row(options, "Toggle", 58)
    local value = options.Default == true
    local rt = c.Runtime
    local input = UI.button(c.Row, "ToggleInput", "", 0, 0, 0, 58)
    input.Size = UDim2.fromScale(1, 1)
    input.ZIndex = 2
    c.Input = input
    local state = UI.text(input, "State", "", 0, 0, 36, 58, 10, T.Secondary, T.Mono)
    state.Position = UDim2.new(1, -112, 0, 0)
    local track = UI.frame(input, "Switch", 0, 18, 43, 23, T.Raised, 5)
    track.Position = UDim2.new(1, -59, 0, 18)
    local outline = UI.stroke(track, T.Line)
    local thumb = UI.frame(track, "Thumb", 4, 4, 13, 15, T.Secondary, 3)
    local notch = UI.frame(thumb, "Notch", 6, 4, 1, 7, T.Ink)
    c.Layout = function(narrow)
        track.Position = UDim2.new(1, -59, 0, narrow and 12 or 18)
        state.Size = UDim2.fromOffset(36, narrow and 46 or 58)
    end
    local function render(instant)
        state.Text = value and "ON" or "OFF"
        state.TextColor3 = value and T.Accent or T.Muted
        outline.Color = value and T.Accent or T.Line
        local props = {BackgroundColor3 = value and T.AccentWash or T.Raised}
        local knobProps = {Position = UDim2.fromOffset(value and 26 or 4, 4), BackgroundColor3 = value and T.Accent or T.Secondary}
        if instant then
            track.BackgroundColor3 = props.BackgroundColor3
            for k, v in pairs(knobProps) do thumb[k] = v end
        else
            rt:Tween(track, props)
            rt:Tween(thumb, knobProps)
        end
        notch.Visible = value
    end
    c.Get = function() return value end
    function c:Set(nextValue, silent)
        if rt.Destroyed then return false end
        nextValue = nextValue == true
        if value == nextValue then return false end
        value = nextValue
        render(false)
        self:Refresh()
        if not silent then rt:Callback(options.Callback, value) end
        return true
    end
    rt:Connect(input.Activated, function() c:Focus(); c:Set(not value) end)
    rt:Connect(input.MouseEnter, function() rt:Tween(track, {BackgroundColor3 = T.Hover}) end)
    rt:Connect(input.MouseLeave, function() render(false) end)
    rt:Connect(input.SelectionGained, function() c:Focus(); outline.Color = T.Accent end)
    rt:Connect(input.SelectionLost, function() render(false) end)
    render(true)
    return c
end

return Toggle
