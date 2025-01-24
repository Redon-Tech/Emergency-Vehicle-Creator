-- Redon Tech Emergency Vehicle Creator, MIT License
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

function utils.arraySwap(array: { [number]: unknown }, index1: number, index2: number)
	local value1 = array[index1]
	local value2 = array[index2]
	array[index1] = value2
	array[index2] = value1
end

function utils.insertAtNumberOrEnd(array: { [number]: unknown }, index: number, value: unknown): number
	if index > #array then
		table.insert(array, value)
		return #array
	else
		table.insert(array, index, value)
		return index
	end
end

function utils.arrayIndexToKey<I, V>(array: { [I]: V }): { [V]: I }
	local output = {}
	for index, value in array do
		output[value] = index
	end
	return output
end

function utils.dictionaryValueToIndex<I, V, K>(dictionary: { [I]: V }, valueIndex: K): { [unknown]: V }
	local output = {}
	for _, value in dictionary do
		if typeof(value) ~= "table" then
			continue
		end
		output[value[valueIndex]] = value
	end
	return output
end

return utils
