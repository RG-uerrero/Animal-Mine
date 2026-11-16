-- Componente Clouds: construye su zona y conecta acciones mediante context.handlers.
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

local Clouds = {}
function Clouds.build(context)
	local scoped = Builders.forModel(context.model)
	local createPart, createCylinder, board, lamp, createTree =
		scoped.createPart, scoped.createCylinder, scoped.board, scoped.lamp, scoped.createTree
	local plots, skillPads, INVENTORY_ACTION_NAMES, handlers = context.plots, context.skp, context.ipn, context.handlers
	--------------------------------------------------------------------------------
	local clouds = {}
	for k = 1, 8 do
		local m = Instance.new("Model")
		local function puff(s, off)
			local p = Instance.new("Part")
			p.Shape = SPHERE_SHAPE
			p.Size = s
			p.Anchored = true
			p.CanCollide = false
			p.CastShadow = false
			p.Material = Enum.Material.SmoothPlastic
			p.Color = Color3.new(1, 1, 1)
			p.Transparency = 0.15
			p.Position = off
			p.Parent = m
			return p
		end
		local main = puff(vector3(30, 14, 22), vector3(0, 0, 0))
		puff(vector3(20, 11, 16), vector3(-16, -2, 3))
		puff(vector3(22, 10, 16), vector3(15, -3, -2))
		m.PrimaryPart = main
		m.Name = "Nube" .. k
		m.Parent = context.model
		clouds[k] = {
			m = m,
			x = worldRandom:NextNumber(-420, 420),
			y = worldRandom:NextNumber(110, 150),
			z = worldRandom:NextNumber(-120, 220),
			sp = worldRandom:NextNumber(1.5, 4),
		}
	end
	return clouds
end
return Clouds
