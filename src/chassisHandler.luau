-- Redon Tech Emnergency Vehicle Creator, MIT License
local log = require(script.Parent.log)
local types = require(script.Parent.types)
local vehicle = require(script.Parent.vehicle)
local utils = require(script.Parent.utils)

export type lightSettings = {
	colors: { [number]: {
		name: string,
		partColor: Color3,
		lightColor: Color3,
		lightoColor: Color3,
	} },
	optimizations: {
		shouldChangeNeons: boolean,
		shouldChangeLights: boolean,
		shouldChangeLightos: boolean,
	},
	lightGroups: {
		[string]: { string },
	},
}

export type chassisConfiguration = {
	lightSettings: lightSettings,
	functions: { types.elsFunction },
	sirens: { types.siren },
}

type chassisHandler = {
	cache: { [Model]: chassisConfiguration },
	hasPluginInstalled: (self: chassisHandler, model: Model) -> (boolean, LocalScript?),
	installPlugin: (self: chassisHandler, model: Model) -> boolean,
	getConfiguration: (self: chassisHandler, model: Model) -> chassisConfiguration?,
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
		return self.cache[model]
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

	local data = {
		lightSettings = utils.deepCopy((require :: any)(lightSettings) :: lightSettings),
		functions = utils.deepCopy((require :: any)(functions) :: { types.elsFunction }),
		sirens = utils.deepCopy((require :: any)(sirens) :: { types.siren }),
	}

	self.cache[model] = data
	return data
end

return chassisHandler
