-- Mantiene el almacen y la version existentes. Studio usa datos separados.
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local SessionStore = require(script.Parent.SessionStore)
local name = (RunService:IsStudio() and "MinaAnimal_Studio_v" or "MinaAnimal_v") .. Config.DATA_VERSION
local store
local ok, err = pcall(function()
	store = DataStoreService:GetDataStore(name)
end)
if not ok then
	warn("[DataService] " .. tostring(err))
end
return SessionStore.new(store, {
	now = os.time,
	newToken = function()
		return HttpService:GenerateGUID(false)
	end,
	wait = task.wait,
	log = warn,
})
