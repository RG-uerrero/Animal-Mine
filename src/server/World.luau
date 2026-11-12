-- src/server/World.luau  (ServerScriptService.Server.World)
-- Construye todo el escenario: suelo, plaza, minas, plataformas, establo, habilidades,
-- teletransporte, renacer y decoracion. No contiene reglas del juego: cuando un jugador
-- usa un boton, llama a los "handlers" que le pasa Main.server.luau.
--
-- ctx.plots    tabla vacia que esta funcion llena con las 4 minas
-- ctx.skp      tabla vacia que se llena con las 8 plataformas de habilidades
-- ctx.ipn      textos de los botones del establo
-- ctx.handlers funciones: deposit (3), roll, inv (6), press, touch, skill, tp, prestige
local P=game:GetService("Players")
local RPS=game:GetService("ReplicatedStorage")
local CollectionService=game:GetService("CollectionService")
local Config=require(RPS.Shared.Config)
local B=require(script.Parent.Builders)
local mk,cyl,label,board,lamp,arbol=B.mk,B.cyl,B.label,B.board,B.lamp,B.arbol
local WOOD,WOODD,STONE,DIRT,ROCKC,RW=B.WOOD,B.WOODD,B.STONE,B.DIRT,B.ROCKC,B.RW
local W=workspace
local V=Vector3.new
local C3=Color3.fromRGB
local BALL=Enum.PartType.Ball
local NSH,FY=Config.NSH,Config.FY
local TIER,SK=Config.TIER,Config.SK

local World={}

function World.build(ctx)
local plots,SKP,IPN,H=ctx.plots,ctx.skp,ctx.ipn,ctx.handlers

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
local dfun=H.deposit
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
rp.Triggered:Connect(function(p) H.roll(p,pl) end)

-- ESTABLO (inventario fisico de gerentes)
local ix0,iz0=cx+20,cz+54
local ibase=cyl("EstabloBase",0.8,11,V(ix0,FY+0.4,iz0),C3(110,90,70),Enum.Material.Wood)
cyl("EstabloAnillo",0.3,9,V(ix0,FY+0.9,iz0),C3(235,185,60),Enum.Material.Metal)
pl.invCF=CFrame.new(ix0,FY+1.05,iz0)
pl.invLbl=label(ibase,"ESTABLO",11.5,360,130,80)
pl.ilbl={}
local ipC={C3(90,130,220),C3(90,130,220),C3(70,190,100),C3(220,150,60),C3(190,100,255),C3(235,185,60)}
local ipA={"Anterior","Siguiente","Equipar / Quitar","Vender copia","Fusionar","Comprar slot"}
local ipF=H.inv
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
pr.Triggered:Connect(function(p) H.press(p,pl,j) end)
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
H.touch(p,j)
end)
end
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
pr.Triggered:Connect(function(p) H.skill(p,k) end)
SKP[k]=pd
pd:SetAttribute("SkillIndex",k)
CollectionService:AddTag(pd,"SkillPad")
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
pr.Triggered:Connect(function(p) H.tp(p,k) end)
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
rpr.Triggered:Connect(H.prestige)

local sp=W:FindFirstChildOfClass("SpawnLocation") or Instance.new("SpawnLocation",W)
sp.Anchored=true
sp.Neutral=true
sp.Size=V(10,1,10)
sp.Position=V(0,1.9,96)
sp.Transparency=1

return CLOUDS
end

return World
