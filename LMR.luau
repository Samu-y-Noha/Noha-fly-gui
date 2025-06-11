--[[ECHO PARA EL CLAN LMR ULTRA v12 by Copilot + Samu-y-Noha]]
local CLAVE = "LMR EL MEJOR CLAN"
local ALARMA_URL = "rbxassetid://9118828563"
local cg = game:GetService("CoreGui")
local pl = game:GetService("Players").LocalPlayer
local sgc = cg:FindFirstChild("CLAVE_LMR_ULTRA") or Instance.new("ScreenGui",cg)
sgc.Name = "CLAVE_LMR_ULTRA"
local bg = Instance.new("Frame",sgc)
bg.Size, bg.Position = UDim2.new(0,400,0,155),UDim2.new(0.5,-200,0.5,-78)
bg.BackgroundColor3, bg.BorderSizePixel = Color3.fromRGB(20,30,50),0
local t1 = Instance.new("TextLabel",bg)
t1.Text = "Introduce la clave para acceder al menú LMR ULTRA"
t1.Font, t1.TextSize, t1.TextColor3 = Enum.Font.GothamBlack,16,Color3.new(1,1,1)
t1.Size, t1.BackgroundTransparency, t1.Position = UDim2.new(1,0,0,36),1,UDim2.new(0,0,0,8)
local tb = Instance.new("TextBox",bg)
tb.Size, tb.Position, tb.PlaceholderText = UDim2.new(0.9,0,0,38),UDim2.new(0.05,0,0,56),"CLAVE DEL CLAN"
tb.Font, tb.TextSize, tb.BackgroundColor3 = Enum.Font.Gotham,16,Color3.fromRGB(30,40,70)
tb.TextColor3, tb.ClearTextOnFocus = Color3.new(1,1,1),true
local go = Instance.new("TextButton",bg)
go.Size, go.Position, go.Text = UDim2.new(0.5,0,0,32),UDim2.new(0.25,0,0,104),"ACCEDER"
go.Font, go.TextSize, go.BackgroundColor3, go.TextColor3 = Enum.Font.GothamBold,16,Color3.fromRGB(0,180,60),Color3.new(1,1,1)
local denied = Instance.new("TextLabel",bg)
denied.Text, denied.Size = "",UDim2.new(1,0,0,24)
denied.Position, denied.TextColor3 = UDim2.new(0,0,0,137),Color3.fromRGB(255,60,60)
denied.Font, denied.TextSize, denied.BackgroundTransparency, denied.Visible = Enum.Font.GothamBold,14,1,false
local function expulsion()
    pl:Kick("Clave incorrecta. ¡Solo el verdadero clan LMR puede entrar!");while true do end
end
local function playNuclearAlarm()
    local a=Instance.new("Sound",game:GetService("SoundService"));a.SoundId=ALARMA_URL;a.Volume=10;a.Looped=false;a:Play()
    spawn(function()wait(5)a:Stop()a:Destroy()end)
end
local function bienvenida()
    local flash=Instance.new("ScreenGui",cg) flash.Name="FlashBienvenidaLMR"
    local fr=Instance.new("Frame",flash) fr.Size=UDim2.new(1,0,1,0) fr.BackgroundColor3=Color3.new(1,1,0) fr.BackgroundTransparency=0.15 fr.ZIndex=2000
    local lbl=Instance.new("TextLabel",flash)
    lbl.Text="BIENVENIDO AL SCRIPT DEL CLAN LMR" lbl.Size=UDim2.new(1,0,0,120) lbl.Position=UDim2.new(0,0,0.45,0)
    lbl.TextColor3=Color3.new(1,1,0) lbl.Font=Enum.Font.GothamBlack lbl.TextSize=52 lbl.BackgroundTransparency=1
    lbl.TextStrokeTransparency=0.15 lbl.TextStrokeColor3=Color3.new(0.7,0.7,0) lbl.ZIndex=2001
    spawn(function()for i=1,18 do lbl.Position=UDim2.new(0,math.random(-8,8),0.45,math.random(-5,5));wait(0.025)end lbl.Position=UDim2.new(0,0,0.45,0)end)
    spawn(function()wait(1.2)for i=0,1,0.1 do fr.BackgroundTransparency=0.15+0.85*i;lbl.TextTransparency=i;lbl.TextStrokeTransparency=0.15+0.85*i;wait(0.04)end flash:Destroy()end)
