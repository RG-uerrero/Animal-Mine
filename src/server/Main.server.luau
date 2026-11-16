-- MINA ANIMAL v2: script principal (src/server/Main.server.luau)
-- Modulos: shared/Config + shared/Formulas | server/Builders + World + DataService | client/Hud.client
local Players = game:GetService("Players")
local Workspace = workspace
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local ECONOMY = Config.Economy
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local DataService = require(script.Parent.DataService)
local SPHERE_SHAPE = Enum.PartType.Ball
local vector3 = Vector3.new
local color3 = Color3.fromRGB
local gameRandom = Random.new() -- aleatorio del juego (rodar gerentes, criticos, cofres)
local MINER_COUNT, MAX_MINER_LEVEL, GROUND_HEIGHT, MAX_DEPOSIT_LEVEL =
	Config.MINER_COUNT, Config.MAX_MINER_LEVEL, Config.GROUND_HEIGHT, Config.MAX_DEPOSIT_LEVEL
local INITIAL_MANAGER_SLOTS, MAX_MANAGER_SLOTS, MAX_MANAGER_STARS, MAX_PRESTIGE_LEVEL =
	Config.INITIAL_MANAGER_SLOTS, Config.MAX_MANAGER_SLOTS, Config.MAX_MANAGER_STARS, Config.MAX_PRESTIGE_LEVEL

local WorldLighting = require(script.Parent.Components.WorldLighting)
WorldLighting.apply()

local Builders = require(script.Parent.Builders)
local World = require(script.Parent.World)
local createPart, createCylinder, label, pop =
	Builders.createPart, Builders.createCylinder, Builders.label, Builders.pop
local DARK_WOOD = Builders.DARK_WOOD
local formatNumber = Formulas.formatNumber

-- DATOS (vienen de shared/Config.luau)
local RARITIES, DUPLICATE_VALUES, TIER_COLORS, MINERS, MANAGERS, MANAGERS_BY_NAME, SKILLS =
	Config.RARITIES,
	Config.DUPLICATE_VALUES,
	Config.TIER_COLORS,
	Config.MINERS,
	Config.MANAGERS,
	Config.MANAGERS_BY_NAME,
	Config.SKILLS

local plots = {}
local playerStates = {}
local joined = {}
local closing = false
local loading = 0
local eventState = { on = false, left = 0 }
local effects = {}
local INVENTORY_ACTION_NAMES = { "ANTERIOR", "SIGUIENTE", "EQUIPAR", "VENDER COPIA", "FUSIONAR", "MAS ESPACIOS" }

-- FORMULAS (vienen de shared/Formulas.luau)
local skillCost, owned, isEquipped, managerBonus =
	Formulas.skillCost, Formulas.owned, Formulas.isEquipped, Formulas.managerBonus
local totalManagerBonus, managerCount, cashMult, production =
	Formulas.totalManagerBonus, Formulas.managerCount, Formulas.cashMult, Formulas.production
local cartCapacity, upgradeCost, rollCost, income =
	Formulas.cartCapacity, Formulas.upgradeCost, Formulas.rollCost, Formulas.income
local depositCapacity, depositUpgradeCost, depositRate, slotCost, prestigeCost =
	Formulas.depositCapacity,
	Formulas.depositUpgradeCost,
	Formulas.depositRate,
	Formulas.slotCost,
	Formulas.prestigeCost

-- Describe el bono real de un gerente para mostrarlo en la interfaz.

local function managerBenefit(playerState, g)
	return "+" .. string.format("%g", managerBonus(playerState, g) * 100) .. "% al recoger mineral"
end

-- Obtiene el saldo autoritativo del jugador; las compras se validan con este valor.

local function getMoney(p)
	local s = p:FindFirstChild("leaderstats")
	return s and s:FindFirstChild("Dinero")
end

-- COMUNICACION CON EL CLIENTE (el HUD lo dibuja src/client/Hud.client.luau)
local notifyEvent = Instance.new("RemoteEvent")
notifyEvent.Name = "Notify"
notifyEvent.Parent = ReplicatedStorage
local hudReadyEvent = Instance.new("RemoteEvent")
hudReadyEvent.Name = "HudReady"
hudReadyEvent.Parent = ReplicatedStorage
local readyEarly = {}

-- mensaje en pantalla; si el HUD del jugador aun no esta listo, se guarda en cola
local function tell(p, txt)
	local playerState = playerStates[p]
	if not playerState then
		return
	end
	if playerState.hudReady then
		notifyEvent:FireClient(p, txt)
	else
		table.insert(playerState.queue, txt)
		if #playerState.queue > 5 then
			table.remove(playerState.queue, 1)
		end
	end
end
local function tellAll(txt)
	for _, p in ipairs(Players:GetPlayers()) do
		tell(p, txt)
	end
end

-- el cliente avisa cuando su HUD esta listo: se envian los mensajes en cola
hudReadyEvent.OnServerEvent:Connect(function(p)
	local playerState = playerStates[p]
	if not playerState then
		readyEarly[p] = true
		return
	end
	playerState.hudReady = true
	for _, m in ipairs(playerState.queue) do
		notifyEvent:FireClient(p, m)
	end
	playerState.queue = {}
	playerState.ui()
end)

-- Comprueba que la sesion esta lista y permite acciones de juego.

local function playable(p)
	local playerState = playerStates[p]
	return playerState and playerState.ready and not playerState.leaving and not closing
end

-- Envuelve acciones para bloquear peticiones durante carga, salida o cierre.
local function guarded(fn)
	return function(p, ...)
		if not playable(p) then
			return
		end
		return fn(p, ...)
	end
end
local prestigeEvent = Instance.new("RemoteEvent")
prestigeEvent.Name = "PrestigeConfirm"
prestigeEvent.Parent = ReplicatedStorage

-- Comprueba requisitos y abre una confirmacion temporal antes del renacimiento.
local function requestPrestige(p)
	if not playable(p) then
		return
	end
	local playerState = playerStates[p]
	if not playerState.plot then
		return
	end
	if playerState.pr >= MAX_PRESTIGE_LEVEL then
		tell(p, "Ya alcanzaste el maximo de renacimientos.")
		return
	end
	for i = 1, MINER_COUNT do
		if not playerState.sh[i].h then
			tell(p, "Para renacer necesitas los 6 mineros contratados.")
			return
		end
	end
	local d = getMoney(p)
	if not d or d.Value < prestigeCost(playerState) then
		tell(p, "Necesitas $" .. formatNumber(prestigeCost(playerState)) .. " para renacer.")
		return
	end
	local token = game:GetService("HttpService"):GenerateGUID(false)
	playerState.confirm = { token = token, expires = os.clock() + 15 }
	prestigeEvent:FireClient(p, token, prestigeCost(playerState))
end
-- EFECTOS
function effects.ring(pos, col, maxs, dur)
	local r = createPart("Onda", vector3(0.4, 2, 2), pos, col, Enum.Material.Neon, Enum.PartType.Cylinder)
	r.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	r.CanCollide = false
	r.CastShadow = false
	r.Transparency = 0.2
	TweenService:Create(
		r,
		TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = vector3(0.4, maxs, maxs), Transparency = 1 }
	):Play()
	Debris:AddItem(r, dur + 0.2)
end
function effects.burst(pos, col, n)
	local a = createPart("Chispas", vector3(1, 1, 1), pos, col)
	a.Transparency = 1
	a.CanCollide = false
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(col)
	pe.Rate = 0
	pe.Lifetime = NumberRange.new(0.6, 1.3)
	pe.Speed = NumberRange.new(14, 30)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
	pe.LightEmission = 1
	pe.Acceleration = vector3(0, -25, 0)
	pe.Parent = a
	pe:Emit(n)
	Debris:AddItem(a, 2)
