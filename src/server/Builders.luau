-- src/server/Builders.luau  (ServerScriptService.Server.Builders)
-- Funciones para crear partes, carteles y decoracion.
-- Las usan Main.server.luau y World.luau.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local WorldText = require(ReplicatedStorage.Shared.WorldText)
local Workspace = workspace
local vector3 = Vector3.new
local color3 = Color3.fromRGB
local SPHERE_SHAPE = Enum.PartType.Ball
local GROUND_HEIGHT = Config.GROUND_HEIGHT
local worldRandom = Random.new(9) -- aleatorio del mundo (siempre igual)

-- Crea una pieza anclada: nombre, tamano, posicion, color, material y forma.

local function createPart(n, s, pos, c, m, shape, parent)
	local p = Instance.new("Part")
	p.Name = n
	p.Anchored = true
	p.Size = s
	p.Position = pos
	if typeof(c) == "Color3" then
		p.Color = c
	else
		p.BrickColor = BrickColor.new(c)
	end
	p.Material = m or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.Parent = parent or Workspace
	return p
end

-- Crea un cilindro horizontal como plataforma; h es altura y d diametro.

local function createCylinder(n, h, d, pos, c, m, parent)
	local p = createPart(n, vector3(h, d, d), pos, c, m, Enum.PartType.Cylinder, parent)
	p.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	return p
end

-- Crea texto flotante con el estilo y alcance definidos en WorldText.

local function label(part, txt, off, w, h, dist, role)
	local g = Instance.new("BillboardGui")
	WorldText.configure(g, role or "detail", math.min(w or 180, 220), math.min(h or 48, 116), dist or 24)
	WorldText.anchor(g, part, off)
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	WorldText.style(t, role)
	t.Text = txt
	t.Parent = g
	g.Parent = part
	return t
end

-- Crea un cartel fijo sobre la cara posterior de una pieza.

local function sign(part, txt)
	local surface = Instance.new("SurfaceGui")
	surface.Name = "MineSign"
	surface.Face = Enum.NormalId.Back
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 30
	surface.LightInfluence = 0
	surface.MaxDistance = 120
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextColor3 = color3(255, 240, 205)
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.TextWrapped = true
	text.Text = txt
	local padding = Instance.new("UIPadding", text)
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	text.Parent = surface
	surface.Parent = part
	return text
end

-- Muestra un texto temporal ascendente para compras o recompensas.

local function pop(part, txt, col)
	local t = label(part, txt, 4, 132, 32, 22, "feedback")
	t.TextColor3 = col or color3(140, 255, 170)
	local g = t.Parent
	local anchor = g.Adornee
	TweenService:Create(
		anchor,
		TweenInfo.new(0.9),
		{ Position = anchor.Position + part.CFrame:VectorToObjectSpace(vector3(0, 3, 0)) }
	):Play()
	Debris:AddItem(anchor, 0.9)
	TweenService:Create(t, TweenInfo.new(0.9), { TextTransparency = 1 }):Play()
	Debris:AddItem(g, 0.9)
end

local WOOD = color3(140, 95, 62)
local DARK_WOOD = color3(105, 70, 46)
local STONE = color3(224, 215, 193)
local DIRT = color3(188, 153, 113)
local ROCK_COLOR = color3(153, 143, 127)

-- Construye un letrero con dos postes orientado hacia el punto indicado.

local function board(pos, target, txt, w, h, parent)
	local baseCreatePart = createPart
	local function createPart(...)
		local part = baseCreatePart(...)
		part.Parent = parent or Workspace
		return part
	end
	local b = createPart("Cartel", vector3(w, h, 1), pos, WOOD, Enum.Material.Wood)
	b.CFrame = CFrame.lookAt(pos, vector3(target.X, pos.Y, target.Z))
	for _, sx in pairs({ -1, 1 }) do
		local po = createPart("Poste", vector3(1.5, pos.Y - 1, 1.5), pos, DARK_WOOD, Enum.Material.Wood)
		po.CFrame = b.CFrame * CFrame.new(sx * (w / 2 - 1.5), -(pos.Y - 1) / 2, 0)
	end
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.PixelsPerStud = 25
	local t = Instance.new("TextLabel", sg)
	t.Size = UDim2.new(1, 0, 1, 0)
	t.BackgroundTransparency = 1
	t.TextColor3 = color3(255, 240, 205)
	t.TextScaled = true
	t.TextWrapped = true
	t.Font = Enum.Font.FredokaOne
	t.Text = txt
	sg.Parent = b
	return b
