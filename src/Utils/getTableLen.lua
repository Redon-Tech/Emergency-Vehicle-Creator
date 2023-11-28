--[[
Redon Tech 2023
EVC V2
--]]

return function(table: {})
	local length = 0

	for _ in pairs(table) do
		length += 1
	end

	return length
end