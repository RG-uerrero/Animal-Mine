-- Vista temporal de los 20 personajes. Ejecutar en SERVIDOR durante Play.
-- Al detener Play desaparece la galeria; no modifica dinero ni inventario.
local Models = require(game.ServerScriptService.Server.AnimalModels)
local Config = require(game.ReplicatedStorage.Shared.Config)
local Builders = require(game.ServerScriptService.Server.Builders)
local gallery = Instance.new("Folder")
gallery.Name = "AnimalDesignPreview"
gallery.Parent = workspace
local entries = {}
for _, data in ipairs(Config.MINERS) do
	table.insert(entries, { data = data, manager = false })
end
for _, data in ipairs(Config.MANAGERS) do
	table.insert(entries, { data = data, manager = true })
end
for index, entry in ipairs(entries) do
	local data = entry.data
	local x = -24 + ((index - 1) % 7) * 8
	local z = 180 + math.floor((index - 1) / 7) * 15
	local model, body = Models.build(CFrame.new(x, Config.GROUND_HEIGHT, z), data.a, data.c, data.k, {
		name = data.n,
		helmet = not entry.manager,
		tie = entry.manager,
		aura = entry.manager and data.r >= 3 and Config.RARITIES[data.r].c or nil,
		parent = gallery,
	})
	Builders.label(body, data.n, 7, 180, 38, 24, "info")
end
print("Galeria temporal creada: 20 personajes, entre z=180 y z=210.")
