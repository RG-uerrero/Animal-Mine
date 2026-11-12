-- src/server/DataService.luau  (ServerScriptService.Server.DataService)
-- Carga y guardado de datos con reintentos.
-- Regla clave: si NO se pudo LEER la partida, el jugador no debe poder guardar,
-- porque su progreso real se sobrescribiria con una partida vacia.

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

-- El nombre del almacen depende de Config.DATA_VERSION:
--   version 1 -> "MinaAnimal_v1" (el mismo que ya usan tus amigos)
--   version 2 -> "MinaAnimal_v2" (todos empiezan de cero)
-- En Studio se usa un almacen aparte, para que las pruebas no pisen el progreso real.
local STORE_NAME = (RunService:IsStudio() and "MinaAnimal_Studio_v" or "MinaAnimal_v") .. Config.DATA_VERSION
local RETRIES = 3

local store = nil
pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
end)

local DataService = {}

local function key(userId)
	return "u" .. userId
end

-- En Studio, si el acceso a la API esta desactivado, reintentar no sirve de nada
local function apiBlocked(err)
	return string.find(tostring(err), "StudioAccessToApisNotAllowed", 1, true) ~= nil
end

-- Devuelve (ok, data)
--   ok = true,  data = tabla  -> partida existente
--   ok = true,  data = nil    -> jugador nuevo
--   ok = false                -> NO se pudo leer (no guardar, no jugar de verdad)
function DataService.load(userId)
	if not store then
		return false, nil
	end
	for attempt = 1, RETRIES do
		local ok, res = pcall(function()
			return store:GetAsync(key(userId))
		end)
		if ok then
			return true, res
		end
		warn("[DataService] fallo al cargar (intento " .. attempt .. "): " .. tostring(res))
		if apiBlocked(res) then
			return false, nil
		end
		task.wait(2 * attempt)
	end
	return false, nil
end

-- Devuelve true si se guardo
function DataService.save(userId, data)
	if not store then
		return false
	end
	for attempt = 1, RETRIES do
		local ok, err = pcall(function()
			store:UpdateAsync(key(userId), function()
				return data
			end)
		end)
		if ok then
			return true
		end
		warn("[DataService] fallo al guardar (intento " .. attempt .. "): " .. tostring(err))
		if apiBlocked(err) then
			return false
		end
		task.wait(2 * attempt)
	end
	return false
end

return DataService
