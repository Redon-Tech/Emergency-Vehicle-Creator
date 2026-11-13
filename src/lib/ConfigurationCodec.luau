-- Redon Tech Emergency Vehicle Creator, MIT License
local LuaEncode = require("../../Packages/LuaEncode")

local ConfigurationCodec = {}
local MAX_BYTES = 4 * 1024 * 1024
local MAX_VALUES = 100000
local MAX_DEPTH = 64

local function checkValue(value: any, active: { [any]: boolean }, depth: number, budget: { number })
	budget[1] += 1
	assert(budget[1] <= MAX_VALUES and depth <= MAX_DEPTH, "Configuration is too large or deeply nested")
	local kind = typeof(value)
	if kind == "table" then
		assert(not active[value] and getmetatable(value) == nil, "Cyclic or metatable-backed data is unsupported")
		active[value] = true
		for key, child in value do
			assert(type(key) == "string" or type(key) == "number", "Unsupported configuration key")
			checkValue(key, active, depth + 1, budget)
			checkValue(child, active, depth + 1, budget)
		end
		active[value] = nil
	elseif kind == "number" then
		assert(value == value and math.abs(value) < math.huge, "Non-finite numbers are unsupported")
	elseif kind == "Color3" then
		for _, channel in { value.R, value.G, value.B } do
			assert(channel == channel and math.abs(channel) < math.huge, "Invalid color")
		end
	else
		assert(kind == "string" or kind == "boolean" or kind == "EnumItem", "Unsupported configuration value: " .. kind)
	end
end

function ConfigurationCodec.encode(value: any, prettify: boolean?): (string?, string?)
	local success, result = pcall(function()
		assert(type(value) == "table", "Configuration must be a table")
		checkValue(value, {}, 0, { 0 })
		local source = "return " .. LuaEncode(value, { Prettify = prettify == true, OutputWarnings = false })
		assert(#source <= MAX_BYTES, "Configuration file is too large")
		return source
	end)
	if not success then
		return nil, tostring(result)
	end
	return result, nil
end

-- Loaded files can construct supported values but cannot access plugin or game APIs.
local constructors = table.freeze({ new = Color3.new, fromRGB = Color3.fromRGB })

function ConfigurationCodec.decode(source: string): (any?, string?)
	local success, result = pcall(function()
		assert(#source <= MAX_BYTES, "Configuration file is too large")
		local chunk, problem = loadstring(source, "EVC configuration")
		assert(chunk, problem)
		setfenv(chunk, table.freeze({ Color3 = constructors, Enum = Enum }))

		local data = chunk()
		assert(type(data) == "table", "Configuration must return a table")
		checkValue(data, {}, 0, { 0 })
		return data
	end)
	if not success then
		return nil, tostring(result)
	end
	return result, nil
end

return ConfigurationCodec
