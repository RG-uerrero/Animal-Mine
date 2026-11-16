-- Componente Fountain: construye su zona y conecta acciones mediante context.handlers.
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

local Fountain = {}
function Fountain.build(context)
	local scoped = Builders.forModel(context.model)
	local createPart, createCylinder, board, lamp, createTree =
		scoped.createPart, scoped.createCylinder, scoped.board, scoped.lamp, scoped.createTree
	local plots, skillPads, INVENTORY_ACTION_NAMES, handlers = context.plots, context.skp, context.ipn, context.handlers
	--------------------------------------------------------------------------------
	createCylinder("FuenteBase", 1.4, 22, vector3(135, GROUND_HEIGHT + 0.7, 112), STONE, Enum.Material.Concrete)
	createCylinder(
		"FuenteAgua",
		0.5,
		18,
		vector3(135, GROUND_HEIGHT + 1.45, 112),
		color3(90, 170, 255),
		Enum.Material.Glass
	).Transparency =
		0.35
	createCylinder("FuentePilar", 5, 2.4, vector3(135, GROUND_HEIGHT + 3.5, 112), STONE, Enum.Material.Concrete)

	-- Emisor de partículas y luz para el chorro de la fuente
	local spout = createPart("Chorro", vector3(1, 1, 1), vector3(135, GROUND_HEIGHT + 6.2, 112), Color3.new(1, 1, 1))
	spout.Transparency = 1
	spout.CanCollide = false

	local wpe = Instance.new("ParticleEmitter")
	wpe.Rate = 80
	wpe.Lifetime = NumberRange.new(1.4, 1.8)
	wpe.Speed = NumberRange.new(22, 28)
	wpe.SpreadAngle = Vector2.new(8, 8)
	wpe.Acceleration = vector3(0, -40, 0)
	wpe.Size = NumberSequence.new(0.6)
	wpe.Transparency = NumberSequence.new(0.3)
	wpe.Color = ColorSequence.new(color3(170, 220, 255))
	wpe.LightEmission = 0.3
	wpe.Parent = spout

	local wl = Instance.new("PointLight", spout)
	wl.Color = color3(120, 190, 255)
	wl.Range = 24
	wl.Brightness = 0.8
end
return Fountain
