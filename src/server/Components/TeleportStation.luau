-- Componente TeleportStation: construye su zona y conecta acciones mediante context.handlers.
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

local TeleportStation = {}
function TeleportStation.build(context)
	local scoped = Builders.forModel(context.model)
	local createPart, createCylinder, board, lamp, createTree =
		scoped.createPart, scoped.createCylinder, scoped.board, scoped.lamp, scoped.createTree
	local plots, skillPads, INVENTORY_ACTION_NAMES, handlers = context.plots, context.skp, context.ipn, context.handlers
	--------------------------------------------------------------------------------
	local TPN = { "Aparicion", "Mi base", "Mi mina", "Establo", "Habilidades" }
	local tpDeck = createPart(
		"ZonaTeletransporte",
		vector3(100, 0.35, 22),
		vector3(-44, GROUND_HEIGHT - 0.175, 106),
		color3(195, 188, 211),
		Enum.Material.Slate
	)
	tpDeck.CanCollide = true
	for i = 1, #TPN do
		local strip = createPart(
			"BaldosaTeletransporte",
			vector3(15, 0.12, 18),
			vector3(-80 + (i - 1) * 18, GROUND_HEIGHT + 0.01, 106),
			color3(222, 214, 235),
			Enum.Material.SmoothPlastic
		)
		strip.CanCollide = false
	end
	local tpart
	for k = 1, #TPN do
		local pd = createCylinder(
			"TpPad",
			0.8,
			8,
			vector3(-80 + (k - 1) * 18, GROUND_HEIGHT + 0.4, 106),
			color3(139, 121, 177),
			Enum.Material.Metal
		)
		label(pd, TPN[k], 3, 138, 38, 24)
		local pr = Instance.new("ProximityPrompt")
		pr.ActionText = "Teletransportar"
		pr.ObjectText = TPN[k]
		pr.HoldDuration = 0.2
		pr.MaxActivationDistance = 7
		pr.RequiresLineOfSight = false
		pr.Parent = pd
		pr.Triggered:Connect(function(p)
			handlers.teleportPlayer(p, k)
		end)
		if k == 3 then
			tpart = pd
		end
	end
	label(tpart, "TELETRANSPORTE", 8, 180, 36, 72, "landmark")
end
return TeleportStation
