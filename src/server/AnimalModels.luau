-- Personajes hechos con geometria local: sin modelos externos ni cambios al guardado.
-- Body conserva el pivote a 1.9 studs que utilizan las animaciones de Main.
local AnimalModels = {}
local vector3 = Vector3.new
local C = Color3.fromRGB
local SPHERE_SHAPE = Enum.PartType.Ball
local PLASTIC = Enum.Material.SmoothPlastic
local INK = C(35, 39, 52)
local CREAM = C(255, 244, 220)
local PINK = C(240, 157, 170)
local GOLD = C(235, 180, 65)
local NAVY = C(49, 79, 105)

-- Identifica la especie para elegir rasgos del modelo.

local function species(name, ears)
	local names = {
		{ "Ratita", "mouse" },
		{ "Pollito", "chick" },
		{ "Conej", "rabbit" },
		{ "Rana", "frog" },
		{ "Cerdito", "pig" },
		{ "Zorr", "fox" },
		{ "Zorro", "fox" },
		{ "Panda", "panda" },
		{ "Pandita", "panda" },
		{ "Buho", "owl" },
		{ "Tigre", "tiger" },
		{ "Lobo", "wolf" },
		{ "Leon", "lion" },
		{ "Dragon", "dragon" },
		{ "Fenix", "phoenix" },
	}
	for _, entry in ipairs(names) do
		if string.find(name, entry[1], 1, true) then
			return entry[2]
		end
	end
	return ears == "long" and "rabbit" or "bear"
end

