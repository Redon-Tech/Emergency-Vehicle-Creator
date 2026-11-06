-- Redon Tech Emergency Vehicle Creator, MIT License

local SimilarityChecker = {}

local function normalizeString(str: string): string
	return str:gsub("[%s_%-_^%p]", ""):lower()
end

function SimilarityChecker.getLevenshteinDistance(str1: string, str2: string): number
	local len1 = #str1
	local len2 = #str2

	local matrix = {}
	for i = 0, len1 do
		matrix[i] = {}
		matrix[i][0] = i
	end
	for j = 0, len2 do
		matrix[0][j] = j
	end

	for i = 1, len1 do
		for j = 1, len2 do
			local cost = (str1:sub(i, i) == str2:sub(j, j)) and 0 or 1
			matrix[i][j] = math.min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1, matrix[i - 1][j - 1] + cost)
		end
	end

	return matrix[len1][len2]
end

--[[
	Sorts a list of strings based on their similarity to a target string.
	If the target is a table of strings, it will sort based on the closest match to any of the targets.
]]
function SimilarityChecker.sortStringsBySimilarity(stringToSort: { string }, targets: { string } | string): { string }
	local targetsTable = type(targets) == "table" and targets or { targets }

	local function getMinDistance(str: string): number
		local minDistance = math.huge
		for _, target in ipairs(targetsTable) do
			local distance = SimilarityChecker.getLevenshteinDistance(normalizeString(str), normalizeString(target))
			if distance < minDistance then
				minDistance = distance
			end
		end
		return minDistance
	end

	table.sort(stringToSort, function(a, b)
		return getMinDistance(a) < getMinDistance(b)
	end)

	return stringToSort
end

return SimilarityChecker
