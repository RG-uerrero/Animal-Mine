-- Pegar en la barra de comandos del CLIENTE durante Play. No toca datos persistentes.
local p = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local layout = require(game.ReplicatedStorage.Shared.LabelLayout)
local root = p.Character:WaitForChild("HumanoidRootPart")
local start = p.Character:GetPivot()
camera.CameraType = Enum.CameraType.Scriptable
p.Character:PivotTo(CFrame.new(-160, 5, -22))
for _, eye in ipairs({ Vector3.new(-185, 13, -2), Vector3.new(-160, 13, -2), Vector3.new(-135, 13, -2) }) do
	camera.CFrame = CFrame.lookAt(eye, Vector3.new(-160, 5, -30))
	task.wait(0.4)
	local visible = {}
	for _, g in ipairs(workspace:GetDescendants()) do
		if g:IsA("BillboardGui") and g:GetAttribute("WorldText") and g.Enabled then
			local anchor = g.Adornee
			local pos = camera:WorldToViewportPoint(anchor.WorldPosition)
			local w, h = g.Size.X.Offset, g.Size.Y.Offset
			table.insert(visible, { x = pos.X - w / 2, y = pos.Y - h / 2, w = w, h = h })
		end
	end
	assert(#visible > 0, "near labels must be visible")
	for i, a in ipairs(visible) do
		for j = i + 1, #visible do
			assert(not layout.overlaps(a, visible[j], 0), "labels overlap")
		end
	end
	print("QA_WORLD_LABELS_OK", eye, #visible)
end
p.Character:PivotTo(CFrame.new(-150, 5, 100))
task.wait(0.4)
for _, g in ipairs(workspace:GetDescendants()) do
	if g:IsA("BillboardGui") and g:GetAttribute("WorldText") and g.Parent.Name == "Boton" then
		assert(not g.Enabled, "distant prices must be hidden")
	end
end
print("QA_DISTANT_PRICES_HIDDEN")
p.Character:PivotTo(start)
camera.CameraType = Enum.CameraType.Custom
