-- En Studio: pegar este archivo en la barra de comandos (modo edicion).
local SessionStore = require(game.ServerScriptService.Server.SessionStore)
local clock = 1000
local serial = 0
local values = {}
local failures = 0
local attempts = 0
local blocked = false
local store = {}
function store:UpdateAsync(key, transform)
	attempts += 1
	if blocked then
		error("403: Cannot write to DataStore from studio if API access is not enabled.")
	end
	if failures > 0 then
		failures -= 1
		error("simulated outage")
	end
	local result = transform(values[key])
	if result ~= nil then
		values[key] = result
	end
	return result
end
local options = {
	now = function()
		return clock
	end,
	newToken = function()
		serial += 1
		return "session-" .. serial
	end,
	wait = function() end,
	log = function() end,
}
local a = SessionStore.new(store, options)
local b = SessionStore.new(store, options)
local ok, data, token = a.load(1)
assert(ok and data._session.id == token, "new profile acquires lock")
local busy, _, reason = b.load(1)
assert(not busy and reason == "busy", "second server cannot load locked profile")
assert(a.save(1, { c = 123, mg = { Rita = 2 } }, token, false), "owner can save")
assert(values.u1.c == 123, "progress persists")
assert(not b.save(1, { c = 0 }, "wrong-token", true), "stranger cannot save or release")
assert(values.u1.c == 123 and values.u1._session.id == token, "rejection leaves data intact")
clock += 60
assert(a.save(1, { c = 200 }, token, false), "autosave renews lease")
assert(values.u1._session.expires == clock + 180, "lease renewed")
clock += 181
local takeover, restored, newToken = b.load(1)
assert(takeover and restored.c == 200, "expired lease can be recovered")
assert(not a.save(1, { c = 999 }, token, true), "old server cannot overwrite new session")
assert(b.save(1, { c = 300 }, newToken, true), "final save releases lease")
assert(values.u1.c == 300 and values.u1._session == nil, "release preserves progress")
assert(a.load(1), "immediate reconnect after release")
values.u2 = { c = 42, sh = { { h = true, l = 5 } } }
local legacy, old, legacyToken = a.load(2)
assert(legacy and old.c == 42 and old.sh[1].l == 5, "legacy profile is preserved")
assert(a.save(2, old, legacyToken, true), "abandoned load can release original data")
assert(values.u2.c == 42 and not values.u2._session, "abandoned load does not reset data")
values.u3 = "corrupt"
local invalid, _, invalidReason = a.load(3)
assert(not invalid and invalidReason == "invalid" and values.u3 == "corrupt", "invalid profile is not overwritten")
failures = 2
attempts = 0
assert(a.load(4) and attempts == 3, "transient failures retry")
failures = 3
local unavailable, _, failureReason = a.load(5)
assert(not unavailable and failureReason == "unavailable" and values.u5 == nil, "failed load cannot create profile")
values.u6 = { _session = { id = "broken" } }
assert(not a.load(6), "invalid lock is rejected")
blocked = true
attempts = 0
assert(not a.load(7) and attempts == 1, "disabled Studio API fails immediately without retries")
print("SessionStore: all regression checks passed")
