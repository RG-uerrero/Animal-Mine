-- src/shared/Formulas.luau  (ReplicatedStorage.Shared.Formulas)
-- Fórmulas de economía. Son funciones puras: reciben el estado "st" del jugador
-- y devuelven números. No crean partes ni tocan el workspace.

local Config = require(script.Parent.Config)

local ECONOMY = Config.Economy
local MINERS = Config.MINERS
local MANAGERS_BY_NAME = Config.MANAGERS_BY_NAME
local MINER_COUNT = Config.MINER_COUNT
local INITIAL_MANAGER_SLOTS = Config.INITIAL_MANAGER_SLOTS

-- Estado global que el servidor puede cambiar (por ahora solo la hora dorada)
local state = { eventOn = false }

-- FORMATO DE NUMEROS (1500 -> 1.50K)
local SUF = { "", "K", "M", "B", "T", "Qa", "Qi" }

-- Abrevia cantidades grandes para mostrarlas en la interfaz.
local function formatNumber(n)
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

-- Las primeras tasas pueden ser menores a una moneda por segundo.

-- Conserva decimales en producciones pequenas para evitar mostrar cero.
local function fmtRate(n)
	if n > 0 and n < 10 then
		return string.format("%.2f", n)
	end
	return formatNumber(n)
end

-- HABILIDADES

-- Calcula el precio del siguiente nivel de una habilidad.
local function skillCost(sk, lv)
	return math.floor(sk.base * sk.grow ^ lv)
end

-- GERENTES

