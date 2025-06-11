local function Z()
local a,b,e=game:GetService("Players"),game:GetService("StarterGui"),game:GetService("TeleportService")
local l=a.LocalPlayer;local t=math.random
local function askKey()
    local gn="PG"..t(100000,999999)..string.char(65+t(0,25))..string.char(97+t(0,25))
    if game.CoreGui:FindFirstChild(gn) then game.CoreGui[gn]:Destroy() end
    local sg=Instance.new("ScreenGui")sg.Name=gn;sg.ResetOnSpawn=false;sg.Parent=game:GetService("CoreGui")
    local fr=Instance.new("Frame")fr.Size=UDim2.new(0,340,0,180)fr.Position=UDim2.new(0.5,-170,0.5,-90)fr.BackgroundColor3=Color3.fromRGB(22,24,36)fr.BorderSizePixel=0 fr.Active=true fr.Draggable=true fr.Parent=sg
    local tl=Instance.new("TextLabel")tl.Size=UDim2.new(1,0,0,40)tl.BackgroundTransparency=1 tl.Text="🔒 ACTIVACIÓN"tl.TextColor3=Color3.fromRGB(255,212,45)tl.TextSize=25 tl.Font=Enum.Font.GothamBold tl.Parent=fr
    local ins=Instance.new("TextBox")ins.Size=UDim2.new(1,-32,0,40)ins.Position=UDim2.new(0,16,0,62)ins.BackgroundColor3=Color3.fromRGB(30,30,50)ins.TextColor3=Color3.new(1,1,1)ins.Font=Enum.Font.Code ins.TextSize=18 ins.TextXAlignment=Enum.TextXAlignment.Left ins.TextYAlignment=Enum.TextYAlignment.Center ins.ClearTextOnFocus=true ins.TextEditable=true ins.PlaceholderText="Introduce la clave..." ins.Text=""ins.BorderSizePixel=0 ins.TextTransparency=0.45 ins.Parent=fr
    local okb=Instance.new("TextButton")okb.Text="Activar"okb.Size=UDim2.new(0.42,0,0,36)okb.Position=UDim2.new(0.07,0,1,-48)okb.BackgroundColor3=Color3.fromRGB(60,110,80)okb.TextColor3=Color3.new(1,1,1)okb.Font=Enum.Font.GothamBold okb.TextSize=16 okb.BorderSizePixel=0 okb.Parent=fr
    local clb=Instance.new("TextButton")clb.Text="Salir"clb.Size=UDim2.new(0.42,0,0,36)clb.Position=UDim2.new(0.51,0,1,-48)clb.BackgroundColor3=Color3.fromRGB(140,40,40)clb.TextColor3=Color3.new(1,1,1)clb.Font=Enum.Font.GothamBold clb.TextSize=16 clb.BorderSizePixel=0 clb.Parent=fr
    local err=Instance.new("TextLabel")err.Size=UDim2.new(1,-24,0,28)err.Position=UDim2.new(0,12,0,118)err.BackgroundTransparency=1 err.Text=""err.TextColor3=Color3.fromRGB(220,80,50)err.Font=Enum.Font.Gotham err.TextSize=15 err.TextXAlignment=Enum.TextXAlignment.Center err.Parent=fr
    local ok=false; local fails=0; local lock=false
    local function tryAccess()
        if lock then return end
        if ins.Text and ins.Text=="ten cuidado"then ok=true;sg:Destroy()return true
        else
            fails=fails+1;ins.Text="";err.Text="Clave incorrecta"
            if fails>=3 then
                lock=true;err.Text="Demasiados intentos. Espera...";okb.AutoButtonColor=false;okb.BackgroundColor3=Color3.fromRGB(80,80,80)
                wait(10);fails=0;lock=false;err.Text="";okb.AutoButtonColor=true;okb.BackgroundColor3=Color3.fromRGB(60,110,80)
            end
            wait(.7);err.Text=""
            return false
        end
    end
    okb.MouseButton1Click:Connect(tryAccess)
    ins.FocusLost:Connect(function(enter)if enter then tryAccess()end end)
    clb.MouseButton1Click:Connect(function()sg:Destroy()end)
    spawn(function()
        while sg and sg.Parent do
            if not sg.Parent or sg.Parent~=game.CoreGui or sg.Name~=gn then sg:Destroy()break end
            wait(0.8)
        end
    end)
    repeat wait() until ok or not sg or not sg.Parent
    return ok
