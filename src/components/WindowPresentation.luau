local UI = require("UI")
local T = require("Theme")
local Motion = require("Motion")
local Shadow = require("components/Shadow")
local Presentation = {}
Presentation.__index = Presentation
local TRANSITION, FOLLOW = 0.18, 0.14

function Presentation.new(window)
    local rt = window.Runtime
    local self = setmetatable({Window = window, State = "expanded"}, Presentation)
    self.Motion = Motion.new(rt, window.Main)
    local capsule = UI.button(window.Root, "RestoreCapsule", "", 0, 16, 148, 38)
    capsule.ZIndex = 201
    capsule.AnchorPoint = Vector2.new(.5, 0)
    capsule.BackgroundColor3, capsule.BackgroundTransparency = T.Shell, 0
    capsule.Visible = false
    UI.corner(capsule, 19)
    UI.stroke(capsule, T.Line)
    Shadow.new(capsule, 19)
    UI.mark(capsule, 13, 9, 20)
    UI.text(capsule, "Label", window.Sidebar.Brand.Text, 42, 0, 70, 38, 15, T.Text, T.Brand)
    UI.chevron(capsule, 125, 18)
    self.CapsuleScale = UI.new("UIScale", capsule, {Scale = 1})
    self.CapsuleMotion = Motion.new(rt, capsule)
    window.Capsule = capsule
    UI.hover(rt, capsule, T.Shell, T.Raised)
    rt:Connect(capsule.Activated, function() window:Restore() end)
    local shield = UI.button(window.Main, "PresentationShield", "", 0, 0, 0, 0)
    shield.Size, shield.ZIndex = UDim2.fromScale(1, 1), 200
    shield.Selectable, shield.Visible = false, false
    self.Shield = shield
    return self
end

function Presentation:Home()
    return UDim2.fromOffset(self.Window.PanelWidth + 12, 0)
end

function Presentation:StopFollow()
    local w = self.Window
    w.Runtime:CancelTween(w.Sidebar, "follow")
    w.Runtime:CancelTween(w.Inspector, "follow")
    w.Sidebar.Position = UDim2.fromOffset(0, 0)
    w.Inspector.Position = self:Home()
end

function Presentation:SettleFollow()
    local w = self.Window
    if w.Runtime.Destroyed then return end
    w.Runtime:Tween(w.Sidebar, {Position = UDim2.fromOffset(0, 0)}, FOLLOW, "follow")
    w.Runtime:Tween(w.Inspector, {Position = self:Home()}, FOLLOW, "follow")
end

function Presentation:Follow(delta)
    local w = self.Window
    if w.Mobile or w.Runtime.Animations == false or w.Minimized then self:StopFollow(); return end
    -- Mirror the horizontal limits so each surface keeps at least 6px of
    -- open space next to the principal panel, including rapid reversals.
    local left = w.Center.X - w.Width * w.Scale / 2
    local top = w.Center.Y - w.Height * w.Scale / 2
    local minimumX = (8 - left) / w.Scale
    local minimumY = (8 - top) / w.Scale
    local maximumY = (w.Viewport.AbsoluteSize.Y - 8 - top) / w.Scale - w.Height
    local function follow(surface, home, low, high)
        w.Runtime:CancelTween(surface, "follow")
        if not surface.Visible then surface.Position = home; return end
        local maximumX = (w.Viewport.AbsoluteSize.X - 8 - left) / w.Scale - surface.Size.X.Offset
        low, high = math.max(low, minimumX), math.min(high, maximumX)
        local x = math.clamp(surface.Position.X.Offset - delta.X / w.Scale, low, math.max(low, high))
        local y = math.clamp(surface.Position.Y.Offset - delta.Y / w.Scale, -14, 14)
        y = math.clamp(y, minimumY, math.max(minimumY, maximumY))
        surface.Position = UDim2.fromOffset(x, y)
    end
    follow(w.Sidebar, UDim2.fromOffset(0, 0), -16, 6)
    local home = self:Home()
    follow(w.Inspector, home, home.X.Offset - 6, home.X.Offset + 16)
    self:SettleFollow()
end

