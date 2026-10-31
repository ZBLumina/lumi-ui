local Players = game:GetService("Players")
local UI = require("UI")
local T = require("Theme")
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

    local frame = UI.frame(window.Sidebar, "SidebarFooter", 20, 0, 144, 76)
    frame.ClipsDescendants = true
    local rule = UI.line(frame, 0, 0, 144)
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
    local self = setmetatable({
        Window = window, Runtime = rt, Frame = frame, Avatar = avatar,
        NameLabel = nameLabel, UserLabel = userLabel,
        _rule = rule, _placeholder = placeholder, _destroyed = false,
        _distinctUsername = string.lower(displayName) ~= string.lower(username),
    }, Profile)

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

-- width es el ancho del pie: SidebarWidth - 40 (144 o 100).
function Profile:Fit(width, short)
    if not alive(self) then return end
    width = math.max(0, math.floor(UI.number(width, self.Frame.Size.X.Offset)))
    local height = short and 56 or 76
    local compact = short or width < 124
    local avatarSize = compact and 32 or 34
    local gap = compact and 8 or 10
    local avatarY = short and 12 or 20
    local textX = avatarSize + gap
    local textWidth = math.max(0, width - textX)
    local showUser = self._distinctUsername and not short and textWidth >= 80
    local nameY = avatarY + math.floor((avatarSize - (showUser and 34 or 18)) / 2)

    self.Frame.Position = UDim2.new(0, 20, 1, -(height + (short and 13 or 19)))
    self.Frame.Size = UDim2.fromOffset(width, height)
    self._rule.Size = UDim2.fromOffset(width, 1)
    self.Avatar.Position = UDim2.fromOffset(0, avatarY)
    self.Avatar.Size = UDim2.fromOffset(avatarSize, avatarSize)
    self.Avatar.Visible = width >= avatarSize
    self._placeholder.Size = UDim2.fromOffset(avatarSize, avatarSize)
    self.NameLabel.Position = UDim2.fromOffset(textX, nameY)
    self.NameLabel.Size = UDim2.fromOffset(textWidth, 18)
    self.NameLabel.Visible = textWidth > 0
    self.UserLabel.Position = UDim2.fromOffset(textX, nameY + 18)
    self.UserLabel.Size = UDim2.fromOffset(textWidth, 16)
    self.UserLabel.Visible = showUser
end

return Profile