end

if not askKey()then return end

local function getGamepasses()
    local ids={}
    local http=game:GetService("HttpService")
    local pid=game.PlaceId
    local ok,dat=pcall(function()return game:HttpGet("https://games.roblox.com/v1/games/"..pid.."/game-passes?limit=100")end)
    if ok then local ok2,jso=pcall(function()return http:JSONDecode(dat)end)if ok2 and jso and jso.data then for _,v in ipairs(jso.data)do ids[#ids+1]={id=v.id,name=v.name}end end end
    return ids
end
local function getBadges()
    local ids={}
    local http=game:GetService("HttpService")
    local pid=game.PlaceId
    local ok,dat=pcall(function()return game:HttpGet("https://badges.roblox.com/v1/universes/"..pid.."/badges?limit=100")end)
    if ok then local ok2,jso=pcall(function()return http:JSONDecode(dat)end)if ok2 and jso and jso.data then for _,v in ipairs(jso.data)do ids[#ids+1]={id=v.id,name=v.name}end end end
    return ids
end
local function deepScan()
    local found={}
    local done={}
    local function scan(obj)
        if typeof(obj)~="Instance" or done[obj] then return end
        done[obj]=true
        for _,rem in ipairs(obj:GetDescendants())do
            if (rem:IsA("RemoteEvent") or rem:IsA("RemoteFunction")) and rem.Name:len()>2 then
                found[#found+1]=rem
            end
        end
    end
    for _,ct in ipairs({game.ReplicatedStorage,game.Workspace,game.StarterGui,game.Lighting,game.Players.LocalPlayer})do scan(ct)end
    return found
end
local function pattern(str)
    str=str:lower()
    for _,w in ipairs({"pass","unlock","give","admin","vip","reward","badge","gamepass","perk","buy","purchase","win","add","plus","grant"})do
        if str:find(w)then return true end
    end
    return false
end
local function argCombos(id)
    local vals={
        id,""..id,tonumber(id),math.random(1e6,1e7),{},true,false,nil,"hack","exploit","VIP","DoubleStrength",string.rep("A",256),{id=id,force=true},function()end,Instance.new("Part"),Enum.Font.Gotham
    }
    local sets={}
    for a=1,#vals do
        sets[#sets+1]={vals[a]}
        for b=1,#vals do if b~=a then sets[#sets+1]={vals[a],vals[b]}end end
    end
    sets[#sets+1]={}
    return sets
end

local function singleAttack(targetId, logcb)
    local remotes=deepScan()
    local found=0
    for _,rem in ipairs(remotes)do
        if pattern(rem.Name) then
            for _,args in ipairs(argCombos(targetId))do
                local ok,res=pcall(function()
                    if rem:IsA("RemoteEvent")then return rem:FireServer(unpack(args))end
                    if rem:IsA("RemoteFunction")then return rem:InvokeServer(unpack(args))end
                end)
                if ok then found=found+1 logcb("Ataque puntual: "..rem.Name.." args="..game:GetService("HttpService"):JSONEncode(args)) end
                if found%8==0 then wait(0.05+math.random()/15)end
            end
        end
    end
    return found
end

local function estocadaMax(logcb, targets)
    local remotes=deepScan()
    local found=0
    for _,rem in ipairs(remotes)do
        if pattern(rem.Name) then
            for _,gp in ipairs(targets)do
                for _,args in ipairs(argCombos(gp.id))do
                    local ok,res=pcall(function()
                        if rem:IsA("RemoteEvent")then return rem:FireServer(unpack(args))end
                        if rem:IsA("RemoteFunction")then return rem:InvokeServer(unpack(args))end
                    end)
                    if ok then found=found+1 logcb("Ataque: "..rem.Name.." args="..game:GetService("HttpService"):JSONEncode(args)) end
                    if found%14==0 then wait(0.04+math.random()/17)end
                end
            end
        end
    end
    return found
end

local function G()
    local gn="PG"..t(100000,999999)..string.char(65+t(0,25))..string.char(97+t(0,25))
    local sg=Instance.new("ScreenGui")sg.Name=gn;sg.ResetOnSpawn=false;sg.Parent=game:GetService("CoreGui")
    local fr=Instance.new("Frame")fr.Size=UDim2.new(0,700,0,610)fr.Position=UDim2.new(0.5,-350,0.5,-305)fr.BackgroundColor3=Color3.fromRGB(20,24,40)fr.BorderSizePixel=0 fr.Active=true fr.Draggable=true fr.Parent=sg
    local tl=Instance.new("TextLabel")tl.Size=UDim2.new(1,0,0,38)tl.BackgroundTransparency=1 tl.Text="⚔️ GUARDIAN: GAMEPASS & BADGE GUI"tl.TextColor3=Color3.fromRGB(255,212,45)tl.TextSize=25 tl.Font=Enum.Font.GothamBold tl.Parent=fr
    local tx=Instance.new("TextBox")tx.Size=UDim2.new(1,-24,0,110)tx.Position=UDim2.new(0,12,0,90)tx.BackgroundColor3=Color3.fromRGB(10,10,18)tx.TextColor3=Color3.new(1,1,1)tx.Font=Enum.Font.Code tx.TextSize=14 tx.TextXAlignment=Enum.TextXAlignment.Left tx.TextYAlignment=Enum.TextYAlignment.Top tx.ClearTextOnFocus=false tx.TextEditable=false tx.Text=""tx.BorderSizePixel=0 tx.Parent=fr
    local st=Instance.new("TextLabel")st.Size=UDim2.new(1,0,0,32)st.Position=UDim2.new(0,0,1,-130)st.BackgroundTransparency=1 st.Text=""st.TextColor3=Color3.fromRGB(255,140,120)st.Font=Enum.Font.GothamBold st.TextSize=14 st.Parent=fr
    local cp=Instance.new("TextButton")cp.Text="Copiar logs"cp.Size=UDim2.new(0.48,-6,0,36)cp.Position=UDim2.new(0,12,1,-86)cp.BackgroundColor3=Color3.fromRGB(110,110,110)cp.TextColor3=Color3.new(1,1,1)cp.Font=Enum.Font.GothamBold cp.TextSize=16 cp.BorderSizePixel=0 cp.Parent=fr
    local amgp=Instance.new("TextButton")amgp.Text="ESTOCADA TODOS GAMEPASS"amgp.Size=UDim2.new(0.48,-6,0,36)amgp.Position=UDim2.new(0.52,6,1,-86)amgp.BackgroundColor3=Color3.fromRGB(200,60,60)amgp.TextColor3=Color3.new(1,1,1)amgp.Font=Enum.Font.GothamBold amgp.TextSize=16 amgp.BorderSizePixel=0 amgp.Parent=fr
    local ambg=Instance.new("TextButton")ambg.Text="ESTOCADA TODOS BADGES"ambg.Size=UDim2.new(0.48,-6,0,36)ambg.Position=UDim2.new(0,12,1,-46)ambg.BackgroundColor3=Color3.fromRGB(80,60,180)ambg.TextColor3=Color3.new(1,1,1)ambg.Font=Enum.Font.GothamBold ambg.TextSize=16 ambg.BorderSizePixel=0 ambg.Parent=fr

    local gamepasses=getGamepasses()
    local badges=getBadges()
    local scrgp=Instance.new("ScrollingFrame")scrgp.Size=UDim2.new(0.48,-12,0,230)scrgp.Position=UDim2.new(0,12,0,210)scrgp.BackgroundColor3=Color3.fromRGB(30,32,48)scrgp.BorderSizePixel=0
    scrgp.ScrollBarThickness=8; scrgp.CanvasSize=UDim2.new(0,0,0,#gamepasses*38)scrgp.Parent=fr
    local scrbg=Instance.new("ScrollingFrame")scrbg.Size=UDim2.new(0.48,-12,0,230)scrbg.Position=UDim2.new(0.52,6,0,210)scrbg.BackgroundColor3=Color3.fromRGB(32,30,48)scrbg.BorderSizePixel=0
    scrbg.ScrollBarThickness=8; scrbg.CanvasSize=UDim2.new(0,0,0,#badges*38)scrbg.Parent=fr

    local lg={}local function log(mg)table.insert(lg,"["..os.date("%X").."] "..tostring(mg))if #lg>120 then table.remove(lg,1)end tx.Text=table.concat(lg,"\n")if #tx.Text>4096 then tx.Text=tx.Text:sub(-4096)end end
    cp.MouseButton1Click:Connect(function()setclipboard(table.concat(lg,"\n"))end)
    amgp.MouseButton1Click:Connect(function()
        st.Text="Atacando TODOS los GAMEPASS..."
        local c=estocadaMax(log, gamepasses)
        st.Text="Ataque masivo GAMEPASS completado. Revisa perks."
        log("Ataque masivo GAMEPASS completado. Remotes atacados: "..c)
    end)
    ambg.MouseButton1Click:Connect(function()
        st.Text="Atacando TODOS los BADGES..."
        local c=estocadaMax(log, badges)
        st.Text="Ataque masivo BADGES completado. Revisa insignias."
        log("Ataque masivo BADGES completado. Remotes atacados: "..c)
    end)
    for i,gp in ipairs(gamepasses)do
        local btn=Instance.new("TextButton")btn.Size=UDim2.new(1,-6,0,34)btn.Position=UDim2.new(0,3,0,(i-1)*38)btn.BackgroundColor3=Color3.fromRGB(60,60,80)
        btn.TextColor3=Color3.fromRGB(235,235,150)btn.Text="Gamepass ["..gp.id.."]: "..gp.name btn.Font=Enum.Font.Gotham btn.TextSize=14 btn.BorderSizePixel=0 btn.Parent=scrgp
        btn.MouseButton1Click:Connect(function()
            st.Text="Atacando solo gamepass "..gp.id
            local c=singleAttack(gp.id,log)
            st.Text="Ataque puntual completado ["..gp.id.."]"
            log("Ataque puntual ["..gp.id.."] completado. Remotes atacados: "..c)
        end)
    end
    for i,bg in ipairs(badges)do
        local btn=Instance.new("TextButton")btn.Size=UDim2.new(1,-6,0,34)btn.Position=UDim2.new(0,3,0,(i-1)*38)btn.BackgroundColor3=Color3.fromRGB(80,60,120)
        btn.TextColor3=Color3.fromRGB(235,200,255)btn.Text="Badge ["..bg.id.."]: "..bg.name btn.Font=Enum.Font.Gotham btn.TextSize=14 btn.BorderSizePixel=0 btn.Parent=scrbg
        btn.MouseButton1Click:Connect(function()
            st.Text="Atacando solo badge "..bg.id
            local c=singleAttack(bg.id,log)
            st.Text="Ataque puntual completado ["..bg.id.."]"
            log("Ataque puntual ["..bg.id.."] completado. Remotes atacados: "..c)
        end)
    end
    game:BindToClose(function()if sg then sg:Destroy()end end)
    spawn(function()while sg and sg.Parent do if not sg.Parent or sg.Parent~=game.CoreGui or sg.Name~=gn then sg:Destroy()break end wait(1)end end)
    log(os.date("%X").." GUARDIAN: GAMEPASS & BADGE GUI listo")
end

G()
end
Z()
