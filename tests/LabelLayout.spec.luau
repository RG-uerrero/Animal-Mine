local Layout = require(game.ReplicatedStorage.Shared.LabelLayout)
local function item(order, x, priority, distance)
	return { order = order, x = x, y = 0, w = 80, h = 40, priority = priority, distance = distance }
end
local nearest = item(1, 0, 80, 5)
local farther = item(2, 20, 80, 15)
local landmark = item(3, 200, 30, 30)
local selected = Layout.select({ farther, landmark, nearest }, 8)
assert(#selected == 2 and selected[1] == nearest and selected[2] == landmark, "nearest detail wins overlap")
local feedback = item(4, 10, 100, 10)
selected = Layout.select({ nearest, feedback }, 8)
assert(#selected == 1 and selected[1] == feedback, "brief feedback has priority")
assert(#Layout.select({ item(1, 0, 80, 1), item(2, 200, 80, 2), item(3, 400, 80, 3) }, 2) == 2, "budget respected")
assert(not Layout.overlaps(item(1, 0, 80, 1), item(2, 100, 80, 2)), "separate signs stay visible")
assert(Layout.overlaps(item(1, 0, 80, 1), item(2, 84, 80, 2)), "padding prevents touching edges")
local a, b = item(1, 0, 80, 5), item(2, 0, 80, 5)
assert(Layout.select({ b, a }, 8)[1] == a, "ties are stable")
assert(#Layout.select({ nearest }, 8, { { x = 0, y = 0, w = 100, h = 100 } }) == 0, "HUD area stays clear")
assert(
	#Layout.select({ landmark }, 1, { { x = 0, y = 0, w = 100, h = 100 } }) == 1,
	"HUD obstacles do not consume label budget"
)
print("LabelLayout: all regression checks passed")
