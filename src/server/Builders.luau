-- src/server/Builders.luau  (ServerScriptService.Server.Builders)
-- Funciones para crear partes, carteles y decoracion.
-- Las usan Main.server.luau y World.luau.
local TS=game:GetService("TweenService")
local DB=game:GetService("Debris")
local RPS=game:GetService("ReplicatedStorage")
local Config=require(RPS.Shared.Config)
local W=workspace
local V=Vector3.new
local C3=Color3.fromRGB
local BALL=Enum.PartType.Ball
local FY=Config.FY
local RW=Random.new(9) -- aleatorio del mundo (siempre igual)

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

return {
mk=mk,cyl=cyl,label=label,pop=pop,board=board,lamp=lamp,arbol=arbol,
WOOD=WOOD,WOODD=WOODD,STONE=STONE,DIRT=DIRT,ROCKC=ROCKC,RW=RW,
}
