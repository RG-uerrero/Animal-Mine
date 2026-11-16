-- src/client/Hud.client.luau  (version 2: interfaz adaptable)
-- Dibuja el HUD en el CLIENTE. El servidor solo publica datos (atributos del jugador,
-- dinero en leaderstats y mensajes por el RemoteEvent "Notify").
--
-- El HUD se adapta al ancho y alto de la pantalla.
-- WorldLabels.client.luau controla la visibilidad de carteles y textos del mundo.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local WorldText = require(ReplicatedStorage.Shared.WorldText)

local color3 = Color3.fromRGB
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- esperar a que la camara tenga un tamano de pantalla real
local camera = workspace.CurrentCamera
while not camera do
	task.wait()
	camera = workspace.CurrentCamera
end
while camera.ViewportSize.Y <= 1 do
	task.wait()
end

-- tactil sin teclado, o pantalla baja (tambien se activa con el emulador de Studio)

-- Detecta pantallas donde conviene reducir el espacio de la interfaz.
local function isCompact()
	return (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
		or camera.ViewportSize.Y < 500
		or camera.ViewportSize.X < 760
end
local compact = isCompact()

-- ======================================================
-- AJUSTES (aqui se cambia el tamano y la posicion de todo)
-- pos/size en pixeles; max = tamano maximo de letra
-- ======================================================
local LAYOUT = {
	desktop = {
		Cash = { pos = UDim2.new(0, 12, 0, 90), size = UDim2.new(0, 220, 0, 44), max = 28 },
		Stat = { pos = UDim2.new(0, 12, 0, 138), size = UDim2.new(0, 220, 0, 30), max = 20 },
		Quest = { pos = UDim2.new(0, 12, 0, 174), size = UDim2.new(0, 220, 0, 74), max = 17 },
		Evento = { pos = UDim2.new(0.5, -200, 0, 8), size = UDim2.new(0, 400, 0, 34), max = 20 },
		Tut = { pos = UDim2.new(0.5, -300, 0, 70), size = UDim2.new(0, 600, 0, 40), max = 22 },
		Msg = { pos = UDim2.new(0.5, -280, 1, -190), size = UDim2.new(0, 560, 0, 70), max = 26 },
		Ger = { pos = UDim2.new(1, -215, 0, 70), size = UDim2.new(0, 200, 0, 215), text = 15 },
		GerBtn = { pos = UDim2.new(1, -215, 0, 44), size = UDim2.new(0, 200, 0, 22) },
	},
	compact = {
		Cash = { pos = UDim2.new(0, 8, 0, 6), size = UDim2.new(0, 120, 0, 28), max = 18 },
		Stat = { pos = UDim2.new(0, 8, 0, 36), size = UDim2.new(0, 120, 0, 18), max = 12 },
		Quest = { pos = UDim2.new(0, 8, 0, 56), size = UDim2.new(0, 150, 0, 40), max = 12 },
		Evento = { pos = UDim2.new(0.5, -110, 0, 40), size = UDim2.new(0, 220, 0, 22), max = 13 },
		Tut = { pos = UDim2.new(0.5, -150, 0, 4), size = UDim2.new(0, 300, 0, 34), max = 14 },
		Msg = { pos = UDim2.new(0.5, -130, 1, -64), size = UDim2.new(0, 260, 0, 44), max = 15 },
		Ger = { pos = UDim2.new(1, -118, 0, 30), size = UDim2.new(0, 112, 0, 110), text = 11 },
		GerBtn = { pos = UDim2.new(1, -118, 0, 6), size = UDim2.new(0, 112, 0, 22) },
	},
}

-- por si quedara un HUD viejo
local old = playerGui:FindFirstChild("HUD")
if old then
	old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false

-- Limita el tamano de letra para mantener textos legibles.

local function limitText(label, max)
	local con = label:FindFirstChildOfClass("UITextSizeConstraint")
	if not con then
		con = Instance.new("UITextSizeConstraint")
		con.Parent = label
	end
	con.MaxTextSize = max
end

-- Construye un panel de texto reutilizable del HUD.

local function box(name, bg, tc)
	local t = Instance.new("TextLabel")
	t.Name = name
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
	limitText(t, 20)
	t.Parent = gui
	return t
end

local cash = box("Cash", color3(30, 90, 50), color3(190, 255, 190))
local stat = box("Stat", color3(28, 32, 44), color3(255, 225, 120))
local quest = box("Quest", color3(28, 32, 44), color3(190, 230, 255))
local evb = box("Evento", color3(150, 100, 0), color3(255, 240, 160))
evb.Visible = false
local tut = box("Tut", color3(0, 0, 0), Color3.new(1, 1, 1))
local tutStroke = tut:FindFirstChildOfClass("UIStroke")
tutStroke.Color = color3(10, 40, 110)
tutStroke.Transparency = 0
tutStroke.Thickness = 2.5
local msg = box("Msg", color3(24, 26, 38), Color3.new(1, 1, 1))
msg.Visible = false

-- panel de gerentes (texto de tamano fijo) y su boton para plegarlo
local ger = box("Ger", color3(24, 30, 50), Color3.new(1, 1, 1))
ger.TextScaled = false
ger.TextXAlignment = Enum.TextXAlignment.Left
ger.TextYAlignment = Enum.TextYAlignment.Top
ger.BackgroundTransparency = 1
ger.Font = Enum.Font.GothamSemibold
ger:FindFirstChildOfClass("UIStroke"):Destroy()
local gerPanel = Instance.new("ScrollingFrame")
gerPanel.Name = "GerPanel"
gerPanel.BackgroundColor3 = color3(24, 30, 50)
gerPanel.BackgroundTransparency = 0.15
gerPanel.BorderSizePixel = 0
gerPanel.ClipsDescendants = true
gerPanel.ScrollBarThickness = 4
gerPanel.ScrollBarImageColor3 = color3(230, 200, 120)
gerPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
gerPanel.CanvasSize = UDim2.fromOffset(0, 0)
Instance.new("UICorner", gerPanel).CornerRadius = UDim.new(0, 12)
gerPanel.Parent = gui
ger.Parent = gerPanel
ger.Position = UDim2.fromOffset(8, 8)
ger.Size = UDim2.new(1, -20, 0, 0)
ger.AutomaticSize = Enum.AutomaticSize.Y

local gerBtn = Instance.new("TextButton")
gerBtn.Name = "GerBtn"
gerBtn.BackgroundColor3 = color3(24, 30, 50)
gerBtn.BackgroundTransparency = 0.2
gerBtn.TextColor3 = Color3.new(1, 1, 1)
gerBtn.Font = Enum.Font.FredokaOne
gerBtn.TextScaled = true
Instance.new("UICorner", gerBtn).CornerRadius = UDim.new(0, 8)
limitText(gerBtn, 14)
gerBtn.Parent = gui

local gerOpen = not compact -- en pantallas pequenas empieza plegado

-- ======================================================
-- DISENO ADAPTABLE
-- ======================================================
local ui = { Cash = cash, Stat = stat, Quest = quest, Evento = evb, Tut = tut, Msg = msg }

-- Reubica los paneles segun la pantalla disponible.

local function applyLayout()
	compact = isCompact()
	local Lighting = compact and LAYOUT.compact or LAYOUT.desktop
	for name, label in pairs(ui) do
		local cfg = Lighting[name]
		label.Position = cfg.pos
		label.Size = cfg.size
		limitText(label, cfg.max)
	end
	tut.BackgroundTransparency = compact and 0.5 or 1
	gerPanel.Position = Lighting.Ger.pos
	gerPanel.Size = Lighting.Ger.size
	ger.TextSize = Lighting.Ger.text
	gerPanel.Visible = gerOpen
	gerBtn.Position = Lighting.GerBtn.pos
	gerBtn.Size = Lighting.GerBtn.size
	gerBtn.Text = gerOpen and "Gerentes -" or "Gerentes +"
	-- Vertical: separar tutorial/evento del dinero, misiones y controles.
	if camera.ViewportSize.X < 620 then
		tut.Position = UDim2.new(0, 8, 0, 104)
		tut.Size = UDim2.new(1, -16, 0, 48)
		evb.Position = UDim2.new(0, 8, 0, 158)
		evb.Size = UDim2.new(1, -16, 0, 24)
		gerPanel.Position = UDim2.new(1, -118, 0, 188)
	end
end

gerBtn.Activated:Connect(function()
	gerOpen = not gerOpen
	applyLayout()
end)
camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyLayout)
applyLayout()