end

-- Construye una farola con luz calida.

local function lamp(x, z, parent)
	local baseCreatePart, baseCreateCylinder = createPart, createCylinder
	local function createPart(...)
		local part = baseCreatePart(...)
		part.Parent = parent or Workspace
		return part
	end
	local function createCylinder(...)
		local part = baseCreateCylinder(...)
		part.Parent = parent or Workspace
		return part
	end
	createCylinder("Poste", 9, 0.8, vector3(x, GROUND_HEIGHT + 4.5, z), color3(50, 52, 58), Enum.Material.Metal)
	local b = createPart(
		"Lampara",
		vector3(2.4, 2.4, 2.4),
		vector3(x, GROUND_HEIGHT + 10, z),
		color3(255, 214, 140),
		Enum.Material.Neon,
		SPHERE_SHAPE
	)
	local l = Instance.new("PointLight", b)
	l.Range = 28
	l.Brightness = 1
	l.Color = color3(255, 200, 120)
end

-- Construye tronco, ramas y copas; modifica aqui el modelo de todos los arboles.

local function createTree(x, z, parent)
	local s = worldRandom:NextNumber(0.85, 1.2)
	local model = Instance.new("Model")
	model.Name = "ArbolPradera"
	model.Parent = parent or Workspace
	local function piece(name, size, pos, color)
		local p = createPart(name, size, pos, color, Enum.Material.SmoothPlastic)
		p.Parent = model
		return p
	end
	piece("Tronco", vector3(2 * s, 10 * s, 2 * s), vector3(x, 1 + 5 * s, z), color3(139, 105, 77))
	for _, side in ipairs({ -1, 1 }) do
		local branch =
			piece("Rama", vector3(1.1 * s, 5 * s, 1.1 * s), vector3(x + side * 1.8 * s, 9 * s, z), color3(139, 105, 77))
		branch.CFrame = branch.CFrame * CFrame.Angles(0, 0, -side * 0.6)
	end
	for _, cluster in ipairs({
		{ 0, 13, 0, 12, 10, 11 },
		{ -4, 11, 1, 8, 7, 8 },
		{ 4, 12, -1, 9, 8, 9 },
		{
			0,
			17,
			0,
			8,
			7,
			8,
		},
	}) do
		local leaf = piece(
			"Copa",
			vector3(cluster[4], cluster[5], cluster[6]) * s,
			vector3(x + cluster[1] * s, 1 + cluster[2] * s, z + cluster[3] * s),
			color3(110 + cluster[2] * 2, 163 + cluster[2], 103)
		)
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = leaf
		leaf.CanCollide = false
	end
end

-- Constructeurs lies a un conteneur explicite; aucun parent global mutable.
local function forModel(parent)
	return {
		createPart = function(n, s, pos, c, m, shape)
			return createPart(n, s, pos, c, m, shape, parent)
		end,
		createCylinder = function(n, h, d, pos, c, m)
			return createCylinder(n, h, d, pos, c, m, parent)
		end,
		board = function(pos, target, text, w, h)
			return board(pos, target, text, w, h, parent)
		end,
		lamp = function(x, z)
			return lamp(x, z, parent)
		end,
		createTree = function(x, z)
			return createTree(x, z, parent)
		end,
	}
end
return {
	forModel = forModel,
	createPart = createPart,
	createCylinder = createCylinder,
	sign = sign,
	label = label,
	pop = pop,
	board = board,
	lamp = lamp,
	createTree = createTree,
	WOOD = WOOD,
	DARK_WOOD = DARK_WOOD,
	STONE = STONE,
	DIRT = DIRT,
	ROCK_COLOR = ROCK_COLOR,
	worldRandom = worldRandom,
}
