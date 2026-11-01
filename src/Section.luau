local UI = require("UI")
local T = require("Theme")
local PropertyLayout = require("PropertyLayout")
local Textos = require("Textos")
local Control = require("Control")
local Fonts = require("Fonts")
local Button = require("controls/Button")
local Toggle = require("controls/Toggle")
local Slider = require("controls/Slider")
local Dropdown = require("controls/Dropdown")
local Input = require("controls/Input")
local Section = {}
Section.__index = Section

function Section.new(tab, name, options)
    local frame = UI.new("Frame", tab.Page, {
        Name = tostring(name) .. "Section", Size = UDim2.new(1, 0, 0, 44),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 0.12, BackgroundColor3 = T.Surface,
        LayoutOrder = #tab.Sections + 1,
    })
    UI.corner(frame, 10)
    UI.stroke(frame, T.SoftLine)
    UI.list(frame, 0)
    local header = UI.new("Frame", frame, {Name = "SectionHeader", Size = UDim2.new(1, 0, 0, 43), LayoutOrder = 0})
    local index = #tab.Sections + 1
    UI.frame(header, "IndexBadge", 16, 10, 24, 24, T.AccentWash, 12).BackgroundTransparency = 0.35
    UI.text(header, "Index", string.format("%02d", index), 16, 0, 24, 43, 10, T.Secondary, T.Mono).TextXAlignment = Enum.TextXAlignment.Center
    local heading = UI.text(header, "Title", name, 45, 0, 440, 43, 15, T.Text, T.Medium)
    heading.TextWrapped,heading.TextTruncate=true,Enum.TextTruncate.None
    local tag = UI.text(header, "Tag", options.Tag or Textos.ajustes, 510, 0, 116, 43, 9, T.Muted, T.Mono)
    tag.TextXAlignment = Enum.TextXAlignment.Right
    tag.Position = UDim2.new(1, -132, 0, 0)
    local self = setmetatable({Name = tostring(name), Tab = tab, Frame = frame, Content = frame, Controls = {},
        Heading = heading, Tag = tag, _order = 0}, Section)
    self.Id = options.Id or tostring(name)
    table.insert(tab.Sections, self)
    local function fitHeader() self:Relayout() end
    tab.Window.Runtime:Connect(header:GetPropertyChangedSignal("AbsoluteSize"), fitHeader)
    fitHeader()
    return self
end

function Section:GetWidth()
    return self.Tab:GetContentWidth() * self.Frame.Size.X.Scale + self.Frame.Size.X.Offset
end

function Section:Relayout()
    local wide = self:GetWidth() >= 420
    self.Tag.Visible = wide
    local reserved=wide and 190 or 61
    local width=math.max(1,self:GetWidth()-reserved)
    local height=math.max(43,math.ceil(Fonts.bounds(self.Heading.Text,self.Heading.TextSize,self.Heading.FontFace,width).Y)+14)
    self.Heading.Parent.Size=UDim2.new(1,0,0,height)
    self.Heading.Size = UDim2.new(1, -reserved, 0, height)
    self.Tag.Size=UDim2.fromOffset(116,height)
end

function Section:Row(options, kind, height)
    local id = Control.id(self, options, kind)
    self._order += 1
    local row = UI.new("CanvasGroup", self.Content, {Name = (options.Name or kind) .. "Row",
        Size = UDim2.new(1, 0, 0, height or 64), LayoutOrder = self._order, ClipsDescendants = true})
    local selection = UI.frame(row, "SelectionWash", 6, 5, 0, 0, T.AccentWash, 8)
    UI.stroke(selection, T.AccentSoft).Transparency = 0.45
    selection.Size = UDim2.new(1, -12, 1, -10)
    selection.BackgroundTransparency, selection.Visible = 0.4, false
    local rule = UI.new("Frame", row, {Name = "Divider", Size = UDim2.new(1, -32, 0, 1),
        Position = UDim2.fromOffset(16, 0), BackgroundTransparency = 0, BackgroundColor3 = T.SoftLine})
    local nombre = options.Name or Textos.nombreTipo(kind)
    local title = UI.text(row, "Name", nombre, 16, 12, 330, 18, 15, T.Text, T.Medium)
    local description = UI.text(row, "Description", options.Description or "", 16, 33, 350, 15, 12, T.Muted)
    title.TextWrapped, description.TextWrapped = true, true
    title.TextTruncate, description.TextTruncate = Enum.TextTruncate.None, Enum.TextTruncate.None
    local control = {Name = nombre, Description = options.Description or "", Kind = kind,
        Row = row, Section = self, Runtime = self.Tab.Window.Runtime, Label = title, DescriptionLabel = description,
        SelectionWash = selection}
    Control.attach(control, options, id)
    control.FocusIndicator = UI.new("Frame", row, {Name = "FocusIndicator", Position = UDim2.fromOffset(0, 14),
        Size = UDim2.new(0, 1, 1, -28), BackgroundTransparency = 0.25, BackgroundColor3 = T.AccentSoft, Visible = false})
    function control:Focus() if not self._destroyed then self.Section.Tab.Window:Focus(self) end end
    function control:Refresh()
        if self.Section.Tab.Window.SelectedControl == self then self:Focus() end
    end
    function control:Relayout()
        if self._destroyed then return end
        local width = self.Section:GetWidth() * row.Size.X.Scale + row.Size.X.Offset
        if width <= 0 then return end
        local placement = PropertyLayout.measure(self, width)
        title.Position = UDim2.fromOffset(16, placement.TitleY)
        title.Size = UDim2.fromOffset(placement.TextWidth, placement.TitleHeight)
        description.Position = UDim2.fromOffset(16, placement.DescriptionY)
        description.Size = UDim2.fromOffset(placement.TextWidth, placement.DescriptionHeight)
        description.Visible = placement.DescriptionHeight > 0
        row.Size = UDim2.new(1, 0, 0, placement.Height)
        if self.Layout then self.Layout(placement) end
    end
    table.insert(self.Controls, control)
    table.insert(self.Tab.Controls, control)
    self.Tab:Relayout()
    local rt = control.Runtime
    rt:Connect(row:GetPropertyChangedSignal("AbsoluteSize"), function() control:Relayout() end)
    task.defer(function() if not rt.Destroyed then control:Relayout() end end)
    rt:Connect(row.MouseEnter, function()
        rt:Tween(rule, {BackgroundColor3 = T.Line})
    end)
    rt:Connect(row.MouseLeave, function() rt:Tween(rule, {BackgroundColor3 = T.SoftLine}) end)
    if #self.Tab.Controls == 1 and self.Tab.Window.ActiveTab == self.Tab then task.defer(function()
        if not rt.Destroyed and not self.Tab.Window.SelectedControl then control:Focus() end
    end) end
    return control
end

function Section:AddButton(options) return Control.finish(Button.new(self, options or {})) end
function Section:AddToggle(options) return Control.finish(Toggle.new(self, options or {})) end
function Section:AddSlider(options) return Control.finish(Slider.new(self, options or {})) end
function Section:AddDropdown(options) return Control.finish(Dropdown.new(self, options or {})) end
function Section:AddImageDropdown(options) return self:AddDropdown(options) end
function Section:AddInput(options) return Control.finish(Input.new(self, options or {})) end

return Section
