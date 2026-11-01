do
    test("scaled inspector wraps descriptions at the native pixel boundary without clipping",function()
        local group,owner=section()
        local c=group:AddInput({Name="Registro de navegación",Description="Puedes desplazarte, seleccionar y copiar este texto.",ReadOnly=true})
        owner:SetPreference("TextScale",1.3);owner:FinishEntrance();owner:FinishPages();c:Focus();settle()
        owner.Context:Fit();settle()
        assert(owner.DetailDescription.TextFits,"inspector clipped a description at 130 percent")
        assert(owner.Context.Hint.AbsolutePosition.Y>=owner.DetailRows[4].AbsolutePosition.Y+owner.DetailRows[4].AbsoluteSize.Y,"hint overlaps properties")
    end)
    test("settings profile actions save and restore a named profile with localized feedback", function()
        local files, reject = {}, false
        local store = {
            Exists=function(path)return files[path]~=nil end,
            MakeFolder=function(path)files[path]=true end,
            Read=function(path)return files[path]end,
            Write=function(path,text)if reject then error("disk unavailable")end;files[path]=text end,
        }
        local owner=Lumi:CreateWindow({Config={Key="product-ui",Storage=store}})
        table.insert(windows,owner)
        local value=owner:AddTab("Inicio",{Id="inicio"}):AddSection("Interacción"):AddSlider({Id="ganancia",Name="Intensidad",Min=0,Max=100,Default=25})
        owner:Ready();owner:OpenSettings();owner:FinishEntrance();owner:FinishPages();settle()
        local function get(id)local c=owner:GetControl(id);assert(c,"missing settings control "..id);return c end
        get("lumi.profile-name"):Set("Mi espacio",true)
        get("lumi.profile-save"):Press()
        eventually(function()return owner:GetActiveProfile()=="Mi espacio"end,"profile button did not save")
        for _,h in ipairs(owner.Notifications.Items) do
            if h.Kind=="Success" then equal(h.Action,nil,"successful save still offers Retry") end
        end
        value:Set(70,true)
        owner:SetLanguage("pt")
        get("lumi.profile-select"):Set("Mi espacio",true)
        get("lumi.profile-load"):Press()
        eventually(function()return value:Get()==25 end,"profile button did not restore values")
        equal(owner:GetLanguage(),"es","profile did not restore saved language")
        local state=owner:GetState()
        assert(state.Controls["lumi.profile-name"]==nil and state.Controls["lumi.profile-select"]==nil,"profile editor persisted itself")
        local before=files[owner.Profiles.Path]
        reject=true;get("lumi.profile-name"):Set("Otro",true);get("lumi.profile-save"):Press();settle()
        equal(files[owner.Profiles.Path],before,"failed save replaced a valid profile")
        equal(owner:GetActiveProfile(),"Mi espacio","failed save published its name")
        local errorToast
        for _,h in ipairs(owner.Notifications.Items)do if h.Kind=="Error"then errorToast=h end end
        assert(errorToast,"save failure has no user feedback")
        owner:SetLanguage("pt");settle()
        equal(errorToast.TitleLabel.Text,"Não foi possível salvar","save error stayed Spanish")
    end)

    test("destroyed controls detach their window cleanup hooks during repeated replacement",function()
        local group,owner=section()
        local before=#owner.Runtime.Cleanups
        for index=1,100 do
            local c=group:AddButton({Id="temporary",Name="Temporal",Callback=function()error("dead callback")end})
            c:Destroy()
        end
        equal(#owner.Runtime.Cleanups,before,"destroyed controls retained parent cleanup closures")
    end)

    test("a failed initial profile write can be retried after storage recovery",function()
        local files,corrupt={},true
        local owner=Lumi:CreateWindow({Config={Key="initial-write",Storage={
            Exists=function(path)return files[path]~=nil end,
            Read=function(path)return files[path]end,
            MakeFolder=function(path)files[path]=true end,
            Write=function(path,text)files[path]=corrupt and "{" or text end,
        }}})
        table.insert(windows,owner)
        owner:AddTab("Inicio"):AddSection("General"):AddToggle({Id="activo",Name="Activo",Default=true})
        owner:Ready();settle()
        local ok=owner:SaveProfile("Trabajo")
        equal(ok,false,"corrupt initial write was accepted")
        corrupt=false
        local problem;ok,problem=owner:SaveProfile("Trabajo")
        assert(ok,problem)
        equal(owner:GetActiveProfile(),"Trabajo","retry did not activate the saved profile")
        assert(game:GetService("HttpService"):JSONDecode(files[owner.Profiles.Path]).Profiles.Trabajo,"retry has no valid file")
    end)

    test("notification actions are reachable and run once through native keyboard input",function()
        local _,owner=section()
        local calls=0
        local h=owner:Notify({Title="Listo",Message="Cambios guardados.",Duration=0,Action={Text="Continuar",Callback=function()calls+=1 end}})
        eventually(function()return h.Visible end,"toast never appeared")
        assert(owner.Keyboard:Focus(h.ActionButton),"toast action is absent from keyboard navigation")
        local vim=game:GetService("VirtualInputManager")
        vim:SendKeyEvent(true,Enum.KeyCode.Return,false,game);task.wait(.03)
        vim:SendKeyEvent(false,Enum.KeyCode.Return,false,game);settle()
        equal(calls,1,"keyboard toast action did not run exactly once")
        equal(h.Dismissed,true,"keyboard action did not dismiss toast")
    end)

    test("closing after a failed pending save keeps the editable window available for retry",function()
        local files,reject={},false
        local owner=Lumi:CreateWindow({Config={Key="close-failure",AutoSave=true,Storage={
            Exists=function(path)return files[path]~=nil end,Read=function(path)return files[path]end,
            MakeFolder=function(path)files[path]=true end,
            Write=function(path,text)if reject then error("unavailable")end;files[path]=text end,
        }}})
        table.insert(windows,owner)
        local c=owner:AddTab("Inicio"):AddSection("General"):AddToggle({Id="activo",Name="Activo"})
        owner:Ready();owner:SaveProfile("Trabajo");reject=true;c:Set(true)
        owner:Close();settle()
        assert(not owner._destroyed and not owner._closing and owner.Root.Parent,"failed close destroyed unsaved state")
        equal(c:Get(),true,"failed close discarded live data")
        reject=false;owner:SetPreference("Animations",false);owner:Close();settle()
        equal(owner.Root.Parent,nil,"successful retry did not close")
        equal(game:GetService("HttpService"):JSONDecode(files[owner.Profiles.Path]).Profiles.Trabajo.Controls.activo.Value,true,"close did not flush")
    end)
end
