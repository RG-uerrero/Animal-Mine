-- Presentacion local: prioridad a lo cercano, sin repetir carteles que se pisan.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Layout = require(Shared.LabelLayout)
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local labels = {}
local order = 0

-- Registra etiquetas del mundo para controlar su visibilidad local.
local function register(instance)
	if not instance:IsA("BillboardGui") or not instance:GetAttribute("WorldText") or labels[instance] then
		return
	end
	order += 1
	labels[instance] = { order = order }
end

-- Espera los atributos de etiquetas recien creadas antes de registrarlas.
local function added(instance)
	if not instance:IsA("BillboardGui") then
		return
	end
	task.defer(register, instance)
	if not instance:GetAttribute("WorldText") then
		instance:GetAttributeChangedSignal("WorldText"):Once(function()
			register(instance)
		end)
	end
end
workspace.DescendantAdded:Connect(added)
playerGui.DescendantAdded:Connect(added)
for _, instance in ipairs(workspace:GetDescendants()) do
	register(instance)
end
for _, instance in ipairs(playerGui:GetDescendants()) do
	register(instance)
end
local priorities = { feedback = 100, detail = 80, info = 70, landmark = 30 }
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.1 then
		return
	end
	elapsed = 0
	local camera = workspace.CurrentCamera
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not camera or not root then
		return
	end
	local small = camera.ViewportSize.X < 760 or camera.ViewportSize.Y < 500
	local candidates = {}
	for gui, entry in pairs(labels) do
		if not gui.Parent then
			labels[gui] = nil
			continue
		end
		local part = gui.Adornee or gui.Parent
		local text = gui:FindFirstChildOfClass("TextLabel")
		local position
		if part:IsA("BasePart") then
			position = part.Position
		elseif part:IsA("Attachment") then
			position = part.WorldPosition
		end
		local wasVisible = gui.Enabled
		gui.Enabled = false
		if not position or not text or text.Text == "" then
			continue
		end
		local range = gui:GetAttribute("TextRange") or 24
		local distance = (root.Position - position).Magnitude
		-- Un pequeno margen evita parpadeos al caminar sobre el limite.
		if distance > range + (wasVisible and 2 or 0) then
			continue
		end
		position += gui.StudsOffsetWorldSpace
		-- La tarjeta no se corta por su objeto, pero tampoco atraviesa muros.
		local rayParams = RaycastParams.new()
		local geometry = part:IsA("Attachment") and part.Parent or part
		local target = geometry.Parent:IsA("Model") and geometry.Parent or geometry
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = { player.Character, target }
		rayParams.RespectCanCollide = true
		local direction = position - camera.CFrame.Position
		if workspace:Raycast(camera.CFrame.Position, direction, rayParams) then
			continue
		end
		local projected, onScreen = camera:WorldToViewportPoint(position)
		if not onScreen or projected.Z <= 0 then
			continue
		end
		local scale = math.clamp(28 / (camera.CFrame.Position - position).Magnitude, 0.6, 1) * (small and 0.86 or 1)
		local width = (gui:GetAttribute("TextWidth") or 180) * scale
		local height = (gui:GetAttribute("TextHeight") or 48) * scale
		local x, y = projected.X - width / 2, projected.Y - height / 2
		if x < 4 or y < 4 or x + width > camera.ViewportSize.X - 4 or y + height > camera.ViewportSize.Y - 4 then
			continue
		end
		gui.Size = UDim2.fromOffset(width, height)
		table.insert(candidates, {
			gui = gui,
			x = x,
			y = y,
			w = width,
			h = height,
			priority = priorities[gui:GetAttribute("TextRole")] or 50,
			distance = distance - (wasVisible and 1.5 or 0),
			order = entry.order,
		})
	end
	local blocked = {}
	local hud = playerGui:FindFirstChild("HUD")
	if hud then
		for _, object in ipairs(hud:GetChildren()) do
			if object:IsA("GuiObject") and object.Visible then
				local pos, size = object.AbsolutePosition, object.AbsoluteSize
				table.insert(blocked, { x = pos.X, y = pos.Y, w = size.X, h = size.Y })
			end
		end
	end
	for _, entry in ipairs(Layout.select(candidates, small and 5 or 8, blocked)) do
		entry.gui.Enabled = true
	end
end)
