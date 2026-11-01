local Fonts = require("Fonts")
local Layout = {}
local PAD, VERTICAL, COLUMN_GAP, STACK_GAP, INPUT_HEIGHT = 16, 12, 24, 12, 36
local widths = {Button = 144, Dropdown = 220, Toggle = 100, Slider = 96, Input = 220}

local function textHeight(label, width, minimum)
    local bounds = Fonts.bounds(label.Text, label.TextSize, label.FontFace, width - 1)
    return math.max(minimum, math.ceil(bounds.Y) + 2)
end

function Layout.inputWidth(text, font, size, minimum, maximum)
    local bounds = Fonts.bounds(text, size, font)
    return math.clamp(math.ceil(bounds.X) + 24, minimum, maximum)
end

function Layout.measure(control, width)
    local phone = control.Section.Tab.Window.Mobile
    local inputHeight = phone and 44 or INPUT_HEIGHT
    local available = math.max(1, math.floor(width - 2 * PAD))
    if control.Kind == "Input" and control.MultiLine then
        local title = textHeight(control.Label, available, 18)
        local description = control.DescriptionLabel.Text ~= "" and textHeight(control.DescriptionLabel, available, 16) or 0
        local text = title + (description > 0 and 4 + description or 0)
        local fieldHeight = math.clamp(control.FieldHeight or 112, 80, 240)
        local fieldY = VERTICAL + text + STACK_GAP
        return {
            Stacked = true, Height = fieldY + fieldHeight + VERTICAL, TextWidth = available,
            TitleHeight = title, DescriptionHeight = description, TitleY = VERTICAL,
            DescriptionY = VERTICAL + title + 4,
            ControlX = PAD, ControlY = fieldY, ControlWidth = available, ControlHeight = fieldHeight,
        }
    end
    local field = math.min(control.ControlWidth or widths[control.Kind], available)
    local caption = available - field - COLUMN_GAP
    local stacked = caption < 200 or (phone and control.Kind ~= "Toggle")
    if stacked then caption = available end
    local title = textHeight(control.Label, caption, 18)
    local description = control.DescriptionLabel.Text ~= "" and textHeight(control.DescriptionLabel, caption, 16) or 0
    local text = title + (description > 0 and 4 + description or 0)
    local header = stacked and text + STACK_GAP + inputHeight or math.max(text, inputHeight)
    local slider = control.Kind == "Slider"
    local height = math.max(64, VERTICAL * 2 + header)
    local top = slider and VERTICAL or (height - header) / 2
    local result = {
        Stacked = stacked, Height = height, TextWidth = caption, TitleHeight = title, DescriptionHeight = description,
        TitleY = top + (stacked and 0 or (header - text) / 2),
        ControlX = width - PAD - field, ControlY = top + (stacked and text + STACK_GAP or (header - inputHeight) / 2),
        ControlWidth = field, ControlHeight = inputHeight,
    }
    result.DescriptionY = result.TitleY + title + 4
    if slider then
        result.HitY, result.HitHeight = top + header + 8, phone and 44 or 28
        result.TrackY = result.HitY + result.HitHeight / 2
        result.BoundsY = result.HitY + result.HitHeight + 2
        result.LaneX, result.LaneWidth = PAD, available
        result.BoundsWidth = math.max(1, (available - 12) / 2)
        result.BoundsHeight = 14
        for _,label in ipairs(control.BoundsLabels or {}) do
            result.BoundsHeight = math.max(result.BoundsHeight, textHeight(label, result.BoundsWidth, 14))
        end
        result.Height = (control.ShowBounds == false and result.HitY + result.HitHeight or result.BoundsY + result.BoundsHeight) + VERTICAL
    end
    return result
end

return Layout
