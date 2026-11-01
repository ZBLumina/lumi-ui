local State = {}
local function finite(value) return type(value)=="number" and value==value and math.abs(value)<math.huge end

function State.Export(w)
    local controls = {}
    for id,c in pairs(w.ControlsById) do
        if c.Persist and not c._destroyed and c.Get then
            controls[id] = {Kind=c.Kind,Value=c:Get(),Enabled=c.Enabled}
        end
    end
    local size = w.Viewport.AbsoluteSize
    local center = w.Main.Visible and (w.Main.AbsolutePosition + w.Main.AbsoluteSize / 2 - w.Viewport.AbsolutePosition) or w.Center
    return {Version=1,Window={Position={X=center.X/math.max(1,size.X),Y=center.Y/math.max(1,size.Y)},
        Page=w.ActiveTab and w.ActiveTab.Id,Preferences=table.clone(w.Preferences)},Controls=controls}
end

function State.Validate(w,state)
    if type(state)~="table" or state.Version~=1 or type(state.Window)~="table" or type(state.Controls)~="table" then
        return nil,"El perfil no tiene un formato válido."
    end
    local view=state.Window
    if type(view.Preferences)~="table" or type(view.Position)~="table"
        or not finite(view.Position.X) or not finite(view.Position.Y)
        or view.Position.X<0 or view.Position.X>1 or view.Position.Y<0 or view.Position.Y>1 then
        return nil,"La posición o las preferencias no son válidas."
    end
    for key,value in pairs(view.Preferences) do
        local valid = (key=="Language" and (value=="es" or value=="pt"))
            or ((key=="Animations" or key=="Inspector") and type(value)=="boolean")
            or (key=="Decoration" and finite(value) and value>=0 and value<=100)
            or (key=="TextScale" and finite(value) and value>=1 and value<=1.3)
        if not valid then return nil,"El perfil contiene una preferencia no válida." end
    end
    local pending={}
    for id,saved in pairs(state.Controls) do
        local c=w.ControlsById[id]
        if c and c.Persist then
            if type(saved)~="table" or saved.Kind~=c.Kind or type(saved.Enabled)~="boolean" then return nil,"El perfil contiene un control no válido." end
            local value=saved.Value
            local valid=(c.Kind=="Toggle" and type(value)=="boolean") or (c.Kind=="Slider" and finite(value))
                or (c.Kind=="Dropdown" and (table.find(c.Values,value)~=nil or (#c.Values==0 and value==nil)))
                or (c.Kind=="Input" and type(value)=="string")
            if not valid then return nil,"El perfil contiene un valor no válido." end
            table.insert(pending,{Control=c,Value=value,Enabled=saved.Enabled})
        end
    end
    return pending
end

function State.Apply(w,state,options)
    if w._destroyed or w._closing then return false,"La ventana está cerrada." end
    local pending,problem=State.Validate(w,state)
    if not pending then return false,problem end
    options=options or {}
    w._applyingState=true
    local ok,issue=pcall(function()
        for name,value in pairs(state.Window.Preferences) do w:SetPreference(name,value) end
        for _,entry in ipairs(pending) do
            entry.Control:Set(entry.Value,options.Silent==true)
            entry.Control:SetEnabled(entry.Enabled)
        end
        local tab=w.TabsById[state.Window.Page]
        if tab then w:SelectTab(tab) end
        local size=w.Viewport.AbsoluteSize
        w:SetCenter(Vector2.new(state.Window.Position.X*size.X,state.Window.Position.Y*size.Y))
    end)
    w._applyingState=false
    if not ok then return false,"No se pudo aplicar el perfil: "..tostring(issue) end
    if w.Profiles then w.Profiles:Changed() end
    return true
end

return State
