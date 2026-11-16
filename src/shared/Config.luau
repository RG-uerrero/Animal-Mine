-- src/shared/Config.luau  (ReplicatedStorage.Shared.Config)
-- Datos fijos del juego: constantes, rarezas, mineros, gerentes y habilidades.
-- IMPORTANTE: el campo "n" de cada gerente (MG) se usa como llave en el guardado.
-- Si cambias un nombre de gerente, los jugadores pierden ese gerente.

local color3 = Color3.fromRGB

local Config = {}

-- CONSTANTES
Config.MINER_COUNT = 6 -- mineros por mina
Config.MAX_MINER_LEVEL = 60 -- nivel maximo de un minero
Config.GROUND_HEIGHT = 1.4 -- altura del suelo
Config.MAX_DEPOSIT_LEVEL = 8 -- nivel maximo del deposito
Config.INITIAL_MANAGER_SLOTS = 3 -- slots de gerentes al empezar
Config.MAX_MANAGER_SLOTS = 8
Config.MAX_MANAGER_STARS = 3 -- estrellas maximas por fusion
Config.MAX_PRESTIGE_LEVEL = 25 -- renacimientos maximos

-- Balance independiente del almacen: no reinicia partidas.
Config.BALANCE_VERSION = 1
Config.Economy = {
	PRODUCTION_SCALE = 0.75,
	LEVEL_GROWTH = 1.10,
	MILESTONE_EVERY = 10,
	MILESTONE_MULTIPLIER = 1.20,
	UPGRADE_BASE = 0.9,
	UPGRADE_GROWTH = 1.16,
	PICKAXE_PER_LEVEL = 0.10,
	NEGOTIATION_PER_LEVEL = 0.05,
	MANAGER_STAR_BONUS = 0.15,
	PRESTIGE_BONUS = 0.10,
	PRESTIGE_COST_BASE = 2000000,
	PRESTIGE_COST_GROWTH = 1.65,
	EVENT_MULTIPLIER = 1.5,
	DEPOSIT_BASE_RATE = 0.0005,
	DEPOSIT_SKILL_RATE = 0.0001,
	CRIT_BASE_CHANCE = 0.02,
	CRIT_SKILL_CHANCE = 0.01,
	CRIT_BONUS_SECONDS = 1.5,
	WORK_HITS_PER_SECOND = 1.5,
	ROLL_BASE = 400,
	ROLL_GROWTH = 1.18,
	ROLL_MAXIMUM = 200000,
	QUEST_MINIMUM = 40,
	QUEST_INCOME_SECONDS = 20,
	QUEST_GOAL_SECONDS = 120,
	CHEST_MINIMUM = 75,
	CHEST_INCOME_SECONDS = 8,
	OFFLINE_SECONDS = 3600,
	OFFLINE_FRACTION = 0.10,
}

-- VERSION DE DATOS: al SUBIR este numero (1 -> 2 -> 3...) todos los jugadores empiezan de cero,
-- porque el guardado pasa a un almacen nuevo. Los datos anteriores no se borran: quedan en
-- el almacen viejo (si vuelves al numero anterior, recuperan su progreso).
-- Subelo solo cuando quieras un reinicio general entre versiones.
Config.DATA_VERSION = 2

-- RAREZAS (w = peso de probabilidad al rodar)
Config.RARITIES = {
	{ n = "Comun", c = color3(210, 210, 210), w = 50 },
	{ n = "Poco comun", c = color3(100, 210, 100), w = 28 },
	{ n = "Raro", c = color3(90, 150, 255), w = 13 },
	{ n = "Epico", c = color3(190, 100, 255), w = 6 },
	{ n = "Legendario", c = color3(255, 175, 50), w = 2.5 },
	{ n = "Mitico", c = color3(255, 80, 100), w = 0.5 },
}

-- precio de venta de una copia repetida, por rareza
Config.DUPLICATE_VALUES = { 20, 50, 150, 500, 1500, 5000 }

-- color de cada minero (cristales, efectos)
Config.TIER_COLORS = {
	color3(255, 150, 200),
	color3(255, 150, 60),
	color3(190, 130, 80),
	color3(235, 235, 245),
	color3(255, 160, 40),
	color3(255, 215, 80),
}

