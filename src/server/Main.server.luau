print("MAIN ARRANCO")

-- MINA ANIMAL v2: script principal (src/server/Main.server.luau)
-- Datos fijos: src/shared/Config.luau | Formulas: src/shared/Formulas.luau | Guardado: src/server/DataService.luau
local P=game:GetService("Players")
local W=workspace
local L=game:GetService("Lighting")
local TS=game:GetService("TweenService")
local RS=game:GetService("RunService")
local DB=game:GetService("Debris")
local RPS=game:GetService("ReplicatedStorage")
local Config=require(RPS.Shared.Config)
local F=require(RPS.Shared.Formulas)
local DataService=require(script.Parent.DataService)
local BALL=Enum.PartType.Ball
local V=Vector3.new
local C3=Color3.fromRGB
local RW=Random.new(9) -- aleatorio del mundo (siempre igual)
local R=Random.new()   -- aleatorio del juego (rodar gerentes, criticos, cofres)
local NSH,MAXL,FY,DEPMAX=Config.NSH,Config.MAXL,Config.FY,Config.DEPMAX
local SLOT0,SLOTMAX,STARMAX,PRMAX=Config.SLOT0,Config.SLOTMAX,Config.STARMAX,Config.PRMAX

-- ILUMINACION Y ATMOSFERA
for _,o in ipairs(L:GetChildren()) do
if o:IsA("PostEffect") or o:IsA("Atmosphere") then o:Destroy() end
end
L.ClockTime=11
L.Brightness=2.6
L.Ambient=C3(110,110,125)
L.OutdoorAmbient=C3(140,140,155)
L.ShadowSoftness=0.3
local atm=Instance.new("Atmosphere")
atm.Density=0.3
atm.Offset=0.2
atm.Color=C3(190,210,240)
atm.Decay=C3(255,230,190)
atm.Glare=0.3
atm.Haze=1.5
atm.Parent=L
local cc=Instance.new("ColorCorrectionEffect",L)
cc.Saturation=0.2
cc.Contrast=0.08
local bl=Instance.new("BloomEffect",L)
bl.Intensity=0.25
bl.Size=24
bl.Threshold=1.2
local sr=Instance.new("SunRaysEffect",L)
sr.Intensity=0.06
sr.Spread=0.7

local function mk(n,s,pos,c,m,shape)
local p=Instance.new("Part")
p.Name=n
p.Anchored=true
p.Size=s
p.Position=pos
if typeof(c)=="Color3" then p.Color=c else p.BrickColor=BrickColor.new(c) end
p.Material=m or Enum.Material.SmoothPlastic
if shape then p.Shape=shape end
p.Parent=W
return p
end

local function cyl(n,h,d,pos,c,m)
local p=mk(n,V(h,d,d),pos,c,m,Enum.PartType.Cylinder)
p.CFrame=CFrame.new(pos)*CFrame.Angles(0,0,math.rad(90))
return p
end

local function label(part,txt,off,w,h,dist)
local g=Instance.new("BillboardGui")
g.Size=UDim2.new(0,w or 260,0,h or 55)
g.StudsOffset=V(0,off,0)
g.MaxDistance=dist or 70
local t=Instance.new("TextLabel",g)
t.Size=UDim2.new(1,0,1,0)
t.BackgroundTransparency=1
t.TextScaled=true
t.Font=Enum.Font.FredokaOne
t.TextColor3=Color3.new(1,1,1)
t.TextStrokeTransparency=0.2
t.Text=txt
g.Parent=part
return t
end

local function pop(part,txt,col)
local g=Instance.new("BillboardGui")
g.Size=UDim2.new(0,150,0,40)
g.StudsOffset=V(math.random(-2,2),4,0)
g.MaxDistance=70
local t=Instance.new("TextLabel",g)
t.Size=UDim2.new(1,0,1,0)
t.BackgroundTransparency=1
t.TextScaled=true
t.Font=Enum.Font.FredokaOne
t.TextColor3=col or C3(120,255,130)
t.TextStrokeTransparency=0.2
t.Text=txt
g.Parent=part
TS:Create(g,TweenInfo.new(0.9),{StudsOffset=g.StudsOffset+V(0,6,0)}):Play()
DB:AddItem(g,0.9)
end

local fmt=F.fmt

local WOOD=C3(140,95,62)
local WOODD=C3(105,70,46)
local STONE=C3(185,190,205)
local DIRT=C3(122,80,62)
local ROCKC=C3(112,84,66)

local function board(pos,target,txt,w,h)
local b=mk("Cartel",V(w,h,1),pos,WOOD,Enum.Material.Wood)
b.CFrame=CFrame.lookAt(pos,V(target.X,pos.Y,target.Z))
for _,sx in pairs({-1,1}) do
local po=mk("Poste",V(1.5,pos.Y-1,1.5),pos,WOODD,Enum.Material.Wood)
po.CFrame=b.CFrame*CFrame.new(sx*(w/2-1.5),-(pos.Y-1)/2,0)
end
local sg=Instance.new("SurfaceGui")
sg.Face=Enum.NormalId.Front
sg.PixelsPerStud=25
local t=Instance.new("TextLabel",sg)
t.Size=UDim2.new(1,0,1,0)
t.BackgroundTransparency=1
t.TextColor3=C3(255,240,205)
t.TextScaled=true
t.TextWrapped=true
t.Font=Enum.Font.FredokaOne
t.Text=txt
sg.Parent=b
return b
end

local function lamp(x,z)
cyl("Poste",9,0.8,V(x,FY+4.5,z),C3(50,52,58),Enum.Material.Metal)
local b=mk("Lampara",V(2.4,2.4,2.4),V(x,FY+10,z),C3(255,214,140),Enum.Material.Neon,BALL)
local l=Instance.new("PointLight",b)
l.Range=28
l.Brightness=1
l.Color=C3(255,200,120)
end

local function arbol(x,z)
local s=RW:NextNumber(0.8,1.3)
mk("Tronco",V(2.4*s,9*s,2.4*s),V(x,1+4.5*s,z),WOODD,Enum.Material.Wood)
mk("Hojas",V(12*s,11*s,12*s),V(x,1+13*s,z),C3(RW:NextInteger(100,130),RW:NextInteger(185,215),RW:NextInteger(80,100)),Enum.Material.Grass,BALL)
end

-- DATOS (vienen de shared/Config.luau)
local RAR,RARV,TIER,SH,MG,MGBY,SK=Config.RAR,Config.RARV,Config.TIER,Config.SH,Config.MG,Config.MGBY,Config.SK

local plots={}
local S={}
local joined={}
local tok={}
local EV={on=false,left=0}
local FX={}
local IPN={"<",">","EQUIPAR","VENDER","FUSIONAR","SLOT+"}

-- FORMULAS (vienen de shared/Formulas.luau)
local skCost,owned,isEq,mbonus=F.skCost,F.owned,F.isEq,F.mbonus
local mgrBonus,mgrCount,cashMult,prod=F.mgrBonus,F.mgrCount,F.cashMult,F.prod
local capOf,upCost,rollCost,income=F.capOf,F.upCost,F.rollCost,F.income
local depCap,depUpCost,depRate,slotCost,prCost=F.depCap,F.depUpCost,F.depRate,F.slotCost,F.prCost

local function dinero(p)
local s=p:FindFirstChild("leaderstats")
return s and s:FindFirstChild("Dinero")
end

local function tell(p,txt)
local pg=p:FindFirstChild("PlayerGui")
local hud=pg and pg:FindFirstChild("HUD")
local m=hud and hud:FindFirstChild("Msg")
if not m then return end
m.Text=txt
m.Visible=true
tok[p]=(tok[p] or 0)+1
local n=tok[p]
task.delay(5,function()
if tok[p]==n and m.Parent then m.Visible=false end
end)
end
local function tellAll(txt)
for _,p in ipairs(P:GetPlayers()) do tell(p,txt) end
end

-- EFECTOS
function FX.ring(pos,col,maxs,dur)
local r=mk("Onda",V(0.4,2,2),pos,col,Enum.Material.Neon,Enum.PartType.Cylinder)
r.CFrame=CFrame.new(pos)*CFrame.Angles(0,0,math.rad(90))
r.CanCollide=false
r.CastShadow=false
r.Transparency=0.2
TS:Create(r,TweenInfo.new(dur,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=V(0.4,maxs,maxs),Transparency=1}):Play()
DB:AddItem(r,dur+0.2)
end
function FX.burst(pos,col,n)
local a=mk("Chispas",V(1,1,1),pos,col)
a.Transparency=1
a.CanCollide=false
local pe=Instance.new("ParticleEmitter")
pe.Color=ColorSequence.new(col)
pe.Rate=0
pe.Lifetime=NumberRange.new(0.6,1.3)
pe.Speed=NumberRange.new(14,30)
pe.SpreadAngle=Vector2.new(180,180)
pe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.9),NumberSequenceKeypoint.new(1,0)})
pe.LightEmission=1
pe.Acceleration=V(0,-25,0)
pe.Parent=a
pe:Emit(n)
DB:AddItem(a,2)
end
function FX.beam(pos,col,dur)
local b=mk("Rayo",V(90,6,6),pos+V(0,45,0),col,Enum.Material.Neon,Enum.PartType.Cylinder)
b.CFrame=CFrame.new(pos+V(0,45,0))*CFrame.Angles(0,0,math.rad(90))
b.CanCollide=false
b.CastShadow=false
b.Transparency=0.35
TS:Create(b,TweenInfo.new(dur),{Size=V(90,0.5,0.5),Transparency=1}):Play()
DB:AddItem(b,dur+0.2)
end
function FX.shake(p,dur,mag)
local ch=p.Character
local h=ch and ch:FindFirstChildOfClass("Humanoid")
if not h then return end
task.spawn(function()
local t0=os.clock()
while os.clock()-t0<dur do
local k=1-(os.clock()-t0)/dur
h.CameraOffset=V(R:NextNumber(-1,1)*mag*k,R:NextNumber(-1,1)*mag*k,0)
task.wait()
end
h.CameraOffset=V(0,0,0)
end)
end
function FX.coin(p,pos,n)
local ch=p.Character
local hrp=ch and ch:FindFirstChild("HumanoidRootPart")
if not hrp then return end
for k=1,n do
local c=cyl("Moneda",0.25,1.4,pos+V(R:NextNumber(-2,2),R:NextNumber(0,2),R:NextNumber(-2,2)),C3(255,215,60),Enum.Material.Neon)
c.CanCollide=false
c.CastShadow=false
TS:Create(c,TweenInfo.new(0.4+k*0.07,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=hrp.Position+V(0,1,0),Transparency=1}):Play()
DB:AddItem(c,1.2)
end
end
function FX.up(pl,i,lvl,p)
local pos=V(pl.cx-25+(i-1)*10,FY+1,pl.cz-36)
local col=TIER[i]
FX.ring(pos,col,14,0.5)
FX.burst(pos+V(0,5,0),col,16)
pop(pl.v[i].pad,"NIVEL "..lvl,col)
if lvl%10==0 then
FX.beam(pos,col,0.8)
FX.ring(pos,C3(255,255,255),26,0.8)
FX.burst(pos+V(0,6,0),C3(255,230,120),40)
if p then FX.shake(p,0.35,0.5) end
end
end

