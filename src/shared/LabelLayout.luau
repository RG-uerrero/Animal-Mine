-- Rectangulos en pantalla. Independiente de Roblox para probar la seleccion.
local Layout = {}
function Layout.overlaps(a, b, gap)
	gap = gap or 6
	return a.x < b.x + b.w + gap and a.x + a.w + gap > b.x and a.y < b.y + b.h + gap and a.y + a.h + gap > b.y
end
function Layout.select(candidates, budget, blocked)
	table.sort(candidates, function(a, b)
		if a.priority ~= b.priority then
			return a.priority > b.priority
		end
		if a.distance ~= b.distance then
			return a.distance < b.distance
		end
		return a.order < b.order
	end)
	local selected = {}
	local occupied = table.clone(blocked or {})
	for _, candidate in ipairs(candidates) do
		local clear = true
		for _, other in ipairs(occupied) do
			if Layout.overlaps(candidate, other) then
				clear = false
				break
			end
		end
		if clear and #selected < budget then
			table.insert(selected, candidate)
			table.insert(occupied, candidate)
		end
	end
	return selected
end
return Layout