-- ======================================================
-- DINERO: se lee directo de leaderstats
-- ======================================================
local getMoney = player:WaitForChild("leaderstats"):WaitForChild("Dinero")

-- Refresca el saldo mostrado a partir del dato replicado por el servidor.
local function updateCash()
	cash.Text = "$ " .. Formulas.formatNumber(getMoney.Value)
end
getMoney:GetPropertyChangedSignal("Value"):Connect(updateCash)
updateCash()

-- ======================================================
-- TEXTOS Y DATOS PUBLICADOS POR EL SERVIDOR
-- ======================================================

-- Refresca la produccion y los multiplicadores del HUD.
local function updateStats()
	local inc = player:GetAttribute("Income") or 0
	local mult = player:GetAttribute("Mult") or 1
	stat.Text = "+" .. Formulas.fmtRate(inc) .. "/s   x" .. string.format("%.2f", mult)
end

-- Muestra o retira el aviso de evento.

local function updateEvent()
	local on = player:GetAttribute("EvOn") == true
	evb.Visible = on
	if on then
		evb.Text = "HORA DORADA x"
			.. string.format("%g", Config.Economy.EVENT_MULTIPLIER)
			.. "   "
			.. tostring(player:GetAttribute("EvLeft") or 0)
			.. "s"
	end
