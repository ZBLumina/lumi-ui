local UI = require("UI")
local T = require("Theme")
local Button = require("controls/Button")
local Toggle = require("controls/Toggle")
local Slider = require("controls/Slider")
local Dropdown = require("controls/Dropdown")
local Section = {}
Section.__index = Section

function Section.new(tab, name, options)
    local frame = UI.new("Frame", tab.Page, {
        Name = tostring(name) .. "Section", Size = UDim2.new(1, 0, 0, 44),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 0, BackgroundColor3 = T.Surface,
        LayoutOrder = #tab.Sections + 1,
    })
    UI.corner(frame, 8)
    UI.stroke(frame, T.SoftLine)
    UI.list(frame, 0)
    local header = UI.new("Frame", frame, {Name = "SectionHeader", Size = UDim2.new(1, 0, 0, 43), LayoutOrder = 0})
    local index = #tab.Sections + 1
    UI.text(header, "Index", string.format("%02d", index), 16, 0, 26, 43, 10, T.Muted, T.Mono)
    UI.text(header, "Title", name, 45, 0, 440, 43, 13, T.Text, T.Medium).Size = UDim2.new(1, -190, 0, 43)
    local tag = UI.text(header, "Tag", options.Tag or "PROPERTIES", 510, 0, 116, 43, 9, T.Muted, T.Mono)
    tag.TextXAlignment = Enum.TextXAlignment.Right
    tag.Position = UDim2.new(1, -132, 0, 0)
    local self = setmetatable({Name = tostring(name), Tab = tab, Frame = frame, Content = frame, Controls = {}, _order = 0}, Section)
    table.insert(tab.Sections, self)
    return self
end

function Section:Row(options, kind, height)
    self._order += 1
    local row = UI.new("Frame", self.Content, {Name = (options.Name or kind) .. "Row",
        Size = UDim2.new(1, 0, 0, height or 56), LayoutOrder = self._order})
    local rule = UI.new("Frame", row, {Name = "Divider", Size = UDim2.new(1, -32, 0, 1),
        Position = UDim2.fromOffset(16, 0), BackgroundTransparency = 0, BackgroundColor3 = T.SoftLine})
    local title = UI.text(row, "Name", options.Name or kind, 16, 12, 330, 18, 14, T.Text, T.Medium)
    local description = UI.text(row, "Description", options.Description or "", 16, 33, 350, 15, 12, T.Muted)
    local control = {Name = options.Name or kind, Description = options.Description or "", Kind = kind,
        Row = row, Section = self, Runtime = self.Tab.Window.Runtime, Label = title, DescriptionLabel = description}
    control.FocusIndicator = UI.new("Frame", row, {Name = "FocusIndicator", Position = UDim2.fromOffset(0, 14),
        Size = UDim2.new(0, 1, 1, -28), BackgroundTransparency = 0.25, BackgroundColor3 = T.AccentSoft, Visible = false})
    function control:Focus() self.Section.Tab.Window:Focus(self) end
    function control:Refresh()
        if self.Section.Tab.Window.SelectedControl == self then self:Focus() end
    end
    function control:Relayout()
        local narrow = row.AbsoluteSize.X / math.max(0.1, self.Section.Tab.Window.Scale) < 560
        local reserve = kind == "Slider" and 128 or (kind == "Toggle" and 144 or (narrow and 32 or 280))
        title.Size = UDim2.new(1, -reserve, 0, 18)
        description.Size = UDim2.new(1, -(kind == "Toggle" and narrow and 32 or reserve), 0, 15)
        description.Position = UDim2.fromOffset(16, kind == "Toggle" and narrow and 43 or 33)
        description.TextSize = 12
        local rowHeight = narrow and ((kind == "Dropdown" or kind == "Button") and 96 or (kind == "Toggle" and 68 or height)) or height
        row.Size = UDim2.new(1, 0, 0, rowHeight or 56)
        if self.Layout then self.Layout(narrow) end
    end
    table.insert(self.Controls, control)
    table.insert(self.Tab.Controls, control)
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

function Section:AddButton(options) return Button.new(self, options or {}) end
function Section:AddToggle(options) return Toggle.new(self, options or {}) end
function Section:AddSlider(options) return Slider.new(self, options or {}) end
function Section:AddDropdown(options) return Dropdown.new(self, options or {}) end

return Section
