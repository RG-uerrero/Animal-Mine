-- Ejecutar en la barra de comandos de Studio, contexto SERVIDOR durante Play.
local Models = require(game.ServerScriptService.Server.AnimalModels)
local Config = require(game.ReplicatedStorage.Shared.Config)
local staging = Instance.new("Folder")
local cases = 0
local maxParts = 0
for _, group in ipairs({ Config.MINERS, Config.MANAGERS }) do
	for _, data in ipairs(group) do
		local manager = data.b ~= nil
		local model, body = Models.build(CFrame.new(), data.a, data.c, data.k, {
			name = data.n,
			helmet = not manager,
			tie = manager,
			aura = manager and data.r >= 3 and Config.RARITIES[data.r].c or nil,
			parent = staging,
		})
		assert(model.PrimaryPart == body and body.Name == "Body", "animation root is preserved")
		assert((body.Position - Vector3.new(0, 1.9, 0)).Magnitude < 0.001, "root height is preserved")
		assert(model:GetAttribute("Role") == (manager and "Manager" or "Miner"))
		assert(model:FindFirstChild(manager and "Corbata" or "Casco"), "profession accessory exists")
		assert(model:FindFirstChild("OjoBlanco") and model:FindFirstChild("BrilloOjo"), "face is complete")
		assert(model.Cabeza:FindFirstChildOfClass("SpecialMesh"), "oval proportions use a sphere mesh")
		if not manager then
			assert(
				(model.ManoPico.Position - model:GetAttribute("ToolGrip")).Magnitude < 0.001,
				"pickaxe grip meets the paw"
			)
		end
		local count = 0
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				count += 1
				assert(
					part.Anchored and not part.CanCollide and not part.CanTouch,
					"decorative geometry cannot block players"
				)
				assert(part.Size.X > 0 and part.Size.Y > 0 and part.Size.Z > 0)
			end
		end
		maxParts = math.max(maxParts, count)
		assert(count <= 100, "character geometry budget exceeded")
		local position = CFrame.new(10, 7, -20) * CFrame.Angles(0, 0.7, 0)
		model:PivotTo(position)
		assert((body.Position - position.Position).Magnitude < 0.001, "PivotTo keeps the animation root")
		print("QA_MODEL", data.n, model:GetAttribute("Species"), count)
		cases += 1
	end
end
staging:Destroy()
print("QA_ANIMAL_MODELS_OK", cases, "max parts", maxParts)