end

local textLinks = { Quest = quest, Tut = tut, Ger = ger }
for attr, label in pairs(textLinks) do
	label.Text = player:GetAttribute(attr) or ""
	player:GetAttributeChangedSignal(attr):Connect(function()
		label.Text = player:GetAttribute(attr) or ""
	end)
end
for _, attr in ipairs({ "Income", "Mult" }) do
	player:GetAttributeChangedSignal(attr):Connect(updateStats)
end
for _, attr in ipairs({ "EvOn", "EvLeft" }) do
	player:GetAttributeChangedSignal(attr):Connect(updateEvent)
end
updateStats()
updateEvent()

-- ======================================================
-- MENSAJES EN PANTALLA (RemoteEvent "Notify")
-- ======================================================
local msgToken = 0

-- Presenta los mensajes recibidos del servidor.
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
local SKILLS = Config.SKILLS
local skillLabels = {}

-- Compone nombre, beneficio, nivel y precio de una habilidad.

local function skillText(k)
	local sk = SKILLS[k]
	local lv = player:GetAttribute("sk_" .. sk.id) or 0
	if lv >= sk.max then
		return sk.name .. "\nNIVEL MAXIMO"
	end
	return sk.name
		.. "\n"
		.. sk.desc
		.. "\nNv "
		.. lv
		.. "/"
		.. sk.max
		.. "  $"
		.. Formulas.formatNumber(Formulas.skillCost(sk, lv))
end

-- Conecta la plataforma de habilidad con su etiqueta y estado local.

local function addSkillPad(pad)
	local k = pad:GetAttribute("SkillIndex")
	if not k or not SKILLS[k] or skillLabels[k] then
		return
	end
	local bg = Instance.new("BillboardGui")
	WorldText.configure(bg, "info", 188, 94, 28)
	WorldText.anchor(bg, pad, 5.5)
	local t = Instance.new("TextLabel", bg)
	t.Size = UDim2.new(1, 0, 1, 0)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = Color3.new(1, 1, 1)
	WorldText.style(t, "info")
	t.Text = skillText(k)
	bg.Parent = gui
	skillLabels[k] = t
end

for k, sk in ipairs(SKILLS) do
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
-- ESTADO DE CARGA Y GUARDADO
local status = Instance.new("TextLabel")
status.Name = "SaveStatus"
status.Size = UDim2.new(1, -24, 0, 24)
status.Position = UDim2.new(0, 12, 1, -26)
status.BackgroundColor3 = color3(70, 45, 20)
status.TextColor3 = Color3.new(1, 1, 1)
status.Font = Enum.Font.GothamBold
status.TextSize = 12
status.TextWrapped = true
status.Parent = gui
local loading = Instance.new("TextButton")
loading.Name = "Loading"
loading.Size = UDim2.fromScale(1, 1)
loading.BackgroundColor3 = color3(20, 26, 38)
loading.BackgroundTransparency = 0.1
loading.Text = "Cargando tu mina..."
loading.TextColor3 = Color3.new(1, 1, 1)
loading.TextSize = 22
loading.Font = Enum.Font.GothamBold
loading.AutoButtonColor = false
loading.ZIndex = 20
loading.Modal = true
loading.Parent = gui

