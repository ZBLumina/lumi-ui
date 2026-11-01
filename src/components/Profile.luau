local Players = game:GetService("Players")
local UI = require("UI")
local T = require("Theme")
local Textos = require("Textos")
local Profile = {}
Profile.__index = Profile

local function text(value)
    if type(value) ~= "string" then return nil end
    local clean = value:gsub("%c", " "):match("^%s*(.-)%s*$")
    return clean ~= "" and clean or nil
end

local function initial(value)
    local ok, nextByte = pcall(utf8.offset, value, 2)
    if not ok then return "?" end
    return string.upper(value:sub(1, (nextByte or #value + 1) - 1))
end

local function alive(self)
    return not self._destroyed and not self.Runtime.Destroyed
        and not self.Window._destroyed and not self.Window._closing
        and self.Frame.Parent == self.Window.Sidebar
        and self.Avatar.Parent == self.Frame
        and self.NameLabel.Parent == self.Frame and self.UserLabel.Parent == self.Frame
        and self._placeholder.Parent == self.Avatar
end

function Profile.new(window, options)
    local rt = window.Runtime
    local settings = type(options) == "table" and options.Profile
    settings = type(settings) == "table" and settings or {}
    local player = Players.LocalPlayer
    local username = text(settings.Username)
    if username then username = text((username:gsub("^@+", ""))) end
    username = username or (player and text(player.Name)) or "usuario"
    local displayName = text(settings.DisplayName) or (player and text(player.DisplayName)) or username
    local first = displayName:match("^%S+") or displayName
    local last = displayName:match("%s(%S+)$")
    local initials = initial(first) .. (last and initial(last) or "")

    local frame = UI.button(window.Sidebar, "SidebarFooter", "", 12, 0, 204, 60)
    frame.BackgroundColor3, frame.BackgroundTransparency = T.Surface, .18
    UI.corner(frame, 9)
    UI.stroke(frame, T.SoftLine)
    frame.ClipsDescendants = true
    local rule = UI.line(frame, 0, 0, 144)
    rule.Visible = false
    local avatar = UI.new("ImageLabel", frame, {
        Name = "Avatar", Image = "", Size = UDim2.fromOffset(34, 34),
        BackgroundColor3 = T.Raised, BackgroundTransparency = 0,
        ScaleType = Enum.ScaleType.Crop,
    })
    UI.corner(avatar, 999)
    local placeholder = UI.text(avatar, "Initials", initials, 0, 0, 34, 34, 13, T.Secondary, T.Medium)
    placeholder.TextXAlignment = Enum.TextXAlignment.Center
    placeholder.TextTruncate = Enum.TextTruncate.None
    placeholder.ZIndex = avatar.ZIndex + 1
    local nameLabel = UI.text(frame, "DisplayName", displayName, 44, 20, 100, 18, 12, T.Text, T.Medium)
    local userLabel = UI.text(frame, "Username", "@" .. username, 44, 38, 100, 16, 11, T.Muted)
    local status = UI.text(frame, "Status", Textos.enLinea, 58, 30, 80, 15, 10, T.Muted)
    local dot = UI.frame(frame, "StatusDot", 48, 35, 4, 4, T.Green, 999)
    UI.chevron(frame, 184, 28, T.Secondary)
    frame.ChevronA.Rotation, frame.ChevronB.Rotation = 45, -45
    local self = setmetatable({
        Window = window, Runtime = rt, Frame = frame, Avatar = avatar,
        NameLabel = nameLabel, UserLabel = userLabel,
        Status = status, StatusDot = dot,
        _rule = rule, _placeholder = placeholder, _destroyed = false,
        _distinctUsername = string.lower(displayName) ~= string.lower(username),
    }, Profile)
    UI.hover(rt, frame, T.Surface, T.Hover)
    rt:Connect(frame.Activated, function() self:Open() end)

    rt:Connect(frame.Destroying, function() self._destroyed = true end)
    rt:Connect(avatar.Destroying, function() self._destroyed = true end)
    local function refreshPlaceholder()
        if not alive(self) then return end
        placeholder.Visible = avatar.Image == "" or not avatar.IsLoaded
    end
    rt:Connect(avatar:GetPropertyChangedSignal("Image"), refreshPlaceholder)
    rt:Connect(avatar:GetPropertyChangedSignal("IsLoaded"), refreshPlaceholder)

    self:Fit(math.max(0, window.Sidebar.Size.X.Offset - 40), false)
    if settings.Avatar ~= nil then
        rt:Callback(function()
            if not alive(self) then return end
            pcall(function() require("ImageSource").Bind(rt, avatar, settings.Avatar) end)
            refreshPlaceholder()
        end)
    elseif player then
        rt:Callback(function()
            if not alive(self) then return end
            local ok, content, ready = pcall(function()
                return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
            end)
            -- La consulta cede; la ventana o el pie pueden haberse destruido.
            if not alive(self) then return end
            if ok and ready and type(content) == "string" and content ~= "" then
                avatar.Image = content
                refreshPlaceholder()
            end
        end)
    end
    return self
end

-- width es el ancho de la tarjeta; bottom reserva el acceso inferior.
function Profile:Fit(width, short, bottom)
    if not alive(self) then return end
    width = math.max(0, math.floor(UI.number(width, self.Frame.Size.X.Offset)))
    local height = short and 50 or 60
    local compact = short or width < 124
    local avatarSize = compact and 32 or 34
    local gap = compact and 8 or 10
    local avatarY = math.floor((height - avatarSize) / 2)
    local textX = 8 + avatarSize + gap
    local textWidth = math.max(0, width - textX - 28)
    local showUser = self._distinctUsername and not short and textWidth >= 80
    local nameY = avatarY + math.floor((avatarSize - 34) / 2)

    self.Frame.Position = UDim2.new(0, 12, 1, -(height + (bottom or 12)))
    self.Frame.Size = UDim2.fromOffset(width, height)
    self._rule.Size = UDim2.fromOffset(width, 1)
    self.Avatar.Position = UDim2.fromOffset(8, avatarY)
    self.Avatar.Size = UDim2.fromOffset(avatarSize, avatarSize)
    self.Avatar.Visible = width >= avatarSize
    self._placeholder.Size = UDim2.fromOffset(avatarSize, avatarSize)
    self.NameLabel.Position = UDim2.fromOffset(textX, nameY)
    self.NameLabel.Size = UDim2.fromOffset(textWidth, 18)
    self.NameLabel.Visible = textWidth > 0
    self.UserLabel.Position = UDim2.fromOffset(textX, nameY + 18)
    self.UserLabel.Size = UDim2.fromOffset(textWidth, 16)
    self.UserLabel.Visible = showUser
    self.Status.Position = UDim2.fromOffset(textX + 9, nameY + 19)
    self.Status.Size = UDim2.fromOffset(math.max(0, textWidth - 9), 15)
    self.Status.Visible = not showUser and textWidth >= 50
    self.StatusDot.Position = UDim2.fromOffset(textX, nameY + 25)
    self.StatusDot.Visible = self.Status.Visible
    self.Frame.ChevronA.Position = UDim2.fromOffset(width - 20, height / 2 - 2)
    self.Frame.ChevronB.Position = UDim2.fromOffset(width - 20, height / 2 + 2)
end

function Profile:Open()
    local w = self.Window
    if not alive(self) or w._closing or w.Minimized then return nil end
    if not self.Tab then
        self.Tab = w:AddTab("Perfil", {Icon = "User", Description = self.UserLabel.Text, Eyebrow = "TU CUENTA / LUMI"})
        self.Tab.Button.Visible = false
        local group = self.Tab:AddSection("Cuenta de Roblox", {Tag = "PERFIL LOCAL"})
        group:AddInput({Name = "Nombre de visualización", Default = self.NameLabel.Text, ReadOnly = true})
        group:AddInput({Name = "Nombre de usuario", Default = self.UserLabel.Text, ReadOnly = true})
        group:AddInput({Name = "Estado", Default = Textos.enLinea, ReadOnly = true})
    end
    w:SelectTab(self.Tab)
    return self.Tab
end

return Profile
