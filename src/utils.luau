-- Redon Tech Emergency Vehicle Creator, MIT License
local utils = {}

--- Deep copies a table, including nested tables.
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

--- Takes a table and swaps the values at the specified indices.
function utils.arraySwap(array: { [number]: unknown }, index1: number, index2: number)
	local value1 = array[index1]
	local value2 = array[index2]
	array[index1] = value2
	array[index2] = value1
end

--- Inserts a value into an array at the specified index or at the end if the index is greater than the array length.
function utils.insertAtNumberOrEnd(array: { [number]: unknown }, index: number, value: unknown): number
	if index > #array then
		table.insert(array, value)
		return #array
	else
		table.insert(array, index, value)
		return index
	end
end

--- Converts an array to a dictionary with the values as keys and their indices as values.
function utils.arrayIndexToKey<I, V>(array: { [I]: V }): { [V]: I }
	local output = {}
	for index, value in array do
		output[value] = index
	end
	return output
end

--- Converts a dictionary of values to an array, using a specified key from the value as the index.
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

--- Compares two tables for equality, including nested tables.
function utils.compareTables(table1: { [any]: any }, table2: { [any]: any }): boolean
	for index, value in table1 do
		if table2[index] == nil then
			return false
		end

		if typeof(value) == "table" then
			if utils.compareTables(value, table2[index]) == false then
				return false
			end
		else
			if table2[index] ~= value then
				return false
			end
		end
	end
	for index, value in table2 do
		if table1[index] == nil then
			return false
		end

		if typeof(value) == "table" then
			if utils.compareTables(value, table1[index]) == false then
				return false
			end
		else
			if table1[index] ~= value then
				return false
			end
		end
	end
	return true
end

return utils
