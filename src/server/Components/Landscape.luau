-- Componente Landscape: construye su zona y conecta acciones mediante context.handlers.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Config = require(ReplicatedStorage.Shared.Config)
local Builders = require(script.Parent.Parent.Builders)

-- Desestructuración de funciones y constantes del módulo Builders y Config
local createPart, createCylinder, label, board, lamp, createTree =
	Builders.createPart, Builders.createCylinder, Builders.label, Builders.board, Builders.lamp, Builders.createTree
local WOOD, DARK_WOOD, STONE, DIRT, ROCK_COLOR, worldRandom =
	Builders.WOOD, Builders.DARK_WOOD, Builders.STONE, Builders.DIRT, Builders.ROCK_COLOR, Builders.worldRandom
local Workspace = workspace
local vector3 = Vector3.new
local color3 = Color3.fromRGB
local SPHERE_SHAPE = Enum.PartType.Ball
local MINER_COUNT, GROUND_HEIGHT = Config.MINER_COUNT, Config.GROUND_HEIGHT
local TIER_COLORS, SKILLS = Config.TIER_COLORS, Config.SKILLS

local Landscape = {}
function Landscape.build(context)
	local scoped = Builders.forModel(context.model)
	local createPart, createCylinder, board, lamp, createTree =
		scoped.createPart, scoped.createCylinder, scoped.board, scoped.lamp, scoped.createTree
	local plots, skillPads, INVENTORY_ACTION_NAMES, handlers = context.plots, context.skp, context.ipn, context.handlers
	--------------------------------------------------------------------------------

	-- Suelo principal y colinas circundantes
	createPart("Suelo", vector3(640, 1, 420), vector3(0, 0.5, 40), color3(126, 169, 105), Enum.Material.Grass)
	for x = -300, 300, 60 do
		local s = worldRandom:NextInteger(30, 55)
		createPart(
			"Colina",
			vector3(90, s, 70),
			vector3(x, s / 3, -130),
			color3(worldRandom:NextInteger(85, 110), worldRandom:NextInteger(170, 195), worldRandom:NextInteger(70, 90)),
			Enum.Material.Grass,
			SPHERE_SHAPE
		)
	end

	-- Plaza central y letrero principal de bienvenida
	createPart("Plaza", vector3(420, 0.3, 60), vector3(0, 1, 100), STONE, Enum.Material.Cobblestone)
	board(
		vector3(0, 17, 138),
		vector3(0, 17, 100),
		"MINA ANIMAL\nContrata mineros, junta dinero y rueda gerentes!",
		56,
		14
	)

	-- Arco de bienvenida: enmarca el letrero y hace visible el punto de llegada.
	for _, x in ipairs({ -31, 31 }) do
		createPart("ArcoBienvenidaPoste", vector3(2.4, 24, 2.4), vector3(x, 12, 138), DARK_WOOD, Enum.Material.Wood)
		createPart(
			"ArcoBienvenidaLuz",
			vector3(3.2, 1.2, 3.2),
			vector3(x, 23.5, 138),
			color3(255, 218, 130),
			Enum.Material.Neon,
			SPHERE_SHAPE
		)
	end
	createPart("ArcoBienvenidaViga", vector3(66, 2, 2.4), vector3(0, 25, 138), WOOD, Enum.Material.Wood)
	createPart(
		"ArcoBienvenidaTecho",
		vector3(70, 1.2, 3.6),
		vector3(0, 26.4, 138),
		color3(255, 205, 105),
		Enum.Material.WoodPlanks
	)

	-- Iluminación y arborización decorativa de la plaza
	for _, x in pairs({ -210, -110, 10, 210 }) do
		lamp(x, 118)
	end
	for _, x in pairs({ -250, -200, -150, -100, -50, 50, 100, 150, 200, 250 }) do
		createTree(x, 160)
	end
	for _, x in pairs({ -100, 0, 100, -200, 200 }) do
		createTree(x, -20)
	end
	for _, x in pairs({ -290, 290 }) do
		for z = 0, 120, 40 do
			createTree(x, z)
		end
	end

	-- Macizos y hierba decorativa fuera de las rutas de las parcelas.
	for _, z in ipairs({ 150, 178, -72 }) do
		for x = -240, 240, 16 do
			for blade = 1, 3 do
				local p = createPart(
					"MataCesped",
					vector3(0.22, 1.3 + blade * 0.3, 0.65),
					vector3(x + blade * 0.6, 1.7, z),
					color3(99 + blade * 8, 143 + blade * 8, 84),
					Enum.Material.SmoothPlastic
				)
				p.CFrame = p.CFrame * CFrame.Angles(0, blade, (blade - 2) * 0.3)
				p.CanCollide = false
			end
		end
	end

	-- Distribución aleatoria de flores en el mapa
	local FLC = {
		color3(255, 120, 170),
		color3(255, 225, 90),
		color3(245, 245, 250),
		color3(180, 120, 255),
		color3(255, 150, 80),
	}
	for _ = 1, 70 do
		createPart(
			"Flor",
			vector3(1, 1, 1),
			vector3(worldRandom:NextNumber(-300, 300), 1.5, worldRandom:NextNumber(142, 240)),
			FLC[worldRandom:NextInteger(1, #FLC)],
			Enum.Material.SmoothPlastic,
			SPHERE_SHAPE
		)
	end
end
return Landscape
