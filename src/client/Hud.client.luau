-- src/client/Hud.client.luau
-- Dibuja el HUD en el CLIENTE. El servidor ya no crea ni actualiza textos en pantalla:
-- solo publica datos (atributos del jugador, el dinero en leaderstats y mensajes por RemoteEvent).
-- Los nombres de los elementos (Cash, Stat, Quest, Evento, Tut, Ger, Msg) se mantienen
-- para que MobileHud.client.luau pueda reacomodarlos en celulares.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Config = require(ReplicatedStorage.Shared.Config)
local F = require(ReplicatedStorage.Shared.Formulas)

local C3 = Color3.fromRGB
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- por si quedara un HUD viejo
local old = playerGui:FindFirstChild("HUD")
if old then
	old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false

local function box(name, pos, size, bg, tc)
	local t = Instance.new("TextLabel")
	t.Name = name
	t.Position = pos
	t.Size = size
	t.BackgroundColor3 = bg
	t.BackgroundTransparency = 0.2
	t.TextColor3 = tc
	t.TextScaled = true
	t.TextWrapped = true
	t.Font = Enum.Font.FredokaOne
	Instance.new("UICorner", t).CornerRadius = UDim.new(0, 12)
	local us = Instance.new("UIStroke", t)
	us.Color = Color3.new(1, 1, 1)
	us.Transparency = 0.75
	us.Thickness = 1.5
	t.Parent = gui
	return t
end

local cash = box("Cash", UDim2.new(0, 12, 0, 90), UDim2.new(0, 220, 0, 44), C3(30, 90, 50), C3(190, 255, 190))
local stat = box("Stat", UDim2.new(0, 12, 0, 138), UDim2.new(0, 220, 0, 30), C3(28, 32, 44), C3(255, 225, 120))
local quest = box("Quest", UDim2.new(0, 12, 0, 174), UDim2.new(0, 220, 0, 74), C3(28, 32, 44), C3(190, 230, 255))
local evb = box("Evento", UDim2.new(0.5, -200, 0, 8), UDim2.new(0, 400, 0, 34), C3(150, 100, 0), C3(255, 240, 160))
evb.Visible = false
local tut = box("Tut", UDim2.new(0.5, -300, 0, 70), UDim2.new(0, 600, 0, 40), C3(0, 0, 0), Color3.new(1, 1, 1))
tut.BackgroundTransparency = 1
local tutStroke = tut:FindFirstChildOfClass("UIStroke")
tutStroke.Color = C3(10, 40, 110)
tutStroke.Transparency = 0
tutStroke.Thickness = 2.5
local ger = box("Ger", UDim2.new(1, -215, 0, 70), UDim2.new(0, 200, 0, 215), C3(24, 30, 50), Color3.new(1, 1, 1))
ger.TextScaled = false
ger.TextSize = 15
ger.TextXAlignment = Enum.TextXAlignment.Left
ger.TextYAlignment = Enum.TextYAlignment.Top
local msg = box("Msg", UDim2.new(0.5, -280, 1, -190), UDim2.new(0, 560, 0, 70), C3(24, 26, 38), Color3.new(1, 1, 1))
msg.Visible = false

-- ======================================================
-- DINERO: se lee directo de leaderstats (cambia al instante, sin viajar texto)
-- ======================================================
local dinero = player:WaitForChild("leaderstats"):WaitForChild("Dinero")
local function updCash()
	cash.Text = "$ " .. F.fmt(dinero.Value)
end
dinero:GetPropertyChangedSignal("Value"):Connect(updCash)
updCash()

-- ======================================================
-- TEXTOS Y DATOS PUBLICADOS POR EL SERVIDOR
-- ======================================================
local function updStat()
	local inc = player:GetAttribute("Income") or 0
	local mult = player:GetAttribute("Mult") or 1
	stat.Text = "+" .. F.fmt(inc) .. "/s   x" .. string.format("%.2f", mult)
end

local function updEvent()
	local on = player:GetAttribute("EvOn") == true
	evb.Visible = on
	if on then
		evb.Text = "HORA DORADA x2   " .. tostring(player:GetAttribute("EvLeft") or 0) .. "s"
	end
end

local textLinks = {
	Quest = quest,
	Tut = tut,
	Ger = ger,
}
for attr, label in pairs(textLinks) do
	label.Text = player:GetAttribute(attr) or ""
	player:GetAttributeChangedSignal(attr):Connect(function()
		label.Text = player:GetAttribute(attr) or ""
	end)
end

for _, attr in ipairs({ "Income", "Mult" }) do
	player:GetAttributeChangedSignal(attr):Connect(updStat)
end
for _, attr in ipairs({ "EvOn", "EvLeft" }) do
	player:GetAttributeChangedSignal(attr):Connect(updEvent)
end
updStat()
updEvent()

-- ======================================================
-- MENSAJES EN PANTALLA (llegan por el RemoteEvent "Notify")
-- ======================================================
local msgToken = 0
local function showMsg(txt)
	msg.Text = txt
	msg.Visible = true
	msgToken += 1
	local n = msgToken
	task.delay(5, function()
		if msgToken == n then
			msg.Visible = false
		end
	end)
end
ReplicatedStorage:WaitForChild("Notify").OnClientEvent:Connect(showMsg)

-- ======================================================
-- CARTELES DE HABILIDADES (sobre cada plataforma de la plaza)
-- ======================================================
local SK = Config.SK
local skillLabels = {}

local function skillText(k)
	local sk = SK[k]
	local lv = player:GetAttribute("sk_" .. sk.id) or 0
	if lv >= sk.max then
		return sk.name .. "\nNIVEL MAXIMO"
	end
	return sk.name .. "\n" .. sk.desc .. "\nNv " .. lv .. "/" .. sk.max .. "  $" .. F.fmt(F.skCost(sk, lv))
end

local function addSkillPad(pad)
	local k = pad:GetAttribute("SkillIndex")
	if not k or skillLabels[k] then
		return
	end
	local bg = Instance.new("BillboardGui")
	bg.Adornee = pad
	bg.Size = UDim2.new(0, 260, 0, 100)
	bg.StudsOffset = Vector3.new(0, 5.5, 0)
	bg.MaxDistance = 45
	local t = Instance.new("TextLabel", bg)
	t.Size = UDim2.new(1, 0, 1, 0)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.2
	t.Text = skillText(k)
	bg.Parent = gui
	skillLabels[k] = t
end

for k, sk in ipairs(SK) do
	player:GetAttributeChangedSignal("sk_" .. sk.id):Connect(function()
		local t = skillLabels[k]
		if t then
			t.Text = skillText(k)
		end
	end)
end

for _, pad in ipairs(CollectionService:GetTagged("SkillPad")) do
	addSkillPad(pad)
end
CollectionService:GetInstanceAddedSignal("SkillPad"):Connect(addSkillPad)

-- ======================================================
-- LISTO: se muestra el HUD y se avisa al servidor para que envie los mensajes pendientes
-- ======================================================
gui.Parent = playerGui
ReplicatedStorage:WaitForChild("HudReady"):FireServer()
