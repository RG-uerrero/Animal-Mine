-- src/shared/Formulas.luau  (ReplicatedStorage.Shared.Formulas)
-- Fórmulas de economía. Son funciones puras: reciben el estado "st" del jugador
-- y devuelven números. No crean partes ni tocan el workspace.

local Config = require(script.Parent.Config)

local SH = Config.SH
local MGBY = Config.MGBY
local NSH = Config.NSH
local SLOT0 = Config.SLOT0

-- Estado global que el servidor puede cambiar (por ahora solo la hora dorada)
local state = { eventOn = false }

-- FORMATO DE NUMEROS (1500 -> 1.50K)
local SUF = { "", "K", "M", "B", "T", "Qa", "Qi" }
local function fmt(n)
	n = math.floor(n)
	if n < 1000 then
		return tostring(n)
	end
	local i = 0
	local x = n
	while x >= 1000 and i < #SUF - 1 do
		x = x / 1000
		i += 1
	end
	return string.format("%.2f%s", x, SUF[i + 1])
end

-- HABILIDADES
local function skCost(sk, lv)
	return math.floor(sk.base * sk.grow ^ lv)
end

-- GERENTES
local function owned(st)
	local l = {}
	for n, c in pairs(st.mg) do
		if c > 0 and MGBY[n] then
			l[#l + 1] = MGBY[n]
		end
	end
	table.sort(l, function(a, b)
		if a.r ~= b.r then
			return a.r > b.r
		end
		return a.n < b.n
	end)
	return l
end

local function isEq(st, n)
	for _, x in ipairs(st.eq) do
		if x == n then
			return true
		end
	end
	return false
end

local function mbonus(st, g)
	return g.b * (1 + 0.5 * (st.star[g.n] or 0))
end

local function mgrBonus(st)
	local t = 0
	for _, n in ipairs(st.eq) do
		local g = MGBY[n]
		if g then
			t += mbonus(st, g)
		end
	end
	return t
end

local function mgrCount(st)
	local t = 0
	for _, c in pairs(st.mg) do
		t += c
	end
	return t
end

-- ECONOMIA
local function cashMult(st)
	return (1 + 0.15 * (st.sk.neg or 0))
		* (1 + mgrBonus(st))
		* (1 + 0.5 * st.pr)
		* (state.eventOn and 2 or 1)
end

local function prod(st, i)
	local l = st.sh[i].l
	return SH[i].bp * 1.25 ^ (l - 1) * 2 ^ math.floor(l / 10) * (1 + 0.25 * (st.sk.pico or 0))
end

local function capOf(st, i)
	return math.max(20, prod(st, i) * 60 * (1 + (st.sk.carro or 0)))
end

local function upCost(i, l)
	return math.floor(SH[i].h * 0.6 * 1.35 ^ l)
end

local function rollCost(st)
	if st.ro == 0 then
		return 0
	end
	return math.floor(400 * 1.8 ^ (st.ro - 1))
end

local function income(st)
	local t = 0
	for i = 1, NSH do
		if st.sh[i].h then
			t += prod(st, i)
		end
	end
	return t * cashMult(st)
end

-- DEPOSITO, SLOTS Y RENACER
local function depCap(st)
	return 5000 * 4 ^ st.dl
end

local function depUpCost(st)
	return math.floor(depCap(st) * 0.5)
end

local function depRate(st)
	return 0.01 + 0.002 * (st.sk.ban or 0)
end

local function slotCost(st)
	return math.floor(5000 * 6 ^ (st.slots - SLOT0))
end

local function prCost(st)
	return math.floor(2000000 * 8 ^ st.pr)
end

return {
	state = state,
	fmt = fmt,
	skCost = skCost,
	owned = owned,
	isEq = isEq,
	mbonus = mbonus,
	mgrBonus = mgrBonus,
	mgrCount = mgrCount,
	cashMult = cashMult,
	prod = prod,
	capOf = capOf,
	upCost = upCost,
	rollCost = rollCost,
	income = income,
	depCap = depCap,
	depUpCost = depUpCost,
	depRate = depRate,
	slotCost = slotCost,
	prCost = prCost,
}