-- MINEROS (h = precio de contratacion, bp = produccion base)
Config.MINERS = {
	{ n = "Conejito", h = 10, bp = 1, a = "White", c = "Pink", k = "long" },
	{ n = "Zorrito", h = 250, bp = 8, a = "Bright orange", c = "White", k = "ear" },
	{ n = "Osito", h = 4000, bp = 60, a = "Brown", c = "Nougat", k = "round" },
	{ n = "Pandita", h = 60000, bp = 450, a = "White", c = "Black", k = "round" },
	{ n = "Tigre", h = 900000, bp = 3500, a = "Deep orange", c = "Black", k = "round" },
	{ n = "Leon", h = 15000000, bp = 28000, a = "Gold", c = "Reddish brown", k = "round" },
}

-- GERENTES (r = rareza, b = bonus de dinero)
Config.MANAGERS = {
	{ n = "Rita la Ratita", r = 1, b = 0.03, a = "Light stone grey", c = "Pink", k = "round" },
	{ n = "Paco Pollito", r = 1, b = 0.03, a = "Bright yellow", c = "Cool yellow", k = "ear" },
	{ n = "Beto Conejo", r = 1, b = 0.04, a = "White", c = "Pink", k = "long" },
	{ n = "Fran la Rana", r = 2, b = 0.06, a = "Bright green", c = "Lime green", k = "round" },
	{ n = "Olga Osita", r = 2, b = 0.06, a = "Brown", c = "Nougat", k = "round" },
	{ n = "Cuco Cerdito", r = 2, b = 0.08, a = "Pink", c = "Carnation pink", k = "ear" },
	{ n = "Zeta Zorro", r = 3, b = 0.12, a = "Bright orange", c = "White", k = "ear" },
	{ n = "Pepe Panda", r = 3, b = 0.12, a = "White", c = "Black", k = "round" },
	{ n = "Bruno Buho", r = 3, b = 0.15, a = "Brown", c = "Cool yellow", k = "ear" },
	{ n = "Tito Tigre", r = 4, b = 0.25, a = "Deep orange", c = "Black", k = "round" },
	{ n = "Lalo Lobo", r = 4, b = 0.3, a = "Steel blue", c = "Light stone grey", k = "ear" },
	{ n = "Leo Leon", r = 5, b = 0.5, a = "Gold", c = "Reddish brown", k = "round" },
	{ n = "Dax Dragon", r = 5, b = 0.6, a = "Bright red", c = "Br. yellowish orange", k = "horn" },
	{ n = "Fox Fenix", r = 6, b = 1, a = "Gold", c = "Bright orange", k = "horn" },
}

-- indice de gerentes por nombre
Config.MANAGERS_BY_NAME = {}
for _, g in ipairs(Config.MANAGERS) do
	Config.MANAGERS_BY_NAME[g.n] = g
end

-- HABILIDADES
Config.SKILLS = {
	{
		id = "pico",
		name = "Pico afilado",
		desc = "+10% mineral",
		max = 10,
		base = 200,
		grow = 2.2,
		col = color3(80, 150, 255),
	},
	{
		id = "botas",
		name = "Botas ligeras",
		desc = "+2 velocidad",
		max = 6,
		base = 150,
		grow = 2.5,
		col = color3(90, 210, 160),
	},
	{
		id = "carro",
		name = "Carritos grandes",
		desc = "+100% capacidad",
		max = 8,
		base = 300,
		grow = 2.6,
		col = color3(230, 150, 70),
	},
	{
		id = "neg",
		name = "Negociacion",
		desc = "+5% dinero",
		max = 10,
		base = 500,
		grow = 2.4,
		col = color3(100, 200, 100),
	},
	{
		id = "suerte",
		name = "Suerte dorada",
		desc = "Mejor suerte al rodar",
		max = 5,
		base = 2500,
		grow = 3.2,
		col = color3(200, 110, 230),
	},
	{
		id = "crit",
		name = "Ojo de oro",
		desc = "+1% golpe critico",
		max = 10,
		base = 1200,
		grow = 2.3,
		col = color3(235, 80, 90),
	},
	{
		id = "ban",
		name = "Banquero",
		desc = "+0.01% interes",
		max = 8,
		base = 3000,
		grow = 3,
		col = color3(60, 200, 200),
	},
}

return Config
