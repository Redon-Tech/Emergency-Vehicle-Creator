-- Redon Tech Emergency Vehicle Creator, MIT License
local log = require(script.Parent.log)
local types = require(script.Parent.types)
local vehicle = require(script.Parent.vehicle)
local LuaEncode = require(script.Parent.Parent.Packages.LuaEncode)
local LuaEncodeSettings = {
	Prettify = true,
}
local exportHeader =
	"-- Redon Tech Emergency Vehicle Creator, MIT License\n\n--DO NOT MODIFY BELOW\n--SUPPORT WILL BE VOIDED IF MODIFIED\n\nreturn "

export type color = {
	name: string,
	partColor: Color3,
	lightColor: Color3,
	lightoColor: Color3,
}

export type lightSettings = {
	colors: { color },
	optimizations: {
		shouldChangeNeons: boolean,
		shouldChangeLights: boolean,
		shouldChangeLightos: boolean,
	},
	lightGroups: {
		{
			name: string,
			lights: { string },
		}
	},
}

export type chassisConfiguration = {
	lightSettings: lightSettings,
	functions: { types.elsFunction },
	sirens: { types.siren },
}

type chassisHandler = {
	cache: {
		[Model]: {
			data: chassisConfiguration,
			functions: ModuleScript,
			sirens: ModuleScript,
			lightSettings: ModuleScript,
		},
	},
	hasPluginInstalled: (self: chassisHandler, model: Model) -> (boolean, LocalScript?),
	installPlugin: (self: chassisHandler, model: Model) -> boolean,
	getConfiguration: (self: chassisHandler, model: Model) -> chassisConfiguration?,
	saveConfiguration: (self: chassisHandler, model: Model) -> boolean,
	getLights: (currentConfiguration: chassisConfiguration, model: Instance) -> { string },
	defaults: {
		activations: { [string]: types.activation },
		functions: types.elsFunction,
		sirens: types.siren,
		modifier: types.siren,
	},
}

local chassisHandler = {
	cache = {},
	defaults = {
		activations = {
			Standard = {
				type = "Standard",
				mode = "Cycle",
				pattern = 0,
				keybinds = { Enum.KeyCode.J, Enum.KeyCode.DPadLeft },
			},
			Override = {
				type = "Override",
				mode = "Park",
				dependentFunction = "",
				dependentPattern = 0,
			},
			Conditional = {
				type = "Conditional",
				mode = "Cycle", -- This won't be used
				conditionMode = "Keybind",
				keybinds = { Enum.KeyCode.J, Enum.KeyCode.DPadLeft },
				conditions = {},
			},
		},
		functions = {
			weight = 0,
			name = "default",
			activations = {
				{
					type = "Standard",
					mode = "Cycle",
					pattern = 0,
					keybinds = { Enum.KeyCode.J, Enum.KeyCode.DPadLeft },
				},
			},
			patterns = { {
				flashers = {},
				faders = {},
				rotators = {},
			} },
		},
		sirens = {
			name = "default",
			type = "Siren",
			behavoir = "Overrides Other Sounds",
			keybinds = { Enum.KeyCode.R, Enum.KeyCode.DPadRight },
			modifiers = {},
		},
		modifier = {
			name = "default",
			type = "Modifier",
			keybinds = { Enum.KeyCode.T, Enum.KeyCode.Unknown },
		},
	},
} :: chassisHandler
table.freeze(chassisHandler.defaults)

function chassisHandler.hasPluginInstalled(self: chassisHandler, model: Model): (boolean, LocalScript?)
	if self.cache[model] then
		return true
	end

	local vehicleType = vehicle:isValidVehicle(model)
	if vehicleType == false then
		return false
	end

	local tune
	if vehicleType == "a" or vehicleType == "ag" then
		tune = model:FindFirstChild("A-Chassis Tune")
	elseif vehicleType == "m" then
		tune = model:FindFirstChild("Tuner")
	elseif vehicleType == "mg" then
		tune = model:FindFirstChild("MG-Chassis tune")
	end

	if tune == nil then
		return false
	end
	local plugins = tune:FindFirstChild("Plugins")
	if plugins == nil then
		return false
	end
	local Plugin = plugins:FindFirstChild("Emergency Vehicle Handler") :: LocalScript?
	if Plugin == nil or Plugin:IsA("LocalScript") == false then
		return false
	end

	return true, Plugin
end

--selene: allow(unused_variable)
function chassisHandler.installPlugin(self: chassisHandler, model: Model): boolean
	-- TODO: Implement this function
	return false
end