-- Lista gerentes conocidos que tienen copias en el inventario.
local function owned(playerState)
	local l = {}
	for n, c in pairs(playerState.mg) do
		if c > 0 and MANAGERS_BY_NAME[n] then
			l[#l + 1] = MANAGERS_BY_NAME[n]
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

-- Comprueba si un gerente esta equipado.

local function isEquipped(playerState, n)
	for _, x in ipairs(playerState.eq) do
		if x == n then
			return true
		end
	end
	return false
end

-- Calcula el bono individual incluyendo estrellas.

local function managerBonus(playerState, g)
	return g.b * (1 + ECONOMY.MANAGER_STAR_BONUS * (playerState.star[g.n] or 0))
end

-- Suma bonos de los gerentes equipados.

local function totalManagerBonus(playerState)
	local t = 0
	for _, n in ipairs(playerState.eq) do
		local g = MANAGERS_BY_NAME[n]
		if g then
			t += managerBonus(playerState, g)
		end
	end
	return t
end

-- Cuenta las copias almacenadas de todos los gerentes.

local function managerCount(playerState)
	local t = 0
	for _, c in pairs(playerState.mg) do
		t += c
	end
	return t
end

-- ECONOMIA

-- Combina habilidades, gerentes, renacimientos y evento al valorar mineral.
local function cashMult(playerState)
	return (1 + ECONOMY.NEGOTIATION_PER_LEVEL * (playerState.sk.neg or 0))
		* (1 + totalManagerBonus(playerState))
		* (1 + ECONOMY.PRESTIGE_BONUS * playerState.pr)
		* (state.eventOn and ECONOMY.EVENT_MULTIPLIER or 1)
end

-- Calcula mineral por segundo segun minero, nivel e inversiones.

local function production(playerState, i)
	local l = playerState.sh[i].l
	return MINERS[i].bp
		* ECONOMY.PRODUCTION_SCALE
		* ECONOMY.LEVEL_GROWTH ^ (l - 1)
		* ECONOMY.MILESTONE_MULTIPLIER ^ math.floor(l / ECONOMY.MILESTONE_EVERY)
		* (1 + ECONOMY.PICKAXE_PER_LEVEL * (playerState.sk.pico or 0))
end

-- Calcula la capacidad de la vagoneta antes de detener la acumulacion.

local function cartCapacity(playerState, i)
	return math.max(20, production(playerState, i) * 60 * (1 + (playerState.sk.carro or 0)))
end

-- Calcula el coste del siguiente nivel del minero.

local function upgradeCost(i, l)
	return math.floor(MINERS[i].h * ECONOMY.UPGRADE_BASE * ECONOMY.UPGRADE_GROWTH ^ l)
end

-- Calcula la tirada gratuita inicial y limita el precio de las siguientes.

local function rollCost(playerState)
	if playerState.ro == 0 then
		return 0
	end
	return math.floor(
		math.min(ECONOMY.ROLL_MAXIMUM, ECONOMY.ROLL_BASE * ECONOMY.ROLL_GROWTH ^ math.min(playerState.ro - 1, 100))
	)
end

-- Suma la produccion de los mineros contratados y aplica bonos de dinero.

local function income(playerState)
	local t = 0
	for i = 1, MINER_COUNT do
		if playerState.sh[i].h then
			t += production(playerState, i)
		end
	end
	return t * cashMult(playerState)
end

-- Recompensas ligadas a produccion, con limites pequenos al comenzar.

-- Construye objetivos y recompensas para un tipo de mision.
local function questFor(playerState, kind)
	local inc = math.max(1, income(playerState))
	local goal
	if kind == 1 then
		goal = math.max(300, math.floor(inc * ECONOMY.QUEST_GOAL_SECONDS))
	elseif kind == 2 then
		goal = math.min(5, 1 + math.floor(playerState.qn / 4))
	else
		goal = 5 + math.min(25, playerState.qn * 2)
	end
	return {
		k = kind,
		goal = goal,
		prog = 0,
		rew = math.max(ECONOMY.QUEST_MINIMUM, math.floor(inc * ECONOMY.QUEST_INCOME_SECONDS)),
	}
end

-- Valida misiones guardadas y adapta su progreso entre versiones de balance.
local function restoreQuest(playerState, saved, version)
	if
		type(saved) ~= "table"
		or (saved.k ~= 1 and saved.k ~= 2 and saved.k ~= 3)
		or type(saved.goal) ~= "number"
		or saved.goal <= 0
		or type(saved.prog) ~= "number"
		or saved.prog < 0
		or type(saved.rew) ~= "number"
		or saved.rew < 0
	then
		return nil
	end
	if version == Config.BALANCE_VERSION then
		return saved
	end
	local updated = questFor(playerState, saved.k)
	local fraction = math.clamp(saved.prog / saved.goal, 0, 1)
	updated.prog = math.min(updated.goal - 1, math.floor(updated.goal * fraction))
	return updated
end

-- Calcula la probabilidad de golpe critico.

local function critChance(playerState)
	return ECONOMY.CRIT_BASE_CHANCE + ECONOMY.CRIT_SKILL_CHANCE * (playerState.sk.crit or 0)
end

-- Calcula el precio de una copia segun rareza y renacimientos.
local function sellValue(playerState, g)
	return math.floor(Config.DUPLICATE_VALUES[g.r] * (1 + ECONOMY.PRESTIGE_BONUS * playerState.pr))
end

-- DEPOSITO, SLOTS Y RENACER

-- Calcula la capacidad del banco segun su nivel.
local function depositCapacity(playerState)
	return 5000 * 4 ^ playerState.dl
end

-- Calcula el coste de ampliar el banco.

local function depositUpgradeCost(playerState)
	return math.floor(depositCapacity(playerState) * 0.5)
end

-- Calcula el interes periodico incluyendo la habilidad de banquero.

local function depositRate(playerState)
	return ECONOMY.DEPOSIT_BASE_RATE + ECONOMY.DEPOSIT_SKILL_RATE * (playerState.sk.ban or 0)
end

-- Calcula el precio del siguiente espacio para gerentes.

local function slotCost(playerState)
	return math.floor(5000 * 6 ^ (playerState.slots - INITIAL_MANAGER_SLOTS))
end

-- Calcula el dinero requerido para renacer.

local function prestigeCost(playerState)
	return math.floor(ECONOMY.PRESTIGE_COST_BASE * ECONOMY.PRESTIGE_COST_GROWTH ^ playerState.pr)
end

return {
	state = state,
	questFor = questFor,
	restoreQuest = restoreQuest,
	critChance = critChance,
	sellValue = sellValue,
	formatNumber = formatNumber,
	fmtRate = fmtRate,
	skillCost = skillCost,
	owned = owned,
	isEquipped = isEquipped,
	managerBonus = managerBonus,
	totalManagerBonus = totalManagerBonus,
	managerCount = managerCount,
	cashMult = cashMult,
	production = production,
	cartCapacity = cartCapacity,
	upgradeCost = upgradeCost,
	rollCost = rollCost,
	income = income,
	depositCapacity = depositCapacity,
	depositUpgradeCost = depositUpgradeCost,
	depositRate = depositRate,
	slotCost = slotCost,
	prestigeCost = prestigeCost,
}
