-- Redon Tech Emergency Vehicle Creator, MIT License
local log = require(script.Parent.log)
local types = require(script.Parent.types)
local vehicle = require(script.Parent.vehicle)
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local LuaEncode = require(script.Parent.Parent.Packages.LuaEncode)
local Fusion = require(script.Parent.Parent.Packages.fusion)
local LuaEncodeSettings = {
	Prettify = false,
	OutputWarnings = false,
}
local exportHeader =
	"-- Redon Tech Emergency Vehicle Creator, MIT License\n\n--DO NOT MODIFY BELOW\n--SUPPORT WILL BE VOIDED IF MODIFIED\n\nreturn "

-- version format: minor.{if rc then 0 else 1}patch
local latestVersion = 0.092
-- please ensure to update handler/EVHEvent/configuration/lightSettings.luau if you update this

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
		shouldChangeParticleEmitters: boolean,
		partTransparency: number,
	},
	lightGroups: {
		{
			name: string,
			lights: { string },
		}
	},
}

export type lightSettingsState = {
	colors: Fusion.Value<{ color }>,
	configuration: {
		shouldChangeNeons: Fusion.Value<boolean>,
		shouldChangeLights: Fusion.Value<boolean>,
		shouldChangeLightos: Fusion.Value<boolean>,
		shouldChangeParticleEmitters: Fusion.Value<boolean>,
		partTransparency: Fusion.Value<number>,
	},
	lightGroups: Fusion.Value<{ { name: Fusion.Value<string>, lights: Fusion.Value<{ string }> } }>,
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
		colors: { color },
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
		colors = {
			{
				name = "Blue",
				partColor = Color3.fromRGB(110, 153, 202),
				lightColor = Color3.fromRGB(0, 0, 255),
				lightoColor = Color3.fromRGB(47, 71, 255),
			},
			{
				name = "Red",
				partColor = Color3.fromRGB(190, 104, 98),
				lightColor = Color3.fromRGB(255, 0, 0),
				lightoColor = Color3.fromRGB(185, 58, 60),
			},
			{
				name = "Yellow",
				partColor = Color3.fromRGB(226, 155, 64),
				lightColor = Color3.fromRGB(255, 200, 0),
				lightoColor = Color3.fromRGB(253, 194, 66),
			},
			{
				name = "White",
				partColor = Color3.fromRGB(255, 255, 255),
				lightColor = Color3.fromRGB(255, 255, 255),
				lightoColor = Color3.fromRGB(255, 255, 255),
			},
			{
				name = "Green",
				partColor = Color3.fromRGB(0, 255, 0),
				lightColor = Color3.fromRGB(0, 255, 0),
				lightoColor = Color3.fromRGB(75, 255, 75),
			},
			{
				name = "Purple",
				partColor = Color3.fromRGB(170, 0, 170),
				lightColor = Color3.fromRGB(200, 0, 200),
				lightoColor = Color3.fromRGB(188, 12, 211),
			},
		},
	},
} :: chassisHandler
table.freeze(chassisHandler.defaults)

--- Checks if the Emergency Vehicle Handler plugin is installed on the given model.
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

--- Checks if the EVC Chassis Plugin is installed on the given model.
--- This is a legacy plugin that was used before the Emergency Vehicle Handler plugin.
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

type oldSiren =
	{
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
	}
	| {
		_Type: "Modifier",
		Name: string,
	}

--- Installs the Emergency Vehicle Handler plugin on the given model.
--- This will convert any old EVC Chassis Plugin data to the new format.
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
												local sortedNames: { string } = {}
												local unsortedColumns: { [string]: { [any]: any } } = {}
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

														table.insert(sortedNames, lightName)
														unsortedColumns[lightName] = newColumn
														if newFlasher.rowCount < #newColumn.rows then
															newFlasher.rowCount = #newColumn.rows
														end
													end

													table.sort(sortedNames)
													for _, lightName in sortedNames do
														table.insert(newFlasher.columns, unsortedColumns[lightName])
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
						moduleStore.Name = "NO LONGER USED, KEPT AS A BACKUP -> ModuleStore"
					end
				end
			end
		end

		oldPlugin:Destroy()
	end

	newHandler.Parent = plugins
	newHandler.Enabled = true
	ChangeHistoryService:SetWaypoint("Installed EVH")
	-- newHandler.EVHEvent.loader.Enabled = true
	return true
end

--- Retrieves the configuration for the given model.
--- If the configuration is already cached, it will return the cached data.
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
	--[[
		Hello, it is me again.
		I understand this now.
		Turns out I am a dumbass and the nightmare of this codebase
		has caused issues like the above, hopefully in the future
		this can be fixed so we can remove dumbass workarounds like
		this.
		- Parker, looking back at the codebase 6 months later
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
			shouldChangeParticleEmitters = false,
			partTransparency = 0.011,
		}
		(data.lightSettings :: any).optimizations = nil
		log.info("Updated lightSettings from optimizations to configuration", oldLightConfiguration, data.lightSettings)
	end
	if data.lightSettings.configuration.shouldChangeParticleEmitters == nil then
		data.lightSettings.configuration.shouldChangeParticleEmitters = false
	end
	if data.lightSettings.version ~= latestVersion then
		local oldLoader = event:FindFirstChild("loader")
		if oldLoader ~= nil then
			oldLoader:Destroy()
		end
		local newLoader = script.Parent.handler.EVHEvent.loader:Clone()
		newLoader.Parent = event

		Plugin.Source = script.Parent.handler.Source
		ChangeHistoryService:SetWaypoint("Updated EVH")
	end
	data.lightSettings.version = latestVersion

	--TODO: in the future abstract this error checking
	for _, currentFunction in data.functions do
		for _, pattern in currentFunction.patterns do
			if pattern.flashers == nil then
				pattern.flashers = {}
			end
			if pattern.faders == nil then
				pattern.faders = {}
			end
			if pattern.rotators == nil then
				pattern.rotators = {}
			end

			for _, flasher in pattern.flashers do
				if flasher.columns == nil then
					flasher.columns = {}
				end
				if flasher.rowCount == nil then
					flasher.rowCount = 1
				end
				if flasher.waitTime == nil then
					flasher.waitTime = 0.1
				end
			end

			for _, fader in pattern.faders do
				if fader.lightName == nil then
					fader.lightName = "LightNameCorrupted"
				end
				if fader.data == nil then
					fader.data = {}
				end
			end

			for _, rotator in pattern.rotators do
				if rotator.lightName == nil then
					rotator.lightName = "LightNameCorrupted"
				end
				if rotator.data == nil then
					rotator.data = {}
				end
			end
		end
	end

	self.cache[model] = {
		data = data,
		functions = functions,
		sirens = sirens,
		lightSettings = lightSettings,
	}
	return data
end

--- Saves the current configuration for the given model.
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
	ChangeHistoryService:SetWaypoint("Saved configuration")

	return true
end

--TODO: Create some algorithm to detect possible lights that already havent been used.
--- Retrieves the list of possible lights from the current configuration.
--- This includes lights from the configuration, light groups, and any other light names referenced.
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

	for _, lightGroup in currentConfiguration.lightSettings.lightGroups do
		local possibleIndex = table.find(possibleLights, lightGroup.name)
		if possibleIndex ~= nil then
			table.remove(possibleLights, possibleIndex)
		end
	end

	table.sort(possibleLights)
	return possibleLights
end

return chassisHandler
