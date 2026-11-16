local playerState = { sh = {}, sk = {}, mg = {}, eq = {}, star = {}, pr = 0, slots = Config.INITIAL_MANAGER_SLOTS, ro = 0, dl = 0, qn = 0 }
for i = 1, Config.MINER_COUNT do
	playerState.sh[i] = { h = false, l = 0, o = 0 }
end
assert(Formulas.income(playerState) == 0, "unhired miners cannot produce")
playerState.sh[1] = { h = true, l = 1, o = 0 }
assert(Formulas.income(playerState) > 0 and Formulas.income(playerState) < 1, "starting income is gradual")
assert(Formulas.fmtRate(Formulas.income(playerState)) ~= "0", "fractional income must be visible")
for i = 1, Config.MINER_COUNT do
	playerState.sh[i] = { h = true, l = 1, o = 0 }
	local base = Formulas.production(playerState, i)
	local previous = base
	for level = 2, Config.MAX_MINER_LEVEL do
		playerState.sh[i].l = level
		local production = Formulas.production(playerState, i)
		assert(production > previous, "every upgrade improves production")
		assert(production / previous < 1.4, "milestone cannot cause a sudden doubling")
		assert(Formulas.upgradeCost(i, level) > 0, "upgrades have a positive price")
		previous = production
	end
	assert(previous / base < 1000, "late-level production stays bounded")
end
for _, sk in ipairs(Config.SKILLS) do
	playerState.sk[sk.id] = sk.max
end
local managers = table.clone(Config.MANAGERS)
table.sort(managers, function(a, b)
	return a.b > b.b
end)
for i = 1, Config.MAX_MANAGER_SLOTS do
	local g = managers[i]
	table.insert(playerState.eq, g.n)
	playerState.mg[g.n] = 1
	playerState.star[g.n] = Config.MAX_MANAGER_STARS
end
playerState.pr = Config.MAX_PRESTIGE_LEVEL
assert(Formulas.cashMult(playerState) < 30, "stacked bonuses stay controlled")
local normal = Formulas.cashMult(playerState)
Formulas.state.eventOn = true
assert(math.abs(Formulas.cashMult(playerState) / normal - 1.5) < 0.000001, "golden hour uses the advertised bonus")
Formulas.state.eventOn = false
local doublingSeconds = math.log(2) / math.log(1 + Formulas.depositRate(playerState)) * 10
assert(doublingSeconds > 3600, "bank cannot double money within an hour")
assert(Formulas.critChance(playerState) <= 0.15, "critical chance stays moderate")
local ev = 0
for i, r in ipairs(Config.RARITIES) do
	ev += r.w / 100 * Config.DUPLICATE_VALUES[i]
end
assert(ev < Config.Economy.ROLL_BASE, "selling random duplicates is not a money printer")
playerState.ro = 0
assert(Formulas.rollCost(playerState) == 0, "first manager stays free")
playerState.ro = 10000
assert(Formulas.rollCost(playerState) == Config.Economy.ROLL_MAXIMUM, "roll cost cannot overflow")
local q = Formulas.questFor(playerState, 1)
local old = { k = 1, goal = 100, prog = 50, rew = 999999999999 }
local migrated = Formulas.restoreQuest(playerState, old, nil)
assert(
	migrated.rew == q.rew and math.abs(migrated.prog / migrated.goal - 0.5) < 0.01,
	"quest migration preserves progress but recalculates old reward"
)
assert(Formulas.restoreQuest(playerState, old, Config.BALANCE_VERSION) == old, "current quests are preserved")
assert(Formulas.restoreQuest(playerState, { k = 1, goal = 0, prog = 0, rew = 5 }, nil) == nil, "invalid quests are rejected")
assert(Config.Economy.OFFLINE_SECONDS * Config.Economy.OFFLINE_FRACTION <= 600, "offline payout stays bounded")
local previous = 0
for i = 0, Config.MAX_PRESTIGE_LEVEL do
	playerState.pr = i
	local cost = Formulas.prestigeCost(playerState)
	assert(cost > previous and cost < math.huge)
	previous = cost
end
print("Economy: all regression checks passed")
