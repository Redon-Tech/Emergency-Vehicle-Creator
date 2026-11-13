-- Redon Tech Emergency Vehicle Creator, MIT License
local ConfigurationCodec = require("./ConfigurationCodec")
local Schemas = require("./SaveLibrary/Schemas")
local SaveFiles = require("./SaveLibrary/SaveFiles")
local LegacySaves = require("./SaveLibrary/LegacySaves")
local Types = require("./SaveLibrary/Types")
local types = require("../types")
local typed = require("../../Packages/typed")

export type Collection<T> = Types.Collection<T>
export type ImportReport = Types.ImportReport
export type SaveLibrary = Types.SaveLibrary

type Schema<T> = { parse: (unknown) -> typed.ParseResult<T> }
local SaveLibrary = {} :: SaveLibrary
local prefix = "RT_EVC_Saves_"

local function validName(name: string): boolean
	return name:find("%S") ~= nil and name:find("%c") == nil
end

local function read(plugin: Plugin, key: string): (unknown, string?)
	local success, value = pcall(function()
		return plugin:GetSetting(key)
	end)
	if not success then
		return nil, tostring(value)
	end
	return value, nil
end

local function write(plugin: Plugin, key: string, value: unknown): (boolean, string?)
	local success, problem = pcall(function()
		plugin:SetSetting(key, value)
	end)
	return success, if success then nil else tostring(problem)
end

local function createCollection<T>(plugin: Plugin, typeId: string, schema: Schema<T>): Collection<T>
	local collection = {} :: Collection<T>
	local indexKey = prefix .. typeId .. "_Index"

	local function recordKey(name: string): string
		return prefix
			.. typeId
			.. "_"
			.. name:gsub(".", function(character)
				return string.format("%02x", string.byte(character))
			end)
	end

	local function validate(value: unknown): (T?, string?)
		local parsed = schema.parse(value)
		if not parsed.ok then
			return nil, typed.formatIssues(parsed.issues)
		end
		return parsed.value, nil
	end

	function collection:list(): ({ string }?, string?)
		local value, problem = read(plugin, indexKey)
		if problem then
			return nil, problem
		end
		if value == nil then
			return {}, nil
		end
		if type(value) ~= "table" then
			return nil, "Invalid save index for " .. typeId
		end
		local index = value :: { [unknown]: unknown }
		local names: { string } = {}
		local seen: { [string]: boolean } = {}
		for key, name in index do
			if
				type(key) ~= "number"
				or key % 1 ~= 0
				or key < 1
				or key > #index
				or type(name) ~= "string"
				or not validName(name)
				or seen[name]
			then
				return nil, "Invalid save index for " .. typeId
			end
			seen[name] = true
			table.insert(names, name)
		end
		if #names ~= #index then
			return nil, "Invalid save index for " .. typeId
		end
		table.sort(names)
		return names, nil
	end

	function collection:load(name: string): (T?, string?)
		local names, problem = self:list()
		if not names then
			return nil, problem
		end
		if not table.find(names, name) then
			return nil, "Save does not exist: " .. name
		end
		local source, readError = read(plugin, recordKey(name))
		if readError then
			return nil, readError
		end
		if type(source) ~= "string" then
			return nil, "Save payload is missing: " .. name
		end
		local record, decodeError = ConfigurationCodec.decode(source)
		if not record then
			return nil, decodeError
		end
		if record.formatVersion ~= 1 or record.typeId ~= typeId or record.name ~= name then
			return nil, "Invalid save record: " .. name
		end
		return validate(record.data)
	end

	function collection:save(name: string, data: T, options: { overwrite: boolean? }?): (boolean, string?)
		if not validName(name) then
			return false, "Save names cannot be blank or contain control characters"
		end
		local names, problem = self:list()
		if not names then
			return false, problem
		end
		local exists = table.find(names, name) ~= nil
		if exists and not (options and options.overwrite) then
			return false, "A save with this name already exists"
		end
		local value, validationError = validate(data)
		if value == nil then
			return false, validationError
		end
		local source, encodeError =
			ConfigurationCodec.encode({ formatVersion = 1, typeId = typeId, name = name, data = value })
		if not source then
			return false, encodeError
		end
		local saved, saveError = write(plugin, recordKey(name), source)
		if not saved then
			return false, saveError
		end
		if exists then
			return true, nil
		end
		table.insert(names, name)
		return write(plugin, indexKey, names)
	end

	function collection:delete(name: string): (boolean, string?)
		local names, problem = self:list()
		if not names then
			return false, problem
		end
		local position = table.find(names, name)
		if not position then
			return false, "Save does not exist: " .. name
		end
		table.remove(names, position)
		local saved, saveError = write(plugin, indexKey, names)
		if not saved then
			return false, saveError
		end
		return write(plugin, recordKey(name), nil)
	end

	function collection:rename(oldName: string, newName: string): (boolean, string?)
		local value, problem = self:load(oldName)
		if value == nil then
			return false, problem
		end
		if oldName == newName then
			return true, nil
		end
		local saved, saveError = self:save(newName, value)
		if not saved then
			return false, saveError
		end
		local deleted, deleteError = self:delete(oldName)
		if not deleted then
			return false,
				"Saved as " .. newName .. ", but could not fully delete " .. oldName .. ": " .. tostring(deleteError)
		end
		return true, nil
	end

	function collection:importFile(): (ImportReport?, string?)
		return SaveFiles.importFile(self, typeId)
	end

	function collection:exportFile(name: string): (boolean, string?)
		local value, problem = self:load(name)
		if value == nil then
			return false, problem
		end
		local source, encodeError =
			ConfigurationCodec.encode({ formatVersion = 1, typeId = typeId, name = name, data = value }, true)
		if not source then
			return false, encodeError
		end
		return SaveFiles.exportFile(plugin, name, source)
	end

	return collection
end

--- Initializes the shared collections and migrates legacy patterns once.
function SaveLibrary.init(plugin: Plugin): ImportReport
	SaveLibrary.patterns = createCollection<<types.pattern>>(plugin, "pattern", Schemas.pattern)
	SaveLibrary.functions = createCollection<<types.elsFunction>>(plugin, "function", Schemas["function"])
	SaveLibrary.activations = createCollection<<types.activation>>(plugin, "activation", Schemas.activation)
	SaveLibrary.sirens = createCollection<<types.siren>>(plugin, "siren", Schemas.siren)
	SaveLibrary.lightSettings = createCollection<<types.lightSettings>>(plugin, "lightSettings", Schemas.lightSettings)
	SaveLibrary.colors = createCollection<<types.color>>(plugin, "color", Schemas.color)
	SaveLibrary.lightGroups = createCollection<<types.lightGroup>>(plugin, "lightGroup", Schemas.lightGroup)
	SaveLibrary.configurations =
		createCollection<<types.chassisConfiguration>>(plugin, "configuration", Schemas.configuration)
	return LegacySaves.migrate(plugin, SaveLibrary.patterns)
end

return SaveLibrary