-- Indica si la partida carga, guarda o funciona como prueba temporal.
local function updateSaveStatus()
	loading.Visible = player:GetAttribute("DataReady") ~= true
	local state = player:GetAttribute("SaveStatus")
	status.Visible = state == "disabled" or state == "error"
	status.Text = state == "disabled" and "MODO DE PRUEBA: esta partida NO se guarda"
		or "No se pudo guardar tu progreso"
end
player:GetAttributeChangedSignal("DataReady"):Connect(updateSaveStatus)
player:GetAttributeChangedSignal("SaveStatus"):Connect(updateSaveStatus)
updateSaveStatus()

-- CONFIRMACION DE RENACER: el servidor valida token, plazo y requisitos.
local prestigeRemote = ReplicatedStorage:WaitForChild("PrestigeConfirm")
local modal = Instance.new("TextButton")
modal.Name = "PrestigeConfirmation"
modal.Size = UDim2.fromScale(1, 1)
modal.BackgroundColor3 = Color3.new(0, 0, 0)
modal.BackgroundTransparency = 0.25
modal.Text = ""
modal.AutoButtonColor = false
modal.Modal = true
modal.Visible = false
modal.ZIndex = 30
modal.Parent = gui
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.9, 0, 0, 260)
panel.BackgroundColor3 = color3(24, 30, 50)
panel.ZIndex = 31
panel.Parent = modal
local sizeLimit = Instance.new("UISizeConstraint", panel)
sizeLimit.MaxSize = Vector2.new(440, 260)
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)
local explanation = Instance.new("TextLabel")
explanation.Position = UDim2.new(0, 16, 0, 12)
explanation.Size = UDim2.new(1, -32, 0, 170)
explanation.BackgroundTransparency = 1
explanation.TextColor3 = Color3.new(1, 1, 1)
explanation.TextWrapped = true
explanation.TextScaled = true
explanation.Font = Enum.Font.GothamBold
explanation.ZIndex = 32
limitText(explanation, 18)
explanation.Parent = panel
local pendingToken

-- Envia la respuesta de confirmacion usando el token del servidor.
local function finishPrestige(accept)
	local token = pendingToken
	pendingToken = nil
	modal.Visible = false
	if token then
		prestigeRemote:FireServer(token, accept)
	end
end
for index, text in ipairs({ "Cancelar", "Si, renacer" }) do
	local button = Instance.new("TextButton")
	button.Position = UDim2.new((index - 1) * 0.5, 12, 1, -62)
	button.Size = UDim2.new(0.5, -24, 0, 48)
	button.BackgroundColor3 = index == 1 and color3(65, 75, 95) or color3(45, 125, 65)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Text = text
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.ZIndex = 32
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 10)
	button.Parent = panel
	button.Activated:Connect(function()
		finishPrestige(index == 2)
	end)
end
prestigeRemote.OnClientEvent:Connect(function(token, cost)
	pendingToken = token
	explanation.Text = "RENACER\n\nNecesitas $"
		.. Formulas.formatNumber(cost)
		.. ". Tus mineros y su mineral se reinician, el deposito queda vacio y empiezas con $30.\n\nConservas gerentes, habilidades, slots y nivel del deposito. Ganas +"
		.. string.format("%g", Config.Economy.PRESTIGE_BONUS * 100)
		.. "% de dinero permanente."
	modal.Visible = true
	task.delay(15, function()
		if pendingToken == token then
			finishPrestige(false)
		end
	end)
end)

-- LISTO: se muestra el HUD y se avisa al servidor para que envie los mensajes pendientes
-- ======================================================
gui.Parent = playerGui
ReplicatedStorage:WaitForChild("HudReady"):FireServer()
