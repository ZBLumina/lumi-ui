local UI = require("UI")
local T = require("Theme")
local Textos = require("Textos")
local Toggle = {}

function Toggle.new(section, options)
    local c = section:Row(options, "Toggle", 64)
    local value = options.Default == true
    local rt = c.Runtime
    local window = section.Tab.Window
    local input = UI.button(c.Row, "ToggleInput", "", 0, 0, 0, 58)
    input.Size = UDim2.fromScale(1, 1)
    input.ZIndex = 2
    c.Input = input
    local state = UI.text(input, "State", "", 0, 0, 36, 58, 10, T.Secondary, T.Mono)
    state.Position = UDim2.new(1, -100, 0, 0)
    local track = UI.frame(input, "Switch", 0, 19, 44, 24, T.Raised, 12)
    track.Position = UDim2.new(1, -52, 0, 19)
    local outline = UI.stroke(track, T.Line)
    local thumb = UI.frame(track, "Thumb", 3, 3, 18, 18, T.Secondary, 999)
    local notch = UI.frame(thumb, "Notch", 6, 4, 1, 4, T.Ink)
    c.Layout = function(place)
        track.Position = UDim2.fromOffset(place.ControlX + place.ControlWidth - 44, place.ControlY + (place.ControlHeight - 24) / 2)
        state.Position = UDim2.fromOffset(place.ControlX, place.ControlY)
        state.Size = UDim2.fromOffset(36, place.ControlHeight)
    end
    local function render(instant)
        state.Text = value and Textos.si or Textos.no
        local stateColor = value and T.Accent or T.Muted
        local outlineColor = value and T.AccentSoft or T.Line
        local props = {BackgroundColor3 = value and T.AccentWash or T.Raised}
        local knobProps = {Position = UDim2.fromOffset(value and 23 or 3, 3), BackgroundColor3 = value and T.Text or T.Secondary}
        if instant then
            state.TextColor3, outline.Color = stateColor, outlineColor
            track.BackgroundColor3 = props.BackgroundColor3
            for k, v in pairs(knobProps) do thumb[k] = v end
        else
            rt:Tween(state, {TextColor3 = stateColor}, 0.12)
            rt:Tween(outline, {Color = outlineColor}, 0.12)
            rt:Tween(track, props)
            rt:Tween(thumb, knobProps)
        end
        notch.Visible = false
    end
    c.Get = function() return value end
    function c:Set(nextValue, silent)
        if rt.Destroyed or window._closing then return false end
        nextValue = nextValue == true
        if value == nextValue then return false end
        value = nextValue
        render(false)
        self:Refresh()
        if not silent then rt:Callback(options.Callback, value) end
        return true
    end
    rt:Connect(input.Activated, function()
        if not c:CanInteract() then return end
        window:FinishEntrance()
        c:Focus()
        c:Set(not value)
    end)
    rt:Connect(input.MouseEnter, function() rt:Tween(track, {BackgroundColor3 = T.Hover}) end)
    rt:Connect(input.MouseLeave, function() render(false) end)
    rt:Connect(input.SelectionGained, function() c:Focus(); outline.Color = T.Accent end)
    rt:Connect(input.SelectionLost, function() render(false) end)
    render(true)
    return c
end

return Toggle
