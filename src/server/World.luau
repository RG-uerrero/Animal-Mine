-- Composicion del escenario: cada componente construye una zona independiente.
-- El orden conserva las posiciones, referencias y secuencia de decoracion originales.
local Components = script.Parent.Components
local Landscape = require(Components.Landscape)
local Clouds = require(Components.Clouds)
local Fountain = require(Components.Fountain)
local MinePlots = require(Components.MinePlots)
local SkillWorkshop = require(Components.SkillWorkshop)
local TeleportStation = require(Components.TeleportStation)
local RebirthStation = require(Components.RebirthStation)
local SpawnPoint = require(Components.SpawnPoint)
local World = {}
function World.build(context)
	local worldModel = Instance.new("Model")
	worldModel.Name = "Mundo"
	worldModel.Parent = workspace
	context.worldModel = worldModel
	local function buildZone(component, name)
		local zone = Instance.new("Model")
		zone.Name = name
		zone.Parent = worldModel
		local zoneContext = table.clone(context)
		zoneContext.model = zone
		return component.build(zoneContext)
	end
	buildZone(Landscape, "Landscape")
	local clouds = buildZone(Clouds, "Clouds")
	buildZone(Fountain, "Fountain")
	buildZone(MinePlots, "MinePlots")
	buildZone(SkillWorkshop, "SkillWorkshop")
	buildZone(TeleportStation, "TeleportStation")
	buildZone(RebirthStation, "RebirthStation")
	buildZone(SpawnPoint, "SpawnPoint")
	return clouds
end
return World