end
function effects.beam(pos, col, dur)
	local b =
		createPart("Rayo", vector3(90, 6, 6), pos + vector3(0, 45, 0), col, Enum.Material.Neon, Enum.PartType.Cylinder)
	b.CFrame = CFrame.new(pos + vector3(0, 45, 0)) * CFrame.Angles(0, 0, math.rad(90))
	b.CanCollide = false
	b.CastShadow = false
	b.Transparency = 0.35
	TweenService:Create(b, TweenInfo.new(dur), { Size = vector3(90, 0.5, 0.5), Transparency = 1 }):Play()
	Debris:AddItem(b, dur + 0.2)
end
function effects.shake(p, dur, mag)
	local ch = p.Character
	local h = ch and ch:FindFirstChildOfClass("Humanoid")
	if not h then
		return
	end
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < dur do
			local k = 1 - (os.clock() - t0) / dur
			h.CameraOffset = vector3(gameRandom:NextNumber(-1, 1) * mag * k, gameRandom:NextNumber(-1, 1) * mag * k, 0)
			task.wait()
		end
		h.CameraOffset = vector3(0, 0, 0)
	end)
end
function effects.coin(p, pos, n)
	local ch = p.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	for k = 1, n do
		local c = createCylinder(
			"Moneda",
			0.25,
			1.4,
			pos + vector3(gameRandom:NextNumber(-2, 2), gameRandom:NextNumber(0, 2), gameRandom:NextNumber(-2, 2)),
			color3(255, 215, 60),
			Enum.Material.Neon
		)
		c.CanCollide = false
		c.CastShadow = false
		TweenService:Create(
			c,
			TweenInfo.new(0.4 + k * 0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = hrp.Position + vector3(0, 1, 0), Transparency = 1 }
		):Play()
		Debris:AddItem(c, 1.2)
	end
end
function effects.up(plot, i, lvl, p)
	local pos = vector3(plot.cx - 25 + (i - 1) * 10, GROUND_HEIGHT + 1, plot.cz - 36)
	local col = TIER_COLORS[i]
	effects.ring(pos, col, 14, 0.5)
	effects.burst(pos + vector3(0, 5, 0), col, 16)
	pop(plot.v[i].pad, "NIVEL " .. lvl, col)
	if lvl % 10 == 0 then
		effects.beam(pos, col, 0.8)
		effects.ring(pos, color3(255, 255, 255), 26, 0.8)
		effects.burst(pos + vector3(0, 6, 0), color3(255, 230, 120), 40)
		if p then
			effects.shake(p, 0.35, 0.5)
		end
	end
end

-- MISIONES

-- Genera la siguiente mision con objetivos y premios del balance actual.
local function newQuest(playerState)
	playerState.q = Formulas.questFor(playerState, gameRandom:NextInteger(1, 3))
end

-- Convierte el progreso de la mision en texto para el HUD.
local function questText(playerState)
	local q = playerState.q
	if not q then
		return ""
	end
	local a =
		{ "Recoge $" .. formatNumber(q.goal), "Rueda " .. q.goal .. " gerente(s)", "Mejora " .. q.goal .. " veces" }
	return "MISION: "
		.. a[q.k]
		.. "\n"
		.. formatNumber(q.prog)
		.. " / "
		.. formatNumber(q.goal)
		.. "   Premio $"
		.. formatNumber(q.rew)
end

-- Acumula progreso y entrega el premio al completar una mision.
local function addQuestProgress(p, kind, n)
	local playerState = playerStates[p]
	if not playerState or not playerState.q then
		return
	end
	local k = ({ earn = 1, roll = 2, up = 3 })[kind]
	if playerState.q.k ~= k then
		return
	end
	playerState.q.prog = playerState.q.prog + n
	if playerState.q.prog >= playerState.q.goal then
		local rew = playerState.q.rew
		local d = getMoney(p)
		if d then
			d.Value = d.Value + rew
		end
		playerState.qn = playerState.qn + 1
		newQuest(playerState)
		tell(p, "MISION COMPLETA! +$" .. formatNumber(rew))
		local ch = p.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		if hrp then
			effects.burst(hrp.Position, color3(255, 225, 90), 30)
		end
	end
end

-- ANIMALES: los modelos conservan el mismo pivote para las animaciones.
local animal = require(script.Parent.AnimalModels).build

-- PICO NUEVO: el mango va en vertical y la cabeza va a lo largo del eje Z
-- (el mismo plano del golpe), asi al balancearlo hacia adelante la punta pega en la roca
local function pickaxe()
	local pk = Instance.new("Model")
	local function part(n, s, cf2, c, mat)
		local p = Instance.new("Part")
		p.Name = n
		p.Size = s
		p.Anchored = true
		p.CanCollide = false
		p.CastShadow = false
		p.Color = c
		p.Material = mat
		p.CFrame = cf2
		p.Parent = pk
		return p
	end
	local hd = part("Mango", vector3(0.38, 3.4, 0.38), CFrame.new(0, 0, 0), DARK_WOOD, Enum.Material.Wood)
	part("Agarre", vector3(0.46, 0.9, 0.46), CFrame.new(0, -1.1, 0), color3(60, 45, 40), Enum.Material.Fabric)
	part("Cabeza", vector3(0.5, 0.5, 3.0), CFrame.new(0, 1.55, 0), color3(150, 155, 170), Enum.Material.Metal)
	part("Aro", vector3(0.7, 0.7, 0.7), CFrame.new(0, 1.55, 0), color3(80, 82, 90), Enum.Material.DiamondPlate)
	local tip
	for _, s in ipairs({ -1, 1 }) do
		local f = part(
			"Filo",
			vector3(0.4, 0.4, 1.0),
			CFrame.new(0, 1.4, s * 1.75) * CFrame.Angles(-s * 0.6, 0, 0),
			color3(215, 220, 235),
			Enum.Material.Metal
		)
		if s == -1 then
			tip = f
		end
	end
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 0
	pe.Color = ColorSequence.new(color3(255, 220, 120))
	pe.Lifetime = NumberRange.new(0.25, 0.5)
	pe.Speed = NumberRange.new(8, 16)
	pe.SpreadAngle = Vector2.new(90, 90)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
	pe.LightEmission = 1
	pe.Acceleration = vector3(0, -30, 0)
	pe.Parent = tip
	pk.PrimaryPart = hd
	pk.Parent = Workspace
	return pk, tip
end

-- ACTUALIZAR TEXTOS

-- Actualiza nombre, precio, nivel y mineral visible de un puesto minero.
local function updateMinerLabel(plot, i)
	local v = plot.v[i]
	local p = plot.owner
	local playerState = p and playerStates[p]
	local sh = playerState and playerState.sh[i]
	if not sh or not sh.h then
		v.btnLbl.Text = "Minero " .. i .. "\n" .. MINERS[i].n .. "\nContratar $" .. formatNumber(MINERS[i].h)
		v.cartLbl.Text = ""
		if v.lbl then
			v.lbl.Text = ""
		end
	else
		if sh.l >= MAX_MINER_LEVEL then
			v.btnLbl.Text = "Nivel " .. sh.l .. "\n" .. MINERS[i].n .. "\nMAXIMO"
		else
			v.btnLbl.Text = "Nivel "
				.. sh.l
				.. "\n"
				.. MINERS[i].n
				.. "\nMejorar $"
				.. formatNumber(upgradeCost(i, sh.l))
		end
		if v.lbl then
			v.lbl.Text = "Nivel " .. sh.l .. "\n" .. MINERS[i].n
		end
	end
end

-- Actualiza el precio de la ruleta segun el propietario de la parcela.

local function updateRollLabel(plot)
	local p = plot.owner
	local playerState = p and playerStates[p]
	plot.rollLbl.TextColor3 = Color3.new(1, 1, 1)
	if playerState then
		plot.rollLbl.Text = "RODAR GERENTE\n"
			.. (playerState.ro == 0 and "GRATIS" or "$" .. formatNumber(rollCost(playerState)))
	else
		plot.rollLbl.Text = "RODAR GERENTE"
	end
end

-- Muestra saldo, capacidad y coste de ampliacion del banco.

