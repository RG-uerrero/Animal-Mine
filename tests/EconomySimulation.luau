-- Simulacion orientativa de un jugador activo; usa Config y Formulas reales.
local function simulate(seed, collectEvery, patience)
	math.randomseed(seed)
	local playerState = { sh = {}, sk = {}, mg = {}, eq = {}, star = {}, pr = 0, slots = Config.INITIAL_MANAGER_SLOTS, ro = 0, dl = 0, qn = 0 }
	for i = 1, Config.MINER_COUNT do
		playerState.sh[i] = { h = false, l = 0, o = 0 }
	end
	local cash = 30
	local milestones = {}
	local economy = Config.Economy or {}
	local function critFactor()
		return 1 + (economy.CRIT_BASE_CHANCE or 0.03) * (economy.CRIT_BONUS_SECONDS or 5) * 1.5
	end
	local function rate()
		return Formulas.income(playerState) * critFactor()
	end
	local function newQuest()
		local k = math.random(1, 3)
		if Formulas.questFor then
			playerState.q = Formulas.questFor(playerState, k)
			return
		end
		local inc = math.max(5, Formulas.income(playerState))
		local goal = k == 1 and math.max(300, math.floor(inc * 100))
			or (k == 2 and math.min(5, 1 + math.floor(playerState.qn / 4)) or 5 + math.min(25, playerState.qn * 2))
		playerState.q = { k = k, goal = goal, prog = 0, rew = math.max(250, math.floor(inc * 70)) }
	end
	local function quest(kind, n)
		if playerState.q.k ~= kind then
			return
		end
		playerState.q.prog += n
		if playerState.q.prog >= playerState.q.goal then
			cash += playerState.q.rew
			playerState.qn += 1
			newQuest()
		end
	end
	local function roll()
		local cost = Formulas.rollCost(playerState)
		if cash < cost then
			return false
		end
		cash -= cost
		playerState.ro += 1
		local r = math.random() * 100
		local rarity = 1
		for i, item in ipairs(Config.RARITIES) do
			r -= item.w
			if r <= 0 then
				rarity = i
				break
			end
		end
		local list = {}
		for _, g in ipairs(Config.MANAGERS) do
			if g.r == rarity then
				table.insert(list, g)
			end
		end
		local g = list[math.random(1, #list)]
		playerState.mg[g.n] = (playerState.mg[g.n] or 0) + 1
		if playerState.mg[g.n] >= 3 and (playerState.star[g.n] or 0) < Config.MAX_MANAGER_STARS then
			playerState.mg[g.n] -= 2
			playerState.star[g.n] = (playerState.star[g.n] or 0) + 1
		end
		local own = Formulas.owned(playerState)
		table.sort(own, function(a, b)
			return Formulas.managerBonus(playerState, a) > Formulas.managerBonus(playerState, b)
		end)
		playerState.eq = {}
		for i = 1, math.min(#own, playerState.slots) do
			table.insert(playerState.eq, own[i].n)
		end
		quest(2, 1)
		return true
	end
	newQuest()
	for time = 0, 14400 do
		local event = economy.EVENT_MULTIPLIER or 2
		Formulas.state.eventOn = time % 300 >= 120 and time % 300 < 180
		if playerState.ro == 0 or (time % 240 == 0 and Formulas.rollCost(playerState) <= cash * 0.15) then
			roll()
		end
		if time % 100 == 50 then
			cash += math.floor(math.max(economy.CHEST_MINIMUM or 500, Formulas.income(playerState) * (economy.CHEST_INCOME_SECONDS or 45)))
		end
		for i, sh in ipairs(playerState.sh) do
			if sh.h then
				sh.o = math.min(Formulas.cartCapacity(playerState, i), sh.o + Formulas.production(playerState, i) * critFactor())
			end
		end
		if time % collectEvery == 0 then
			local collected = 0
			for _, sh in ipairs(playerState.sh) do
				if sh.h then
					collected += math.floor(sh.o * Formulas.cashMult(playerState))
					sh.o = 0
				end
			end
			cash += collected
			quest(1, collected)
		end
		local all = true
		for _, sh in ipairs(playerState.sh) do
			if not sh.h then
				all = false
				break
			end
		end
		if all and cash >= Formulas.prestigeCost(playerState) then
			return { seconds = time, hires = milestones, cash = math.floor(cash), income = math.floor(Formulas.income(playerState)), rolls = playerState.ro }
		end
		for purchase = 1, 2 do
			local current = rate()
			local best
			local function consider(cost, delta, kind, index)
				if delta <= 0 then
					return
				end
				local score = cost / delta + patience * math.max(0, cost - cash) / math.max(current, 0.1)
				if not best or score < best.score then
					best = { cost = cost, score = score, kind = kind, index = index }
				end
			end
			for i, sh in ipairs(playerState.sh) do
				if not sh.h and (i == 1 or playerState.sh[i - 1].h) then
					sh.h = true
					sh.l = 1
					local delta = rate() - current
					sh.h = false
					sh.l = 0
					consider(Config.MINERS[i].h, delta, "hire", i)
				elseif sh.h and sh.l < Config.MAX_MINER_LEVEL then
					local cost = Formulas.upgradeCost(i, sh.l)
					sh.l += 1
					local delta = rate() - current
					sh.l -= 1
					consider(cost, delta, "up", i)
				end
			end
			for i, sk in ipairs(Config.SKILLS) do
				if sk.id == "pico" or sk.id == "neg" then
					local lv = playerState.sk[sk.id] or 0
					if lv < sk.max then
						playerState.sk[sk.id] = lv + 1
						local delta = rate() - current
						playerState.sk[sk.id] = lv
						consider(Formulas.skillCost(sk, lv), delta, "skill", i)
					end
				end
			end
			if not best or cash < best.cost then
				break
			end
			cash -= best.cost
			if best.kind == "hire" then
				playerState.sh[best.index].h = true
				playerState.sh[best.index].l = 1
				milestones[best.index] = time
			elseif best.kind == "up" then
				playerState.sh[best.index].l += 1
				quest(3, 1)
			else
				local id = Config.SKILLS[best.index].id
				playerState.sk[id] = (playerState.sk[id] or 0) + 1
			end
		end
	end
	return { seconds = 14400, hires = milestones, cash = math.floor(cash), income = math.floor(Formulas.income(playerState)), incomplete = true }
end
local runs = {}
for _, patience in ipairs({ 0.25, 1, 3 }) do
	for _, seed in ipairs({ 1, 7, 42 }) do
		local result = simulate(seed, collectEvery or 10, patience)
		table.insert(runs, result.seconds)
		local times = {}
		for i = 1, Config.MINER_COUNT do
			times[i] = result.hires[i] and string.format("%.1f", result.hires[i] / 60) or "--"
		end
		print(
			string.format(
				"policy %.2f seed %d: %.1f min; hires=[%s]; income=%d; incomplete=%s",
				patience,
				seed,
				result.seconds / 60,
				table.concat(times, ", "),
				result.income,
				tostring(result.incomplete or false)
			)
		)
	end
end
Formulas.state.eventOn = false
table.sort(runs)
print("MEDIAN_MINUTES",runs[math.ceil(#runs/2)]/60)
return runs
