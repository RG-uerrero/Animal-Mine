-- Estilo comun para informacion del mundo; no contiene reglas de economia.
local WorldText = {}
function WorldText.style(text, role)
	text.Font = Enum.Font.GothamSemibold
	text.TextScaled = true
	text.TextWrapped = true
	text.TextStrokeTransparency = 1
	text.TextColor3 = Color3.fromRGB(245, 241, 224)
	text.BackgroundColor3 = Color3.fromRGB(26, 35, 39)
	text.BackgroundTransparency = role == "feedback" and 1 or 0.12
	local size = Instance.new("UITextSizeConstraint")
	size.MaxTextSize = role == "landmark" and 20 or 17
	size.MinTextSize = 9
	size.Parent = text
	Instance.new("UICorner", text).CornerRadius = UDim.new(0, 8)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.Parent = text
end
function WorldText.configure(gui, role, width, height, range)
	gui.Name = "WorldLabel"
	gui.Enabled = false -- El cliente muestra solo las etiquetas seleccionadas.
	gui:SetAttribute("WorldText", true)
	gui:SetAttribute("TextRole", role or "detail")
	gui:SetAttribute("TextWidth", width)
	gui:SetAttribute("TextHeight", height)
	gui:SetAttribute("TextRange", range)
	gui.Size = UDim2.fromOffset(width, height)
	gui.MaxDistance = math.max(range, 80)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
end
function WorldText.anchor(gui, part, height)
	local anchor = Instance.new("Attachment")
	anchor.Name = "TextAnchor"
	anchor.Position = part.CFrame:VectorToObjectSpace(Vector3.new(0, height, 0))
	anchor.Parent = part
	gui.Adornee = anchor
	return anchor
end
return WorldText