local function updateDepositLabel(plot)
	local p = plot.owner
	local playerState = p and playerStates[p]
	if not playerState then
		plot.depLbl.Text = "DEPOSITO"
		plot.dlbl[1].Text = "DEPOSITAR"
		plot.dlbl[2].Text = "RETIRAR"
		plot.dlbl[3].Text = "AMPLIAR"
		return
	end
	plot.depLbl.Text = "DEPOSITO (Nv "
		.. playerState.dl
		.. ")\n$"
		.. formatNumber(playerState.dep)
		.. " / $"
		.. formatNumber(depositCapacity(playerState))
		.. "\nInteres "
		.. string.format("%.2f", depositRate(playerState) * 100)
		.. "% cada 10s"
	plot.dlbl[1].Text = "DEPOSITAR\nTodo tu dinero"
	plot.dlbl[2].Text = "RETIRAR\n$" .. formatNumber(playerState.dep)
	if playerState.dl >= MAX_DEPOSIT_LEVEL then
		plot.dlbl[3].Text = "AMPLIAR\nMAXIMO"
	else
		plot.dlbl[3].Text = "AMPLIAR\n$" .. formatNumber(depositUpgradeCost(playerState))
	end
end

-- ESTABLO (inventario de gerentes)

-- Muestra el gerente seleccionado y las acciones disponibles para sus copias.
local function updateInventoryLabels(plot)
	if plot.invModel then
		plot.invModel:Destroy()
		plot.invModel = nil
	end
	local p = plot.owner
	local playerState = p and playerStates[p]
	local lb = plot.invLbl
	lb.TextColor3 = Color3.new(1, 1, 1)
	for k = 1, 6 do
		plot.ilbl[k].Text = INVENTORY_ACTION_NAMES[k]
	end
	if not playerState then
		lb.Text = "ESTABLO"
		return
	end
	local l = owned(playerState)
	if #l == 0 then
		lb.Text = "ESTABLO\nAun no tienes gerentes.\nRueda uno en la plataforma!"
		return
	end
	playerState.ix = math.clamp(playerState.ix, 1, #l)
	local g = l[playerState.ix]
	local c = playerState.mg[g.n]
	local sr2 = playerState.star[g.n] or 0
	local eq = isEquipped(playerState, g.n)
	lb.TextColor3 = RARITIES[g.r].c
	lb.Text = g.n
		.. "  ("
		.. playerState.ix
		.. "/"
		.. #l
		.. ")\n"
		.. RARITIES[g.r].n
		.. "  x"
		.. c
		.. "  "
		.. string.rep("*", sr2)
		.. "\n"
		.. managerBenefit(playerState, g)
		.. "\n"
		.. (eq and "EQUIPADO" or "en el establo")
		.. "   Slots "
		.. #playerState.eq
		.. "/"
		.. playerState.slots
	plot.ilbl[3].Text = eq and "QUITAR" or "EQUIPAR"
	plot.ilbl[4].Text = (c > 1) and ("VENDER\n$" .. formatNumber(Formulas.sellValue(playerState, g)))
		or "VENDER\n(sin copias)"
	plot.ilbl[5].Text = (sr2 >= MAX_MANAGER_STARS) and "FUSION\nMAXIMA"
		or ((c >= 3) and "FUSIONAR\n+1 estrella" or "FUSIONAR\n(3 copias)")
	plot.ilbl[6].Text = (playerState.slots >= MAX_MANAGER_SLOTS) and "SLOTS\nMAXIMO"
		or ("ESPACIO+\n$" .. formatNumber(slotCost(playerState)))
	local m =
		animal(plot.invCF, g.a, g.c, g.k, { tie = true, name = g.n, aura = (g.r >= 3) and RARITIES[g.r].c or nil })
	m.Parent = plot.managersModel
	plot.invModel = m
end

-- MINEROS

-- Aplica la pose del animal y del pico durante la animacion.
local function place(v, yo, lean, rot, a)
	local cfm = v.cf * CFrame.new(0, yo, 0) * CFrame.Angles(lean, rot, 0)
	v.model:PivotTo(cfm * CFrame.new(0, 1.9, 0))
	if v.pk then
		v.pk:PivotTo(cfm * CFrame.new(v.grip or vector3(1.9, 3, -1.4)) * CFrame.Angles(a, 0, 0) * CFrame.new(0, 1.1, 0))
	end
end

-- Retira el modelo y las referencias visuales de un minero.

local function despawn(plot, i)
	local v = plot.v[i]
	v.anim = false
	if v.model then
		v.model:Destroy()
		v.model = nil
	end
	if v.pk then
		v.pk:Destroy()
		v.pk = nil
	end
	v.tip = nil
	v.tipPE = nil
	v.lbl = nil
	v.mound.Size = vector3(4.5, 2, 3.4)
end

-- Crea el animal y su pico en el puesto de trabajo correspondiente.

local function spawnMiner(plot, i, anim)
	local v = plot.v[i]
	if v.model then
		return
	end
	local x = plot.cx - 25 + (i - 1) * 10
	local d = MINERS[i]
	local cf = CFrame.new(x, GROUND_HEIGHT, plot.cz - 36)
	local m, body = animal(cf, d.a, d.c, d.k, { helmet = true, name = d.n })
	m.Parent = v.containerModel
	v.model = m
	v.grip = m:GetAttribute("ToolGrip")
	v.cf = cf
	v.ph = 0
	v.pk, v.tip = pickaxe()
	v.pk.Parent = v.containerModel
	v.tipPE = v.tip:FindFirstChildOfClass("ParticleEmitter")
	v.work = true
	-- Nombre y nivel se muestran una sola vez, sobre el boton.
	v.lbl = nil
	if not anim then
		place(v, 0, 0, 0, 0.3)
		return
	end
	-- ANIMACION DE CONTRATACION: cae del cielo girando con un rayo de luz
	v.anim = true
	place(v, 45, 0, 0, 0.3)
	local pos = vector3(x, GROUND_HEIGHT + 0.3, plot.cz - 36)
	effects.beam(pos, TIER_COLORS[i], 1.4)
	local nl = label(body, "Nuevo: " .. d.n, 8, 164, 38, 26, "feedback")
	nl.TextColor3 = TIER_COLORS[i]
	Debris:AddItem(nl.Parent, 2.6)
	task.spawn(function()
		local t0 = os.clock()
		while true do
			local u = (os.clock() - t0) / 0.8
			if v.model ~= m then
				return
			end
			if u >= 1 then
				break
			end
			place(v, 45 * (1 - u * u), 0, u * 4 * math.pi, 0.3)
			task.wait()
		end
		if v.model ~= m then
			return
		end
		place(v, 0, 0, 0, 0.3)
		effects.ring(pos, TIER_COLORS[i], 18, 0.6)
		task.delay(0.15, function()
			effects.ring(pos, color3(255, 255, 255), 26, 0.8)
		end)
		effects.burst(pos + vector3(0, 4, 0), TIER_COLORS[i], 40)
		effects.burst(pos + vector3(0, 4, 0), color3(255, 235, 140), 25)
		if plot.owner then
			effects.shake(plot.owner, 0.4, 0.6)
		end
		for k = 1, 2 do
			local hgt = 3.5 / k
			local t1 = os.clock()
			while true do
				local u = (os.clock() - t1) / 0.28
				if u >= 1 then
					break
				end
				if v.model ~= m then
					return
				end
				place(v, hgt * math.sin(u * math.pi), 0, 0, 0.3)
				task.wait()
			end
		end
		if v.model then
			place(v, 0, 0, 0, 0.3)
		end
		v.anim = false
	end)
end

-- Transfiere mineral de la vagoneta al saldo y actualiza la mision.

local function collect(p, i, manual)
	local playerState = playerStates[p]
	if not playerState or not playerState.plot then
		return 0
	end
	local sh = playerState.sh[i]
	if not sh.h or sh.o < 1 then
		return 0
	end
	local amt = math.floor(sh.o * cashMult(playerState))
	sh.o = 0
	local d = getMoney(p)
	if d then
		d.Value = d.Value + amt
	end
	local pad = playerState.plot.v[i].pad
	pop(pad, "+$" .. formatNumber(amt))
	if manual then
		effects.coin(p, pad.Position, 5)
	end
	playerState.coll = true
	playerState.tot = playerState.tot + amt
	addQuestProgress(p, "earn", amt)
	return amt
end

-- Contrata o mejora al minero tras comprobar propietario, saldo y nivel.

local function pressBtn(p, plot, i)
	if plot.owner ~= p then
		return
	end
	local playerState = playerStates[p]
	local d = getMoney(p)
	if not playerState or not d then
		return
	end
	local sh = playerState.sh[i]
	if not sh.h then
		if i > 1 and not playerState.sh[i - 1].h then
			tell(p, "Primero contrata al minero anterior.")
			return
		end
		local c = MINERS[i].h
		if d.Value < c then
			tell(p, "Te faltan $" .. formatNumber(c - d.Value) .. " para contratar a " .. MINERS[i].n .. ".")
			return
		end
		d.Value = d.Value - c
		sh.h = true
		sh.l = 1
		sh.o = 0
		spawnMiner(plot, i, true)
		tell(p, "Contrataste a " .. MINERS[i].n .. "! Ya esta picando.")
	else
		if sh.l >= MAX_MINER_LEVEL then
			tell(p, "Este minero ya esta al maximo.")
			return
		end
		local c = upgradeCost(i, sh.l)
		if d.Value < c then
			tell(p, "Te faltan $" .. formatNumber(c - d.Value) .. " para mejorar.")
			return
		end
		d.Value = d.Value - c
		sh.l = sh.l + 1
		tell(p, MINERS[i].n .. " subio al nivel " .. sh.l .. "!")
		effects.up(plot, i, sh.l, p)
		addQuestProgress(p, "up", 1)
	end
	updateMinerLabel(plot, i)
	playerState.ui()
end

-- DEPOSITO

-- Mueve dinero al banco hasta alcanzar su capacidad.
local function depositAll(p, plot)
	if plot.owner ~= p then
		return
	end
	local playerState = playerStates[p]
	local d = getMoney(p)
	if not playerState or not d then
		return
	end
	local room = math.floor(depositCapacity(playerState) - playerState.dep)
	if room < 1 then
		tell(p, "Tu deposito esta lleno. Ampliarlo te deja guardar mas.")
		return
	end
	local amt = math.min(math.floor(d.Value), room)
	if amt < 1 then
		tell(p, "No tienes dinero para depositar.")
		return
	end
	d.Value = d.Value - amt
	playerState.dep = playerState.dep + amt
	pop(plot.dPad[1], "-$" .. formatNumber(amt), color3(255, 200, 120))
	tell(
		p,
		"Depositaste $"
			.. formatNumber(amt)
			.. ". Gana "
			.. string.format("%.2f", depositRate(playerState) * 100)
			.. "% de interes cada 10 segundos."
	)
	updateDepositLabel(plot)
	playerState.ui()
end

-- Devuelve el saldo del banco al dinero disponible.

local function withdrawAll(p, plot)
	if plot.owner ~= p then
		return
	end
	local playerState = playerStates[p]
	local d = getMoney(p)
	if not playerState or not d then
		return
	end
	local amt = math.floor(playerState.dep)
	if amt < 1 then
		tell(p, "No tienes dinero en el deposito.")
		return
	end
	playerState.dep = playerState.dep - amt
	d.Value = d.Value + amt
	pop(plot.dPad[2], "+$" .. formatNumber(amt))
	effects.coin(p, plot.dPad[2].Position, 5)
	tell(p, "Retiraste $" .. formatNumber(amt) .. " del deposito.")
	updateDepositLabel(plot)
	playerState.ui()
end

-- Cobra la ampliacion y aumenta el nivel del deposito.

local function upgradeDeposit(p, plot)
	if plot.owner ~= p then
		return
	end
	local playerState = playerStates[p]
	local d = getMoney(p)
	if not playerState or not d then
		return
	end
	if playerState.dl >= MAX_DEPOSIT_LEVEL then
		tell(p, "Tu deposito ya esta al maximo.")
		return
	end
	local c = depositUpgradeCost(playerState)
	if d.Value < c then
		tell(p, "Te faltan $" .. formatNumber(c - d.Value) .. " para ampliar el deposito.")
		return
	end
	d.Value = d.Value - c
	playerState.dl = playerState.dl + 1
	tell(
		p,
		"Deposito nivel "
			.. playerState.dl
			.. "! Ahora guarda hasta $"
			.. formatNumber(depositCapacity(playerState))
			.. "."
	)
	effects.ring(plot.dPad[3].Position + vector3(0, 1, 0), color3(235, 185, 60), 14, 0.6)
	updateDepositLabel(plot)
	playerState.ui()
end

-- ACCIONES DEL ESTABLO

-- Resuelve el gerente seleccionado dentro del inventario del jugador.
local function selectedManager(playerState)
	local l = owned(playerState)
	if #l == 0 then
		return nil, l
	end
	playerState.ix = math.clamp(playerState.ix, 1, #l)
	return l[playerState.ix], l
end

-- Crea la accion de recorrer el inventario en una direccion.
local function navigateInventory(d2)
	return function(p, plot)
		if plot.owner ~= p then
			return
		end
		local playerState = playerStates[p]
		if not playerState then
			return
		end
		local g, l = selectedManager(playerState)
		if not g then
			tell(p, "Aun no tienes gerentes. Rueda uno!")
			return
		end
		playerState.ix = (playerState.ix - 1 + d2) % #l + 1
		updateInventoryLabels(plot)
	end
end

-- Alterna el gerente equipado respetando el limite de espacios.
local function equipManager(p, plot)
	if plot.owner ~= p then
		return
	end
	local playerState = playerStates[p]
	if not playerState then
		return
	end
	local g = selectedManager(playerState)
	if not g then
		tell(p, "Aun no tienes gerentes. Rueda uno!")
		return
	end
	if isEquipped(playerState, g.n) then
		for k, n in ipairs(playerState.eq) do
			if n == g.n then
				table.remove(playerState.eq, k)
				break
			end
		end
		tell(p, g.n .. " se fue al establo.")
	else
		if #playerState.eq >= playerState.slots then
			tell(p, "Todos tus slots estan llenos. Quita uno o compra mas slots.")
			return
		end
		table.insert(playerState.eq, g.n)
		tell(p, g.n .. " equipado: " .. managerBenefit(playerState, g) .. ".")
		effects.burst(plot.invCF.Position + vector3(0, 4, 0), RARITIES[g.r].c, 20)
	end
	updateInventoryLabels(plot)
	playerState.ui()
end

-- Vende una copia repetida y calcula su recompensa.
local function sellManagerCopy(p, plot)
	if plot.owner ~= p then
		return
	end
	local playerState = playerStates[p]
	local d = getMoney(p)
	if not playerState or not d then
		return
	end
	local g = selectedManager(playerState)
	if not g then
		return
	end
	local c = playerState.mg[g.n]
	if c <= 1 then
		tell(p, "No tienes copias repetidas de " .. g.n .. ".")
		return
	end
	local price = Formulas.sellValue(playerState, g)
	playerState.mg[g.n] = c - 1
	d.Value = d.Value + price
	effects.coin(p, plot.invCF.Position + vector3(0, 3, 0), 6)
	tell(p, "Vendiste una copia de " .. g.n .. " por $" .. formatNumber(price) .. ".")
	updateInventoryLabels(plot)
	playerState.ui()
end

-- Consume copias para aumentar las estrellas del gerente.
local function fuseManager(p, plot)
	if plot.owner ~= p then
		return
	end
	local playerState = playerStates[p]
	if not playerState then
		return
	end
	local g = selectedManager(playerState)
	if not g then
		return
	end
	local c = playerState.mg[g.n]
	local sr2 = playerState.star[g.n] or 0
	if sr2 >= MAX_MANAGER_STARS then
		tell(p, g.n .. " ya tiene el maximo de estrellas.")
		return
	end
	if c < 3 then
		tell(p, "Necesitas 3 copias de " .. g.n .. ": se gastan 2 y ganas 1 estrella.")
		return
	end
	playerState.mg[g.n] = c - 2
	playerState.star[g.n] = sr2 + 1
	effects.ring(plot.invCF.Position + vector3(0, 1, 0), color3(190, 100, 255), 16, 0.7)
	effects.burst(plot.invCF.Position + vector3(0, 5, 0), color3(255, 230, 120), 35)
	tell(
		p,
		g.n
			.. " subio a "
			.. (sr2 + 1)
			.. " estrella(s)! Cada estrella suma +"
			.. string.format("%g", ECONOMY.MANAGER_STAR_BONUS * 100)
			.. "% de su bono base."
	)
	updateInventoryLabels(plot)
	playerState.ui()
end

-- Compra un espacio adicional para equipar gerentes.
local function buyManagerSlot(p, plot)
	if plot.owner ~= p then
		return
	end
	local playerState = playerStates[p]
	local d = getMoney(p)
	if not playerState or not d then
		return
	end
	if playerState.slots >= MAX_MANAGER_SLOTS then
		tell(p, "Ya tienes el maximo de slots.")
		return
	end
	local c = slotCost(playerState)
	if d.Value < c then
		tell(p, "Te faltan $" .. formatNumber(c - d.Value) .. " para un slot nuevo.")
		return
	end
	d.Value = d.Value - c
	playerState.slots = playerState.slots + 1
	tell(p, "Nuevo slot de gerente! Ahora puedes equipar " .. playerState.slots .. ".")
	effects.ring(plot.invCF.Position + vector3(0, 1, 0), color3(235, 185, 60), 14, 0.6)
	updateInventoryLabels(plot)
	playerState.ui()
end

-- RENACER

-- Aplica el renacimiento y reconstruye el progreso que corresponde reiniciar.
local function doPrestige(p)
	local playerState = playerStates[p]
	local d = getMoney(p)
	if not playerState or not d or not playerState.plot then
		return
	end
	if playerState.pr >= MAX_PRESTIGE_LEVEL then
		tell(p, "Ya alcanzaste el maximo de renacimientos!")
		return
	end
	for i = 1, MINER_COUNT do
		if not playerState.sh[i].h then
			tell(p, "Para renacer necesitas a los 6 mineros contratados.")
			return
		end
	end
	local c = prestigeCost(playerState)
	if d.Value < c then
		tell(p, "Para renacer necesitas $" .. formatNumber(c) .. ". Te faltan $" .. formatNumber(c - d.Value) .. ".")
		return
	end
	local plot = playerState.plot
	for i = 1, MINER_COUNT do
		despawn(plot, i)
		playerState.sh[i] = { h = false, l = 0, o = 0 }
		updateMinerLabel(plot, i)
	end
	playerState.pr = playerState.pr + 1
	playerState.dep = 0
	playerState.tmr = 0
	d.Value = 30
	local rb = p:FindFirstChild("leaderstats") and p.leaderstats:FindFirstChild("Renacer")
	if rb then
		rb.Value = playerState.pr
	end
	newQuest(playerState)
	local ch = p.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if hrp then
		effects.beam(hrp.Position, color3(255, 215, 80), 1.2)
		effects.ring(hrp.Position, color3(255, 255, 255), 30, 1)
		effects.burst(hrp.Position, color3(255, 215, 80), 60)
	end
	effects.shake(p, 0.6, 0.8)
	tellAll(
		p.Name
			.. " renacio! Renacer "
			.. playerState.pr
			.. " (+"
			.. string.format("%g", playerState.pr * ECONOMY.PRESTIGE_BONUS * 100)
			.. "% de dinero para siempre)"
	)
	updateDepositLabel(plot)
	updateRollLabel(plot)
	playerState.ui()
end

prestigeEvent.OnServerEvent:Connect(function(p, token, accept)
	if not playable(p) then
		return
	end
	local playerState = playerStates[p]
	local pending = playerState.confirm
	if not pending or pending.token ~= token then
		return
	end
	playerState.confirm = nil
	if accept == true and os.clock() <= pending.expires then
		doPrestige(p)
	end
end)
-- GERENTES

-- Elige un gerente usando rareza y suerte del jugador.
local function pickMgr(playerState)
	local s = playerState.sk.suerte or 0
	local ws = {}
	local tot = 0
	for i, r in ipairs(RARITIES) do
		ws[i] = r.w * (1 + 0.25 * s * (i - 1))
		tot = tot + ws[i]
	end
	local x = gameRandom:NextNumber(0, tot)
	local rid = 1
	for i = 1, #ws do
		x = x - ws[i]
		if x <= 0 then
			rid = i
			break
		end
	end
	local list = {}
	for _, g in ipairs(MANAGERS) do
		if g.r == rid then
			table.insert(list, g)
		end
	end
	return list[gameRandom:NextInteger(1, #list)]
end

-- Cobra la tirada y coordina su animacion y entrega de gerente.

local function doRoll(p, plot)
	if plot.owner ~= p or plot.rolling then
		return
	end
	local playerState = playerStates[p]
	local d = getMoney(p)
	if not playerState or not d then
		return
	end
	local c = rollCost(playerState)
	if d.Value < c then
		tell(p, "Te faltan $" .. formatNumber(c - d.Value) .. " para rodar un gerente.")
		return
	end
	plot.rolling = true
	d.Value = d.Value - c
	playerState.ro = playerState.ro + 1
	local g = pickMgr(playerState)
	playerState.mg[g.n] = (playerState.mg[g.n] or 0) + 1
	plot.q.Enabled = false
	-- efecto tragaperras en el pedestal
	for k = 1, 16 do
		local rg = MANAGERS[gameRandom:NextInteger(1, #MANAGERS)]
		plot.rollLbl.Text = rg.n
		plot.rollLbl.TextColor3 = RARITIES[rg.r].c
		task.wait(0.04 + k * 0.008)
	end
	if plot.owner ~= p or playerStates[p] ~= playerState then
		return
	end
	if not playable(p) then
		plot.rolling = false
		plot.q.Enabled = true
		return
	end
	local pos = vector3(plot.cx + 18, GROUND_HEIGHT + 1, plot.cz + 27)
	local rc = RARITIES[g.r].c
	effects.ring(pos, rc, 16, 0.7)
	effects.burst(pos + vector3(0, 5, 0), rc, 20 + g.r * 8)
	if g.r >= 4 then
		effects.beam(pos, rc, 1.2)
		effects.shake(p, 0.4, 0.2 * g.r)
	end
	local cf = CFrame.new(plot.cx + 18, GROUND_HEIGHT + 2.1, plot.cz + 27) * CFrame.Angles(0, math.pi, 0)
	local m, body = animal(cf, g.a, g.c, g.k, { tie = true, name = g.n, aura = (g.r >= 3) and rc or nil })
	m.Parent = plot.managersModel
	if g.r >= 4 then
		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(rc)
		pe.Rate = 18
		pe.Lifetime = NumberRange.new(1, 2)
		pe.Speed = NumberRange.new(2, 4)
		pe.Size = NumberSequence.new(0.5)
		pe.LightEmission = 1
		pe.Parent = body
	end
	local lb =
		label(body, g.n .. "\n" .. RARITIES[g.r].n .. "\n" .. managerBenefit(playerState, g), 6, 212, 82, 28, "info")
	lb.TextColor3 = rc
	if #playerState.eq < playerState.slots and not isEquipped(playerState, g.n) then
		table.insert(playerState.eq, g.n)
		tell(p, g.n .. ": " .. managerBenefit(playerState, g) .. ". Equipado!")
	else
		tell(p, g.n .. ": " .. managerBenefit(playerState, g) .. ". Equipalo en el Establo para activar el bono.")
	end
	if g.r >= 5 then
		tellAll(p.Name .. " consiguio a " .. g.n .. " (" .. RARITIES[g.r].n .. ")!")
	end
	addQuestProgress(p, "roll", 1)
	local l = owned(playerState)
	for k, x in ipairs(l) do
		if x.n == g.n then
			playerState.ix = k
		end
	end
	updateRollLabel(plot)
	updateInventoryLabels(plot)
	playerState.ui()
	task.delay(4, function()
		m:Destroy()
		if plot.owner ~= p or playerStates[p] ~= playerState then
			return
		end
		plot.q.Enabled = true
		plot.rolling = false
	end)
end

-- Aplica al personaje la velocidad obtenida con habilidades.

local function applySpeed(p)
	local ch = p.Character
	local h = ch and ch:FindFirstChildOfClass("Humanoid")
	local playerState = playerStates[p]
	if h and playerState then
		h.WalkSpeed = 16 + 2 * (playerState.sk.botas or 0)
	end
end

-- publica el nivel de cada habilidad; el cliente arma los carteles con esos datos

-- Publica niveles de habilidades como atributos para la interfaz.
local function refreshSkills(p)
	local playerState = playerStates[p]
	if not playerState then
		return
	end
	for _, sk in ipairs(SKILLS) do
		p:SetAttribute("sk_" .. sk.id, playerState.sk[sk.id] or 0)
	end
end

local skillPads = {}

-- Valida y compra un nivel de habilidad.
local function buySkill(p, k)
	local playerState = playerStates[p]
	local d = getMoney(p)
	if not playerState or not d then
		return
	end
	local sk = SKILLS[k]
	local lv = playerState.sk[sk.id] or 0
	if lv >= sk.max then
		tell(p, sk.name .. " ya esta al maximo!")
		return
	end
	local c = skillCost(sk, lv)
	if d.Value < c then
		tell(p, "Te faltan $" .. formatNumber(c - d.Value) .. " para " .. sk.name .. ".")
		return
	end
	d.Value = d.Value - c
	playerState.sk[sk.id] = lv + 1
	tell(p, sk.name .. " nivel " .. (lv + 1) .. "! " .. sk.desc)
	effects.ring(skillPads[k].Position + vector3(0, 1, 0), sk.col, 14, 0.6)
	effects.burst(skillPads[k].Position + vector3(0, 4, 0), sk.col, 18)
	applySpeed(p)
	refreshSkills(p)
	playerState.ui()
end

-- Elige el destino y desplaza al personaje; aqui se ajustan las llegadas.

local function teleportPlayer(p, where)
	local playerState = playerStates[p]
	local ch = p.Character
	if not ch then
		return
	end
	local plot = playerState and playerState.plot
	local pos
	if where == 1 then
		pos = vector3(0, 5, 100)
	elseif where == 2 and plot then
		pos = vector3(plot.cx, 5, plot.cz + 30)
	elseif where == 3 and plot then
		pos = vector3(plot.cx, 5, plot.cz - 20)
	elseif where == 4 and plot then
		pos = vector3(plot.cx + 20, 5, plot.cz + 44)
	elseif where == 5 then
		pos = vector3(70, 5, 130)
	else
		tell(p, "No tienes mina asignada.")
		return
	end
	ch:PivotTo(CFrame.new(pos))
end

-- MUNDO (lo construye src/server/World.luau; aqui solo se le pasan las acciones)
local clouds = World.build({
	plots = plots,
	skp = skillPads,
	ipn = INVENTORY_ACTION_NAMES,
	handlers = {
		deposit = { guarded(depositAll), guarded(withdrawAll), guarded(upgradeDeposit) },
		roll = guarded(doRoll),
		inv = {
			guarded(navigateInventory(-1)),
			guarded(navigateInventory(1)),
			guarded(equipManager),
			guarded(sellManagerCopy),
			guarded(fuseManager),
			guarded(buyManagerSlot),
		},
		press = guarded(pressBtn),
		touch = function(p, j)
			if not playable(p) then
				return
			end
			local a = collect(p, j, true)
			if a > 0 then
				local playerState = playerStates[p]
				if playerState then
					playerState.ui()
				end
			end
		end,
		skill = guarded(buySkill),
		teleportPlayer = guarded(teleportPlayer),
		prestige = requestPrestige,
	},
})

-- textos iniciales de los carteles
for _, plot in ipairs(plots) do
	updateDepositLabel(plot)
	updateInventoryLabels(plot)
	updateRollLabel(plot)
	for j = 1, MINER_COUNT do
		updateMinerLabel(plot, j)
	end
end

-- COFRES DEL TESORO Y EVENTOS
local chestM

-- Construye un cofre temporal y conecta su recompensa.
local function spawnChest()
	if chestM and chestM.Parent then
		return
	end
	local pos = vector3(gameRandom:NextNumber(-190, 190), GROUND_HEIGHT, gameRandom:NextNumber(78, 125))
	local m = Instance.new("Model")
	m.Name = "Cofre"
	local function pc(n, s, off, c, mat)
		local p = Instance.new("Part")
		p.Name = n
		p.Size = s
		p.Anchored = true
		p.Color = c
		p.Material = mat
		p.CFrame = CFrame.new(pos + off)
		p.Parent = m
		return p
	end
	local base = pc("Base", vector3(4, 2.4, 3), vector3(0, 1.2, 0), color3(150, 95, 50), Enum.Material.Wood)
	pc("Tapa", vector3(4.2, 1.2, 3.2), vector3(0, 3, 0), color3(170, 110, 55), Enum.Material.Wood)
	pc("Cerradura", vector3(0.8, 1, 0.4), vector3(0, 2.4, -1.6), color3(255, 215, 60), Enum.Material.Neon)
	pc("Banda", vector3(4.3, 0.4, 3.3), vector3(0, 2.2, 0), color3(255, 200, 60), Enum.Material.Metal)
	local gl = Instance.new("PointLight", base)
	gl.Color = color3(255, 215, 90)
	gl.Range = 22
	gl.Brightness = 1.5
	label(base, "COFRE DEL TESORO", 6, 184, 38, 65, "landmark")
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 10
	pe.Lifetime = NumberRange.new(1, 2)
	pe.Speed = NumberRange.new(3, 6)
	pe.SpreadAngle = Vector2.new(40, 40)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	pe.Color = ColorSequence.new(color3(255, 225, 100))
	pe.LightEmission = 1
	pe.Parent = base
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = "Abrir cofre"
	pr.ObjectText = "Tesoro"
	pr.HoldDuration = 0.8
	pr.MaxActivationDistance = 10
	pr.RequiresLineOfSight = false
	pr.Parent = base
	pr.Triggered:Connect(function(p)
		local playerState = playerStates[p]
		local d = getMoney(p)
		if not playable(p) or not d or m.Parent == nil then
			return
		end
		local amt = math.floor(math.max(ECONOMY.CHEST_MINIMUM, income(playerState) * ECONOMY.CHEST_INCOME_SECONDS))
		d.Value = d.Value + amt
		effects.beam(pos, color3(255, 215, 80), 1)
		effects.ring(pos + vector3(0, 1, 0), color3(255, 215, 80), 20, 0.7)
		effects.burst(pos + vector3(0, 3, 0), color3(255, 225, 100), 50)
		effects.coin(p, pos + vector3(0, 3, 0), 8)
		tellAll(p.Name .. " abrio el cofre del tesoro y gano $" .. formatNumber(amt) .. "!")
		m:Destroy()
	end)
	m.Parent = Workspace
	chestM = m
	Debris:AddItem(m, 70)
	tellAll("Aparecio un COFRE DEL TESORO en la plaza! Corre por el!")
end

-- Activa los efectos y el multiplicador de la hora dorada.

local function evStart()
	eventState.on = true
	Formulas.state.eventOn = true
	eventState.left = 60
	cc.TintColor = color3(255, 235, 170)
	tellAll(
		"HORA DORADA! Dinero al recoger mineral x"
			.. string.format("%g", ECONOMY.EVENT_MULTIPLIER)
			.. " durante 60 segundos!"
	)
end

-- Restaura el estado normal al terminar el evento.
local function evEnd()
	eventState.on = false
	Formulas.state.eventOn = false
	cc.TintColor = color3(255, 255, 255)
	tellAll("La hora dorada termino.")
end

-- GUARDADO (la logica de lectura/escritura vive en DataService.luau)

-- Copia tablas para aislar el guardado del estado que sigue cambiando.
local function copy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for k, v in pairs(value) do
		result[k] = copy(v)
	end
	return result
end

-- Guarda una instantanea de la partida y gestiona la liberacion de sesion.
local function save(p, release)
	local playerState = playerStates[p]
	local d = getMoney(p)
	if not playerState or not playerState.loaded or not d then
		return
	end
	while playerState.saving do
		task.wait()
	end
	if playerState.released then
		return
	end
	playerState.saving = true
	local sh = {}
	for i = 1, MINER_COUNT do
		sh[i] = { h = playerState.sh[i].h, l = playerState.sh[i].l }
	end
	local snapshot = copy({
		c = d.Value,
		sh = sh,
		sk = playerState.sk,
		mg = playerState.mg,
		eq = playerState.eq,
		star = playerState.star,
		slots = playerState.slots,
		ro = playerState.ro,
		coll = playerState.coll,
		dep = math.floor(playerState.dep),
		dl = playerState.dl,
		pr = playerState.pr,
		q = playerState.q,
		qn = playerState.qn,
		tot = playerState.tot,
		bv = Config.BALANCE_VERSION,
		ts = os.time(),
	})
	local ok = DataService.save(p.UserId, snapshot, playerState.session, release)
	playerState.saving = false
	if release and ok then
		playerState.released = true
	end
	p:SetAttribute("SaveStatus", ok and "saved" or "error")
	if not ok then
		playerState.ready = false
		if p.Parent == Players then
			p:Kick("No se pudo guardar de forma segura. Vuelve a entrar en un momento.")
		end
	end
end

-- Devuelve la indicacion apropiada para el avance inicial del jugador.

local function tutorial(playerState)
	local n = 0
	for i = 1, MINER_COUNT do
		if playerState.sh[i].h then
			n = n + 1
		end
	end
	if n == 0 then
		return "Ve al boton rojo de tu mina y contrata a tu primer minero."
	end
	if not playerState.coll then
		return "Corre sobre la vagoneta para recoger el mineral y ganar dinero."
	end
	if playerState.ro == 0 then
		return "Ve a la plataforma de gerentes y presiona Rodar para conseguir tu primer gerente."
	end
	local t = 0
	for _, x in pairs(playerState.sk) do
		t = t + x
	end
	if t == 0 then
		return "Visita Habilidades en la plaza y mejora tu primera habilidad."
	end
	if n < MINER_COUNT then
		return "Contrata mas mineros y mejoralos con los botones rojos."
	end
	if playerState.pr == 0 then
		return "Cuando tengas dinero de sobra ve a RENACER en la plaza para un bono permanente."
	end
	return "Mejora todo al maximo y consigue gerentes miticos!"
end

-- Carga y valida datos, asigna parcela e inicializa el estado del jugador.

local function setup(p)
	if p:FindFirstChild("leaderstats") then
		return
	end
	local f = Instance.new("Folder")
	f.Name = "leaderstats"
	local d = Instance.new("NumberValue")
	d.Name = "Dinero"
	d.Value = 30
	d.Parent = f
	local rb = Instance.new("IntValue")
	rb.Name = "Renacer"
	rb.Value = 0
	rb.Parent = f
	f.Parent = p
	local playerState = {
		sh = {},
		sk = {},
		mg = {},
		eq = {},
		star = {},
		ro = 0,
		tmr = 0,
		itmr = 0,
		dep = 0,
		dl = 0,
		coll = false,
		ui = function() end,
		queue = {},
		hudReady = false,
		pr = 0,
		slots = INITIAL_MANAGER_SLOTS,
		ix = 1,
		tot = 0,
		qn = 0,
	}
	for i = 1, MINER_COUNT do
		playerState.sh[i] = { h = false, l = 0, o = 0 }
	end
	playerStates[p] = playerState
	p:SetAttribute("DataReady", false)
	p:SetAttribute("SaveStatus", "loading")
	if readyEarly[p] then
		playerState.hudReady = true
		readyEarly[p] = nil
	end
	for _, q in ipairs(plots) do
		if not q.owner then
			q.owner = p
			playerState.plot = q
			q.nameLbl.Text = "Mina de " .. p.Name
			break
		end
	end
	local plot = playerState.plot
	-- CARGA SEGURA: si no se pudo leer la partida, no se juega de verdad ni se guarda encima
	if not plot then
		p:Kick("Las 4 minas estan ocupadas. Intenta en otro servidor.")
		return
	end
	loading += 1
	local ok, data, session = DataService.load(p.UserId)
	if p.Parent ~= Players or playerStates[p] ~= playerState or closing then
		if ok then
			DataService.save(p.UserId, data, session, true)
		end
		loading -= 1
		return
	end
	loading -= 1
	playerState.session = session
	if not ok then
		if RunService:IsStudio() and session == "unavailable" then
			warn(
				"DataStore no disponible: juegas SIN guardar. Publica el lugar y activa el acceso a servicios de API en Studio."
			)
		else
			p:Kick("No se pudo cargar tu progreso. Vuelve a entrar en un momento.")
			return
		end
	end
	if type(data) ~= "table" then
		data = nil
	end
	if data then
		d.Value = data.c or 30
		playerState.ro = data.ro or 0
		playerState.sk = data.sk or {}
		playerState.mg = data.mg or {}
		playerState.star = data.star or {}
		playerState.coll = data.coll or false
		playerState.dep = data.dep or 0
		playerState.dl = math.clamp(data.dl or 0, 0, MAX_DEPOSIT_LEVEL)
		playerState.pr = math.clamp(data.pr or 0, 0, MAX_PRESTIGE_LEVEL)
		playerState.slots = math.clamp(data.slots or INITIAL_MANAGER_SLOTS, INITIAL_MANAGER_SLOTS, MAX_MANAGER_SLOTS)
		playerState.tot = data.tot or 0
		playerState.qn = data.qn or 0
		if data.sh then
			for i = 1, MINER_COUNT do
				local s = data.sh[i]
				if s and s.h then
					playerState.sh[i] = { h = true, l = math.max(1, s.l or 1), o = 0 }
				end
			end
		end
		if type(data.eq) == "table" then
			for _, n in ipairs(data.eq) do
				if
					MANAGERS_BY_NAME[n]
					and (playerState.mg[n] or 0) > 0
					and not isEquipped(playerState, n)
					and #playerState.eq < playerState.slots
				then
					table.insert(playerState.eq, n)
				end
			end
		else
			-- partida vieja: equipa automaticamente a los mejores gerentes
			local l = owned(playerState)
			table.sort(l, function(a, b)
				return a.b > b.b
			end)
			for k = 1, math.min(#l, playerState.slots) do
				table.insert(playerState.eq, l[k].n)
			end
		end
	end
	rb.Value = playerState.pr
	if data then
		playerState.q = Formulas.restoreQuest(playerState, data.q, data.bv)
	end
	if not playerState.q then
		newQuest(playerState)
	end
	playerState.loaded = ok
	playerState.ready = true
	p:SetAttribute("DataReady", true)
	p:SetAttribute("SaveStatus", ok and "saved" or "disabled")
	if plot then
		for i = 1, MINER_COUNT do
			if playerState.sh[i].h then
				spawnMiner(plot, i, false)
			end
			updateMinerLabel(plot, i)
		end
		updateRollLabel(plot)
		updateDepositLabel(plot)
		updateInventoryLabels(plot)
	end
	-- EL HUD LO DIBUJA EL CLIENTE (src/client/Hud.client.luau).
	-- El servidor solo publica los datos como atributos del jugador.
	playerState.ui = function()
		p:SetAttribute("Income", income(playerState))
		p:SetAttribute("Mult", cashMult(playerState))
		p:SetAttribute("Quest", questText(playerState))
		p:SetAttribute("Tut", tutorial(playerState))
		p:SetAttribute("EvOn", eventState.on)
		p:SetAttribute("EvLeft", eventState.left)
		local lines = {
			"EQUIPADOS (" .. #playerState.eq .. "/" .. playerState.slots .. ")",
			"Bono total: +" .. string.format("%g", totalManagerBonus(playerState) * 100) .. "%",
			"Al recoger mineral",
			"",
		}
		for _, n in ipairs(playerState.eq) do
			table.insert(lines, n .. " " .. string.rep("*", playerState.star[n] or 0))
			table.insert(lines, managerBenefit(playerState, MANAGERS_BY_NAME[n]))
			table.insert(lines, "")
		end
		table.insert(lines, "")
		if #playerState.eq == 0 then
			table.insert(lines, "Equipa un gerente en el establo para activar su bono.")
		end
		table.insert(lines, "Solo cuentan los equipados.")
		table.insert(lines, "Gerentes: " .. managerCount(playerState) .. "   Renacer: " .. playerState.pr)
		p:SetAttribute("Ger", table.concat(lines, "\n"))
	end
	refreshSkills(p)
	playerState.ui()
	if not plot then
		tell(p, "El servidor esta lleno (4 minas). Intenta en otro servidor.")
	elseif data and data.ts then
		local off = math.clamp(os.time() - data.ts, 0, ECONOMY.OFFLINE_SECONDS)
		if off >= 60 then
			local gain = math.floor(income(playerState) * off * ECONOMY.OFFLINE_FRACTION)
			if gain > 0 then
				d.Value = d.Value + gain
				tell(p, "Bienvenido de vuelta! Tus mineros ganaron $" .. formatNumber(gain) .. " mientras no estabas.")
			end
		end
	end
end

-- Prepara la posicion y habilidades cuando aparece un personaje.

local function onChar(p, ch)
	ch:WaitForChild("HumanoidRootPart")
	ch:WaitForChild("Humanoid")
	task.wait(0.3)
	local playerState = playerStates[p]
	if playerState and playerState.plot then
		ch:PivotTo(CFrame.new(playerState.plot.cx, GROUND_HEIGHT + 3, playerState.plot.cz + 30))
	end
	applySpeed(p)
end

-- Conecta la entrada del jugador con la carga de su partida.

local function join(p)
	if joined[p] then
		return
	end
	joined[p] = true
	if closing then
		p:Kick("Servidor cerrando. Vuelve a entrar.")
		return
	end
	setup(p)
	if p.Parent ~= Players or not playerStates[p] or not playerStates[p].ready then
		return
	end
	p.CharacterAdded:Connect(function(ch)
		onChar(p, ch)
	end)
	if p.Character then
		task.spawn(onChar, p, p.Character)
	end
end
Players.PlayerAdded:Connect(join)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(join, p)
end

Players.PlayerRemoving:Connect(function(p)
	local playerState = playerStates[p]
	if playerState then
		playerState.leaving = true
	end
	save(p, true)
	local plot = playerState and playerState.plot
	playerStates[p] = nil
	joined[p] = nil
	readyEarly[p] = nil
	if plot then
		for i = 1, MINER_COUNT do
			despawn(plot, i)
		end
		plot.owner = nil
		plot.rolling = false
		plot.q.Enabled = true
		plot.nameLbl.Text = "MINA LIBRE"
		for i = 1, MINER_COUNT do
			updateMinerLabel(plot, i)
		end
		updateRollLabel(plot)
		updateDepositLabel(plot)
		updateInventoryLabels(plot)
	end
end)

-- al cerrar el servidor se guarda a todos en paralelo
game:BindToClose(function()
	closing = true
	local pending = 0
	for _, p in ipairs(Players:GetPlayers()) do
		pending += 1
		task.spawn(function()
			save(p, true)
			pending -= 1
		end)
	end
	while pending > 0 or loading > 0 do
		task.wait()
	end
end)

-- ANIMACION: picar de verdad (el pico se levanta y golpea la roca), nubes y establo
RunService.Heartbeat:Connect(function(dt)
	local t = os.clock()
	for _, plot in ipairs(plots) do
		for i = 1, MINER_COUNT do
			local v = plot.v[i]
			if v.model and v.cf and not v.anim then
				local s = 0
				local a = 0.35
				local lean = 0
				if v.work then
					local ph = (t * ECONOMY.WORK_HITS_PER_SECOND + i * 0.37) % 1
					if ph < 0.28 then
						s = (ph / 0.28) ^ 2
					else
						s = 1 - (ph - 0.28) / 0.72
					end
					local prev = v.ph or 0
					v.ph = ph
					a = 0.8 - 2.0 * s
					lean = -0.1 * s
					if prev < 0.28 and ph >= 0.28 then
						if v.tipPE then
							v.tipPE:Emit(6)
						end
						local p = plot.owner
						local playerState = p and playerStates[p]
						if
							playable(p)
							and playerState.sh[i].h
							and gameRandom:NextNumber() < Formulas.critChance(playerState)
						then
							local sh = playerState.sh[i]
							sh.o = math.min(
								cartCapacity(playerState, i),
								sh.o + production(playerState, i) * ECONOMY.CRIT_BONUS_SECONDS
							)
							pop(v.pad, "CRITICO!", color3(255, 90, 90))
						end
					end
				end
				place(v, 0, lean, 0, a)
			end
		end
		if plot.invModel and plot.invModel.PrimaryPart then
			plot.invModel:PivotTo(plot.invCF * CFrame.Angles(0, t * 0.8, 0) * CFrame.new(0, 1.9, 0))
		end
	end
	for _, c in ipairs(clouds) do
		c.x = c.x + c.sp * dt
		if c.x > 440 then
			c.x = -440
		end
		c.m:PivotTo(CFrame.new(c.x, c.y, c.z))
	end
end)

-- Produccion, interes del deposito y recogida automatica de gerentes
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, plot in ipairs(plots) do
			local p = plot.owner
			local playerState = p and playerStates[p]
			if playable(p) then
				for i = 1, MINER_COUNT do
					local sh = playerState.sh[i]
					local v = plot.v[i]
					if sh.h then
						local c = cartCapacity(playerState, i)
						sh.o = math.min(c, sh.o + production(playerState, i) * 0.5)
						v.work = sh.o < c
						local s = 0.3 + 1.0 * (sh.o / c)
						v.mound.Size = vector3(4.5 * s, 2 * s + 0.2, 3.4 * s)
						v.cartLbl.Text = formatNumber(sh.o)
							.. " / "
							.. formatNumber(c)
							.. ((sh.o >= c) and "\nLLENA!" or "")
					end
				end
				-- NO hay recoleccion automatica: el mineral se queda en la vagoneta (hasta su tope)
				-- y el jugador debe ir a recogerlo pisando la vagoneta.
				playerState.itmr = playerState.itmr + 0.5
				if playerState.itmr >= 10 then
					playerState.itmr = 0
					if playerState.dep > 0 then
						playerState.dep =
							math.min(depositCapacity(playerState), playerState.dep * (1 + depositRate(playerState)))
					end
				end
				updateDepositLabel(plot)
				playerState.ui()
			end
		end
	end
end)

-- Reloj del mundo: dia y noche, hora dorada y cofres
task.spawn(function()
	local t = 0
	while true do
		task.wait(1)
		t = t + 1
		Lighting.ClockTime = (Lighting.ClockTime + 0.03) % 24
		if eventState.on then
			eventState.left = eventState.left - 1
			if eventState.left <= 0 then
				evEnd()
			end
		elseif t % 300 == 120 then
			evStart()
		end
		if t % 100 == 50 then
			spawnChest()
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(60)
		for _, p in ipairs(Players:GetPlayers()) do
			task.spawn(save, p)
		end
	end
end)
