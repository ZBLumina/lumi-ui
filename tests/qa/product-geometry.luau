local w=getgenv().__LumiUI._windows[1]
local saved=w:GetState()
local autosave=w.Profiles.AutoSave
w.Profiles.AutoSave=false
w.Profiles:_cancel()
local count,combinations=0,0
local function inside(row,object,name)
    local a,b,s,z=object.AbsolutePosition,row.AbsolutePosition,object.AbsoluteSize,row.AbsoluteSize
    assert(a.X>=b.X-1 and a.Y>=b.Y-1 and a.X+s.X<=b.X+z.X+1 and a.Y+s.Y<=b.Y+z.Y+1,name.." escapes its container")
end
local function textFits(label,name)
    assert(label.TextFits,name.." clips text")
    assert(label.TextBounds.Y<=label.AbsoluteSize.Y+1,name.." clips text height")
end
local function separate(a,b,name)
    if not a.Visible or not b.Visible then return end
    local x=math.min(a.AbsolutePosition.X+a.AbsoluteSize.X,b.AbsolutePosition.X+b.AbsoluteSize.X)-math.max(a.AbsolutePosition.X,b.AbsolutePosition.X)
    local y=math.min(a.AbsolutePosition.Y+a.AbsoluteSize.Y,b.AbsolutePosition.Y+b.AbsoluteSize.Y)-math.max(a.AbsolutePosition.Y,b.AbsolutePosition.Y)
    assert(x<=1 or y<=1,name.." overlaps")
end
local ok,problem=xpcall(function()
    w:OpenProfile();w:OpenSettings()
    for _,language in ipairs({"es","pt"}) do
        for _,factor in ipairs({1,1.3}) do
            w:SetLanguage(language);w:SetPreference("TextScale",factor)
            for _,size in ipairs({Vector2.new(1920,1080),Vector2.new(1132,720),Vector2.new(900,720),Vector2.new(640,360),Vector2.new(420,700),Vector2.new(320,500)})do
                w.Viewport.Size=UDim2.fromOffset(size.X,size.Y);task.wait(.08);w:Fit();w:FinishEntrance();w:FinishPages();task.wait(.08)
                for _,tab in ipairs(w.Tabs)do
                    w:SelectTab(tab);w:FinishPages();task.wait(.06)
                    textFits(tab.Title,tab.Name.." title");textFits(tab.Subtitle,tab.Name.." subtitle");textFits(tab.Header.Eyebrow,tab.Name.." eyebrow")
                    for _,section in ipairs(tab.Sections)do textFits(section.Heading,section.Name.." section")end
                    for _,c in ipairs(tab.Controls)do
                        inside(c.Row,c.Label,c.Name.." label");textFits(c.Label,c.Name.." label")
                        if c.DescriptionLabel.Visible then inside(c.Row,c.DescriptionLabel,c.Name.." description");textFits(c.DescriptionLabel,c.Name.." description")end
                        local field=c.Kind=="Toggle" and c.Input.Switch or (c.Field or (c.ValueInput and c.ValueInput.Parent) or c.Input)
                        inside(c.Row,field,c.Name.." field");separate(field,c.Label,c.Name.." field/name");separate(field,c.DescriptionLabel,c.Name.." field/description")
                        if c.Kind=="Slider"then textFits(c.Row.Minimum,c.Name.." minimum");textFits(c.Row.Maximum,c.Name.." maximum")end
                        if w.Mobile then
                            assert((c.Kind=="Toggle" and c.Input.AbsoluteSize.Y or field.AbsoluteSize.Y)/w.Scale>=43.9,c.Name.." touch target too small")
                        end
                        count+=1
                    end
                end
                w:ToggleNavigation(true);task.wait(.06)
                for _,label in ipairs({w.Sidebar.Brand,w.Sidebar.BrandSub,w.Settings.Label,w.Settings.Value,w.Profile.NameLabel})do textFits(label,label:GetFullName())end
                separate(w.Profile.Frame,w.Settings.Button,"profile/settings footer")
                combinations+=1
                print("[LUMI PRODUCT GEOMETRY] PASS",language,factor,size)
            end
        end
    end
end,debug.traceback)
w.Viewport.Size=UDim2.fromScale(1,1);task.wait(.1);w:Fit();w:ApplyState(saved,{Silent=true});w:FinishPages()
w.Profiles.AutoSave=autosave;w.Profiles.Dirty=false;w.Profiles:_cancel()
if not ok then error(problem)end
print("[LUMI PRODUCT GEOMETRY] complete",combinations,"combinations",count,"control layouts")
