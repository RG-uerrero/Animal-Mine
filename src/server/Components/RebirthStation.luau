-- Componente RebirthStation: construye su zona y conecta acciones mediante context.handlers.
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

local RebirthStation = {}
function RebirthStation.build(context)
	local scoped = Builders.forModel(context.model)
	local createPart, createCylinder, board, lamp, createTree =
		scoped.createPart, scoped.createCylinder, scoped.board, scoped.lamp, scoped.createTree
	local plots, skillPads, INVENTORY_ACTION_NAMES, handlers = context.plots, context.skp, context.ipn, context.handlers
	--------------------------------------------------------------------------------
	local rebirthDeck = createCylinder(
		"ZonaRenacer",
		0.5,
		30,
		vector3(180, GROUND_HEIGHT - 0.25, 106),
		color3(130, 105, 75),
		Enum.Material.Slate
	)
	rebirthDeck.CanCollide = true
	for k = 1, 12 do
		local a = math.rad((k - 1) * 30)
		local dot = createPart(
			"LuzBordeRenacer",
			vector3(1.1, 0.35, 1.1),
			vector3(180 + 17 * math.cos(a), GROUND_HEIGHT + 0.35, 106 + 17 * math.sin(a)),
			color3(255, 215, 105),
			Enum.Material.Neon,
			SPHERE_SHAPE
		)
		dot.CanCollide = false
	end
	local rpd = createCylinder(
		"RenacerPad",
		1,
		12,
		vector3(180, GROUND_HEIGHT + 0.5, 106),
		color3(255, 200, 60),
		Enum.Material.Neon
	)
	createCylinder(
		"RenacerAnillo",
		0.4,
		16,
		vector3(180, GROUND_HEIGHT + 0.2, 106),
		color3(255, 255, 255),
		Enum.Material.Neon
	)
	label(
		rpd,
		"RENACER\n+" .. string.format("%g", Config.Economy.PRESTIGE_BONUS * 100) .. "% de dinero permanente",
		7,
		196,
		56,
		38,
		"info"
	)

	local rpr = Instance.new("ProximityPrompt")
	rpr.ActionText = "Renacer (mantener)"
	rpr.ObjectText = "Reinicia tu progreso"
	rpr.HoldDuration = 2
	rpr.MaxActivationDistance = 10
	rpr.RequiresLineOfSight = false
	rpr.Parent = rpd
	rpr.Triggered:Connect(handlers.prestige)
end
return RebirthStation