function AnimalModels.build(cf, ca, cb, ears, options)
	local ex = options or {}
	local kind = species(ex.name or "", ears)
	local fur = typeof(ca) == "Color3" and ca or BrickColor.new(ca).Color
	local secondary = typeof(cb) == "Color3" and cb or BrickColor.new(cb).Color
	local soft = fur:Lerp(CREAM, 0.42)
	local darkFur = fur:Lerp(INK, 0.25)
	local manager = ex.tie == true
	local toolGrip = vector3(1.42, 2.1, -0.6)
	local accent = ex.aura or (kind == "mouse" and C(85, 167, 150) or C(211, 105, 80))
	local model = Instance.new("Model")
	model.Name = ex.name or "Animal"
	model:SetAttribute("Species", kind)
	model:SetAttribute("Role", manager and "Manager" or "Miner")
	model:SetAttribute("ModelVersion", 2)
	if ex.helmet then
		model:SetAttribute("ToolGrip", toolGrip)
	end
	local function part(name, size, offset, color, shape, rotation, material)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Material = material or PLASTIC
		p.Color = color
		local actualShape = shape or SPHERE_SHAPE
		p.Shape = actualShape == SPHERE_SHAPE and Enum.PartType.Block or actualShape
		if actualShape == SPHERE_SHAPE then
			-- La esfera incorporada conserva las proporciones de cada eje.
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = p
		end
		p.CastShadow = size.X > 0.25 and size.Y > 0.25
		p.CFrame = cf * CFrame.new(offset) * (rotation or CFrame.identity)
		p.Parent = model
		return p
	end
	local function wedge(name, size, offset, color, rotation)
		local p = Instance.new("WedgePart")
		p.Name, p.Size, p.Color = name, size, color
		p.Material = PLASTIC
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
		p.CFrame = cf * CFrame.new(offset) * (rotation or CFrame.identity)
		p.Parent = model
		return p
	end
	local function oval(name, size, offset, color, tilt)
		return part(name, size, offset, color, SPHERE_SHAPE, CFrame.Angles(0, 0, math.rad(tilt or 0)))
	end

	-- Cabeza grande, cuerpo compacto y patas anchas: una silueta legible de lejos.
	local body = oval("Body", vector3(2.25, 2.45, 1.95), vector3(0, 1.9, 0), fur)
	oval(
		"Cabeza",
		kind == "frog" and vector3(3.1, 2.3, 2.25) or vector3(2.95, 2.65, 2.35),
		vector3(0, 3.95, -0.05),
		fur
	)
	oval("Panza", vector3(1.65, 1.8, 0.5), vector3(0, 1.85, -0.86), soft)
	for _, side in ipairs({ -1, 1 }) do
		oval(
			"Brazo",
			vector3(0.78, 1.48, 0.86),
			vector3(side * 1.29, ex.helmet and side == 1 and 2.25 or 2.05, ex.helmet and side == 1 and -0.27 or -0.03),
			fur,
			side * 12
		)
		oval(
			ex.helmet and side == 1 and "ManoPico" or "Manopla",
			vector3(0.78, 0.72, 0.85),
			ex.helmet and side == 1 and toolGrip or vector3(side * 1.42, 1.55, -0.15),
			soft
		)
		oval("Pie", vector3(1.12, 0.68, 1.45), vector3(side * 0.69, 0.53, -0.25), manager and INK or C(105, 79, 63))
		oval("Suela", vector3(1.15, 0.18, 1.48), vector3(side * 0.69, 0.26, -0.25), INK)
	end

	-- Orejas y colas propias de cada especie.
	if kind == "rabbit" then
		for _, side in ipairs({ -1, 1 }) do
			oval("OrejaLarga", vector3(0.7, 2.3, 0.64), vector3(side * 0.73, 6.08, 0.05), fur, -side * 12)
			oval("InteriorOreja", vector3(0.36, 1.72, 0.16), vector3(side * 0.76, 6.12, -0.25), PINK, -side * 12)
		end
		oval("ColaAlgodon", vector3(1, 1, 0.95), vector3(0, 1.45, 1.1), CREAM)
	elseif kind == "mouse" then
		for _, side in ipairs({ -1, 1 }) do
			oval("OrejaRedonda", vector3(1.4, 1.5, 0.5), vector3(side * 1.25, 5.03, 0), fur, -side * 14)
			oval("InteriorOreja", vector3(0.94, 1.02, 0.16), vector3(side * 1.25, 5.04, -0.25), PINK, -side * 14)
		end
		oval("Cola", vector3(0.3, 0.3, 1.4), vector3(0, 1.25, 1.45), PINK)
		oval("ColaCurva", vector3(1.3, 0.28, 0.32), vector3(0.52, 1.24, 2.03), PINK, 12)
	elseif kind == "fox" or kind == "wolf" or kind == "pig" then
		for _, side in ipairs({ -1, 1 }) do
			wedge(
				"OrejaPunta",
				vector3(0.85, 1.3, 0.7),
				vector3(side * 1.0, 5.18, 0.04),
				fur,
				CFrame.Angles(0, 0, math.rad(-side * 16))
			)
			wedge(
				"InteriorOreja",
				vector3(0.48, 0.83, 0.12),
				vector3(side * 1.02, 5.19, -0.34),
				kind == "pig" and PINK or CREAM,
				CFrame.Angles(0, 0, math.rad(-side * 16))
			)
		end
		oval("Cola", vector3(1.15, 1.2, 2.0), vector3(0, 1.4, 1.55), fur, -18)
		oval("PuntaCola", vector3(0.95, 1.0, 1.05), vector3(0, 1.45, 2.36), kind == "pig" and PINK or CREAM)
	elseif kind == "chick" or kind == "phoenix" then
		for i = -1, 1 do
			oval(
				"Cresta",
				vector3(0.33, 0.8 + 0.2 * (i + 1), 0.42),
				vector3(i * 0.28, 5.25, 0.15),
				kind == "chick" and C(239, 151, 66) or C(244, 112, 46),
				i * 18
			)
		end
	elseif kind ~= "frog" and kind ~= "dragon" and kind ~= "owl" then
		for _, side in ipairs({ -1, 1 }) do
			oval(
				"OrejaRedonda",
				vector3(0.95, 1.0, 0.64),
				vector3(side * 1.18, 5.0, 0.04),
				kind == "panda" and INK or fur
			)
			oval(
				"InteriorOreja",
				vector3(0.53, 0.57, 0.17),
				vector3(side * 1.18, 5.0, -0.28),
				kind == "panda" and C(94, 100, 113) or secondary
			)
		end
		oval("Cola", vector3(0.65, 0.65, 0.65), vector3(0, 1.38, 1.05), darkFur)
	end

	if kind == "lion" then
		for i = 0, 9 do
			local angle = i * math.pi * 2 / 10
			oval(
				"Melena",
				vector3(1.25, 1.35, 1.0),
				vector3(math.cos(angle) * 1.39, 3.96 + math.sin(angle) * 1.34, 0.31),
				secondary,
				-i * 36
			)
		end
	elseif kind == "tiger" then
		for _, side in ipairs({ -1, 1 }) do
			for i = 0, 2 do
				oval(
					"RayaMejilla",
					vector3(0.46, 0.13, 0.14),
					vector3(side * 1.03, 3.56 + i * 0.29, -0.98),
					INK,
					side * (12 + i * 5)
				)
			end
		end
		oval("RayaFrente", vector3(0.22, 0.56, 0.12), vector3(0, 4.88, -0.82), INK)
	end

	-- Ojos con volumen y brillo pequeno; sin luces de neon sobre toda la cara.
	local eyeY = kind == "frog" and 4.65 or 4.13
	for _, side in ipairs({ -1, 1 }) do
		if kind == "panda" or kind == "owl" then
			oval(
				"MascaraOjo",
				vector3(1.04, 1.18, 0.36),
				vector3(side * 0.67, eyeY, -1.02),
				kind == "panda" and INK or CREAM,
				-side * 13
			)
		elseif kind == "frog" then
			oval("OjoElevado", vector3(1.12, 1.15, 0.9), vector3(side * 0.79, 4.65, -0.45), fur)
		end
		oval("OjoBlanco", vector3(0.69, 0.83, 0.24), vector3(side * 0.65, eyeY, -1.14), C(255, 253, 242), -side * 5)
		oval("Pupila", vector3(0.39, 0.58, 0.16), vector3(side * 0.64, eyeY - 0.02, -1.29), INK)
		oval("BrilloOjo", vector3(0.15, 0.18, 0.06), vector3(side * 0.64 - 0.075, eyeY + 0.12, -1.38), CREAM)
		oval("Mejilla", vector3(0.42, 0.22, 0.1), vector3(side * 1.02, 3.63, -1.02), fur:Lerp(PINK, 0.5))
		oval("Ceja", vector3(0.49, 0.11, 0.12), vector3(side * 0.65, eyeY + 0.55, -1.01), darkFur, side * 8)
	end
	if kind == "chick" or kind == "owl" or kind == "phoenix" then
		wedge("Pico", vector3(0.68, 0.5, 0.78), vector3(0, 3.65, -1.27), GOLD, CFrame.Angles(math.rad(180), 0, 0))
	elseif kind == "pig" then
		oval("Trompa", vector3(1.12, 0.76, 0.48), vector3(0, 3.65, -1.26), PINK)
		for _, side in ipairs({ -1, 1 }) do
			oval("FosaNasal", vector3(0.14, 0.2, 0.06), vector3(side * 0.25, 3.68, -1.51), darkFur)
		end
	elseif kind == "frog" then
		for _, side in ipairs({ -1, 1 }) do
			oval("FosaNasal", vector3(0.12, 0.12, 0.08), vector3(side * 0.22, 3.93, -1.18), darkFur)
		end
	else
		for _, side in ipairs({ -1, 1 }) do
			oval(
				"Hocico",
				vector3(0.82, 0.59, 0.46),
				vector3(side * 0.3, 3.55, -1.1),
				kind == "mouse" and soft or CREAM
			)
		end
		oval(
			"Nariz",
			vector3(0.39, 0.27, 0.22),
			vector3(0, 3.75, -1.43),
			(kind == "rabbit" or kind == "mouse") and PINK or INK
		)
	end
	for _, side in ipairs({ -1, 1 }) do
		oval("Sonrisa", vector3(0.29, 0.07, 0.08), vector3(side * 0.13, 3.37, -1.35), INK, side * 14)
	end
	if kind == "rabbit" then
		part("Diente", vector3(0.36, 0.32, 0.12), vector3(0, 3.25, -1.31), CREAM, Enum.PartType.Block)
	elseif kind == "mouse" then
		for _, side in ipairs({ -1, 1 }) do
			for i = -1, 1 do
				part(
					"Bigote",
					vector3(0.65, 0.035, 0.035),
					vector3(side * 1.07, 3.49 + i * 0.17, -1.22),
					CREAM,
					Enum.PartType.Block,
					CFrame.Angles(0, 0, math.rad(side * i * 12))
				)
			end
		end
	end

	-- Profesion: peto y casco frente a chaleco, corbata y libreta.
	oval("Uniforme", vector3(2.31, 1.65, 2.0), vector3(0, 1.63, 0), manager and NAVY:Lerp(accent, 0.25) or NAVY)
	if manager then
		part("Camisa", vector3(0.9, 1.13, 0.12), vector3(0, 2.3, -1.02), CREAM, Enum.PartType.Block)
		for _, side in ipairs({ -1, 1 }) do
			part(
				"Solapa",
				vector3(0.36, 0.82, 0.14),
				vector3(side * 0.48, 2.34, -1.1),
				NAVY,
				Enum.PartType.Block,
				CFrame.Angles(0, 0, math.rad(side * 22))
			)
		end
		oval("NudoCorbata", vector3(0.25, 0.24, 0.14), vector3(0, 2.66, -1.18), accent)
		wedge("Corbata", vector3(0.32, 0.64, 0.14), vector3(0, 2.23, -1.19), accent)
		part(
			"Libreta",
			vector3(0.87, 1.13, 0.18),
			vector3(1.5, 1.94, -0.63),
			C(124, 87, 61),
			Enum.PartType.Block,
			CFrame.Angles(0, 0, math.rad(-12))
		)
		part(
			"Papel",
			vector3(0.68, 0.9, 0.04),
			vector3(1.5, 1.94, -0.74),
			CREAM,
			Enum.PartType.Block,
			CFrame.Angles(0, 0, math.rad(-12))
		)
		part("Clip", vector3(0.35, 0.13, 0.08), vector3(1.6, 2.44, -0.78), GOLD, Enum.PartType.Block)
		for i = 0, 2 do
			part(
				"LineaLibreta",
				vector3(0.42, 0.035, 0.025),
				vector3(1.5, 2.1 - i * 0.18, -0.78),
				NAVY,
				Enum.PartType.Block
			)
		end
	else
		oval("Peto", vector3(1.36, 1.23, 0.18), vector3(0, 2.05, -1.04), NAVY:Lerp(CREAM, 0.15))
		for _, side in ipairs({ -1, 1 }) do
			part(
				"Tirante",
				vector3(0.26, 0.83, 0.14),
				vector3(side * 0.56, 2.62, -0.92),
				NAVY,
				Enum.PartType.Block,
				CFrame.Angles(0, 0, math.rad(side * 9))
			)
			oval("BotonPeto", vector3(0.16, 0.16, 0.08), vector3(side * 0.55, 2.31, -1.17), GOLD)
		end
		part("Bolsillo", vector3(0.59, 0.4, 0.1), vector3(0, 1.94, -1.19), NAVY, Enum.PartType.Block)
	end
	if ex.helmet then
		oval("Casco", vector3(3.04, 0.95, 2.55), vector3(0, 5.07, -0.05), C(247, 193, 65))
		oval("Visera", vector3(3.13, 0.18, 2.73), vector3(0, 4.79, -0.16), GOLD)
		part("BandaCasco", vector3(1.18, 0.22, 0.12), vector3(0, 4.97, -1.35), INK, Enum.PartType.Block)
		oval("MarcoFoco", vector3(0.63, 0.63, 0.22), vector3(0, 5.05, -1.42), INK)
		local lamp = oval("Foco", vector3(0.43, 0.43, 0.14), vector3(0, 5.05, -1.56), C(255, 239, 177))
		lamp.Material = Enum.Material.Neon
		local light = Instance.new("PointLight")
		light.Color, light.Range, light.Brightness = C(255, 230, 173), 6, 0.45
		light.Parent = lamp
	end
	if kind == "dragon" or kind == "phoenix" then
		for _, side in ipairs({ -1, 1 }) do
			for i = 0, 2 do
				wedge(
					"PlumaAla",
					vector3(0.18, 1.75 - i * 0.26, 1.1),
					vector3(side * (1.5 + i * 0.36), 2.8 - i * 0.15, 0.76),
					kind == "phoenix" and C(240, 114 + i * 23, 44) or C(154, 59, 65),
					CFrame.Angles(0, math.rad(side * 25), math.rad(-side * 30))
				)
			end
			if kind == "dragon" then
				wedge(
					"Cuerno",
					vector3(0.43, 1.07, 0.52),
					vector3(side * 0.91, 5.28, 0.15),
					CREAM,
					CFrame.Angles(0, 0, math.rad(-side * 20))
				)
			end
		end
		oval("Cola", vector3(0.8, 0.7, 1.5), vector3(0, 1.4, 1.35), fur)
		for i = 0, 2 do
			wedge("Espina", vector3(0.3, 0.53, 0.4), vector3(0, 2.1 - i * 0.25, 1 + i * 0.43), GOLD)
		end
	end
	if ex.aura then
		local aura = part(
			"Aura",
			vector3(0.1, 4.6, 4.6),
			vector3(0, 0.12, 0),
			ex.aura,
			Enum.PartType.Cylinder,
			CFrame.Angles(0, 0, math.pi / 2),
			Enum.Material.Neon
		)
		aura.Transparency = 0.65
		aura.CastShadow = false
	end
	model.PrimaryPart = body
	model.Parent = ex.parent or workspace
	return model, body
end

return AnimalModels
