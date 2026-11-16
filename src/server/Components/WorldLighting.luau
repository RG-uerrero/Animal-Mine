-- Componente visual de iluminacion; no modifica las reglas del juego.
local Lighting = game:GetService("Lighting")
local color3 = Color3.fromRGB
local WorldLighting = {}
function WorldLighting.apply()
	-- ILUMINACION Y ATMOSFERA
	for _, o in ipairs(Lighting:GetChildren()) do
		if o:IsA("PostEffect") or o:IsA("Atmosphere") then
			o:Destroy()
		end
	end
	Lighting.ClockTime = 11
	Lighting.Brightness = 2.6
	Lighting.Ambient = color3(110, 110, 125)
	Lighting.OutdoorAmbient = color3(140, 140, 155)
	Lighting.ShadowSoftness = 0.3
	local atm = Instance.new("Atmosphere")
	atm.Density = 0.3
	atm.Offset = 0.2
	atm.Color = color3(190, 210, 240)
	atm.Decay = color3(255, 230, 190)
	atm.Glare = 0.3
	atm.Haze = 1.5
	atm.Parent = Lighting
	local cc = Instance.new("ColorCorrectionEffect", Lighting)
	cc.Saturation = 0.2
	cc.Contrast = 0.08
	local bl = Instance.new("BloomEffect", Lighting)
	bl.Intensity = 0.25
	bl.Size = 24
	bl.Threshold = 1.2
	local sr = Instance.new("SunRaysEffect", Lighting)
	sr.Intensity = 0.06
	sr.Spread = 0.7
end
return WorldLighting
