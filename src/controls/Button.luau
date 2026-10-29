local UI = require("UI")
local T = require("Theme")
local Button = {}

function Button.new(section, options)
    local c = section:Row(options, "Button", 60)
    local rt = c.Runtime
    local window = section.Tab.Window
    local secondary = options.Variant == "Secondary"
    local normal = secondary and T.Raised or T.Accent
    local hover = secondary and T.Hover or T.AccentHover
    local action = UI.button(c.Row, "Action", options.Action or "Run action", 0, 15, 144, 30)
    action.AnchorPoint = Vector2.new(0.5, 0.5)
    action.Position = UDim2.new(1, -88, 0, 30)
    action.BackgroundTransparency = 0
    action.BackgroundColor3, action.TextColor3 = normal, secondary and T.Text or T.Ink
    action.Font = T.Medium
    action.ZIndex = 2
    UI.corner(action, 5)
    if secondary then UI.stroke(action, T.Line) end
    c.Input = action
    local scale = UI.new("UIScale", action, {Scale = 1})
    local hovered, pressed = false, false
    local function settleScale()
        if rt.Animations == false then scale.Scale = 1; return end
        rt:Tween(scale, {Scale = pressed and 0.975 or (hovered and 1.01 or 1)}, pressed and 0.07 or 0.12)
    end
    c.Layout = function(narrow) action.Position = UDim2.new(1, -88, 0, narrow and 69 or 30) end
    local count = 0
    c.Get = function() return count == 0 and "Ready" or (tostring(count) .. " completed") end
    function c:Press()
        if rt.Destroyed or window._closing then return false end
        window:FinishEntrance()
        count += 1
        local generation = count
        self:Focus()
        action.Text = "Completed"
        if rt.Animations ~= false then
            rt:Tween(scale, {Scale = 0.975}, 0.07)
            rt:Delay(0.07, function() if generation == count then settleScale() end end)
        end
        rt:Delay(0.7, function()
            if generation == count then action.Text = options.Action or "Run action" end
        end)
        rt:Callback(options.Callback)
        return true
    end
    UI.hover(rt, action, normal, hover)
    rt:Connect(action.MouseEnter, function() if not window._closing then hovered = true; settleScale() end end)
    rt:Connect(action.MouseLeave, function() hovered = false; pressed = false; settleScale() end)
    rt:Connect(action.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if window._closing then return end
            pressed = true
            settleScale()
            rt:Tween(action, {BackgroundColor3 = secondary and T.Surface or T.Secondary}, 0.06)
        end
    end)
    rt:Connect(action.InputEnded, function()
        pressed = false
        settleScale()
        rt:Tween(action, {BackgroundColor3 = normal}, 0.08)
    end)
    rt:Connect(action.Activated, function() c:Press() end)
    rt:Connect(action.SelectionGained, function() c:Focus() end)
    return c
end

return Button
