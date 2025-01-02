-- Redon Tech Emnergency Vehicle Creator, MIT License
local utils = {}

function utils.deepCopy<T>(inputTable: T): T
	if typeof(inputTable) ~= "table" then
		return inputTable
	end

	local function copy(input: { any })
		local output = {}
		for key, value in pairs(input) do
			if typeof(value) == "table" then
				output[key] = copy(value)
			else
				output[key] = value
			end
		end
		return output
	end

	return copy(inputTable)
end

return utils
