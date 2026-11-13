-- Redon Tech Emergency Vehicle Creator, MIT License
local StudioService = game:GetService("StudioService")
local Selection = game:GetService("Selection")
local SerializationService = game:GetService("SerializationService")
local HttpService = game:GetService("HttpService")
local ConfigurationCodec = require("../ConfigurationCodec")
local LegacySaves = require("./LegacySaves")
local Types = require("./Types")
local utils = require("../utils")

local SaveFiles = {}

--- Returns false without an error when the user cancels the export.
function SaveFiles.exportFile(plugin: Plugin, name: string, source: string): (boolean, string?)
	local selection = Selection:Get()
	local module = Instance.new("ModuleScript")
	local success, saved = pcall(function()
		module.Name = name
		module.Source = "-- Redon Tech Emergency Vehicle Creator\n\n" .. source
		module.Parent = game:GetService("ServerStorage")
		Selection:Set({ module })
		return plugin:PromptSaveSelectionAsync(name .. ".luau")
	end)
	module:Destroy()
	local restored, restoreError = pcall(function()
		Selection:Set(selection)
	end)
	if not success then
		return false, tostring(saved)
	end
	if not restored then
		return false, tostring(restoreError)
	end
	return saved, nil
end

local function importSource<T>(
	collection: Types.Collection<T>,
	typeId: string,
	source: string,
	name: string
): Types.ImportReport
	local report: Types.ImportReport = { imported = {}, failures = {}, cancelled = false }
	local value, problem = ConfigurationCodec.decode(source)
	if value == nil then
		local success, data = pcall(function()
			return HttpService:JSONDecode(source)
		end)
		assert(success, problem or tostring(data))
		value = data
	end
	assert(type(value) == "table", "Imported save must be a table")
	local currentFormat = value.formatVersion ~= nil
	local entries
	if currentFormat then
		assert(value.formatVersion == 1, "Unsupported save format version")
		assert(value.typeId == typeId, "This file contains a different kind of save")
		assert(type(value.name) == "string", "Imported save name must be a string")
		entries = { [value.name] = value.data }
		assert(value.data ~= nil, "Imported save has no data")
	else
		assert(typeId == "pattern", "Legacy files contain patterns only")
		entries = if value.elsCreator ~= nil or value.flashers ~= nil then { [name] = value } else value
	end
	for saveName, savedValue in entries do
		local success, importError = pcall(function()
			assert(type(saveName) == "string", "Imported save name must be a string")
			local data = savedValue
			if not currentFormat then
				local converted, conversionError = LegacySaves.convert(data)
				assert(converted, conversionError)
				data = converted
			end
			local names, listError = collection:list()
			assert(names, listError)
			local destination = utils.getUniqueString(saveName, names)
			-- save validates imported data against this collection's schema.
			local saved, saveError = collection:save(destination, data :: T)
			assert(saved, saveError)
			table.insert(report.imported, destination)
		end)
		if not success then
			table.insert(report.failures, { name = tostring(saveName), message = tostring(importError) })
		end
	end
	return report
end

function SaveFiles.importFile<T>(collection: Types.Collection<T>, typeId: string): (Types.ImportReport?, string?)
	local success, file = pcall(function()
		return StudioService:PromptImportFileAsync({ "luau", "lua", "json", "rbxm" })
	end)
	if not success then
		return nil, tostring(file)
	end
	if file == nil then
		return { imported = {}, failures = {}, cancelled = true }, nil
	end
	local instances: { Instance } = {}
	local imported, report = pcall(function()
		assert(file.Size <= 4 * 1024 * 1024, "Save file is too large")
		local name = file.Name:gsub("%.[^.]+$", "")
		local source = file:GetBinaryContents()
		if file.Name:lower():match("%.rbxm$") then
			instances = SerializationService:DeserializeInstancesAsync(buffer.fromstring(source))
			assert(#instances == 1, "Legacy download must contain one script")
			local instance = instances[1]
			assert(instance:IsA("ModuleScript") or instance:IsA("Script"), "Legacy download must contain a script")
			source = instance.Source
			name = instance.Name
		end
		return importSource(collection, typeId, source, name)
	end)
	for _, instance in instances do
		instance:Destroy()
	end
	file:Destroy()
	if not imported then
		return nil, tostring(report)
	end
	return report, nil
end

return SaveFiles
