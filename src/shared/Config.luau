-- src/shared/Config.luau  (ReplicatedStorage.Shared.Config)
-- Datos fijos del juego: constantes, rarezas, mineros, gerentes y habilidades.
-- IMPORTANTE: el campo "n" de cada gerente (MG) se usa como llave en el guardado.
-- Si cambias un nombre de gerente, los jugadores pierden ese gerente.

local C3 = Color3.fromRGB

local Config = {}

-- CONSTANTES
Config.NSH = 6 -- mineros por mina
Config.MAXL = 60 -- nivel maximo de un minero
Config.FY = 1.4 -- altura del suelo
Config.DEPMAX = 8 -- nivel maximo del deposito
Config.SLOT0 = 3 -- slots de gerentes al empezar
Config.SLOTMAX = 8
Config.STARMAX = 3 -- estrellas maximas por fusion
Config.PRMAX = 25 -- renacimientos maximos

-- RAREZAS (w = peso de probabilidad al rodar)
Config.RAR = {
	{ n = "Comun", c = C3(210, 210, 210), w = 50 },
	{ n = "Poco comun", c = C3(100, 210, 100), w = 28 },
	{ n = "Raro", c = C3(90, 150, 255), w = 13 },
	{ n = "Epico", c = C3(190, 100, 255), w = 6 },
	{ n = "Legendario", c = C3(255, 175, 50), w = 2.5 },
	{ n = "Mitico", c = C3(255, 80, 100), w = 0.5 },
}

-- precio de venta de una copia repetida, por rareza
Config.RARV = { 300, 2500, 25000, 250000, 3000000, 50000000 }

-- color de cada minero (cristales, efectos)
Config.TIER = {
	C3(255, 150, 200),
	C3(255, 150, 60),
	C3(190, 130, 80),
	C3(235, 235, 245),
	C3(255, 160, 40),
	C3(255, 215, 80),
}

-- MINEROS (h = precio de contratacion, bp = produccion base)
Config.SH = {
	{ n = "Conejito", h = 10, bp = 1, a = "White", c = "Pink", k = "long" },
	{ n = "Zorrito", h = 250, bp = 8, a = "Bright orange", c = "White", k = "ear" },
	{ n = "Osito", h = 4000, bp = 60, a = "Brown", c = "Nougat", k = "round" },
	{ n = "Pandita", h = 60000, bp = 450, a = "White", c = "Black", k = "round" },
	{ n = "Tigre", h = 900000, bp = 3500, a = "Deep orange", c = "Black", k = "round" },
	{ n = "Leon", h = 15000000, bp = 28000, a = "Gold", c = "Reddish brown", k = "round" },
}

-- GERENTES (r = rareza, b = bonus de dinero)
Config.MG = {
	{ n = "Rita la Ratita", r = 1, b = 0.05, a = "Light stone grey", c = "Pink", k = "round" },
	{ n = "Paco Pollito", r = 1, b = 0.05, a = "Bright yellow", c = "Cool yellow", k = "ear" },
	{ n = "Beto Conejo", r = 1, b = 0.06, a = "White", c = "Pink", k = "long" },
	{ n = "Fran la Rana", r = 2, b = 0.12, a = "Bright green", c = "Lime green", k = "round" },
	{ n = "Olga Osita", r = 2, b = 0.12, a = "Brown", c = "Nougat", k = "round" },
	{ n = "Cuco Cerdito", r = 2, b = 0.14, a = "Pink", c = "Carnation pink", k = "ear" },
	{ n = "Zeta Zorro", r = 3, b = 0.3, a = "Bright orange", c = "White", k = "ear" },
	{ n = "Pepe Panda", r = 3, b = 0.3, a = "White", c = "Black", k = "round" },
	{ n = "Bruno Buho", r = 3, b = 0.35, a = "Brown", c = "Cool yellow", k = "ear" },
	{ n = "Tito Tigre", r = 4, b = 0.8, a = "Deep orange", c = "Black", k = "round" },
	{ n = "Lalo Lobo", r = 4, b = 0.8, a = "Steel blue", c = "Light stone grey", k = "ear" },
	{ n = "Leo Leon", r = 5, b = 2, a = "Gold", c = "Reddish brown", k = "round" },
	{ n = "Dax Dragon", r = 5, b = 2.2, a = "Bright red", c = "Br. yellowish orange", k = "horn" },
	{ n = "Fox Fenix", r = 6, b = 6, a = "Gold", c = "Bright orange", k = "horn" },
}

-- indice de gerentes por nombre
Config.MGBY = {}
for _, g in ipairs(Config.MG) do
	Config.MGBY[g.n] = g
end

-- HABILIDADES
Config.SK = {
	{ id = "pico", name = "Pico afilado", desc = "+25% mineral", max = 10, base = 200, grow = 2.2, col = C3(80, 150, 255) },
	{ id = "botas", name = "Botas ligeras", desc = "+2 velocidad", max = 6, base = 150, grow = 2.5, col = C3(90, 210, 160) },
	{ id = "carro", name = "Carritos grandes", desc = "+100% capacidad", max = 8, base = 300, grow = 2.6, col = C3(230, 150, 70) },
	{ id = "neg", name = "Negociacion", desc = "+15% dinero", max = 10, base = 500, grow = 2.4, col = C3(100, 200, 100) },
	{ id = "gv", name = "Gerentes veloces", desc = "Recogen mas rapido", max = 5, base = 1500, grow = 3, col = C3(230, 200, 60) },
	{ id = "suerte", name = "Suerte dorada", desc = "Mejor suerte al rodar", max = 5, base = 2500, grow = 3.2, col = C3(200, 110, 230) },
	{ id = "crit", name = "Ojo de oro", desc = "+2% golpe critico", max = 10, base = 1200, grow = 2.3, col = C3(235, 80, 90) },
	{ id = "ban", name = "Banquero", desc = "+0.2% interes", max = 8, base = 3000, grow = 3, col = C3(60, 200, 200) },
}

return Config