-- MISIONES
local function newQuest(st)
local k=R:NextInteger(1,3)
local inc=math.max(5,income(st))
local goal
if k==1 then goal=math.max(300,math.floor(inc*100))
elseif k==2 then goal=math.min(5,1+math.floor(st.qn/4))
else goal=5+math.min(25,st.qn*2) end
st.q={k=k,goal=goal,prog=0,rew=math.max(250,math.floor(inc*70))}
end
local function qtext(st)
local q=st.q
if not q then return "" end
local a={"Recoge $"..fmt(q.goal),"Rueda "..q.goal.." gerente(s)","Mejora "..q.goal.." veces"}
return "MISION: "..a[q.k].."\n"..fmt(q.prog).." / "..fmt(q.goal).."   Premio $"..fmt(q.rew)
end
local function qadd(p,kind,n)
local st=S[p]
if not st or not st.q then return end
local k=({earn=1,roll=2,up=3})[kind]
if st.q.k~=k then return end
st.q.prog=st.q.prog+n
if st.q.prog>=st.q.goal then
local rew=st.q.rew
local d=dinero(p)
if d then d.Value=d.Value+rew end
st.qn=st.qn+1
newQuest(st)
tell(p,"MISION COMPLETA! +$"..fmt(rew))
local ch=p.Character
local hrp=ch and ch:FindFirstChild("HumanoidRootPart")
if hrp then FX.burst(hrp.Position,C3(255,225,90),30) end
end
end

-- ANIMALES
local function animal(cf,ca,cb,k,ex)
ex=ex or {}
local nm=ex.name or ""
local m=Instance.new("Model")
local FAB=Enum.Material.Fabric
local NEON=Enum.Material.Neon
local DARK=C3(40,30,35)
local PINK=C3(255,170,190)
local function has(s) return string.find(nm,s)~=nil end
local function pt(n,s,off,col,shape,mat)
local p=Instance.new("Part")
p.Name=n
p.Size=s
p.Anchored=true
p.CanCollide=false
if typeof(col)=="Color3" then p.Color=col else p.BrickColor=BrickColor.new(col) end
p.Material=mat or Enum.Material.SmoothPlastic
if shape then p.Shape=shape end
p.CFrame=cf*CFrame.new(off)
p.Parent=m
return p
end
local body=pt("Body",V(2.8,2.9,2.8),V(0,1.9,0),ca,BALL,FAB)
pt("Panza",V(1.9,1.9,1.1),V(0,1.7,-1.15),cb,BALL,FAB)
pt("Cabeza",V(2.6,2.4,2.4),V(0,4.1,0),ca,BALL,FAB)
pt("BrazoI",V(0.9,1.6,0.9),V(-1.6,2.3,-0.3),ca,BALL,FAB)
pt("BrazoD",V(0.9,1.6,0.9),V(1.6,2.3,-0.3),ca,BALL,FAB)
pt("PieI",V(1.1,0.8,1.5),V(-0.8,0.7,-0.3),cb,BALL,FAB)
pt("PieD",V(1.1,0.8,1.5),V(0.8,0.7,-0.3),cb,BALL,FAB)
if has("Zor") or has("Fox") then
local fox=has("Fox")
pt("Cola",V(1.2,1.2,2.6),V(0,1.9,2.1),ca,BALL,FAB)
pt("PuntaCola",V(1,1,1.1),V(0,1.95,3.2),fox and C3(255,140,30) or "White",BALL,fox and NEON or FAB)
else
pt("Cola",V(0.9,0.9,0.9),V(0,1.5,1.7),cb,BALL,FAB)
end
if k=="long" then
pt("OrejaI",V(0.6,2.2,0.6),V(-0.6,6.3,0),ca,BALL,FAB)
pt("OrejaD",V(0.6,2.2,0.6),V(0.6,6.3,0),ca,BALL,FAB)
pt("OrejaIntI",V(0.3,1.6,0.3),V(-0.6,6.3,-0.22),PINK,BALL)
pt("OrejaIntD",V(0.3,1.6,0.3),V(0.6,6.3,-0.22),PINK,BALL)
elseif k=="round" then
pt("OrejaI",V(1,1,0.6),V(-1.3,5.3,0),ca,BALL,FAB)
pt("OrejaD",V(1,1,0.6),V(1.3,5.3,0),ca,BALL,FAB)
pt("OrejaIntI",V(0.55,0.55,0.3),V(-1.3,5.3,-0.25),cb,BALL,FAB)
pt("OrejaIntD",V(0.55,0.55,0.3),V(1.3,5.3,-0.25),cb,BALL,FAB)
elseif k=="horn" then
pt("CuernoI",V(0.45,1.3,0.45),V(-0.6,6,0),cb,nil,Enum.Material.Marble)
pt("CuernoD",V(0.45,1.3,0.45),V(0.6,6,0),cb,nil,Enum.Material.Marble)
else
pt("OrejaI",V(0.7,1.3,0.7),V(-1,5.8,0),ca,BALL,FAB)
pt("OrejaD",V(0.7,1.3,0.7),V(1,5.8,0),ca,BALL,FAB)
pt("OrejaIntI",V(0.4,0.8,0.4),V(-1,5.75,-0.25),cb,BALL,FAB)
pt("OrejaIntD",V(0.4,0.8,0.4),V(1,5.75,-0.25),cb,BALL,FAB)
end
if has("Panda") or has("Pandita") then
for _,sx in ipairs({-1,1}) do
pt("Mancha",V(0.95,1.1,0.4),V(sx*0.65,4.3,-1),"Black",BALL,FAB)
end
end
if has("Tigre") then
for _,sx in ipairs({-1,1}) do
for j=0,2 do
pt("Raya",V(0.4,0.3,1.4),V(sx*1.3,2.6-j*0.55,0),"Black",BALL,FAB)
end
pt("RayaCara",V(0.25,0.7,0.25),V(sx*0.5,4.95,-0.9),"Black",BALL)
end
pt("RayaCara",V(0.25,0.8,0.25),V(0,5,-0.95),"Black",BALL)
end
if has("Leon") or has("Leo ") then
pt("Melena",V(3.9,3.9,1.8),V(0,4.1,0.7),k=="round" and cb or ca,BALL,FAB)
pt("MelenaB",V(3.2,1.6,2),V(0,3.2,0.5),k=="round" and cb or ca,BALL,FAB)
end
if has("Dragon") or has("Fenix") then
local fen=has("Fenix")
local wc=fen and C3(255,120,30) or C3(170,30,35)
for _,sx in ipairs({-1,1}) do
local w=pt("Ala",V(0.3,2.8,2.2),V(sx*1.7,3.1,1.1),wc,nil,fen and NEON or Enum.Material.SmoothPlastic)
w.Transparency=fen and 0.25 or 0
end
for j=0,2 do
pt("Pua",V(0.5,0.9,0.5),V(0,3.6-j*0.5,1.5+j*0.3),cb,BALL,Enum.Material.Marble)
end
end
if has("Pollito") then
pt("Pico",V(0.7,0.35,0.8),V(0,3.85,-1.6),"Bright orange")
end
if has("Cerdito") then
pt("Trompa",V(1.2,0.9,0.5),V(0,3.85,-1.45),C3(255,150,170),BALL,FAB)
end
if has("Rana") then
for _,sx in ipairs({-1,1}) do
pt("OjoSalon",V(0.9,0.9,0.9),V(sx*0.75,5.1,-0.5),ca,BALL,FAB)
end
end
for _,sx in ipairs({-1,1}) do
pt("OjoBlanco",V(0.75,0.85,0.4),V(sx*0.6,4.35,-1.05),"White",BALL)
pt("Pupila",V(0.45,0.55,0.3),V(sx*0.6,4.33,-1.25),"Black",BALL)
pt("Brillo",V(0.2,0.2,0.2),V(sx*0.5,4.5,-1.38),"White",BALL,NEON)
local mj=pt("Mejilla",V(0.5,0.3,0.2),V(sx*1,3.85,-1),C3(255,150,160),BALL)
mj.Transparency=0.4
end
pt("Hocico",V(1,0.7,0.6),V(0,3.8,-1.25),cb,BALL,FAB)
pt("Nariz",V(0.4,0.3,0.3),V(0,3.98,-1.52),DARK,BALL)
pt("Boca",V(0.5,0.12,0.1),V(0,3.55,-1.5),DARK)
if k=="long" then
pt("Diente",V(0.35,0.4,0.15),V(0,3.42,-1.5),"White")
end
if ex.helmet then
pt("Casco",V(2.9,1.5,2.9),V(0,5,0),"Bright yellow",BALL,Enum.Material.Metal)
pt("CascoBanda",V(3.2,0.25,3.2),V(0,4.55,0),C3(60,60,65),BALL,Enum.Material.Metal)
local foco=pt("Foco",V(0.7,0.7,0.5),V(0,5.2,-1.35),C3(255,240,160),BALL,NEON)
local lg=Instance.new("PointLight")
lg.Range=10
lg.Brightness=0.8
lg.Color=C3(255,235,170)
lg.Parent=foco
end
if ex.tie then
pt("Collar",V(1.4,0.35,0.5),V(0,2.95,-1.3),"White",nil,FAB)
pt("Nudo",V(0.4,0.4,0.3),V(0,2.85,-1.5),"Bright red",nil,FAB)
pt("Corbata",V(0.5,1,0.3),V(0,2.2,-1.5),"Bright red",nil,FAB)
end
if ex.aura then
local au=pt("Aura",V(6,0.15,6),V(0,0.05,0),ex.aura,BALL,NEON)
au.Transparency=0.5
end
m.PrimaryPart=body
m.Parent=W
return m,body
end

