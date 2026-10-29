local UI = require("UI")
local T = require("Theme")
local Button = {}

function Button.new(section, options)
    local c = section:Row(options, "Button", 60)
    local rt = c.Runtime
    local secondary = options.Variant == "Secondary"
    local normal = secondary and T.Raised or T.Accent
    local hover = secondary and T.Hover or T.AccentHover
    local action = UI.button(c.Row, "Action", options.Action or "Run action", 0, 15, 144, 30)
    action.Position = UDim2.new(1, -160, 0, 15)
    action.BackgroundTransparency = 0
    action.BackgroundColor3, action.TextColor3 = normal, secondary and T.Text or T.Ink
    action.Font = T.Medium
    action.ZIndex = 2
    UI.corner(action, 5)
    if secondary then UI.stroke(action, T.Line) end
    c.Input = action
    c.Layout = function(narrow) action.Position = UDim2.new(1, -160, 0, narrow and 54 or 15) end
    local count = 0
    c.Get = function() return count == 0 and "Ready" or (tostring(count) .. " completed") end
    function c:Press()
        if rt.Destroyed then return false end
        count += 1
        self:Focus()
        action.Text = "Completed"
        rt:Callback(options.Callback)
        task.delay(0.7, function()
            if not rt.Destroyed then action.Text = options.Action or "Run action" end
        end)
        return true
    end
    UI.hover(rt, action, normal, hover)
    rt:Connect(action.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            rt:Tween(action, {BackgroundColor3 = secondary and T.Surface or T.Secondary}, 0.06)
        end
    end)
    rt:Connect(action.InputEnded, function() rt:Tween(action, {BackgroundColor3 = normal}, 0.08) end)
    rt:Connect(action.Activated, function() c:Press() end)
    rt:Connect(action.SelectionGained, function() c:Focus() end)
    return c
end

return Button
