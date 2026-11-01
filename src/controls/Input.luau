local UI = require("UI")
local T = require("Theme")
local Textos = require("Textos")
local Fonts = require("Fonts")
local Input = {}

function Input.new(section, options)
    local c = section:Row(options, "Input", 64)
    local rt, window = c.Runtime, section.Tab.Window
    c.MultiLine, c.ReadOnly = options.MultiLine == true, options.ReadOnly == true
    c.ControlWidth = 220
    c.FieldHeight = math.clamp(UI.number(options.Height, 112), 80, 240)
    local maximum = UI.number(options.MaxLength, nil)
    if maximum then maximum = math.max(0, math.floor(maximum)) end
    c.MaxLength = maximum
    c.Range = maximum and string.format(Textos.limiteTexto, maximum) or Textos.sinLimiteTexto

    local function normalize(nextValue)
        local text = nextValue == nil and "" or tostring(nextValue)
        if maximum then
            local count = 0
            -- Cut only at grapheme boundaries, including composed accents and emoji.
            for first in utf8.graphemes(text) do
                count += 1
                if count > maximum then return text:sub(1, first - 1) end
            end
        end
        return text
    end
    local value = normalize(options.Default)
    local field = UI.new(c.MultiLine and "ScrollingFrame" or "Frame", c.Row, {
        Name = "TextField", Size = UDim2.fromOffset(220, c.MultiLine and c.FieldHeight or 36),
        BackgroundColor3 = T.Raised, BackgroundTransparency = 0, ClipsDescendants = true, ZIndex = 2,
    })
    UI.corner(field, 8)
    local border = UI.stroke(field, T.Line)
    if c.MultiLine then
        field.CanvasSize = UDim2.new()
        field.AutomaticCanvasSize = Enum.AutomaticSize.None
        field.ScrollingDirection = Enum.ScrollingDirection.Y
        field.ScrollBarThickness = 3
        field.ScrollBarImageColor3 = T.Line
        field.Active = true
    end
    local box = UI.new("TextBox", field, {
        Name = "ValueInput", Position = UDim2.fromOffset(10, c.MultiLine and 10 or 0),
        Size = UDim2.new(1, -20, 0, c.MultiLine and c.FieldHeight - 10 or 36),
        AutomaticSize = Enum.AutomaticSize.None,
        Text = value, PlaceholderText = options.Placeholder or Textos.placeholderTexto,
        TextColor3 = T.Text, PlaceholderColor3 = T.Muted, Font = T.Font, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = c.MultiLine and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
        TextWrapped = c.MultiLine, TextTruncate = Enum.TextTruncate.None,
        MultiLine = c.MultiLine, TextEditable = not c.ReadOnly, ClearTextOnFocus = false,
        Active = true, Selectable = true, ZIndex = 2,
    })
    if c.MultiLine then
        -- Include the bottom inset in the growing textbox and therefore its canvas.
        UI.new("UIPadding", box, {PaddingBottom = UDim.new(0, 10)})
    end
    c.Input, c.ValueInput, c.Field = box, box, field
    box:SetAttribute("LumiTranslateText", options.Translate == true and c.ReadOnly)
    c.Get = function() return value end
    local textWidth, pending, revision = 200, nil, 0
    local function scheduleTextLayout()
        if not c.MultiLine or rt.Destroyed or window._closing then return end
        revision += 1
        local version = revision
        rt:CancelDelay(pending)
        pending = rt:Delay(0, function()
            local text, cursor = box.Text, box.CursorPosition
            -- TextBox clips its native TextBounds to its height. Measure the full
            -- text with its real font so read-only logs can also scroll to the end.
            local full = Fonts.bounds(text .. " ", box.TextSize, box.FontFace, textWidth)
            local caret = cursor > 0 and Fonts.bounds(text:sub(1, cursor - 1) .. " ",
                box.TextSize, box.FontFace, textWidth) or nil
            local line = Fonts.bounds("Ag", box.TextSize, box.FontFace, textWidth).Y
            if version ~= revision or rt.Destroyed or window._closing then return end
            local height = math.max(c.FieldHeight - 10, math.ceil(full.Y) + 10)
            box.Size = UDim2.fromOffset(textWidth, height)
            field.CanvasSize = UDim2.fromOffset(0, height + 10)
            if caret and box:IsFocused() then
                local view = field.AbsoluteSize.Y / window.Scale
                local top, bottom = math.max(0, caret.Y - line), 12 + caret.Y
                local y = field.CanvasPosition.Y
                if top < y then y = top elseif bottom > y + view then y = bottom - view end
                field.CanvasPosition = Vector2.new(0, math.clamp(y, 0, math.max(0, height + 10 - view)))
            end
            pending = nil
        end)
    end
    c.Layout = function(place)
        if rt.Destroyed or window._closing then return end
        field.Position = UDim2.fromOffset(place.ControlX, place.ControlY)
        field.Size = UDim2.fromOffset(place.ControlWidth, place.ControlHeight)
        box.Size = UDim2.fromOffset(math.max(1, place.ControlWidth - 20),
            math.max(1, place.ControlHeight - (c.MultiLine and 10 or 0)))
        textWidth = math.max(1, place.ControlWidth - 20)
        scheduleTextLayout()
    end
    function c:Set(nextValue, silent)
        if rt.Destroyed or window._closing then return false end
        nextValue = normalize(nextValue)
        local changed = nextValue ~= value
        -- Store first so the Text signal cannot turn a silent render into an edit.
        value = nextValue
        if box.Text ~= value then box.Text = value end
        if changed then
            self:Refresh()
            if not silent then rt:Callback(options.Callback, value) end
        end
        return changed
    end
    rt:Connect(box:GetPropertyChangedSignal("Text"), function()
        -- Localized read-only text is presentation. Keep the original value,
        -- its length limit and callbacks independent of the displayed language.
        if not (c.ReadOnly and options.Translate == true) then c:Set(box.Text) end
        scheduleTextLayout()
    end)
    if c.MultiLine then
        rt:Connect(box:GetPropertyChangedSignal("CursorPosition"), scheduleTextLayout)
        rt:Connect(field:GetPropertyChangedSignal("AbsoluteSize"), scheduleTextLayout)
    end
    rt:Connect(box.Focused, function()
        if window._closing then return end
        c:Focus()
        rt:Tween(border, {Color = T.Accent})
        scheduleTextLayout()
    end)
    rt:Connect(box.FocusLost, function()
        if not window._closing then rt:Tween(border, {Color = T.Line}) end
    end)
    rt:Connect(box.SelectionGained, function()
        if not window._closing then c:Focus() end
    end)
    c:Relayout()
    return c
end

return Input