function Presentation:Fit()
    local w = self.Window
    self:FinishTransition()
    local viewport = w.Viewport.AbsoluteSize
    local height = w.Mobile and 44 or 38
    w.Capsule.Size = UDim2.fromOffset(148, height)
    w.Capsule.Label.Size = UDim2.fromOffset(70, height)
    w.Capsule.LumiMark.Position = UDim2.fromOffset(13, (height - 20) / 2)
    w.Capsule.Chevron.Position = UDim2.fromOffset(122, height / 2 - 8)
    w.Capsule:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, height / 2)
    local top = w.Mobile and w.SafeTop or 16
    self.CapsuleHome = UDim2.fromOffset(viewport.X / 2, math.min(top, math.max(8, viewport.Y - height - 8)))
    w.Capsule.Position = self.CapsuleHome
end

function Presentation:FinishTransition()
    if self.State ~= "minimizing" and self.State ~= "restoring" then return end
    local w, rt = self.Window, self.Window.Runtime
    self.Motion:Finish()
    self.CapsuleMotion:Finish()
    rt:CancelTween(w.UIScale, "presentation")
    rt:CancelTween(w.Main, "presentation")
    rt:CancelTween(self.CapsuleScale, "presentation")
    rt:CancelTween(w.Capsule, "presentation")
    w.UIScale.Scale, self.CapsuleScale.Scale = w.Scale, 1
    w.Main.Position = UDim2.fromOffset(w.Center.X, w.Center.Y)
    w.Capsule.Position = self.CapsuleHome
    w.Main.Visible, w.Capsule.Visible = not w.Minimized, w.Minimized
    self.Shield.Visible = false
    self.State = w.Minimized and "minimized" or "expanded"
end

function Presentation:Prepare()
    local w = self.Window
    w:FinishEntrance()
    self:FinishTransition()
    w:ToggleNavigation(false)
    w:EndPointer()
    w:ClosePopup()
    w:ReleaseInput()
    self:StopFollow()
    w:FinishPages()
end

function Presentation:Minimize()
    local w, rt = self.Window, self.Window.Runtime
    if w._destroyed or w._closing or w.Minimized then return false end
    self:Prepare()
    w.Minimized, self.State = true, "minimizing"
    w.Capsule.Visible = true
    self.Shield.Visible = true
    if rt.Animations == false then self:FinishTransition(); return true end
    self.CapsuleScale.Scale = .94
    rt:Tween(self.CapsuleScale, {Scale = 1}, TRANSITION, "presentation")
    self.CapsuleMotion:Fade(.65, 0, TRANSITION)
    rt:Tween(w.UIScale, {Scale = w.Scale * .98}, TRANSITION, "presentation")
    rt:Tween(w.Main, {Position = UDim2.fromOffset(w.Center.X, w.Center.Y - 10)}, TRANSITION, "presentation")
    self.Motion:Fade(0, 1, TRANSITION, function() self:FinishTransition() end)
    return true
end

function Presentation:Restore()
    local w, rt = self.Window, self.Window.Runtime
    if w._destroyed or w._closing or not w.Minimized then return false end
    self:Prepare()
    w.Minimized, self.State = false, "restoring"
    w.Main.Visible = true
    self.Shield.Visible = true
    if rt.Animations == false then self:FinishTransition(); return true end
    w.UIScale.Scale = w.Scale * .98
    w.Main.Position = UDim2.fromOffset(w.Center.X, w.Center.Y - 10)
    rt:Tween(w.UIScale, {Scale = w.Scale}, TRANSITION, "presentation")
    rt:Tween(w.Main, {Position = UDim2.fromOffset(w.Center.X, w.Center.Y)}, TRANSITION, "presentation")
    self.CapsuleMotion:Fade(0, 1, TRANSITION)
    self.Motion:Fade(.65, 0, TRANSITION, function() self:FinishTransition() end)
    return true
end

function Presentation:CloseMinimized()
    local w = self.Window
    w.Capsule.Selectable = false
    self.CapsuleMotion:Fade(0, 1, Motion.Time.Close, function() w:Destroy() end)
end

return Presentation
