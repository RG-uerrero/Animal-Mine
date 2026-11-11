-- src/server/DataService.luau  (ServerScriptService.Server.DataService)
-- Carga y guardado de datos con reintentos.
-- Regla clave: si NO se pudo LEER la partida, el jugador no debe poder guardar,
-- porque su progreso real se sobrescribiria con una partida vacia.

local DataStoreService = game:GetService("DataStoreService")

local STORE_NAME = "MinaAnimal_v1" -- no lo cambies o los jugadores pierden su progreso
local RETRIES = 3

local store = nil
pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
end)

local DataService = {}

local function key(userId)
	return "u" .. userId
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
		task.wait(2 * attempt)
	end
	return false
end

return DataService