end
local function launchLMR()
    sgc:Destroy() playNuclearAlarm() bienvenida() wait(1.1)
    local conns,achievements={},{}
    local function connect(ev,f)local c=ev:Connect(f)table.insert(conns,c)return c end
    local function cleanup()for _,c in ipairs(conns)do pcall(function()c:Disconnect()end)end for _,g in ipairs(cg:GetChildren())do if g.Name=="ECHO_CLAN_LMR_ULTRA"then pcall(function()g:Destroy()end)end end end
    pcall(function()if (type(setreadonly)=="function" and type(getrawmetatable)=="function") then local mt=getrawmetatable(game)if mt and not isreadonly(mt)then setreadonly(mt,true)end end end)
    local function notify(txt,t,color)local sg=cg:FindFirstChild("ECHO_CLAN_LMR_ULTRA")if not sg then return end local n=Instance.new("TextLabel",sg) n.Text=txt n.Size=UDim2.new(0.82,0,0,34) n.Position=UDim2.new(0.09,0,0,18) n.BackgroundColor3=color or Color3.fromRGB(30,160,60) n.TextColor3=Color3.new(1,1,1) n.Font=Enum.Font.GothamBold n.TextSize=18 n.BackgroundTransparency=0.15 n.ZIndex=1000 n.BorderSizePixel=0 n.ClipsDescendants=true n.TextWrapped=true spawn(function()wait(t or 1.2)n:Destroy()end)end
    local sg=Instance.new("ScreenGui",cg) sg.Name="ECHO_CLAN_LMR_ULTRA" sg.ZIndexBehavior=Enum.ZIndexBehavior.Global
    local main=Instance.new("Frame",sg) main.BackgroundColor3=Color3.fromRGB(16,22,36) main.Size=UDim2.new(0,402,0,638) main.Position=UDim2.new(0.02,0,0.19,0) main.BorderSizePixel=0 main.AnchorPoint=Vector2.new(0,0) main.Active=true main.Draggable=true main.ClipsDescendants=true
    local title=Instance.new("TextLabel",main)
    title.Text="ECHO PARA EL CLAN LMR ULTRA v12\nMuscle Legends Supreme"
    title.Font=Enum.Font.GothamBlack title.TextSize=22 title.TextColor3=Color3.new(1,1,1) title.Size=UDim2.new(1,0,0,54) title.BackgroundTransparency=1 title.TextWrapped=true
    local function mkbtn(txt,y,c3)local btn=Instance.new("TextButton",main)btn.Size=UDim2.new(1,-32,0,38)btn.Position=UDim2.new(0,16,0,y)btn.BackgroundColor3=c3 or Color3.fromRGB(30,34,60)btn.Text=txt btn.Font=Enum.Font.GothamBold btn.TextColor3=Color3.fromRGB(1,1,1)btn.TextSize=17 btn.BorderSizePixel=0 btn.AutoButtonColor=true btn.TextWrapped=true return btn end
    local Y=60
    local function unlock_ach(name,desc)if not achievements[name]then achievements[name]=true notify("🏅 LOGRO: "..name.." - "..desc,2,Color3.fromRGB(255,215,60))end end
    -- AUTOKILL ULTRA SLIDER/PRO
    local AKWL={ [pl.Name]=true,["Samu-y-Noha"]=true }
    local CLAN={["LMR"]=true,["lmr"]=true,["Lmr"]=true}
    local SETTINGS_KEY = "LMR_AUTOKILL_SETTINGS"
    local function load_settings()if isfile and readfile and isfile(SETTINGS_KEY)then local s,d=pcall(function()return game:GetService("HttpService"):JSONDecode(readfile(SETTINGS_KEY))end)if s and d then return d end end return{mode_move=false,attack_speed=6,auto_fps=false}end
    local function save_settings(d)if writefile then pcall(function()writefile(SETTINGS_KEY,game:GetService("HttpService"):JSONEncode(d))end)end end
    local st=load_settings()
    local akp_on,akp_con,akp_kills=false,nil,0
    local akp_mode_move=st.mode_move or false
    local akp_attack_speed=st.attack_speed or 6
    local akp_max_speed=20
    local akp_auto_fps=st.auto_fps or false
    local function set_config(_m,_s,_a)st.mode_move=_m;st.attack_speed=_s;st.auto_fps=_a;save_settings(st)end
    local function make_slider(parent,label,minv,maxv,val,onch)
        local frame=Instance.new("Frame",parent)
        frame.Size=UDim2.new(1,-32,0,38)frame.Position=UDim2.new(0,16,0,parent.UIListLayout and parent.UIListLayout.AbsoluteContentSize.Y or 0)frame.BackgroundColor3=Color3.fromRGB(40,34,60)frame.Name="Slider_"..label
        local lbl=Instance.new("TextLabel",frame)
        lbl.Size=UDim2.new(0.39,0,1,0)lbl.Position=UDim2.new(0,0,0,0)lbl.BackgroundTransparency=1;lbl.Text=label;lbl.Font=Enum.Font.GothamBold;lbl.TextColor3=Color3.new(1,1,1);lbl.TextSize=15
        local slider_bg=Instance.new("Frame",frame)
        slider_bg.Size=UDim2.new(0.46,0,0.45,0)slider_bg.Position=UDim2.new(0.43,0,0.27,0)slider_bg.BackgroundColor3=Color3.fromRGB(60,60,120)slider_bg.BorderSizePixel=0
        local slider_fill=Instance.new("Frame",slider_bg)
        slider_fill.Size=UDim2.new((val-minv)/(maxv-minv),0,1,0)slider_fill.Position=UDim2.new(0,0,0,0)slider_fill.BackgroundColor3=Color3.fromRGB(200,180,50)slider_fill.BorderSizePixel=0
        local slider_btn=Instance.new("TextButton",slider_bg)
        slider_btn.Size=UDim2.new(0,20,1,0)slider_btn.Position=UDim2.new((val-minv)/(maxv-minv)-0.025,0,0,0)slider_btn.BackgroundColor3=Color3.fromRGB(255,220,90)slider_btn.Text=""slider_btn.AutoButtonColor=false slider_btn.BorderSizePixel=0 slider_btn.Name="SliderBtn"
        local val_lbl=Instance.new("TextLabel",frame)
        val_lbl.Size=UDim2.new(0.12,0,1,0)val_lbl.Position=UDim2.new(0.89,0,0,0)val_lbl.BackgroundTransparency=1 val_lbl.Text=tostring(val)val_lbl.Font=Enum.Font.GothamBold val_lbl.TextColor3=Color3.new(1,1,1)val_lbl.TextSize=15
        local function set_slider(_v)_v=math.clamp(math.floor(_v+0.5),minv,maxv)slider_fill.Size=UDim2.new((_v-minv)/(maxv-minv),0,1,0)slider_btn.Position=UDim2.new((_v-minv)/(maxv-minv)-0.025,0,0,0)val_lbl.Text=tostring(_v)onch(_v)end
        slider_btn.MouseButton1Down:Connect(function()
            local mouse=pl:GetMouse()
            local conn
            conn=mouse.Move:Connect(function()
                local rel=(mouse.X-slider_bg.AbsolutePosition.X)/slider_bg.AbsoluteSize.X
                set_slider(minv+rel*(maxv-minv))
            end)
            local up;up=mouse.Button1Up:Connect(function()if conn then conn:Disconnect()end up:Disconnect()end)
        end)
        return frame, set_slider
    end
    local akp_btn=mkbtn("AutoKill Players: OFF",Y,Color3.fromRGB(255,40,90));Y=Y+34
    local akp_mode_btn=mkbtn("Modo Ataque: "..(akp_mode_move and "Moverse" or "Distancia"),Y,Color3.fromRGB(180,40,100));Y=Y+34
    local akp_auto_btn=mkbtn("Auto FPS/Ping: "..(akp_auto_fps and "ON" or "OFF"),Y,Color3.fromRGB(80,180,220));Y=Y+34
    local slider_frame,set_slider_val=make_slider(main,"Velocidad/s",1,akp_max_speed,akp_attack_speed,function(newval)
        akp_attack_speed=newval;set_config(akp_mode_move,akp_attack_speed,akp_auto_fps)
        notify("Velocidad de ataque: "..akp_attack_speed.." golpes/s",1,Color3.fromRGB(220,160,60))
    end)
    akp_btn.MouseButton1Click:Connect(function()
        akp_on=not akp_on
        akp_btn.Text="AutoKill Players: "..(akp_on and "ON" or "OFF")
        if akp_on then
            akp_kills=0
            local last_attack=tick()
            akp_con=connect(game:GetService("RunService").RenderStepped,function()
                if not akp_on then return end
                if akp_auto_fps then
                    local fps=math.clamp(workspace.GetRealPhysicsFPS and workspace:GetRealPhysicsFPS() or 60,10,240)
                    local ping=0.05
                    pcall(function()
                        local net=game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
                        if net then ping=tonumber(string.match(net:GetValueString(),"%d+%.?%d*"))/1000 end
                    end)
                    local max_auto=math.max(2,math.floor(1/((1/fps)+ping)))
                    akp_attack_speed=math.clamp(akp_attack_speed,1,math.min(max_auto,akp_max_speed))
                    set_slider_val(akp_attack_speed)
                end
                local now=tick()
                if now-last_attack>=(1/akp_attack_speed)then
                    last_attack=now
                    local me=pl
                    local myChar=me.Character
                    if not myChar or not myChar:FindFirstChild("HumanoidRootPart")then return end
                    for _,p in pairs(game.Players:GetPlayers())do
                        if p~=me and p.Character and p.Character:FindFirstChild("HumanoidRootPart")and p.Character:FindFirstChild("Humanoid")then
                            if AKWL[p.Name]then continue end
                            local lname=p.Name:lower()
                            local skip=false
                            for clan in pairs(CLAN)do if lname:find(clan:lower())then skip=true break end end
                            if skip then continue end
                            if p.Character.Humanoid.Health>0 then
                                if akp_mode_move then
                                    local dist=(myChar.HumanoidRootPart.Position-p.Character.HumanoidRootPart.Position).Magnitude
                                    if dist>8 then myChar.HumanoidRootPart.CFrame=p.Character.HumanoidRootPart.CFrame+Vector3.new(0,2,0)end
                                end
                                pcall(function()game:GetService("ReplicatedStorage").Events.liftRemote:FireServer("rep")end)
                                if p.Character.Humanoid.Health==0 then
                                    akp_kills=akp_kills+1
                                    notify("☠️ "..p.Name.." eliminado! ("..akp_kills..")",1,Color3.fromRGB(255,60,120))
                                end
                            end
                        end
                    end
                end
            end)
            unlock_ach("¡Asesino Pro!","AutoKill Players ultra activado.")
        else pcall(function()akp_con:Disconnect()end)notify("AutoKill Players desactivado.",1.2,Color3.fromRGB(255,80,120)) end
    end)
    akp_mode_btn.MouseButton1Click:Connect(function()
        akp_mode_move=not akp_mode_move
        akp_mode_btn.Text="Modo Ataque: "..(akp_mode_move and "Moverse" or "Distancia")
        set_config(akp_mode_move,akp_attack_speed,akp_auto_fps)
        notify("Modo AutoKill: "..(akp_mode_move and "Moverse+Distancia"or"Solo distancia"),1,Color3.fromRGB(220,50,120))
    end)
    akp_auto_btn.MouseButton1Click:Connect(function()
        akp_auto_fps=not akp_auto_fps
        akp_auto_btn.Text="Auto FPS/Ping: "..(akp_auto_fps and "ON"or"OFF")
        set_config(akp_mode_move,akp_attack_speed,akp_auto_fps)
        notify("Auto ajuste velocidad FPS/ping: "..(akp_auto_fps and "ON"or"OFF"),0.9,Color3.fromRGB(130,230,255))
    end)
    -- Puedes añadir más módulos aquí igual de compactos y eficientes
end

go.MouseButton1Click:Connect(function()
    if tb.Text==CLAVE then launchLMR()
    else denied.Visible=true;denied.Text="❌ Clave incorrecta";wait(0.6);denied.Visible=false;tb.Text="";expulsion() end
end)
