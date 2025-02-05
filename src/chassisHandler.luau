-- Redon Tech Emergency Vehicle Creator, MIT License
local log = require(script.Parent.log)
local types = require(script.Parent.types)
local vehicle = require(script.Parent.vehicle)
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local LuaEncode = require(script.Parent.Parent.Packages.LuaEncode)
local LuaEncodeSettings = {
	Prettify = true,
}
local exportHeader =
	"-- Redon Tech Emergency Vehicle Creator, MIT License\n\n--DO NOT MODIFY BELOW\n--SUPPORT WILL BE VOIDED IF MODIFIED\n\nreturn "

-- version format: minor.{if rc then 0 else 1}patch
local latestVersion = 0.02

export type color = {
	name: string,
	partColor: Color3,
	lightColor: Color3,
	lightoColor: Color3,
}

export type lightSettings = {
	version: number,
	colors: { color },
	configuration: {
		shouldChangeNeons: boolean,
		shouldChangeLights: boolean,
		shouldChangeLightos: boolean,
		partTransparency: number,
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
	hasEVCChassisPluginInstalled: (self: chassisHandler, model: Model) -> (boolean, LocalScript?),
	installPlugin: (self: chassisHandler, model: Model) -> boolean,
	getConfiguration: (self: chassisHandler, model: Model) -> chassisConfiguration?,
	saveConfiguration: (self: chassisHandler, model: Model) -> boolean,
	getLights: (currentConfiguration: chassisConfiguration, model: Instance) -> { string },
	defaults: {
		functions: types.elsFunction,
		modifier: types.siren,
	},
}

local chassisHandler = {
	cache = {},
	defaults = {
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

function chassisHandler.hasEVCChassisPluginInstalled(_: chassisHandler, model: Model): (boolean, LocalScript?)
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
	local Plugin = plugins:FindFirstChild("EVCPlugin_Client") :: LocalScript?
	if Plugin == nil or Plugin:IsA("LocalScript") == false then
		return false
	end

	return true, Plugin
end

type oldSiren = {
	_Type: "Hold" | "Siren",
	Name: string,
	OverrideOtherSounds: boolean,
	Modifiers: {
		[string]: {
			Name: string,
			PlayNonModified: boolean,
			PlayOnModifierChange: boolean,
			Delay: number,
		},
	}?,
} | {
	_Type: "Modifier",
	Name: string,
}

function chassisHandler.installPlugin(self: chassisHandler, model: Model): boolean
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

	local newHandler = script.Parent.handler:Clone()
	newHandler.Name = "Emergency Vehicle Handler"

	local isOldPluginInstalled, oldPlugin = self:hasEVCChassisPluginInstalled(model)
	if isOldPluginInstalled == true and oldPlugin ~= nil then
		local oldSettings = oldPlugin:FindFirstChild("Settings", true) :: ModuleScript?
		if oldSettings == nil then
			log.warn("Old plugin installed but Settings not found")
			newHandler:Destroy()
			return false
		end
		local loadedSettings = (require :: any)(oldSettings)
		local secondaryKeybinds: { [Enum.KeyCode]: Enum.KeyCode } = {}
		if loadedSettings.SecondaryKeybinds ~= nil and typeof(loadedSettings.SecondaryKeybinds) == "table" then
			for keybind: Enum.KeyCode, secondaryKeybind: Enum.KeyCode in loadedSettings.SecondaryKeybinds do
				secondaryKeybinds[keybind] = secondaryKeybind
			end
		end

		local convertedSirens: { types.siren } = {}
		if loadedSettings.Sirens ~= nil and typeof(loadedSettings.Sirens) == "table" then
			for keybind: Enum.KeyCode, siren: oldSiren in loadedSettings.Sirens do
				if siren._Type ~= "Modifier" then
					local newSiren: types.siren = {
						name = siren.Name,
						type = siren._Type,
						behavoir = if siren.OverrideOtherSounds
							then "Overrides Other Sounds"
							else "Plays Simultaneously",
						keybinds = { keybind },
						modifiers = {},
					}
					if
						siren.Modifiers ~= nil
						and typeof(siren.Modifiers) == "table"
						and newSiren.type ~= "Modifier" -- satisfy the type engine
					then
						for modifierName, modifier in siren.Modifiers do
							table.insert(newSiren.modifiers, {
								name = modifierName,
								modifiedSirenName = modifier.Name,
								parentSoundBehavior = if modifier.PlayNonModified
									then "Play Parent Sound"
									else "Plays Simultaneously",
								behavoir = if modifier.PlayOnModifierChange
									then "Play Automatically"
									else "Require Parent Replay",
								delay = modifier.Delay,
							})
						end
					end

					for secondaryKeybind, originalKeybind in secondaryKeybinds do
						if originalKeybind == keybind then
							table.insert(newSiren.keybinds, secondaryKeybind)
						end
					end

					table.insert(convertedSirens, newSiren)
				elseif siren._Type == "Modifier" then
					local newModifier: types.siren = {
						name = siren.Name,
						type = "Modifier",
						keybinds = { keybind },
					}

					for secondaryKeybind, originalKeybind in secondaryKeybinds do
						if originalKeybind == keybind then
							table.insert(newModifier.keybinds, secondaryKeybind)
						end
					end

					table.insert(convertedSirens, newModifier)
				end
			end
		end
		newHandler.EVHEvent.configuration.sirens.Source = exportHeader .. LuaEncode(convertedSirens, LuaEncodeSettings)

		local convertedFunctions: { types.elsFunction } = {}
		local lightbarName = loadedSettings.LightbarName or loadedSettings.LightbarLocation or "Lightbar"
		local car = oldPlugin:FindFirstAncestorWhichIsA("Model")

		if car ~= nil then
			local body = car:FindFirstChild("Body")
			if body ~= nil then
				local lightbar = body:FindFirstChild(lightbarName)
				if lightbar ~= nil then
					local moduleStore = lightbar:FindFirstChild("ModuleStore")
					if moduleStore ~= nil then
						for _, functionFolder in moduleStore:GetChildren() do
							if functionFolder:IsA("Folder") then
								local newFunction: types.elsFunction = {
									weight = 0,
									name = functionFolder.Name,
									activations = {},
									patterns = {},
								}
								for _, patternFolder in functionFolder:GetChildren() do
									if patternFolder:IsA("Folder") then
										local newPattern: types.pattern = {
											flashers = {},
											faders = {},
											rotators = {},
										}
										for _, moduleScript in patternFolder:GetChildren() do
											if moduleScript:IsA("ModuleScript") then
												local loadedModule = (require :: any)(moduleScript)
												if typeof(loadedModule) ~= "table" then
													continue
												end

												local waitTime = 0.1
												if
													loadedModule.Settings ~= nil
													and typeof(loadedModule.Settings) == "table"
												then
													waitTime = loadedModule.Settings.WaitTime or waitTime
													if newFunction.weight == 0 then
														newFunction.weight = loadedModule.Settings.Weight or 0
													end
												end

												local newFlasher: types.flasherSection = {
													columns = {},
													rowCount = 1,
													waitTime = waitTime,
												}
												if
													loadedModule.Lights ~= nil
													and typeof(loadedModule.Lights) == "table"
												then
													for lightName, lightData in loadedModule.Lights do
														local newColumn = {
															lightName = lightName,
															rows = {},
														}
														for _, color in lightData do
															table.insert(newColumn.rows, color)
														end
														table.insert(newFlasher.columns, newColumn)
														if newFlasher.rowCount < #newColumn.rows then
															newFlasher.rowCount = #newColumn.rows
														end
													end

													table.insert(newPattern.flashers, newFlasher)
												end

												if
													loadedModule.Rotators ~= nil
													and typeof(loadedModule.Rotators) == "table"
												then
													for lightName, lightData in loadedModule.Rotators do
														local newRotator: types.rotatorSection = {
															lightName = lightName,
															data = {},
														}
														for _, data in lightData do
															local newData = {
																type = "Angle" :: "Angle",
																color = data.Color,
																velocity = data.Velocity,
																angle = data.Angle,
															}
															table.insert(newRotator.data, newData)
														end
														table.insert(newPattern.rotators, newRotator)
													end
												end

												if
													loadedModule.Faders ~= nil
													and typeof(loadedModule.Faders) == "table"
												then
													for lightName, lightData in loadedModule.Faders do
														local newFader: types.faderSection = {
															lightName = lightName,
															data = {},
														}
														for _, data in lightData do
															local newData = {
																type = "Advanced" :: "Advanced",
																time = data.Time,
																goal = data.Transparency,
																color = data.Color,
																easingStyle = data.EasingStyle,
																easingDirection = data.EasingDirection,
															}
															table.insert(newFader.data, newData)
														end
														table.insert(newPattern.faders, newFader)
													end
												end
											end
										end

										table.insert(newFunction.patterns, newPattern)
									end
								end

								if loadedSettings.Keybinds ~= nil and typeof(loadedSettings.Keybinds) == "table" then
									for keybind, functionToCyle in loadedSettings.Keybinds do
										if functionToCyle == functionFolder.Name then
											local newActivation: types.activation = {
												type = "Standard",
												mode = "Cycle",
												pattern = 0,
												keybinds = { keybind },
											}

											for secondaryKeybind, originalKeybind in secondaryKeybinds do
												if originalKeybind == keybind then
													table.insert((newActivation :: any).keybinds, secondaryKeybind)
												end
											end

											table.insert(newFunction.activations, newActivation)
										end
									end
								end

								table.insert(convertedFunctions, newFunction)
							end
						end

						newHandler.EVHEvent.configuration.functions.Source = exportHeader
							.. LuaEncode(convertedFunctions, LuaEncodeSettings)
					end
				end
			end
		end

		oldPlugin:Destroy()
	end

	newHandler.Parent = plugins
	newHandler.Enabled = true
	-- newHandler.EVHEvent.loader.Enabled = true
	return true
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

	--TODO: In the future abstract updating
	if data.lightSettings.version == nil then
		data.lightSettings.version = 0
	end
	local oldLightConfiguration = (data.lightSettings :: any).optimizations
	if oldLightConfiguration ~= nil then
		data.lightSettings.configuration = {
			shouldChangeNeons = oldLightConfiguration.shouldChangeNeons,
			shouldChangeLights = oldLightConfiguration.shouldChangeLights,
			shouldChangeLightos = oldLightConfiguration.shouldChangeLightos,
			partTransparency = 0.011,
		};
		(data.lightSettings :: any).optimizations = nil
		log.info("Updated lightSettings from optimizations to configuration", oldLightConfiguration, data.lightSettings)
	end
	if data.lightSettings.version ~= latestVersion then
		local oldLoader = event:FindFirstChild("loader")
		if oldLoader ~= nil then
			oldLoader:Destroy()
		end
		local newLoader = script.Parent.handler.EVHEvent.loader:Clone()
		newLoader.Parent = event

		Plugin.Source = script.Parent.handler.Source
	end
	data.lightSettings.version = 0.01

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

	log.debug(
		"Saved configuration for",
		model.Name,
		configuration.data,
		{ functionsSourceBase },
		{ sirensSourceBase },
		{ lightSettingsSourceBase }
	)
	configuration.functions.Source = exportHeader .. functionsSourceBase
	configuration.sirens.Source = exportHeader .. sirensSourceBase
	configuration.lightSettings.Source = exportHeader .. lightSettingsSourceBase

	return true
end

function chassisHandler.getLights(currentConfiguration: chassisConfiguration, model: Instance): { string }
	local possibleLights = {}
	for _, functions in currentConfiguration.functions do
		for _, pattern in functions.patterns do
			for _, flasher in pattern.flashers do
				for _, columns in flasher.columns do
					if table.find(possibleLights, columns.lightName) == nil then
						table.insert(possibleLights, columns.lightName)
					end
				end
			end

			for _, fader in pattern.faders do
				if table.find(possibleLights, fader.lightName) == nil then
					table.insert(possibleLights, fader.lightName)
				end
			end

			for _, rotator in pattern.rotators do
				if table.find(possibleLights, rotator.lightName) == nil then
					table.insert(possibleLights, rotator.lightName)
				end
			end
		end
	end

	for _, lightGroup in currentConfiguration.lightSettings.lightGroups do
		local possibleIndex = table.find(possibleLights, lightGroup.name)
		if possibleIndex ~= nil then
			table.remove(possibleLights, possibleIndex)
		end
	end

	if vehicle:isValidVehicle(model) then
		if vehicle:isVehicleCustomizable(model) then
			local outfittingFolder = vehicle:getOutfitting(model)
			if outfittingFolder ~= nil then
				for _, lightPart in outfittingFolder.model:GetDescendants() do
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