-- PICO NUEVO: el mango va en vertical y la cabeza va a lo largo del eje Z
-- (el mismo plano del golpe), asi al balancearlo hacia adelante la punta pega en la roca
local function pickaxe()
local pk=Instance.new("Model")
local function part(n,s,cf2,c,mat)
local p=Instance.new("Part")
p.Name=n
p.Size=s
p.Anchored=true
p.CanCollide=false
p.CastShadow=false
p.Color=c
p.Material=mat
p.CFrame=cf2
p.Parent=pk
return p
end
local hd=part("Mango",V(0.38,3.4,0.38),CFrame.new(0,0,0),WOODD,Enum.Material.Wood)
part("Agarre",V(0.46,0.9,0.46),CFrame.new(0,-1.1,0),C3(60,45,40),Enum.Material.Fabric)
part("Cabeza",V(0.5,0.5,3.0),CFrame.new(0,1.55,0),C3(150,155,170),Enum.Material.Metal)
part("Aro",V(0.7,0.7,0.7),CFrame.new(0,1.55,0),C3(80,82,90),Enum.Material.DiamondPlate)
local tip
for _,s in ipairs({-1,1}) do
local f=part("Filo",V(0.4,0.4,1.0),CFrame.new(0,1.4,s*1.75)*CFrame.Angles(-s*0.6,0,0),C3(215,220,235),Enum.Material.Metal)
if s==-1 then tip=f end
end
local pe=Instance.new("ParticleEmitter")
pe.Rate=0
pe.Color=ColorSequence.new(C3(255,220,120))
pe.Lifetime=NumberRange.new(0.25,0.5)
pe.Speed=NumberRange.new(8,16)
pe.SpreadAngle=Vector2.new(90,90)
pe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.4),NumberSequenceKeypoint.new(1,0)})
pe.LightEmission=1
pe.Acceleration=V(0,-30,0)
pe.Parent=tip
pk.PrimaryPart=hd
pk.Parent=W
return pk,tip
end

-- ACTUALIZAR TEXTOS
local function updShaft(pl,i)
local v=pl.v[i]
local p=pl.owner
local st=p and S[p]
local sh=st and st.sh[i]
if not sh or not sh.h then
v.btnLbl.Text="Minero "..i.."\n"..SH[i].n.."\nContratar $"..fmt(SH[i].h)
v.cartLbl.Text=""
if v.lbl then v.lbl.Text="" end
else
if sh.l>=MAXL then v.btnLbl.Text="Nivel "..sh.l.."\n"..SH[i].n.."\nMAXIMO"
else v.btnLbl.Text="Nivel "..sh.l.."\n"..SH[i].n.."\nMejorar $"..fmt(upCost(i,sh.l)) end
if v.lbl then v.lbl.Text="Nivel "..sh.l.."\n"..SH[i].n end
end
end

local function updRoll(pl)
local p=pl.owner
local st=p and S[p]
pl.rollLbl.TextColor3=Color3.new(1,1,1)
if st then
pl.rollLbl.Text="RODAR GERENTE\n"..(st.ro==0 and "GRATIS" or "$"..fmt(rollCost(st)))
else
pl.rollLbl.Text="RODAR GERENTE"
end
end

local function updDeposit(pl)
local p=pl.owner
local st=p and S[p]
if not st then
pl.depLbl.Text="DEPOSITO"
pl.dlbl[1].Text="DEPOSITAR"
pl.dlbl[2].Text="RETIRAR"
pl.dlbl[3].Text="AMPLIAR"
return
end
pl.depLbl.Text="DEPOSITO (Nv "..st.dl..")\n$"..fmt(st.dep).." / $"..fmt(depCap(st)).."\nInteres "..string.format("%.1f",depRate(st)*100).."% cada 10s"
pl.dlbl[1].Text="DEPOSITAR\nTodo tu dinero"
pl.dlbl[2].Text="RETIRAR\n$"..fmt(st.dep)
if st.dl>=DEPMAX then pl.dlbl[3].Text="AMPLIAR\nMAXIMO"
else pl.dlbl[3].Text="AMPLIAR\n$"..fmt(depUpCost(st)) end
end

