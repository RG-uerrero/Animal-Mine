-- Componente SkillWorkshop: construye su zona y conecta acciones mediante context.handlers.
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

local SkillWorkshop = {}
function SkillWorkshop.build(context)
	local scoped = Builders.forModel(context.model)
	local createPart, createCylinder, board, lamp, createTree =
		scoped.createPart, scoped.createCylinder, scoped.board, scoped.lamp, scoped.createTree
	local plots, skillPads, INVENTORY_ACTION_NAMES, handlers = context.plots, context.skp, context.ipn, context.handlers
	--------------------------------------------------------------------------------
	local hx, hz = 70, 106
	-- Cada grupo de acciones tiene su propia zona de color y una huella amplia.
	-- Esto ordena los botones y permite leerlos como estaciones desde la plaza.
	createPart(
		"TallerSuelo",
		vector3(68, 0.4, 50),
		vector3(hx, GROUND_HEIGHT - 0.2, hz),
		color3(216, 204, 179),
		Enum.Material.WoodPlanks
	)
	board(vector3(hx, 10, hz + 27), vector3(hx, 10, hz), "TALLER DE HABILIDADES", 42, 5)

	for k, sk in ipairs(SKILLS) do
		local col = (k - 1) % 4
		local pos = vector3(hx - 18 + col * 12, GROUND_HEIGHT + 0.4, hz - 10 + math.floor((k - 1) / 4) * 18)
		createPart(
			"BaldosaHabilidad",
			vector3(10, 0.2, 10),
			pos - vector3(0, 0.3, 0),
			color3(245, 234, 212),
			Enum.Material.SmoothPlastic
		)
		local pd = createCylinder("HabPad", 0.8, 7, pos, sk.col, Enum.Material.SmoothPlastic)
		local pr = Instance.new("ProximityPrompt")
		pr.ActionText = "Mejorar"
		pr.ObjectText = sk.name
		pr.HoldDuration = 0.2
		pr.MaxActivationDistance = 7
		pr.RequiresLineOfSight = false
		pr.Parent = pd
		pr.Triggered:Connect(function(p)
			handlers.skill(p, k)
		end)
		skillPads[k] = pd
		pd:SetAttribute("SkillIndex", k)
		CollectionService:AddTag(pd, "SkillPad")
	end
end
return SkillWorkshop
