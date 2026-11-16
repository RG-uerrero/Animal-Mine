-- Separado para probar la persistencia con un almacen simulado.
local SessionStore = {}
function SessionStore.new(store, options)
	local DataService = {}
	local now = options.now
	local newToken = options.newToken
	local wait = options.wait
	local log = options.log

	-- Reintenta operaciones de almacenamiento y reconoce errores de acceso de Studio.
	local function request(userId, transform)
		for attempt = 1, 3 do
			local ok, result = pcall(function()
				return store:UpdateAsync("u" .. userId, transform)
			end)
			if ok then
				return true, result
			end
			log("[DataService] " .. tostring(result))
			if
				string.find(tostring(result), "StudioAccessToApisNotAllowed", 1, true)
				or string.find(
					tostring(result),
					"Cannot write to DataStore from studio if API access is not enabled",
					1,
					true
				)
			then
				break
			end
			if attempt < 3 then
				wait(attempt * 2)
			end
		end
		return false, nil
	end
	function DataService.load(userId)
		local token = newToken()
		local reason
		local ok, data = request(userId, function(old)
			reason = nil
			if old ~= nil and type(old) ~= "table" then
				reason = "invalid"
				return nil
			end
			local lock = old and old._session
			if lock and (type(lock) ~= "table" or type(lock.id) ~= "string" or type(lock.expires) ~= "number") then
				reason = "invalid"
				return nil
			end
			if lock and lock.id ~= token and lock.expires > now() then
				reason = "busy"
				return nil
			end
			local nextData = table.clone(old or {})
			nextData._session = { id = token, expires = now() + 180 }
			return nextData
		end)
		if not ok or not data then
			return false, nil, reason or "unavailable"
		end
		return true, data, token
	end
	function DataService.save(userId, data, token, release)
		local ok, result = request(userId, function(old)
			if type(old) ~= "table" or not old._session or old._session.id ~= token then
				return nil
			end
			local nextData = table.clone(data)
			nextData._session = not release and { id = token, expires = now() + 180 } or nil
			return nextData
		end)
		return ok and result ~= nil
	end
	return DataService
end
return SessionStore