-- ESTABLO (inventario de gerentes)
local function updInv(pl)
if pl.invModel then
pl.invModel:Destroy()
pl.invModel=nil
end
local p=pl.owner
local st=p and S[p]
local lb=pl.invLbl
lb.TextColor3=Color3.new(1,1,1)
for k=1,6 do pl.ilbl[k].Text=IPN[k] end
if not st then
lb.Text="ESTABLO"
return
end
local l=owned(st)
if #l==0 then
lb.Text="ESTABLO\nAun no tienes gerentes.\nRueda uno en la plataforma!"
return
end
st.ix=math.clamp(st.ix,1,#l)
local g=l[st.ix]
local c=st.mg[g.n]
local sr2=st.star[g.n] or 0
local eq=isEq(st,g.n)
lb.TextColor3=RAR[g.r].c
lb.Text=g.n.."  ("..st.ix.."/"..#l..")\n"..RAR[g.r].n.."  x"..c.."  "..string.rep("*",sr2).."\n+"..math.floor(mbonus(st,g)*100).."% dinero\n"..(eq and "EQUIPADO" or "en el establo").."   Slots "..#st.eq.."/"..st.slots
pl.ilbl[3].Text=eq and "QUITAR" or "EQUIPAR"
pl.ilbl[4].Text=(c>1) and ("VENDER\n$"..fmt(RARV[g.r]*(1+st.pr))) or "VENDER\n(sin copias)"
pl.ilbl[5].Text=(sr2>=STARMAX) and "FUSION\nMAXIMA" or ((c>=3) and "FUSIONAR\n+1 estrella" or "FUSIONAR\n(3 copias)")
pl.ilbl[6].Text=(st.slots>=SLOTMAX) and "SLOTS\nMAXIMO" or ("SLOT+\n$"..fmt(slotCost(st)))
local m=animal(pl.invCF,g.a,g.c,g.k,{tie=true,name=g.n,aura=(g.r>=3) and RAR[g.r].c or nil})
pl.invModel=m
end

-- MINEROS
local function place(v,yo,lean,rot,a)
local cfm=v.cf*CFrame.new(0,yo,0)*CFrame.Angles(lean,rot,0)
v.model:PivotTo(cfm*CFrame.new(0,1.9,0))
if v.pk then
v.pk:PivotTo(cfm*CFrame.new(1.9,3,-1.4)*CFrame.Angles(a,0,0)*CFrame.new(0,1.1,0))
end
end

local function despawn(pl,i)
local v=pl.v[i]
v.anim=false
if v.model then
v.model:Destroy()
v.model=nil
end
if v.pk then
v.pk:Destroy()
v.pk=nil
end
v.tip=nil
v.tipPE=nil
v.lbl=nil
v.mound.Size=V(4.5,2,3.4)
end

local function spawnMiner(pl,i,anim)
local v=pl.v[i]
if v.model then return end
local x=pl.cx-25+(i-1)*10
local d=SH[i]
local cf=CFrame.new(x,FY,pl.cz-36)
local m,body=animal(cf,d.a,d.c,d.k,{helmet=true,name=d.n})
v.model=m
v.cf=cf
v.ph=0
v.pk,v.tip=pickaxe()
v.tipPE=v.tip:FindFirstChildOfClass("ParticleEmitter")
v.work=true
local bg=Instance.new("BillboardGui")
bg.Adornee=body
bg.Size=UDim2.new(0,200,0,60)
bg.StudsOffset=V(0,6,0)
bg.MaxDistance=60
local t=Instance.new("TextLabel",bg)
t.Size=UDim2.new(1,0,1,0)
t.BackgroundTransparency=1
t.TextScaled=true
t.Font=Enum.Font.FredokaOne
t.TextColor3=Color3.new(1,1,1)
t.TextStrokeTransparency=0.2
bg.Parent=body
v.lbl=t
if not anim then
place(v,0,0,0,0.3)
return
end
-- ANIMACION DE CONTRATACION: cae del cielo girando con un rayo de luz
v.anim=true
place(v,45,0,0,0.3)
local pos=V(x,FY+0.3,pl.cz-36)
FX.beam(pos,TIER[i],1.4)
local nl=label(body,"NUEVO: "..d.n.."!",9,320,60,90)
nl.TextColor3=TIER[i]
DB:AddItem(nl.Parent,2.6)
task.spawn(function()
local t0=os.clock()
while true do
local u=(os.clock()-t0)/0.8
if u>=1 or not v.model then break end
place(v,45*(1-u*u),0,u*4*math.pi,0.3)
task.wait()
end
if not v.model then return end
place(v,0,0,0,0.3)
FX.ring(pos,TIER[i],18,0.6)
task.delay(0.15,function() FX.ring(pos,C3(255,255,255),26,0.8) end)
FX.burst(pos+V(0,4,0),TIER[i],40)
FX.burst(pos+V(0,4,0),C3(255,235,140),25)
if pl.owner then FX.shake(pl.owner,0.4,0.6) end
for k=1,2 do
local hgt=3.5/k
local t1=os.clock()
while true do
local u=(os.clock()-t1)/0.28
if u>=1 then break end
if not v.model then return end
place(v,hgt*math.sin(u*math.pi),0,0,0.3)
task.wait()
end
end
if v.model then place(v,0,0,0,0.3) end
v.anim=false
end)
end

local function collect(p,i,manual)
local st=S[p]
if not st or not st.plot then return 0 end
local sh=st.sh[i]
if not sh.h or sh.o<1 then return 0 end
local amt=math.floor(sh.o*cashMult(st))
sh.o=0
local d=dinero(p)
if d then d.Value=d.Value+amt end
local pad=st.plot.v[i].pad
pop(pad,"+$"..fmt(amt))
if manual then FX.coin(p,pad.Position,5) end
st.coll=true
st.tot=st.tot+amt
qadd(p,"earn",amt)
return amt
end

local function pressBtn(p,pl,i)
if pl.owner~=p then return end
local st=S[p]
local d=dinero(p)
if not st or not d then return end
local sh=st.sh[i]
if not sh.h then
if i>1 and not st.sh[i-1].h then
tell(p,"Primero contrata al minero anterior.")
return
end
local c=SH[i].h
if d.Value<c then
tell(p,"Te faltan $"..fmt(c-d.Value).." para contratar a "..SH[i].n..".")
return
end
d.Value=d.Value-c
sh.h=true
sh.l=1
sh.o=0
spawnMiner(pl,i,true)
tell(p,"Contrataste a "..SH[i].n.."! Ya esta picando.")
else
if sh.l>=MAXL then
tell(p,"Este minero ya esta al maximo.")
return
end
local c=upCost(i,sh.l)
if d.Value<c then
tell(p,"Te faltan $"..fmt(c-d.Value).." para mejorar.")
return
end
d.Value=d.Value-c
sh.l=sh.l+1
tell(p,SH[i].n.." subio al nivel "..sh.l.."!")
FX.up(pl,i,sh.l,p)
qadd(p,"up",1)
end
updShaft(pl,i)
st.ui()
end

-- DEPOSITO
local function depositAll(p,pl)
if pl.owner~=p then return end
local st=S[p]
local d=dinero(p)
if not st or not d then return end
local room=math.floor(depCap(st)-st.dep)
if room<1 then
tell(p,"Tu deposito esta lleno. Ampliarlo te deja guardar mas.")
return
end
local amt=math.min(math.floor(d.Value),room)
if amt<1 then
tell(p,"No tienes dinero para depositar.")
return
end
d.Value=d.Value-amt
st.dep=st.dep+amt
pop(pl.dPad[1],"-$"..fmt(amt),C3(255,200,120))
tell(p,"Depositaste $"..fmt(amt)..". Gana "..string.format("%.1f",depRate(st)*100).."% de interes cada 10 segundos.")
updDeposit(pl)
st.ui()
end

local function withdrawAll(p,pl)
if pl.owner~=p then return end
local st=S[p]
local d=dinero(p)
if not st or not d then return end
local amt=math.floor(st.dep)
if amt<1 then
tell(p,"No tienes dinero en el deposito.")
return
end
st.dep=st.dep-amt
d.Value=d.Value+amt
pop(pl.dPad[2],"+$"..fmt(amt))
FX.coin(p,pl.dPad[2].Position,5)
tell(p,"Retiraste $"..fmt(amt).." del deposito.")
updDeposit(pl)
st.ui()
end

local function upgradeDeposit(p,pl)
if pl.owner~=p then return end
local st=S[p]
local d=dinero(p)
if not st or not d then return end
if st.dl>=DEPMAX then
tell(p,"Tu deposito ya esta al maximo.")
return
end
local c=depUpCost(st)
if d.Value<c then
tell(p,"Te faltan $"..fmt(c-d.Value).." para ampliar el deposito.")
return
end
d.Value=d.Value-c
st.dl=st.dl+1
tell(p,"Deposito nivel "..st.dl.."! Ahora guarda hasta $"..fmt(depCap(st))..".")
FX.ring(pl.dPad[3].Position+V(0,1,0),C3(235,185,60),14,0.6)
updDeposit(pl)
st.ui()
end

-- ACCIONES DEL ESTABLO
local function invSel(st)
local l=owned(st)
if #l==0 then return nil,l end
st.ix=math.clamp(st.ix,1,#l)
return l[st.ix],l
end
local function invNav(d2)
return function(p,pl)
if pl.owner~=p then return end
local st=S[p]
if not st then return end
local g,l=invSel(st)
if not g then
tell(p,"Aun no tienes gerentes. Rueda uno!")
return
end
st.ix=(st.ix-1+d2)%#l+1
updInv(pl)
end
end
local function invEquip(p,pl)
if pl.owner~=p then return end
local st=S[p]
if not st then return end
local g=invSel(st)
if not g then
tell(p,"Aun no tienes gerentes. Rueda uno!")
return
end
if isEq(st,g.n) then
for k,n in ipairs(st.eq) do
if n==g.n then
table.remove(st.eq,k)
break
end
end
tell(p,g.n.." se fue al establo.")
else
if #st.eq>=st.slots then
tell(p,"Todos tus slots estan llenos. Quita uno o compra mas slots.")
return
end
table.insert(st.eq,g.n)
tell(p,g.n.." equipado! +"..math.floor(mbonus(st,g)*100).."% de dinero.")
FX.burst(pl.invCF.Position+V(0,4,0),RAR[g.r].c,20)
end
updInv(pl)
st.ui()
end
local function invSell(p,pl)
if pl.owner~=p then return end
local st=S[p]
local d=dinero(p)
if not st or not d then return end
local g=invSel(st)
if not g then return end
local c=st.mg[g.n]
if c<=1 then
tell(p,"No tienes copias repetidas de "..g.n..".")
return
end
local price=RARV[g.r]*(1+st.pr)
st.mg[g.n]=c-1
d.Value=d.Value+price
FX.coin(p,pl.invCF.Position+V(0,3,0),6)
tell(p,"Vendiste una copia de "..g.n.." por $"..fmt(price)..".")
updInv(pl)
st.ui()
end
local function invFuse(p,pl)
if pl.owner~=p then return end
local st=S[p]
if not st then return end
local g=invSel(st)
if not g then return end
local c=st.mg[g.n]
local sr2=st.star[g.n] or 0
if sr2>=STARMAX then
tell(p,g.n.." ya tiene el maximo de estrellas.")
return
end
if c<3 then
tell(p,"Necesitas 3 copias de "..g.n..": se gastan 2 y ganas 1 estrella.")
return
end
st.mg[g.n]=c-2
st.star[g.n]=sr2+1
FX.ring(pl.invCF.Position+V(0,1,0),C3(190,100,255),16,0.7)
FX.burst(pl.invCF.Position+V(0,5,0),C3(255,230,120),35)
tell(p,g.n.." subio a "..(sr2+1).." estrella(s)! Su bonus crece +50%.")
updInv(pl)
st.ui()
end
local function invSlot(p,pl)
if pl.owner~=p then return end
local st=S[p]
local d=dinero(p)
if not st or not d then return end
if st.slots>=SLOTMAX then
tell(p,"Ya tienes el maximo de slots.")
return
end
local c=slotCost(st)
if d.Value<c then
tell(p,"Te faltan $"..fmt(c-d.Value).." para un slot nuevo.")
return
end
d.Value=d.Value-c
st.slots=st.slots+1
tell(p,"Nuevo slot de gerente! Ahora puedes equipar "..st.slots..".")
FX.ring(pl.invCF.Position+V(0,1,0),C3(235,185,60),14,0.6)
updInv(pl)
st.ui()
end

-- RENACER
local function doPrestige(p)
local st=S[p]
local d=dinero(p)
if not st or not d or not st.plot then return end
if st.pr>=PRMAX then
tell(p,"Ya alcanzaste el maximo de renacimientos!")
return
end
for i=1,NSH do
if not st.sh[i].h then
tell(p,"Para renacer necesitas a los 6 mineros contratados.")
return
end
end
local c=prCost(st)
if d.Value<c then
tell(p,"Para renacer necesitas $"..fmt(c)..". Te faltan $"..fmt(c-d.Value)..".")
return
end
local pl=st.plot
for i=1,NSH do
despawn(pl,i)
st.sh[i]={h=false,l=0,o=0}
updShaft(pl,i)
end
st.pr=st.pr+1
st.dep=0
st.tmr=0
d.Value=30
local rb=p:FindFirstChild("leaderstats") and p.leaderstats:FindFirstChild("Renacer")
if rb then rb.Value=st.pr end
newQuest(st)
local ch=p.Character
local hrp=ch and ch:FindFirstChild("HumanoidRootPart")
if hrp then
FX.beam(hrp.Position,C3(255,215,80),1.2)
FX.ring(hrp.Position,C3(255,255,255),30,1)
FX.burst(hrp.Position,C3(255,215,80),60)
end
FX.shake(p,0.6,0.8)
tellAll(p.Name.." renacio! Renacer "..st.pr.." (+"..(st.pr*50).."% de dinero para siempre)")
updDeposit(pl)
updRoll(pl)
st.ui()
end

-- GERENTES
local function pickMgr(st)
local s=st.sk.suerte or 0
local ws={}
local tot=0
for i,r in ipairs(RAR) do
ws[i]=r.w*(1+0.25*s*(i-1))
tot=tot+ws[i]
end
local x=R:NextNumber(0,tot)
local rid=1
for i=1,#ws do
x=x-ws[i]
if x<=0 then
rid=i
break
end
end
local list={}
for _,g in ipairs(MG) do
if g.r==rid then table.insert(list,g) end
end
return list[R:NextInteger(1,#list)]
end

local function doRoll(p,pl)
if pl.owner~=p or pl.rolling then return end
local st=S[p]
local d=dinero(p)
if not st or not d then return end
local c=rollCost(st)
if d.Value<c then
tell(p,"Te faltan $"..fmt(c-d.Value).." para rodar un gerente.")
return
end
pl.rolling=true
d.Value=d.Value-c
st.ro=st.ro+1
local g=pickMgr(st)
st.mg[g.n]=(st.mg[g.n] or 0)+1
pl.q.Enabled=false
-- efecto tragaperras en el pedestal
for k=1,16 do
local rg=MG[R:NextInteger(1,#MG)]
pl.rollLbl.Text=rg.n
pl.rollLbl.TextColor3=RAR[rg.r].c
task.wait(0.04+k*0.008)
end
if pl.owner~=p then
pl.rolling=false
pl.q.Enabled=true
return
end
local pos=V(pl.cx+18,FY+1,pl.cz+36)
local rc=RAR[g.r].c
FX.ring(pos,rc,16,0.7)
FX.burst(pos+V(0,5,0),rc,20+g.r*8)
if g.r>=4 then
FX.beam(pos,rc,1.2)
FX.shake(p,0.4,0.2*g.r)
end
local cf=CFrame.new(pl.cx+18,FY+2.1,pl.cz+36)*CFrame.Angles(0,math.pi,0)
local m,body=animal(cf,g.a,g.c,g.k,{tie=true,name=g.n,aura=(g.r>=3) and rc or nil})
if g.r>=4 then
local pe=Instance.new("ParticleEmitter")
pe.Color=ColorSequence.new(rc)
pe.Rate=18
pe.Lifetime=NumberRange.new(1,2)
pe.Speed=NumberRange.new(2,4)
pe.Size=NumberSequence.new(0.5)
pe.LightEmission=1
pe.Parent=body
end
local lb=label(body,g.n.."\n"..RAR[g.r].n,6,260,80,80)
lb.TextColor3=rc
if #st.eq<st.slots and not isEq(st,g.n) then
table.insert(st.eq,g.n)
tell(p,"Nuevo gerente "..RAR[g.r].n..": "..g.n.."! Equipado: +"..math.floor(g.b*100).."% de dinero.")
else
tell(p,"Nuevo gerente "..RAR[g.r].n..": "..g.n.."! Equipalo en el Establo.")
end
if g.r>=5 then tellAll(p.Name.." consiguio a "..g.n.." ("..RAR[g.r].n..")!") end
qadd(p,"roll",1)
local l=owned(st)
for k,x in ipairs(l) do
if x.n==g.n then st.ix=k end
end
updRoll(pl)
updInv(pl)
st.ui()
task.delay(4,function()
m:Destroy()
pl.q.Enabled=true
pl.rolling=false
end)
end

local function applySpeed(p)
local ch=p.Character
local h=ch and ch:FindFirstChildOfClass("Humanoid")
local st=S[p]
if h and st then h.WalkSpeed=16+2*(st.sk.botas or 0) end
end

local function refreshSkills(p)
local st=S[p]
if not st or not st.sl then return end
for k,sk in ipairs(SK) do
local lv=st.sk[sk.id] or 0
local t=st.sl[k]
if t then
if lv>=sk.max then t.Text=sk.name.."\nNIVEL MAXIMO"
else t.Text=sk.name.."\n"..sk.desc.."\nNv "..lv.."/"..sk.max.."  $"..fmt(skCost(sk,lv)) end
end
end
end

local SKP={}
local function buySkill(p,k)
local st=S[p]
local d=dinero(p)
if not st or not d then return end
local sk=SK[k]
local lv=st.sk[sk.id] or 0
if lv>=sk.max then
tell(p,sk.name.." ya esta al maximo!")
return
end
local c=skCost(sk,lv)
if d.Value<c then
tell(p,"Te faltan $"..fmt(c-d.Value).." para "..sk.name..".")
return
end
d.Value=d.Value-c
st.sk[sk.id]=lv+1
tell(p,sk.name.." nivel "..(lv+1).."! "..sk.desc)
FX.ring(SKP[k].Position+V(0,1,0),sk.col,14,0.6)
FX.burst(SKP[k].Position+V(0,4,0),sk.col,18)
applySpeed(p)
refreshSkills(p)
st.ui()
end

local function tp(p,where)
local st=S[p]
local ch=p.Character
if not ch then return end
local pl=st and st.plot
local pos
if where==1 then pos=V(0,5,100)
elseif where==2 and pl then pos=V(pl.cx,5,pl.cz+30)
elseif where==3 and pl then pos=V(pl.cx,5,pl.cz-20)
elseif where==4 and pl then pos=V(pl.cx+20,5,pl.cz+44)
elseif where==5 then pos=V(70,5,130)
else
tell(p,"No tienes mina asignada.")
return
end
ch:PivotTo(CFrame.new(pos))
end

-- MUNDO
mk("Suelo",V(640,1,420),V(0,0.5,40),C3(105,205,85),Enum.Material.Grass)
for x=-300,300,60 do
local s=RW:NextInteger(30,55)
mk("Colina",V(90,s,70),V(x,s/3,-130),C3(RW:NextInteger(85,110),RW:NextInteger(170,195),RW:NextInteger(70,90)),Enum.Material.Grass,BALL)
end
mk("Plaza",V(420,0.3,60),V(0,1.25,100),STONE,Enum.Material.Cobblestone)
board(V(0,16,138),V(0,16,100),"MINA ANIMAL\nContrata mineros, junta dinero y rueda gerentes!",56,14)
for _,x in pairs({-150,-75,0,150,225}) do lamp(x,118) end
for _,x in pairs({-250,-200,-150,-100,-50,50,100,150,200,250}) do arbol(x,160) end
for _,x in pairs({-100,0,100,-200,200}) do arbol(x,-20) end
for _,x in pairs({-290,290}) do
for z=0,120,40 do arbol(x,z) end
end

-- flores
local FLC={C3(255,120,170),C3(255,225,90),C3(245,245,250),C3(180,120,255),C3(255,150,80)}
for _=1,70 do
mk("Flor",V(1,1,1),V(RW:NextNumber(-300,300),1.5,RW:NextNumber(142,240)),FLC[RW:NextInteger(1,#FLC)],Enum.Material.SmoothPlastic,BALL)
end

-- nubes
local CLOUDS={}
for k=1,8 do
local m=Instance.new("Model")
local function puff(s,off)
local p=Instance.new("Part")
p.Shape=BALL
p.Size=s
p.Anchored=true
p.CanCollide=false
p.CastShadow=false
p.Material=Enum.Material.SmoothPlastic
p.Color=Color3.new(1,1,1)
p.Transparency=0.15
p.Position=off
p.Parent=m
return p
end
local main=puff(V(30,14,22),V(0,0,0))
puff(V(20,11,16),V(-16,-2,3))
puff(V(22,10,16),V(15,-3,-2))
m.PrimaryPart=main
m.Parent=W
CLOUDS[k]={m=m,x=RW:NextNumber(-420,420),y=RW:NextNumber(110,150),z=RW:NextNumber(-120,220),sp=RW:NextNumber(1.5,4)}
end

-- fuente de la plaza
cyl("FuenteBase",1.4,22,V(120,FY+0.7,112),STONE,Enum.Material.Concrete)
cyl("FuenteAgua",0.5,18,V(120,FY+1.45,112),C3(90,170,255),Enum.Material.Glass).Transparency=0.35
cyl("FuentePilar",5,2.4,V(120,FY+3.5,112),STONE,Enum.Material.Concrete)
local spout=mk("Chorro",V(1,1,1),V(120,FY+6.2,112),Color3.new(1,1,1))
spout.Transparency=1
spout.CanCollide=false
local wpe=Instance.new("ParticleEmitter")
wpe.Rate=80
wpe.Lifetime=NumberRange.new(1.4,1.8)
wpe.Speed=NumberRange.new(22,28)
wpe.SpreadAngle=Vector2.new(8,8)
wpe.Acceleration=V(0,-40,0)
wpe.Size=NumberSequence.new(0.6)
wpe.Transparency=NumberSequence.new(0.3)
wpe.Color=ColorSequence.new(C3(170,220,255))
wpe.LightEmission=0.3
wpe.Parent=spout
local wl=Instance.new("PointLight",spout)
wl.Color=C3(120,190,255)
wl.Range=24
wl.Brightness=0.8

for i=1,4 do
local cx=(i-1)*100-150
local cz=0
local pl={i=i,cx=cx,cz=cz,v={}}
plots[i]=pl
mk("MinaSuelo",V(70,0.4,58),V(cx,1.2,cz-18),DIRT,Enum.Material.Ground)
mk("MuroFondo",V(70,24,4),V(cx,FY+12,cz-48),ROCKC,Enum.Material.Slate)
mk("MuroLado",V(4,12,58),V(cx-35,FY+6,cz-18),ROCKC,Enum.Material.Slate)
mk("MuroLado",V(4,12,58),V(cx+35,FY+6,cz-18),ROCKC,Enum.Material.Slate)
for _,zz in pairs({-9.2,-6.8}) do
mk("Riel",V(70,0.4,0.6),V(cx,FY+0.5,cz+zz),C3(205,210,225),Enum.Material.Metal)
end
for tx=-34,34,4 do
mk("Durmiente",V(0.8,0.3,5),V(cx+tx,FY+0.15,cz-8),WOODD,Enum.Material.Wood)
end
mk("Plataforma",V(70,0.4,46),V(cx,1.2,cz+34),STONE,Enum.Material.Concrete)
mk("Camino",V(14,0.2,34),V(cx,1.3,cz+73),STONE,Enum.Material.Concrete)
local dep=mk("Deposito",V(22,12,14),V(cx-20,FY+6,cz+46),C3(130,140,170),Enum.Material.Concrete)
mk("DepositoPuerta",V(8,8,0.5),V(cx-20,FY+4,cz+38.8),C3(60,65,85),Enum.Material.Metal)
pl.depLbl=label(dep,"DEPOSITO",11,300,110,80)

pl.dPad={}
pl.dlbl={}
local dcol={C3(70,190,100),C3(220,80,80),C3(235,185,60)}
local dact={"Depositar todo","Retirar todo","Ampliar"}
local dfun={depositAll,withdrawAll,upgradeDeposit}
for k=1,3 do
local pd=cyl("DepPad",0.6,6,V(cx-28+(k-1)*8,FY+0.3,cz+33),dcol[k],Enum.Material.Metal)
pl.dPad[k]=pd
pl.dlbl[k]=label(pd,"",4,200,70,50)
local dp=Instance.new("ProximityPrompt")
dp.ActionText=dact[k]
dp.ObjectText="Deposito"
dp.HoldDuration=0.2
dp.MaxActivationDistance=10
dp.RequiresLineOfSight=false
dp.Parent=pd
local fn=dfun[k]
dp.Triggered:Connect(function(p) fn(p,pl) end)
end
updDeposit(pl)

local cart=mk("CartelMina",V(26,5,1),V(cx,FY+16,cz-45.5),WOOD,Enum.Material.Wood)
pl.nameLbl=label(cart,"MINA LIBRE",0,420,90,150)

-- plataforma de rodar gerentes
local rx,rz=cx+18,cz+36
cyl("RodarBase",0.6,16,V(rx,FY+0.3,rz),C3(160,165,185),Enum.Material.Concrete)
cyl("RodarAnillo",0.4,9,V(rx,FY+0.8,rz),C3(210,60,60),Enum.Material.Metal)
local ped=cyl("Pedestal",1.5,6,V(rx,FY+1.35,rz),C3(235,185,60),Enum.Material.Metal)
pl.rollLbl=label(ped,"RODAR GERENTE",6,300,80,70)
local qg=Instance.new("BillboardGui")
qg.Size=UDim2.new(0,70,0,70)
qg.StudsOffset=V(0,3.2,0)
qg.MaxDistance=60
local qt=Instance.new("TextLabel",qg)
qt.Size=UDim2.new(1,0,1,0)
qt.BackgroundTransparency=1
qt.TextScaled=true
qt.Font=Enum.Font.FredokaOne
qt.TextColor3=C3(20,20,25)
qt.TextStrokeColor3=Color3.new(1,1,1)
qt.TextStrokeTransparency=0
qt.Text="?"
qg.Parent=ped
pl.q=qg
local rp=Instance.new("ProximityPrompt")
rp.ActionText="Rodar"
rp.ObjectText="Gerente"
rp.HoldDuration=0.2
rp.MaxActivationDistance=12
rp.RequiresLineOfSight=false
rp.Parent=ped
rp.Triggered:Connect(function(p) doRoll(p,pl) end)

-- ESTABLO (inventario fisico de gerentes)
local ix0,iz0=cx+20,cz+54
local ibase=cyl("EstabloBase",0.8,11,V(ix0,FY+0.4,iz0),C3(110,90,70),Enum.Material.Wood)
cyl("EstabloAnillo",0.3,9,V(ix0,FY+0.9,iz0),C3(235,185,60),Enum.Material.Metal)
pl.invCF=CFrame.new(ix0,FY+1.05,iz0)
pl.invLbl=label(ibase,"ESTABLO",11.5,360,130,80)
pl.ilbl={}
local ipC={C3(90,130,220),C3(90,130,220),C3(70,190,100),C3(220,150,60),C3(190,100,255),C3(235,185,60)}
local ipA={"Anterior","Siguiente","Equipar / Quitar","Vender copia","Fusionar","Comprar slot"}
local ipF={invNav(-1),invNav(1),invEquip,invSell,invFuse,invSlot}
for k=1,6 do
local pd=cyl("EstPad",0.6,4.4,V(cx+7.5+(k-1)*5,FY+0.3,cz+48),ipC[k],Enum.Material.Metal)
pl.ilbl[k]=label(pd,IPN[k],2.8,170,60,45)
local ip=Instance.new("ProximityPrompt")
ip.ActionText=ipA[k]
ip.ObjectText="Establo"
ip.HoldDuration=(k<=2) and 0 or 0.15
ip.MaxActivationDistance=4
ip.RequiresLineOfSight=false
ip.Parent=pd
local fn=ipF[k]
ip.Triggered:Connect(function(p) fn(p,pl) end)
end
updInv(pl)

-- tuneles de mineros
for j=1,NSH do
local x=cx-25+(j-1)*10
local v={}
pl.v[j]=v
mk("Poste",V(2,12,2),V(x-4,FY+6,cz-44),WOODD,Enum.Material.Wood)
mk("Poste",V(2,12,2),V(x+4,FY+6,cz-44),WOODD,Enum.Material.Wood)
mk("Viga",V(10,2,2.4),V(x,FY+12.5,cz-44),WOOD,Enum.Material.Wood)
mk("Roca",V(9,9,7),V(x,FY+4.2,cz-46),ROCKC,Enum.Material.Slate,BALL)
mk("Roca",V(5,5,5),V(x-2.5,FY+2.2,cz-42),C3(125,92,70),Enum.Material.Slate,BALL)
mk("Roca",V(4,4,4),V(x+2.7,FY+1.8,cz-41.5),C3(100,75,60),Enum.Material.Slate,BALL)
mk("Oro",V(1.6,1.6,1.6),V(x+1,FY+5,cz-42.8),C3(235,190,70),Enum.Material.Metal,BALL)
mk("Entrada",V(9,0.1,10),V(x,FY+0.05,cz-37),C3(196,165,125),Enum.Material.Sand)
-- cristales brillantes del color del minero
for kk=1,4 do
local sx=(kk%2==0) and 1 or -1
local cr=mk("Cristal",V(0.9,RW:NextNumber(2,3.6),0.9),V(x+sx*(3.4+RW:NextNumber(0,0.8)),FY+1.8,cz-40.5-RW:NextNumber(0,1.5)),TIER[j],Enum.Material.Neon)
cr.CFrame=CFrame.new(cr.Position)*CFrame.Angles(RW:NextNumber(-0.4,0.4),RW:NextNumber(0,3),RW:NextNumber(-0.4,0.4))
cr.Transparency=0.15
cr.CanCollide=false
if kk==1 then
local cl=Instance.new("PointLight",cr)
cl.Color=TIER[j]
cl.Range=14
cl.Brightness=0.7
end
end
cyl("BotonBase",0.5,7,V(x,FY+0.25,cz-27),C3(60,60,70),Enum.Material.Metal)
local btn=cyl("Boton",0.7,5.5,V(x,FY+0.6,cz-27),C3(225,55,55),Enum.Material.Metal)
v.btnLbl=label(btn,"",4,240,80,60)
local pr=Instance.new("ProximityPrompt")
pr.ActionText="Contratar / Mejorar"
pr.ObjectText="Minero "..j
pr.HoldDuration=0.2
pr.MaxActivationDistance=10
pr.RequiresLineOfSight=false
pr.Parent=btn
pr.Triggered:Connect(function(p) pressBtn(p,pl,j) end)
mk("Vagoneta",V(6,2.4,4.4),V(x,FY+1.7,cz-8),C3(150,100,60),Enum.Material.Wood)
v.mound=mk("Mineral",V(4.5,2,3.4),V(x,FY+3.1,cz-8),TIER[j],Enum.Material.Glass,BALL)
local pad=mk("Recoger",V(8,3,7),V(x,FY+2,cz-8),Color3.new(1,1,1))
pad.Transparency=1
pad.CanCollide=false
v.pad=pad
v.cartLbl=label(pad,"",3,200,50,50)
local deb=0
pad.Touched:Connect(function(h)
local p=P:GetPlayerFromCharacter(h.Parent)
if not p or p~=pl.owner then return end
if os.clock()-deb<0.5 then return end
deb=os.clock()
local a=collect(p,j,true)
if a>0 then
local st=S[p]
if st then st.ui() end
end
end)
updShaft(pl,j)
end
updRoll(pl)
end

-- HABILIDADES (plaza este)
local hx,hz=70,106
local hub=cyl("HabHub",0.8,12,V(hx,FY+0.4,hz),C3(70,75,130),Enum.Material.Metal)
label(hub,"HABILIDADES",5,300,60,80)
for k,sk in ipairs(SK) do
local a=math.rad((k-1)*45)
local pos=V(hx+18*math.cos(a),FY+0.4,hz+18*math.sin(a))
local pd=cyl("HabPad",0.8,9,pos,sk.col,Enum.Material.Metal)
local pr=Instance.new("ProximityPrompt")
pr.ActionText="Mejorar"
pr.ObjectText=sk.name
pr.HoldDuration=0.2
pr.MaxActivationDistance=7
pr.RequiresLineOfSight=false
pr.Parent=pd
pr.Triggered:Connect(function(p) buySkill(p,k) end)
SKP[k]=pd
end

-- TELETRANSPORTE (plaza oeste)
local TPN={"Aparicion","Mi base","Mi mina","Establo","Habilidades"}
local tpart
for k=1,#TPN do
local pd=cyl("TpPad",0.8,8,V(-80+(k-1)*18,FY+0.4,106),C3(150,60,210),Enum.Material.Metal)
label(pd,TPN[k],4,240,50,60)
local pr=Instance.new("ProximityPrompt")
pr.ActionText="Teletransportar"
pr.ObjectText=TPN[k]
pr.HoldDuration=0.2
pr.MaxActivationDistance=7
pr.RequiresLineOfSight=false
pr.Parent=pd
pr.Triggered:Connect(function(p) tp(p,k) end)
if k==3 then tpart=pd end
end
label(tpart,"TELETRANSPORTE",9,300,50,80)

-- RENACER (plaza este)
local rpd=cyl("RenacerPad",1,12,V(180,FY+0.5,106),C3(255,200,60),Enum.Material.Neon)
cyl("RenacerAnillo",0.4,16,V(180,FY+0.2,106),C3(255,255,255),Enum.Material.Neon)
label(rpd,"RENACER\nReinicia mineros y dinero\n+50% de dinero PARA SIEMPRE\n(necesitas los 6 mineros)",8,380,120,80)
local rpr=Instance.new("ProximityPrompt")
rpr.ActionText="Renacer (mantener)"
rpr.ObjectText="Reinicia tu progreso"
rpr.HoldDuration=2
rpr.MaxActivationDistance=10
rpr.RequiresLineOfSight=false
rpr.Parent=rpd
rpr.Triggered:Connect(doPrestige)

local sp=W:FindFirstChildOfClass("SpawnLocation") or Instance.new("SpawnLocation",W)
sp.Anchored=true
sp.Neutral=true
sp.Size=V(10,1,10)
sp.Position=V(0,1.9,96)
sp.Transparency=1

-- COFRES DEL TESORO Y EVENTOS
local chestM
local function spawnChest()
if chestM and chestM.Parent then return end
local pos=V(R:NextNumber(-190,190),FY,R:NextNumber(78,125))
local m=Instance.new("Model")
m.Name="Cofre"
local function pc(n,s,off,c,mat)
local p=Instance.new("Part")
p.Name=n
p.Size=s
p.Anchored=true
p.Color=c
p.Material=mat
p.CFrame=CFrame.new(pos+off)
p.Parent=m
return p
end
local base=pc("Base",V(4,2.4,3),V(0,1.2,0),C3(150,95,50),Enum.Material.Wood)
pc("Tapa",V(4.2,1.2,3.2),V(0,3,0),C3(170,110,55),Enum.Material.Wood)
pc("Cerradura",V(0.8,1,0.4),V(0,2.4,-1.6),C3(255,215,60),Enum.Material.Neon)
pc("Banda",V(4.3,0.4,3.3),V(0,2.2,0),C3(255,200,60),Enum.Material.Metal)
local gl=Instance.new("PointLight",base)
gl.Color=C3(255,215,90)
gl.Range=22
gl.Brightness=1.5
label(base,"COFRE DEL TESORO",6,300,50,120)
local pe=Instance.new("ParticleEmitter")
pe.Rate=10
pe.Lifetime=NumberRange.new(1,2)
pe.Speed=NumberRange.new(3,6)
pe.SpreadAngle=Vector2.new(40,40)
pe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.6),NumberSequenceKeypoint.new(1,0)})
pe.Color=ColorSequence.new(C3(255,225,100))
pe.LightEmission=1
pe.Parent=base
local pr=Instance.new("ProximityPrompt")
pr.ActionText="Abrir cofre"
pr.ObjectText="Tesoro"
pr.HoldDuration=0.8
pr.MaxActivationDistance=10
pr.RequiresLineOfSight=false
pr.Parent=base
pr.Triggered:Connect(function(p)
local st=S[p]
local d=dinero(p)
if not st or not d or m.Parent==nil then return end
local amt=math.floor(math.max(500,income(st)*45))
d.Value=d.Value+amt
FX.beam(pos,C3(255,215,80),1)
FX.ring(pos+V(0,1,0),C3(255,215,80),20,0.7)
FX.burst(pos+V(0,3,0),C3(255,225,100),50)
FX.coin(p,pos+V(0,3,0),8)
tellAll(p.Name.." abrio el cofre del tesoro y gano $"..fmt(amt).."!")
m:Destroy()
end)
m.Parent=W
chestM=m
DB:AddItem(m,70)
tellAll("Aparecio un COFRE DEL TESORO en la plaza! Corre por el!")
end

local function evStart()
EV.on=true
F.state.eventOn=true
EV.left=60
cc.TintColor=C3(255,235,170)
tellAll("HORA DORADA! Todo el dinero x2 durante 60 segundos!")
end
local function evEnd()
EV.on=false
F.state.eventOn=false
cc.TintColor=C3(255,255,255)
tellAll("La hora dorada termino.")
end

-- GUARDADO (la logica de lectura/escritura vive en DataService.luau)
local function save(p)
local st=S[p]
local d=dinero(p)
if not st or not st.loaded or not d then return end
local sh={}
for i=1,NSH do sh[i]={h=st.sh[i].h,l=st.sh[i].l} end
DataService.save(p.UserId,{c=d.Value,sh=sh,sk=st.sk,mg=st.mg,eq=st.eq,star=st.star,slots=st.slots,ro=st.ro,coll=st.coll,dep=math.floor(st.dep),dl=st.dl,pr=st.pr,q=st.q,qn=st.qn,tot=st.tot,ts=os.time()})
end

local function tutorial(st)
local n=0
for i=1,NSH do
if st.sh[i].h then n=n+1 end
end
if n==0 then return "Ve al boton rojo de tu mina y contrata a tu primer minero." end
if not st.coll then return "Corre sobre la vagoneta para recoger el mineral y ganar dinero." end
if st.ro==0 then return "Ve a la plataforma de gerentes y presiona Rodar para conseguir tu primer gerente." end
local t=0
for _,x in pairs(st.sk) do t=t+x end
if t==0 then return "Visita Habilidades en la plaza y mejora tu primera habilidad." end
if n<NSH then return "Contrata mas mineros y mejoralos con los botones rojos." end
if st.pr==0 then return "Cuando tengas dinero de sobra ve a RENACER en la plaza para un bono permanente." end
return "Mejora todo al maximo y consigue gerentes miticos!"
end

local function setup(p)
if p:FindFirstChild("leaderstats") then return end
local f=Instance.new("Folder")
f.Name="leaderstats"
local d=Instance.new("NumberValue")
d.Name="Dinero"
d.Value=30
d.Parent=f
local rb=Instance.new("IntValue")
rb.Name="Renacer"
rb.Value=0
rb.Parent=f
f.Parent=p
local st={sh={},sk={},mg={},eq={},star={},ro=0,tmr=0,itmr=0,dep=0,dl=0,coll=false,sl={},ui=function() end,pr=0,slots=SLOT0,ix=1,tot=0,qn=0}
for i=1,NSH do st.sh[i]={h=false,l=0,o=0} end
S[p]=st
for _,q in ipairs(plots) do
if not q.owner then
q.owner=p
st.plot=q
q.nameLbl.Text="Mina de "..p.Name
break
end
end
local pl=st.plot
-- CARGA SEGURA: si no se pudo leer la partida, no se juega de verdad ni se guarda encima
local ok,data=DataService.load(p.UserId)
if not ok then
if RS:IsStudio() then
warn("DataStore no disponible: juegas SIN guardar. Publica el lugar y activa el acceso a servicios de API en Studio.")
else
p:Kick("No se pudo cargar tu progreso. Vuelve a entrar en un momento.")
return
end
end
if type(data)~="table" then data=nil end
if data then
d.Value=data.c or 30
st.ro=data.ro or 0
st.sk=data.sk or {}
st.mg=data.mg or {}
st.star=data.star or {}
st.coll=data.coll or false
st.dep=data.dep or 0
st.dl=math.clamp(data.dl or 0,0,DEPMAX)
st.pr=math.clamp(data.pr or 0,0,PRMAX)
st.slots=math.clamp(data.slots or SLOT0,SLOT0,SLOTMAX)
st.tot=data.tot or 0
st.qn=data.qn or 0
if type(data.q)=="table" and data.q.k and data.q.goal and data.q.prog and data.q.rew then st.q=data.q end
if data.sh then
for i=1,NSH do
local s=data.sh[i]
if s and s.h then st.sh[i]={h=true,l=math.max(1,s.l or 1),o=0} end
end
end
if type(data.eq)=="table" then
for _,n in ipairs(data.eq) do
if MGBY[n] and (st.mg[n] or 0)>0 and not isEq(st,n) and #st.eq<st.slots then table.insert(st.eq,n) end
end
else
-- partida vieja: equipa automaticamente a los mejores gerentes
local l=owned(st)
table.sort(l,function(a,b) return a.b>b.b end)
for k=1,math.min(#l,st.slots) do table.insert(st.eq,l[k].n) end
end
end
rb.Value=st.pr
if not st.q then newQuest(st) end
st.loaded=ok
if pl then
for i=1,NSH do
if st.sh[i].h then spawnMiner(pl,i,false) end
updShaft(pl,i)
end
updRoll(pl)
updDeposit(pl)
updInv(pl)
end
local pg=p:WaitForChild("PlayerGui")
local old=pg:FindFirstChild("HUD")
if old then old:Destroy() end
local g=Instance.new("ScreenGui")
g.Name="HUD"
g.ResetOnSpawn=false
local function box(name,pos,size,bg,tc)
local t=Instance.new("TextLabel")
t.Name=name
t.Position=pos
t.Size=size
t.BackgroundColor3=bg
t.BackgroundTransparency=0.2
t.TextColor3=tc
t.TextScaled=true
t.TextWrapped=true
t.Font=Enum.Font.FredokaOne
Instance.new("UICorner",t).CornerRadius=UDim.new(0,12)
local us=Instance.new("UIStroke",t)
us.Color=Color3.new(1,1,1)
us.Transparency=0.75
us.Thickness=1.5
t.Parent=g
return t
end
local cash=box("Cash",UDim2.new(0,12,0,90),UDim2.new(0,220,0,44),C3(30,90,50),C3(190,255,190))
local stat=box("Stat",UDim2.new(0,12,0,138),UDim2.new(0,220,0,30),C3(28,32,44),C3(255,225,120))
local qst=box("Quest",UDim2.new(0,12,0,174),UDim2.new(0,220,0,74),C3(28,32,44),C3(190,230,255))
local evb=box("Evento",UDim2.new(0.5,-200,0,8),UDim2.new(0,400,0,34),C3(150,100,0),C3(255,240,160))
evb.Visible=false
local tut=box("Tut",UDim2.new(0.5,-300,0,70),UDim2.new(0,600,0,40),C3(0,0,0),Color3.new(1,1,1))
tut.BackgroundTransparency=1
local ts=tut:FindFirstChildOfClass("UIStroke")
ts.Color=C3(10,40,110)
ts.Transparency=0
ts.Thickness=2.5
local mgl=box("Ger",UDim2.new(1,-215,0,70),UDim2.new(0,200,0,215),C3(24,30,50),Color3.new(1,1,1))
mgl.TextScaled=false
mgl.TextSize=15
mgl.TextXAlignment=Enum.TextXAlignment.Left
mgl.TextYAlignment=Enum.TextYAlignment.Top
local msg=box("Msg",UDim2.new(0.5,-280,1,-190),UDim2.new(0,560,0,70),C3(24,26,38),Color3.new(1,1,1))
msg.Visible=false
for k,_ in ipairs(SK) do
local bg=Instance.new("BillboardGui")
bg.Adornee=SKP[k]
bg.Size=UDim2.new(0,260,0,100)
bg.StudsOffset=V(0,5.5,0)
bg.MaxDistance=45
local t=Instance.new("TextLabel",bg)
t.Size=UDim2.new(1,0,1,0)
t.BackgroundTransparency=1
t.TextScaled=true
t.Font=Enum.Font.FredokaOne
t.TextColor3=Color3.new(1,1,1)
t.TextStrokeTransparency=0.2
bg.Parent=g
st.sl[k]=t
end
st.ui=function()
cash.Text="$ "..fmt(d.Value)
stat.Text="+"..fmt(income(st)).."/s   x"..string.format("%.2f",cashMult(st))
qst.Text=qtext(st)
tut.Text=tutorial(st)
evb.Visible=EV.on
if EV.on then evb.Text="HORA DORADA x2   "..EV.left.."s" end
local lines={"EQUIPADOS ("..#st.eq.."/"..st.slots..")"}
for _,n in ipairs(st.eq) do
table.insert(lines,n.." "..string.rep("*",st.star[n] or 0))
end
table.insert(lines,"")
table.insert(lines,"Gerentes: "..mgrCount(st).."   Renacer: "..st.pr)
mgl.Text=table.concat(lines,"\n")
end
d.Changed:Connect(function() st.ui() end)
refreshSkills(p)
g.Parent=pg
st.ui()
if not pl then
tell(p,"El servidor esta lleno (4 minas). Intenta en otro servidor.")
elseif data and data.ts then
local off=math.clamp(os.time()-data.ts,0,7200)
if off>=60 then
local gain=math.floor(income(st)*off*0.25)
if gain>0 then
d.Value=d.Value+gain
tell(p,"Bienvenido de vuelta! Tus mineros ganaron $"..fmt(gain).." mientras no estabas.")
end
end
end
end

local function onChar(p,ch)
ch:WaitForChild("HumanoidRootPart")
ch:WaitForChild("Humanoid")
task.wait(0.3)
local st=S[p]
if st and st.plot then ch:PivotTo(CFrame.new(st.plot.cx,FY+3,st.plot.cz+30)) end
applySpeed(p)
end

local function join(p)
if joined[p] then return end
joined[p]=true
setup(p)
p.CharacterAdded:Connect(function(ch) onChar(p,ch) end)
if p.Character then task.spawn(onChar,p,p.Character) end
end
P.PlayerAdded:Connect(join)
for _,p in ipairs(P:GetPlayers()) do task.spawn(join,p) end

P.PlayerRemoving:Connect(function(p)
save(p)
local st=S[p]
local pl=st and st.plot
S[p]=nil
joined[p]=nil
tok[p]=nil
if pl then
for i=1,NSH do despawn(pl,i) end
pl.owner=nil
pl.rolling=false
pl.q.Enabled=true
pl.nameLbl.Text="MINA LIBRE"
for i=1,NSH do updShaft(pl,i) end
updRoll(pl)
updDeposit(pl)
updInv(pl)
end
end)

-- al cerrar el servidor se guarda a todos en paralelo
game:BindToClose(function()
local pending=0
for _,p in ipairs(P:GetPlayers()) do
pending+=1
task.spawn(function()
save(p)
pending-=1
end)
end
while pending>0 do task.wait() end
end)

-- ANIMACION: picar de verdad (el pico se levanta y golpea la roca), nubes y establo
RS.Heartbeat:Connect(function(dt)
local t=os.clock()
for _,pl in ipairs(plots) do
for i=1,NSH do
local v=pl.v[i]
if v.model and v.cf and not v.anim then
local s=0
local a=0.35
local lean=0
if v.work then
local ph=(t*1.5+i*0.37)%1
if ph<0.28 then
s=(ph/0.28)^2
else
s=1-(ph-0.28)/0.72
end
local prev=v.ph or 0
v.ph=ph
a=0.8-2.0*s
lean=-0.1*s
if prev<0.28 and ph>=0.28 then
if v.tipPE then v.tipPE:Emit(6) end
local p=pl.owner
local st=p and S[p]
if st and st.sh[i].h and R:NextNumber()<0.03+0.02*(st.sk.crit or 0) then
local sh=st.sh[i]
sh.o=math.min(capOf(st,i),sh.o+prod(st,i)*5)
pop(v.pad,"CRITICO!",C3(255,90,90))
end
end
end
place(v,0,lean,0,a)
end
end
if pl.invModel and pl.invModel.PrimaryPart then
pl.invModel:PivotTo(pl.invCF*CFrame.Angles(0,t*0.8,0)*CFrame.new(0,1.9,0))
end
end
for _,c in ipairs(CLOUDS) do
c.x=c.x+c.sp*dt
if c.x>440 then c.x=-440 end
c.m:PivotTo(CFrame.new(c.x,c.y,c.z))
end
end)

-- Produccion, interes del deposito y recogida automatica de gerentes
task.spawn(function()
while true do
task.wait(0.5)
for _,pl in ipairs(plots) do
local p=pl.owner
local st=p and S[p]
if st then
for i=1,NSH do
local sh=st.sh[i]
local v=pl.v[i]
if sh.h then
local c=capOf(st,i)
sh.o=math.min(c,sh.o+prod(st,i)*0.5)
v.work=sh.o<c
local s=0.3+1.0*(sh.o/c)
v.mound.Size=V(4.5*s,2*s+0.2,3.4*s)
v.cartLbl.Text=fmt(sh.o).." / "..fmt(c)
end
end
st.tmr=st.tmr+0.5
if #st.eq>0 and st.tmr>=math.max(2,12-2*(st.sk.gv or 0)) then
st.tmr=0
for i=1,NSH do collect(p,i,false) end
end
st.itmr=st.itmr+0.5
if st.itmr>=10 then
st.itmr=0
if st.dep>0 then
st.dep=math.min(depCap(st),st.dep*(1+depRate(st)))
end
end
updDeposit(pl)
st.ui()
end
end
end
end)

-- Reloj del mundo: dia y noche, hora dorada y cofres
task.spawn(function()
local t=0
while true do
task.wait(1)
t=t+1
L.ClockTime=(L.ClockTime+0.03)%24
if EV.on then
EV.left=EV.left-1
if EV.left<=0 then evEnd() end
elseif t%300==120 then
evStart()
end
if t%100==50 then spawnChest() end
end
end)

task.spawn(function()
while true do
task.wait(60)
for _,p in ipairs(P:GetPlayers()) do task.spawn(save,p) end
end
end)
