local prefix, reverse, direction, detectOtherSize, otherSidePrefix, otherDifference = "", true, "X", false, "L", 0.2
local existingCount = 0

local parts = game.Selection:Get()
if #parts == 0 then
	return
end
for _, v in pairs(parts) do
	if v:IsA("BasePart") == false then
		error("Only parts are allowed")
	end
end
local basePosition = parts[1].Position

if detectOtherSize ~= false then
	local otherParts = {}
	for _, v in pairs(parts) do
		if math.abs(v.Position[detectOtherSize] - basePosition[detectOtherSize]) <= otherDifference then
			table.insert(otherParts, v)
		end
	end

	table.sort(otherParts, function(a, b)
		return if reverse == false
			then a.Position[direction] < b.Position[direction]
			else a.Position[direction] > b.Position[direction]
	end)

	for i, v in pairs(otherParts) do
		v.Name = otherSidePrefix .. i + existingCount
		table.remove(parts, table.find(parts, v))
	end
end

table.sort(parts, function(a, b)
	return if reverse == false
		then a.Position[direction] < b.Position[direction]
		else a.Position[direction] > b.Position[direction]
end)

for i, v in pairs(parts) do
	v.Name = prefix .. i + existingCount
end
