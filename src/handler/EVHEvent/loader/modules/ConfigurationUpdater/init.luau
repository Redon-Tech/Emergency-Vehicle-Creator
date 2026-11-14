-- Redon Tech Emergency Vehicle Creator, MIT License
local V0_02 = require("./ConfigurationUpdater/Versions/0.02")
local V0_05 = require("./ConfigurationUpdater/Versions/0.05")

-- Version format: minor.{if rc then 0 else 1}patch.
local ConfigurationUpdater = { version = 0.092 }
local updates = { V0_02, V0_05 }

function ConfigurationUpdater.update(data: any)
	assert(type(data) == "table", "Configuration must be a table")
	assert(type(data.lightSettings) == "table", "lightSettings must be a table")
	if data.lightSettings.version == nil then
		data.lightSettings.version = 0
	end
	local sourceVersion = data.lightSettings.version
	assert(type(sourceVersion) == "number", "lightSettings.version must be a number")

	for _, update in updates do
		if sourceVersion < update.version and update.version <= ConfigurationUpdater.version then
			print(string.format("Updating configuration from version %.3f to %.3f", sourceVersion, update.version))
			update.update(data)
		end
	end
end

return ConfigurationUpdater
