local functions = {}

function functions.tablelen(t: table): number
	local n = 0

	for _ in pairs(t) do
		n = n + 1
	end
	return n
end

function functions.tablevaluelen(t: table): number
	local n = 0

	for index in pairs(t) do
		if index > n then
			n = index
		end
	end
	return n
end

function functions.getvaluebykey(t: table, key: number): any
	for i, v in pairs(t) do
		print(i, key)
		if i == key then
			return v
		end
	end
	return nil
end

return functions