function chassisHandler.getConfiguration(self: chassisHandler, model: Model): chassisConfiguration?
	if self.cache[model] then
		return self.cache[model].data
	end

	local installed, Plugin = self:hasPluginInstalled(model)
	if installed == false or Plugin == nil then
		return
	end

	local event = Plugin:FindFirstChild("EVHEvent")
	if event == nil then
		log.warn("Plugin installed but EVHEvent not found")
		return
	end
	local configuration = event:FindFirstChild("configuration")
	if configuration == nil then
		log.warn("Plugin installed but configuration not found")
		return
	end

	local functions = configuration:FindFirstChild("functions") :: ModuleScript?
	local sirens = configuration:FindFirstChild("sirens") :: ModuleScript?
	local lightSettings = configuration:FindFirstChild("lightSettings") :: ModuleScript?
	if
		functions == nil
		or sirens == nil
		or lightSettings == nil
		or functions:IsA("ModuleScript") == false
		or sirens:IsA("ModuleScript") == false
		or lightSettings:IsA("ModuleScript") == false
	then
		log.warn("Plugin installed but configuration is invalid")
		return
	end

	--[[
		This is done to ensure that we are not requiring a reference
		but rather the actual data in the ModuleScript
		because for reasons beyond me, some things like lightgroups
		just wont show up in the data if its re-required after
		exporting new data to it
		DM parker if u dont understand this
		I personally hate this 😎
	]]
	local clonedFunctions = functions:Clone()
	local clonedSirens = sirens:Clone()
	local clonedLightSettings = lightSettings:Clone()
	local data = {
		functions = (require :: any)(clonedFunctions) :: { types.elsFunction },
		sirens = (require :: any)(clonedSirens) :: { types.siren },
		lightSettings = (require :: any)(clonedLightSettings) :: lightSettings,
	}
	clonedFunctions:Destroy()
	clonedSirens:Destroy()
	clonedLightSettings:Destroy()
	log.debug("Loaded configuration for", model.Name, data)

	self.cache[model] = {
		data = data,
		functions = functions,
		sirens = sirens,
		lightSettings = lightSettings,
	}
	return data
end

function chassisHandler.saveConfiguration(self: chassisHandler, model: Model): boolean
	local configuration = self.cache[model]
	if configuration == nil then
		return false
	end

	local functionsSourceBase = LuaEncode(configuration.data.functions, LuaEncodeSettings)
	local sirensSourceBase = LuaEncode(configuration.data.sirens, LuaEncodeSettings)
	local lightSettingsSourceBase = LuaEncode(configuration.data.lightSettings, LuaEncodeSettings)

	configuration.functions.Source = exportHeader .. functionsSourceBase
	configuration.sirens.Source = exportHeader .. sirensSourceBase
	configuration.lightSettings.Source = exportHeader .. lightSettingsSourceBase
	log.debug(
		"Saved configuration for",
		model.Name,
		configuration.data,
		{ functionsSourceBase },
		{ sirensSourceBase },
		{ lightSettingsSourceBase }
	)

	return true
end

function chassisHandler.getLights(currentConfiguration: chassisConfiguration, model: Instance): { string }
	local possibleLights = {}
	for _, functions in pairs(currentConfiguration.functions) do
		for _, pattern in pairs(functions.patterns) do
			for _, flasher in pairs(pattern.flashers) do
				for _, columns in pairs(flasher.columns) do
					if table.find(possibleLights, columns.lightName) == nil then
						table.insert(possibleLights, columns.lightName)
					end
				end
			end

			for _, fader in pairs(pattern.faders) do
				if table.find(possibleLights, fader.lightName) == nil then
					table.insert(possibleLights, fader.lightName)
				end
			end

			for _, rotator in pairs(pattern.rotators) do
				if table.find(possibleLights, rotator.lightName) == nil then
					table.insert(possibleLights, rotator.lightName)
				end
			end
		end
	end

	if vehicle:isValidVehicle(model) then
		if vehicle:isVehicleCustomizable(model) then
			local outfittingFolder = vehicle:getOutfitting(model)
			if outfittingFolder ~= nil then
				for _, lightPart in pairs(outfittingFolder.model:GetDescendants()) do
					if lightPart:IsA("BasePart") and lightPart.Parent ~= nil and lightPart.Parent.Name == "_LIGHTS" then
						if table.find(possibleLights, lightPart.Name) == nil then
							table.insert(possibleLights, lightPart.Name)
						end
					end
				end
			end
		end
	end

	table.sort(possibleLights)
	return possibleLights
end

return chassisHandler
