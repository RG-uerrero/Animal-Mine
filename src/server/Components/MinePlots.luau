-- Componente MinePlots: construye su zona y conecta acciones mediante context.handlers.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Config = require(ReplicatedStorage.Shared.Config)
local Builders = require(script.Parent.Parent.Builders)

-- Desestructuración de funciones y constantes del módulo Builders y Config
local createPart, createCylinder, label, board, lamp, createTree =
	Builders.createPart, Builders.createCylinder, Builders.label, Builders.board, Builders.lamp, Builders.createTree
local WOOD, DARK_WOOD, STONE, DIRT, ROCK_COLOR, worldRandom =
	Builders.WOOD, Builders.DARK_WOOD, Builders.STONE, Builders.DIRT, Builders.ROCK_COLOR, Builders.worldRandom
local Workspace = workspace
local vector3 = Vector3.new
local color3 = Color3.fromRGB
local SPHERE_SHAPE = Enum.PartType.Ball
local MINER_COUNT, GROUND_HEIGHT = Config.MINER_COUNT, Config.GROUND_HEIGHT
local TIER_COLORS, SKILLS = Config.TIER_COLORS, Config.SKILLS

local MinePlots = {}
function MinePlots.build(context)
	local scoped = Builders.forModel(context.model)
	local createPart, createCylinder, board, lamp, createTree =
		scoped.createPart, scoped.createCylinder, scoped.board, scoped.lamp, scoped.createTree
	local plots, skillPads, INVENTORY_ACTION_NAMES, handlers = context.plots, context.skp, context.ipn, context.handlers
	--------------------------------------------------------------------------------
	for i = 1, 4 do
		local cx = (i - 1) * 100 - 150
		local cz = 0
		local mineModel = Instance.new("Model")
		mineModel.Name = "Mina" .. i
		mineModel.Parent = context.model
		local function group(name)
			local model = Instance.new("Model")
			model.Name = name
			model.Parent = mineModel
			return model
		end
		local structureModel = group("Estructura")
		local bankModel = group("Deposito")
		local managersModel = group("Gerentes")
		local workersModel = group("PuestosMineros")
		local scoped = Builders.forModel(structureModel)
		local createPart, createCylinder = scoped.createPart, scoped.createCylinder
		local plot = { i = i, cx = cx, cz = cz, owner = nil, v = {} }
		plots[i] = plot
		plot.model = mineModel
		plot.managersModel = managersModel

		-- Estructura física y suelo de la mina
		createPart("MinaSuelo", vector3(70, 0.4, 60), vector3(cx, 1.2, cz - 20), DIRT, Enum.Material.Ground)
		createPart(
			"MuroFondo", 
			vector3(70, 18, 4), 
			vector3(cx, GROUND_HEIGHT + 9, cz - 48),
			ROCK_COLOR,
			Enum.Material.Slate
		)
		createPart(
			"MuroLado",
			vector3(3, 4, 56),
			vector3(cx - 33.5, GROUND_HEIGHT + 2, cz - 18),
			ROCK_COLOR,
			Enum.Material.Slate
		)
		createPart(
			"MuroLado",
			vector3(3, 4, 56),
			vector3(cx + 33.5, GROUND_HEIGHT + 2, cz - 18),
			ROCK_COLOR,
			Enum.Material.Slate
		)

		-- Rieles y durmientes estéticos mineros
		for _, zz in pairs({ -9.2, -6.8 }) do
			createPart(
				"Riel",
				vector3(70, 0.4, 0.6),
				vector3(cx, GROUND_HEIGHT + 0.5, cz + zz),
				color3(205, 210, 225),
				Enum.Material.Metal
			)
		end
		for tx = -34, 34, 4 do
			createPart(
				"Durmiente",
				vector3(0.8, 0.3, 5),
				vector3(cx + tx, GROUND_HEIGHT + 0.15, cz - 8),
				DARK_WOOD,
				Enum.Material.Wood
			)
		end

		createPart("CimientoMina", vector3(76, 1.5, 122), vector3(cx, 0.1, cz + 10), ROCK_COLOR, Enum.Material.Slate)
		createPart("Plataforma", vector3(70, 0.3, 60), vector3(cx, 1, cz + 40), STONE, Enum.Material.Cobblestone)
		createPart(
			"PasilloCentral",
			vector3(10, 0.12, 58),
			vector3(cx, GROUND_HEIGHT + 0.06, cz + 40),
			color3(245, 230, 201),
			Enum.Material.SmoothPlastic
		)
		for _, side in ipairs({ -1, 1 }) do
			createPart(
				"BordeParcela",
				vector3(2, 0.6, 60),
				vector3(cx + side * 34, GROUND_HEIGHT + 0.2, cz + 40),
				WOOD,
				Enum.Material.WoodPlanks
			)
		end
		createPart(
			"TarimaBanco",
			vector3(29, 0.15, 44),
			vector3(cx - 20, GROUND_HEIGHT + 0.075, cz + 45),
			color3(203, 219, 193),
			Enum.Material.SmoothPlastic
		)
		createPart(
			"TarimaGerentes",
			vector3(29, 0.15, 44),
			vector3(cx + 20, GROUND_HEIGHT + 0.075, cz + 45),
			color3(213, 207, 228),
			Enum.Material.SmoothPlastic
		)

		-- Zona de Depósito de recursos
		local scoped = Builders.forModel(bankModel)
		local createPart, createCylinder = scoped.createPart, scoped.createCylinder
		local dep = createPart(
			"Deposito",
			vector3(22, 12, 14),
			vector3(cx - 20, GROUND_HEIGHT + 6, cz + 46),
			color3(208, 185, 145),
			Enum.Material.WoodPlanks
		)
		createPart(
			"DepositoPuerta",
			vector3(8, 8, 0.5),
			vector3(cx - 20, GROUND_HEIGHT + 4, cz + 38.8),
			color3(60, 65, 85),
			Enum.Material.Metal
		)
		createPart(
			"TechoBanco",
			vector3(25, 1.4, 17),
			vector3(cx - 20, GROUND_HEIGHT + 12.7, cz + 46),
			color3(95, 133, 122),
			Enum.Material.SmoothPlastic
		)
		plot.depLbl = label(dep, "BANCO DE MINERAL", 8, 220, 96, 36, "info")

		-- Pads de interacción del depósito (Depositar, Retirar, Ampliar)
		plot.dPad = {}
		plot.dlbl = {}
		local dcol = { color3(70, 190, 100), color3(120, 80, 80), color3(0, 255, 255) }
		local dact = { "Depositar todo", "Retirar todo", "Ampliar deposito" }
		local dname = { "DEPOSITAR", "RETIRAR", "AMPLIAR\nDEPOSITO" }
		local dfun = handlers.deposit
		for k = 1, 3 do
			local pd = createCylinder(
				"DepPad",
				0.6,
				6,
				vector3(cx - 28 + (k - 1) * 8, GROUND_HEIGHT + 0.3, cz + 33),
				dcol[k],
				Enum.Material.Metal
			)

			plot.dPad[k] = pd
			plot.dlbl[k] = label(pd, dname[k], 3.2, 116, 42, 24, "detail")
			local dp = Instance.new("ProximityPrompt")
			dp.ActionText = dact[k]
			dp.ObjectText = "Deposito"
			dp.HoldDuration = 0.2
			dp.MaxActivationDistance = 5
			dp.RequiresLineOfSight = false
			dp.Parent = pd
			local fn = dfun[k]
			dp.Triggered:Connect(function(p)
				fn(p, plot)
			end)
		end

		local scoped = Builders.forModel(structureModel)
		local createPart, createCylinder = scoped.createPart, scoped.createCylinder
		local cart = createPart(
			"CartelMina",
			vector3(26, 5, 1),
			vector3(cx, GROUND_HEIGHT + 16, cz - 45.5),
			WOOD,
			Enum.Material.Wood
		)
		plot.nameLbl = Builders.sign(cart, "MINA LIBRE")

		-- 4.1 Plataforma para rodar gerentes (Gacha / Ruleta)
		local scoped = Builders.forModel(managersModel)
		local createPart, createCylinder = scoped.createPart, scoped.createCylinder
		local rx, rz = cx + 20, cz + 27
		createCylinder(
			"RodarBase",
			0.6,
			16,
			vector3(rx, GROUND_HEIGHT + 0.3, rz),
			color3(160, 165, 185),
			Enum.Material.Concrete
		)
		createCylinder(
			"RodarAnillo",
			0.4,
			9,
			vector3(rx, GROUND_HEIGHT + 0.8, rz),
			color3(210, 60, 60),
			Enum.Material.Metal
		)
		local ped = createCylinder(
			"Pedestal",
			1.5,
			6,
			vector3(rx, GROUND_HEIGHT + 1.35, rz),
			color3(235, 185, 60),
			Enum.Material.Metal
		)
		plot.rollLbl = label(ped, "RODAR GERENTE", 6, 180, 60, 34)

		local qg = Instance.new("BillboardGui")
		qg.Size = UDim2.new(4, 0, 1, 0)
		qg.StudsOffset = vector3(0, 3.2, 0)
		qg.MaxDistance = 40
		qg.AlwaysOnTop = false

		local qt = Instance.new("TextLabel", qg)
		qt.Size = UDim2.new(1, 0, 1, 0)
		qt.BackgroundTransparency = 1
		qt.TextScaled = true
		qt.Font = Enum.Font.FredokaOne
		qt.TextColor3 = color3(20, 20, 25)
		qt.TextStrokeColor3 = Color3.new(1, 1, 1)
		qt.TextStrokeTransparency = 0
		qt.Text = "?"
		qg.Parent = ped
		plot.q = qg

		local rp = Instance.new("ProximityPrompt")
		rp.ActionText = "Rodar"
		rp.ObjectText = "Gerente"
		rp.HoldDuration = 0.2
		rp.MaxActivationDistance = 6
		rp.RequiresLineOfSight = false
		rp.Parent = ped
		rp.Triggered:Connect(function(p)
			handlers.roll(p, plot)
		end)

		-- 4.2 Establo (Inventario físico de gerentes equipados/almacenados)
		local ix0, iz0 = cx + 20, cz + 43
		local ibase = createCylinder(
			"EstabloBase",
			0.8,
			11,
			vector3(ix0, GROUND_HEIGHT + 0.4, iz0),
			color3(110, 90, 70),
			Enum.Material.Wood
		)
		createCylinder(
			"EstabloAnillo",
			0.3,
			9,
			vector3(ix0, GROUND_HEIGHT + 0.9, iz0),
			color3(235, 185, 60),
			Enum.Material.Metal
		)
		plot.invCF = CFrame.new(ix0, GROUND_HEIGHT + 1.05, iz0)
		plot.invLbl = label(ibase, "GERENTES\nY ESTABLO", 10, 220, 116, 32, "info")
		plot.ilbl = {}

		local ipC = {
			color3(90, 130, 220),
			color3(90, 130, 220),
			color3(70, 190, 100),
			color3(220, 150, 60),
			color3(190, 100, 255),
			color3(235, 185, 60),
		}
		local ipA = { "Anterior", "Siguiente", "Equipar / Quitar", "Vender copia", "Fusionar", "Comprar slot" }
		local ipF = handlers.inv
		for k = 1, 6 do
			local pd = createCylinder(
				"EstPad",
				0.5,
				4,
				vector3(cx + 12 + ((k - 1) % 3) * 8, GROUND_HEIGHT + 0.3, cz + 55 + math.floor((k - 1) / 3) * 8),
				ipC[k],
				Enum.Material.Metal
			)
			plot.ilbl[k] = label(pd, INVENTORY_ACTION_NAMES[k], 2.8, 116, 48, 16)
			local ip = Instance.new("ProximityPrompt")
			ip.ActionText = ipA[k]
			ip.ObjectText = "Establo"
			ip.HoldDuration = (k <= 2) and 0 or 0.15
			ip.MaxActivationDistance = 4
			ip.RequiresLineOfSight = false
			ip.Parent = pd
			local fn = ipF[k]
			ip.Triggered:Connect(function(p)
				fn(p, plot)
			end)
		end

		-- 4.3 Túneles de mineros (Slots de trabajo individuales)
		for j = 1, MINER_COUNT do
			local x = cx - 25 + (j - 1) * 10
			local workerModel = Instance.new("Model")
			workerModel.Name = "Puesto" .. j
			workerModel.Parent = workersModel
			local scoped = Builders.forModel(workerModel)
			local createPart, createCylinder = scoped.createPart, scoped.createCylinder
			local v = { containerModel = workerModel }
			plot.v[j] = v

			-- Elementos estructurales del túnel
			createPart(
				"Poste",
				vector3(2, 12, 2),
				vector3(x - 4, GROUND_HEIGHT + 6, cz - 44),
				DARK_WOOD,
				Enum.Material.Wood
			)
			createPart(
				"Poste",
				vector3(2, 12, 2),
				vector3(x + 4, GROUND_HEIGHT + 6, cz - 44),
				DARK_WOOD,
				Enum.Material.Wood
			)
			createPart("Viga", vector3(10, 2, 2.4), vector3(x, GROUND_HEIGHT + 12.5, cz - 44), WOOD, Enum.Material.Wood)
			createPart(
				"Roca",
				vector3(9, 9, 7),
				vector3(x, GROUND_HEIGHT + 4.2, cz - 46),
				ROCK_COLOR,
				Enum.Material.Slate,
				SPHERE_SHAPE
			)
			createPart(
				"Roca",
				vector3(5, 5, 5),
				vector3(x - 2.5, GROUND_HEIGHT + 2.2, cz - 42),
				color3(125, 92, 70),
				Enum.Material.Slate,
				SPHERE_SHAPE
			)
			createPart(
				"Roca",
				vector3(4, 4, 4),
				vector3(x + 2.7, GROUND_HEIGHT + 1.8, cz - 41.5),
				color3(100, 75, 60),
				Enum.Material.Slate,
				SPHERE_SHAPE
			)
			createPart(
				"Oro",
				vector3(1.6, 1.6, 1.6),
				vector3(x + 1, GROUND_HEIGHT + 5, cz - 42.8),
				color3(235, 190, 70),
				Enum.Material.Metal,
				SPHERE_SHAPE
			)
			createPart(
				"Entrada",
				vector3(9, 0.1, 10),
				vector3(x, GROUND_HEIGHT + 0.05, cz - 37),
				color3(196, 165, 125),
				Enum.Material.Sand
			)

			-- Cristales brillantes con los colores correspondientes al tier del minero
			for kk = 1, 4 do
				local sx = (kk % 2 == 0) and 1 or -1
				local cr = createPart(
					"Cristal",
					vector3(0.9, worldRandom:NextNumber(2, 3.6), 0.9),
					vector3(
						x + sx * (3.4 + worldRandom:NextNumber(0, 0.8)),
						GROUND_HEIGHT + 1.8,
						cz - 40.5 - worldRandom:NextNumber(0, 1.5)
					),
					TIER_COLORS[j],
					Enum.Material.Neon
				)
				cr.CFrame = CFrame.new(cr.Position)
					* CFrame.Angles(
						worldRandom:NextNumber(-0.4, 0.4),
						worldRandom:NextNumber(0, 3),
						worldRandom:NextNumber(-0.4, 0.4)
					)
				cr.Transparency = 0.15
				cr.CanCollide = false
				if kk == 1 then
					local cl = Instance.new("PointLight", cr)
					cl.Color = TIER_COLORS[j]
					cl.Range = 14
					cl.Brightness = 0.7
				end
			end

			-- Botón de contratación y mejora del minero
			createCylinder(
				"BotonBase",
				0.5,
				7,
				vector3(x, GROUND_HEIGHT + 0.25, cz - 27),
				color3(60, 60, 70),
				Enum.Material.Metal
			)
			local btn = createCylinder(
				"Boton",
				0.7,
				5.5,
				vector3(x, GROUND_HEIGHT + 0.6, cz - 27),
				color3(225, 55, 55),
				Enum.Material.Metal
			)
			v.btnLbl = label(btn, "", 6.5, 148, 66, 28)
			local pr = Instance.new("ProximityPrompt")
			pr.ActionText = "Contratar / Mejorar"
			pr.ObjectText = "Minero " .. j
			pr.HoldDuration = 0.2
			pr.MaxActivationDistance = 5
			pr.RequiresLineOfSight = false
			pr.Parent = btn
			pr.Triggered:Connect(function(p)
				handlers.press(p, plot, j)
			end)

			-- Vagoneta y acumulación de minerales en el túnel
			createPart(
				"Vagoneta",
				vector3(6, 2.4, 4.4),
				vector3(x, GROUND_HEIGHT + 1.7, cz - 8),
				color3(150, 100, 60),
				Enum.Material.Wood
			)
			v.mound = createPart(
				"Mineral",
				vector3(4.5, 2, 3.4),
				vector3(x, GROUND_HEIGHT + 3.1, cz - 8),
				TIER_COLORS[j],
				Enum.Material.Glass,
				SPHERE_SHAPE
			)

			-- Pad táctil para recoger recursos automáticamente al tocarlo
			local pad =
				createPart("Recoger", vector3(8, 3, 7), vector3(x, GROUND_HEIGHT + 2, cz - 8), Color3.new(1, 1, 1))
			pad.Transparency = 1
			pad.CanCollide = false
			v.pad = pad
			v.cartLbl = label(pad, "", 4.5, 124, 38, 24)

			local deb = 0
			pad.Touched:Connect(function(h)
				local p = Players:GetPlayerFromCharacter(h.Parent)
				if not p or p ~= plot.owner then
					return
				end
				if os.clock() - deb < 0.5 then
					return
				end
				deb = os.clock()
				handlers.touch(p, j)
			end)
		end
	end
end
return MinePlots
