--[[
	Redon Tech 2023
	EVC V2
--]]

--------------------------------------------------------------------------------
-- Types --
--------------------------------------------------------------------------------

type elsLight = {number}

type rotatorLight = {
	color: number,
	angle: number,
	velocity: number
}

type faderLight = {
	color: number,
	transparency: number,
	timeTaken: number,
	easingStyle: EnumItem,
	easingDirection: EnumItem,
	repeatCount: number,
	reverses: boolean,
	timeDelay: number,
}

type patternModule = {
	instance: ModuleScript,
	data: {},
	moduleSettings: {
		waitTime: number,
		weight: number,
		colors: {}?,
		light: any?,
	},
	lights: {string:{elsLight}},
	rotators: {string:{number:{rotatorLight}}},
	faders: {string:{number:{faderLight}}},
	count: number,
	max_count: number,
}

type pattern = {
	modules: {patternModule}
}

type lightbarFunction = {
	patterns: {number:pattern},
	currentPattern: number,
	maxPattern: number,
}

type lightInstance = {
	running_module: patternModule?,
	possible_modules: {patternModule}
}

type runningCoroutine = {
	thread: thread,
	running_patterns: {patternModule}
}

type rotatorLightThread = {
	thread: thread,
	currentRunner: number,
	run: boolean
}

type tweenLightThread = {
	thread: thread,
	tween: Tween,
	currentRunner: number,
	run: boolean
}

type sirenModifier = {
	modifierName: string,
	name: string,
	playNonModified: boolean,
	playOnModifierChange: boolean,
	timeDelay: number,
}

type siren = {
	_type: string,
	keybind: EnumItem,
	name: string,
	overrideOtherSounds: boolean,
	modifiers: {string:sirenModifier}
}

type modifier = {
	_type: string,
	keybind: EnumItem,
	name: string,
	enabled: boolean
}

--------------------------------------------------------------------------------
-- Init --
--------------------------------------------------------------------------------

local error = function(...)
	error(`"[EVC]" {...} \n {debug.traceback()}`)
end
local warn = function(...)
	warn("[EVC]", ...)
end

local car:Model = script.Parent.Parent
local event:RemoteEvent = script.Parent
local pluginSettings = require(script.Parent.Settings)
local body:Model = car:WaitForChild("Body")
local misc:Model = car:WaitForChild("Misc")
local lightbar:Model = body:WaitForChild(pluginSettings.LightbarName)
local soundPart:BasePart = lightbar:FindFirstChild(pluginSettings.SirenName)

local TweenService = game:GetService("TweenService")

local lightParts:{string:BasePart} = {}
local lights:{string:lightInstance} = {}
local lightbarFunctions:{name:lightbarFunction} = {}
local coroutines = {}
local rotatorThreads:{string:rotatorLightThread} = {}
local tweenThreads:{string:tweenLightThread} = {}
local sirensByKeybind:{EnumItem:siren|modifier} = {}
local sirensByName:{EnumItem:siren} = {}
local modifiers:{string:modifier} = {}
local dependentOverrides:{string:{string}} = {}

--------------------------------------------------------------------------------
-- Functions --
--------------------------------------------------------------------------------

-- Checks
if lightbar == nil then
	error(`No lightbar found`)
end
if lightbar:FindFirstChild("ModuleStore") == nil then
	error(`No modulestore found`)
end
if soundPart == nil then
	warn(`No soundpart found will be unable to play any sirens`)
end

for _,part in pairs(lightbar:GetChildren()) do
	if part:IsA("BasePart") and lightParts[part.Name] == nil then
		lightParts[part.Name] = part
	elseif part:IsA("BasePart") then
		warn(`Duplicate lightPart ({part.Name}) in {lightbar.Name} (Body)`)
	end
end

for _,v in pairs(pluginSettings.LightbarLocations.Body) do
	local model = body:FindFirstChild(v)
	if model ~= nil then
		for _,part in pairs(model:GetChildren()) do
			if part:IsA("BasePart") and lightParts[part.Name] == nil then
				lightParts[part.Name] = part
			elseif part:IsA("BasePart") then
				warn(`Duplicate lightPart ({part.Name}) in {model.Name} (Body)`)
			end
		end
	end
end

for _,v in pairs(pluginSettings.LightbarLocations.Misc) do
	local model = misc:FindFirstChild(v)
	if model ~= nil then
		for _,part in pairs(model:GetChildren()) do
			if part:IsA("BasePart") and lightParts[part.Name] == nil then
				lightParts[part.Name] = part
			elseif part:IsA("BasePart") then
				warn(`Duplicate lightPart ({part.Name}) in {model.Name} (Misc)`)
			end
		end
	end
end

-- Spinup Coroutine
local function spinupCoroutine(waitTime:number, patterns:{})
	if patterns == nil or waitTime == nil then return end
	if coroutines[waitTime] ~= nil then return end

	coroutines[waitTime] = {
		running_patterns = patterns,
		thread = coroutine.create(function()
			while task.wait(waitTime) do
				if rawlen(coroutines[waitTime].running_patterns) == 0 then
					break
				else
					task.defer(function()
						for _,pattern:patternModule in pairs(coroutines[waitTime].running_patterns) do
							if pattern.count >= pattern.max_count then
								pattern.count = 1
							else
								pattern.count += 1
							end

							for lightName,lightData in pairs(pattern.lights) do
								if lights[lightName].running_module == pattern and lightData[pattern.count] ~= nil and lightParts:FindFirstChild(lightName) then
									pattern.moduleSettings.light(lightParts[lightName], lightData[pattern.count], pattern.moduleSettings.colors)
								end
							end
						end
					end)
				end
			end

			coroutines[waitTime] = nil
			return "Killed"
		end)
	}

	coroutine.resume(coroutines[waitTime].thread)
end

-- Setup Functions
local function registerLight(lightName:string)
	if lights[lightName] == nil then
		lights[lightName] = {
			running_module = nil,
			possible_modules = {}
		}
	end
end

local function registerRotator(lightName:string)
	if lightbar:FindFirstChild(`motor{lightName}`) == nil and lightParts[lightName] then
		local motorPart = Instance.new("Part")
		motorPart.Name = `motor{lightName}`
		motorPart.Size = Vector3.new(.1,.1,.1)
		motorPart.CFrame = lightParts[lightName].CFrame
		motorPart.Transparency = 1
		local weld = Instance.new("Weld")
		weld.Part0 = car.DriveSeat
		weld.Part1 = motorPart
		weld.C0 = car.DriveSeat.CFrame:Inverse()*car.DriveSeat.CFrame 
		weld.C1 = motorPart.CFrame:Inverse()*car.DriveSeat.CFrame 
		weld.Parent = car.DriveSeat

		local Center = if lightParts[lightName]:FindFirstChild("inverse") ~= nil then CFrame.new(lightParts[lightName].inverse.Position) else CFrame.new(lightParts[lightName].Position)
		local XYZ = if lightParts[lightName]:FindFirstChild("inverse") ~= nil then CFrame.Angles(lightParts[lightName].inverse.CFrame:toEulerAnglesXYZ()) else CFrame.Angles(lightParts[lightName].CFrame:toEulerAnglesXYZ())
		local motor = Instance.new("Motor6D")
		motor.Name = "Motor"
		motor.Part0 = motorPart
		motor.Part1 = lightParts[lightName]
		motor.C0 = (motorPart.CFrame:Inverse() * Center) * XYZ
		motor.C1 = (lightParts[lightName].CFrame:Inverse() * Center) * XYZ
		motor.Parent = motorPart

		for i,v in pairs(car.DriveSeat:GetChildren()) do
			if v:IsA("Weld") and v.Part1 == lightParts[lightName] then
				v:Destroy()
			end
		end

		for i,v in pairs(game.JointsService:GetDescendants()) do
			if v:IsA("Weld") and v.Part1 == lightParts[lightName] then
				v:Destroy()
			end
		end

		motorPart.Parent = lightbar
	end
end

local function setLightRunningModule(lightName:string, module:patternModule, skipPossibleModules:boolean)
	local light:lightInstance = lights[lightName]

	if light.running_module == nil or light.running_module.moduleSettings.weight < module.moduleSettings.weight then
		if light.running_module ~= nil and light.running_module.instance.Parent.Parent ~= module.instance.Parent.Parent then
			table.insert(light.possible_modules, light.running_module)
		end
		light.running_module = module
		if table.find(light.possible_modules, module) then
			table.remove(light.possible_modules, table.find(light.possible_modules, module))
		end
	elseif skipPossibleModules ~= true then
		table.insert(light.possible_modules, module)
	end
end

for _,func:Folder in pairs(lightParts.ModuleStore:GetChildren()) do
	if func:IsA("Folder") and lightbarFunctions[func.Name] == nil then
		local funcTable:lightbarFunction = {
			patterns = {},
			currentPattern = 0,
			maxPattern = 0
		}

		lightbar:GetAttributeChangedSignal(func.Name):Connect(function()
			local patternNumber:number = lightbar:GetAttribute(func.Name)
			if typeof(patternNumber) ~= "number" then return end

			if patternNumber > funcTable.maxPattern then
				lightbar:SetAttribute(func.Name, 0)
				return
			end

			if funcTable.patterns[funcTable.currentPattern] ~= nil then
				local currentPattern:pattern = funcTable.patterns[funcTable.currentPattern]

				for _,patternModule:patternModule in pairs(currentPattern.modules) do
					for lightName,lightData in pairs(patternModule.lights) do
						if lights[lightName].running_module == patternModule then
							lights[lightName].running_module = nil

							if rawlen(lights[lightName].possible_modules) > 0 then
								for _,module in pairs(lights[lightName].possible_modules) do
									setLightRunningModule(lightName, module, true)
								end
							end
						else
							table.remove(lights[lightName].possible_modules, table.find(lights[lightName].possible_modules, patternModule))
						end
					end

					for lightName,lightData in pairs(patternModule.rotators) do
						if lights[lightName].running_module == patternModule then
							lights[lightName].running_module = nil

							if rawlen(lights[lightName].possible_modules) > 0 then
								for _,module in pairs(lights[lightName].possible_modules) do
									setLightRunningModule(lightName, module, true)
								end
							end
						else
							table.remove(lights[lightName].possible_modules, table.find(lights[lightName].possible_modules, patternModule))
						end
					end

					for lightName,lightData in pairs(patternModule.faders) do
						if lights[lightName].running_module == patternModule then
							lights[lightName].running_module = nil

							if rawlen(lights[lightName].possible_modules) > 0 then
								for _,module in pairs(lights[lightName].possible_modules) do
									setLightRunningModule(lightName, module, true)
								end
							end
						else
							table.remove(lights[lightName].possible_modules, table.find(lights[lightName].possible_modules, patternModule))
						end
					end
				end
			end

			if funcTable.patterns[patternNumber] ~= nil then
				local pattern:pattern = funcTable.patterns[patternNumber]

				for _,patternModule:patternModule in pairs(pattern.modules) do
					for lightName,lightData in pairs(patternModule.lights) do
						setLightRunningModule(lightName, patternModule)
					end
					for lightName,lightData in pairs(patternModule.rotators) do
						setLightRunningModule(lightName, patternModule)
						local rotatorTable:rotatorLightThread = {
							currentRunner = 0,
							run = true
						}
						rotatorThreads[lightName] = rotatorTable
						rotatorThreads[lightName].thread = task.defer(function()
							local motor = lightbar[`motor{lightName}`]
							while task.wait(1/3) do
								if rotatorTable.run == false or lights[lightName].running_module ~= patternModule then
									break
								else
									if math.abs(motor.Motor.CurrentAngle - motor.Motor.DesiredAngle) < 0.05 then
										if rotatorTable.currentRunner >= rawlen(lightData) then
											rotatorTable.currentRunner = 1
										else
											rotatorTable.currentRunner += 1
										end

										patternModule.moduleSettings.light(lightParts[lightName], lightData[rotatorTable.currentRunner].color, patternModule.moduleSettings.colors)
										motor.Motor.MaxVelocity = lightData[rotatorTable.currentRunner].velocity
										motor.Motor.DesiredAngle = math.rad(lightData[rotatorTable.currentRunner].angle)
									end
								end
							end

							patternModule.moduleSettings.light(lightParts[lightName], 0, patternModule.moduleSettings.colors)
							motor.Motor.MaxVelocity = 5555555555555
							motor.Motor.DesiredAngle = 0
							rotatorThreads[lightName] = nil
							return "Killed"
						end)
					end
					for lightName,lightData in pairs(patternModule.faders) do
						setLightRunningModule(lightName, patternModule)
						local faderTable:tweenLightThread = {
							currentRunner = 0,
							run = true
						}
						tweenThreads[lightName] = faderTable
						tweenThreads[lightName].thread = task.defer(function()
							while task.wait(1/3) do
								if faderTable.run == false or lights[lightName].running_module ~= patternModule then
									break
								else
									if faderTable.currentRunner >= rawlen(lightData) then
										faderTable.currentRunner = 1
									else
										faderTable.currentRunner += 1
									end

									local lightData:faderLight = lightData[faderTable.currentRunner]
									if lightData.color ~= 0 then
										lightParts[lightName].Color = patternModule.moduleSettings.colors[lightData.color]
									end
									-- patternModule.moduleSettings.light(lightbar[lightName], lightData.color, patternModule.moduleSettings.colors)
									local tweenInfo = TweenInfo.new(
										lightData.timeTaken,
										lightData.easingStyle,
										lightData.easingDirection,
										lightData.repeatCount,
										lightData.reverses
									)
									faderTable.tween = TweenService:Create(lightParts[lightName], tweenInfo, {Transparency = lightData.transparency})
									faderTable.tween:Play()
									faderTable.tween.Completed:Wait()
								end
							end

							patternModule.moduleSettings.light(lightParts[lightName], 0, patternModule.moduleSettings.colors)
							tweenThreads[lightName] = nil
							return "Killed"
						end)
					end

					if coroutines[patternModule.moduleSettings.waitTime] then
						table.insert(coroutines[patternModule.moduleSettings.waitTime].running_patterns, patternModule)
					else
						spinupCoroutine(patternModule.moduleSettings.waitTime, {patternModule})
					end
				end

				if dependentOverrides[func.Name] ~= nil then
					for _,override in pairs(dependentOverrides[func.Name]) do
						if lightbar:GetAttribute(override) == 0 and lightbar:GetAttribute(`should{override}`) == true then
							lightbar:SetAttribute(override, 1)
						end
					end
				end
			else
				for _,pattern in pairs(funcTable.patterns) do
					for _,patternModule:patternModule in pairs(pattern.modules) do
						for lightName,lightData in pairs(patternModule.lights) do
							if lightParts[lightName] then
								patternModule.moduleSettings.light(lightParts[lightName], 0, patternModule.moduleSettings.colors)
							end
						end
						for lightName,lightData in pairs(patternModule.rotators) do
							if lightParts[lightName] then
								patternModule.moduleSettings.light(lightParts[lightName], 0, patternModule.moduleSettings.colors)
							end
						end
						for lightName,lightData in pairs(patternModule.faders) do
							if lightParts[lightName] then
								patternModule.moduleSettings.light(lightParts[lightName], 0, patternModule.moduleSettings.colors)
							end
						end
					end
				end

				if dependentOverrides[func.Name] ~= nil then
					for _,override in pairs(dependentOverrides[func.Name]) do
						lightbar:SetAttribute(override, 0)
					end
				end
			end

			if funcTable.patterns[funcTable.currentPattern] ~= nil then
				local currentPattern:pattern = funcTable.patterns[funcTable.currentPattern]

				for _,patternModule:patternModule in pairs(currentPattern.modules) do
					if table.find(coroutines[patternModule.moduleSettings.waitTime].running_patterns, patternModule) then
						table.remove(coroutines[patternModule.moduleSettings.waitTime].running_patterns, table.find(coroutines[patternModule.moduleSettings.waitTime].running_patterns, patternModule))
					end
				end
			end

			funcTable.currentPattern = patternNumber
		end)

		-- Setup Patterns
		for _,patternCont:Folder in pairs(func:GetChildren()) do
			local patternNumber = tonumber(patternCont.Name:match("%d+"))
			if patternCont:IsA("Folder") and patternNumber and funcTable.patterns[patternNumber] == nil then
				local pattern:pattern = {
					modules = {}
				}

				for _,patternModule in pairs(patternCont:GetChildren()) do
					if patternModule:IsA("ModuleScript") then
						local data = require(patternModule)
						if data and data["Settings"] ~= nil then
							local moduleSettings = {
								waitTime = data.Settings.WaitTime,
								weight = data.Settings.Weight,
								colors = pluginSettings.Colors,
								light = pluginSettings.Light,
							}
							if data.Settings["Colors"] ~= nil then
								moduleSettings.colors = data.Settings.Colors
							end
							if data.Settings["Light"] ~= nil then
								moduleSettings.light = data.Settings.Light
							end
							local patternModuleTable:patternModule = {
								instance = patternModule,
								data = data,
								moduleSettings = moduleSettings,
								lights = {},
								rotators = {},
								faders = {},
								count = 0,
								max_count = 0
							}


							if data["Lights"] ~= nil then
								for lightName,lightData in pairs(data.Lights) do
									registerLight(lightName)
									if patternModuleTable.lights[lightName] == nil and typeof(lightData) == "table" and lightParts[lightName] then
										patternModuleTable.lights[lightName] = lightData
										patternModuleTable.max_count = rawlen(lightData)
									else
										warn(`Duplicate light ({lightName}) in {func.Name}.{patternModule.Name}.Lights`)
									end
								end
							end

							if data["Rotators"] ~= nil then
								for lightName,lightData in pairs(data.Rotators) do
									registerLight(lightName)
									registerRotator(lightName)
									if patternModuleTable.rotators[lightName] == nil and typeof(lightData) == "table" and lightParts[lightName] then
										local lightDataTable = {}
										for i,v in pairs(lightData) do
											lightDataTable[i] = {
												color = v.Color,
												angle = v.Angle,
												velocity = v.Velocity
											}
										end
										patternModuleTable.rotators[lightName] = lightDataTable
									else
										warn(`Duplicate rotator ({lightName}) in {func.Name}.{patternModule.Name}.Rotators`)
									end
								end
							end

							if data["Faders"] ~= nil then
								for lightName,lightData in pairs(data.Faders) do
									registerLight(lightName)
									if patternModuleTable.faders[lightName] == nil and typeof(lightData) == "table" and lightParts[lightName] then
										local lightDataTable = {}
										for i,v in pairs(lightData) do
											lightDataTable[i] = {
												color = v.Color,
												transparency = v.Transparency,
												timeTaken = v.Time,
												easingStyle = v.EasingStyle,
												easingDirection = v.EasingDirection,
												repeatCount = v.RepeatCount,
												reverses = v.Reverses,
												timeDelay = v.TimeDelay,
											}
										end
										patternModuleTable.faders[lightName] = lightDataTable
									else
										warn(`Duplicate fader ({lightName}) in {func.Name}.{patternModule.Name}.Faders`)
									end
								end
							end

							table.insert(pattern.modules, patternModuleTable)
						end
					end
				end

				funcTable.maxPattern += 1
				funcTable.patterns[patternNumber] = pattern
			end
		end

		lightbar:SetAttribute(func.Name, 0)
	end
end

-- Dependent Overrides
for _,override in pairs(pluginSettings.Overrides.Chassis) do
	if typeof(override) == "table" then
		if override[1] ~= nil and override[2] ~= nil then
			if dependentOverrides[override[2]] == nil then
				dependentOverrides[override[2]] = {}
			end
			table.insert(dependentOverrides[override[2]], override[1])
		end
	end
end

for _,override in pairs(pluginSettings.Overrides.Sirens) do
	if typeof(override) == "table" then
		if override[1] ~= nil and override[2] ~= nil then
			if dependentOverrides[override[2]] == nil then
				dependentOverrides[override[2]] = {}
			end
			table.insert(dependentOverrides[override[2]], override[1])
		end
	end
end

-- Siren System
for keybind:EnumItem,siren:{} in pairs(pluginSettings.Sirens) do
	if siren._Type ~= nil and (siren._Type == "Siren" or siren._Type == "Hold") and siren.Name ~= nil and siren.OverrideOtherSounds ~= nil then
		local sirenData:siren = {
			_type = siren._Type:lower(),
			keybind = keybind,
			name = siren.Name,
			overrideOtherSounds = siren.OverrideOtherSounds,
			modifiers = {}
		}
		
		if siren.Modifiers ~= nil then
			for name,modifier in pairs(siren.Modifiers) do
				if name ~= nil and modifier ~= nil and modifier.Name ~= nil and modifier.PlayNonModified ~= nil and modifier.PlayOnModifierChange ~= nil and modifier.Delay ~= nil then
					local modifierData:sirenModifier = {
						modifierName = name,
						name = modifier.Name,
						playNonModified = modifier.PlayNonModified,
						playOnModifierChange = modifier.PlayOnModifierChange,
						timeDelay = modifier.Delay
					}
					
					sirenData.modifiers[name] = modifierData
				end
			end
		end
		
		sirensByKeybind[keybind] = sirenData
		sirensByName[sirenData.name] = sirenData
	elseif siren._Type ~= nil and siren._Type == "Modifier" and siren.Name ~= nil then
		local modifierData:modifier = {
			_type = "modifier",
			keybind = keybind,
			name = siren.Name,
			enabled = false
		}
		
		modifiers[modifierData.name] = modifierData
		sirensByKeybind[keybind] = modifiers[modifierData.name]
	end
end

local function playStopModified(name, modifiedName)
	local sirenData:siren = sirensByName[name]
	local modifiedData:sirenModifier = sirenData.modifiers[modifiedName]
	local modifierData:modifier = modifiers[modifiedName]
	local sound:Sound = soundPart[name]
	local modifiedSound:Sound = soundPart[modifiedData.name]
	
	if modifierData.enabled and sound.Playing == true then
		if modifiedData.playNonModified then
			modifiedSound:Play()
			modifiedSound.TimePosition = sound.TimePosition + modifiedData.timeDelay
		else
			modifiedSound:Play()
			sound:Stop()
			modifiedSound.TimePosition = sound.TimePosition + modifiedData.timeDelay
		end
	else
		if modifiedData.playNonModified then
			modifiedSound:Stop()
		elseif modifiedSound.IsPlaying == true then
			modifiedSound:Stop()
			sound:Play()
			sound.TimePosition = modifiedSound.TimePosition - modifiedData.timeDelay
		end
	end
end

local function playSiren(name)
	local sirenData:siren = sirensByName[name]
	local sound:Sound = soundPart[name]
	
	if sirenData.overrideOtherSounds then
		if sirenData._type == "hold" then
			for _,v in pairs(soundPart:GetChildren()) do
				if v:IsA("Sound") and v ~= sound then
					if v:GetAttribute("OriginalVolume") == nil then
						v:SetAttribute("OriginalVolume", v.Volume)
					end
					v.Volume = 0
				end
			end
		else
			for _,v in pairs(soundPart:GetChildren()) do
				if v:IsA("Sound") and v ~= sound then
					v:Stop()
				end
			end
		end
	end
	
	if sound:GetAttribute("OriginalVolume") then
		sound.Volume = sound:GetAttribute("OriginalVolume")
	end
	sound:Play()

	if pluginSettings.Overrides.Sirens[sirenData.name] ~= nil then
		if typeof(pluginSettings.Overrides.Sirens[sirenData.name]) == "string" then
			lightbar:SetAttribute(pluginSettings.Overrides.Sirens[sirenData.name], 1)
		elseif typeof(pluginSettings.Overrides.Sirens[sirenData.name]) == "table" then
			lightbar:SetAttribute(`should{pluginSettings.Overrides.Sirens[sirenData.name][1]}`, true)
			lightbar:SetAttribute(
				pluginSettings.Overrides.Sirens[sirenData.name][1],
				if lightbar:GetAttribute(pluginSettings.Overrides.Sirens[sirenData.name][2]) > 0 then 1 else 0
			)
		end
	end

	for modifiedName,data:sirenModifier in pairs(sirenData.modifiers) do
		if soundPart:FindFirstChild(data.name) then
			playStopModified(name,modifiedName)
		end
	end
end

local function stopSiren(name)
	local sirenData:siren = sirensByName[name]
	local sound:Sound = soundPart[name]
	
	if sirenData.overrideOtherSounds then
		if sirenData._type == "hold" then
			for _,v in pairs(soundPart:GetChildren()) do
				if v:IsA("Sound") and v ~= sound and v:GetAttribute("OriginalVolume") then
					v.Volume = v:GetAttribute("OriginalVolume")
				end
			end
		end
	end
	
	sound:Stop()

	if pluginSettings.Overrides.Sirens[sirenData.name] ~= nil then
		if typeof(pluginSettings.Overrides.Sirens[sirenData.name]) == "string" then
			lightbar:SetAttribute(pluginSettings.Overrides.Sirens[sirenData.name], 0)
		elseif typeof(pluginSettings.Overrides.Sirens[sirenData.name]) == "table" then
			lightbar:SetAttribute(`should{pluginSettings.Overrides.Sirens[sirenData.name][1]}`, false)
			lightbar:SetAttribute(pluginSettings.Overrides.Sirens[sirenData.name][1], 0)
		end
	end

	for modifiedName,data:sirenModifier in pairs(sirenData.modifiers) do
		if soundPart:FindFirstChild(data.name) then
			playStopModified(name,modifiedName)
		end
	end
end

-- Default State
for functionName,state in pairs(pluginSettings.DefaultFunctionState) do
	lightbar:SetAttribute(functionName, state)
end

-- Input Handler
event.OnServerEvent:Connect(function(player, eventType:string, ...)
	if player.Character ~= car.DriveSeat.Occupant.Parent then return end

	if eventType == "Input" then
		local state:EnumItem, inputType:EnumItem, keycode:EnumItem = ...
		if state == Enum.UserInputState.Begin then
			if pluginSettings.Keybinds[keycode] then
				if typeof(lightbar:GetAttribute(pluginSettings.Keybinds[keycode])) ~= "number" then return end
				lightbar:SetAttribute(pluginSettings.Keybinds[keycode],  lightbar:GetAttribute(pluginSettings.Keybinds[keycode])+1)
			elseif sirensByKeybind[keycode] then
				local sirenData:siren|modifier = sirensByKeybind[keycode]
				if sirenData._type == "siren" or sirenData._type == "hold" then
					if soundPart:FindFirstChild(sirenData.name) then
						if soundPart[sirenData.name].Playing and sirenData._type ~= "hold" then
							stopSiren(sirenData.name)
						else
							playSiren(sirenData.name)
						end
					end
				elseif sirenData._type == "modifier" then
					if sirenData.enabled then
						sirenData.enabled = false
						if pluginSettings.Overrides.Sirens[sirenData.name] ~= nil then
							lightbar:SetAttribute(pluginSettings.Overrides.Sirens[sirenData.name], 0)
						end

						for _,v:siren in pairs(sirensByName) do
							if v.modifiers[sirenData.name] then
								playStopModified(v.name, sirenData.name)
							end
						end
					else
						sirenData.enabled = true
						if pluginSettings.Overrides.Sirens[sirenData.name] ~= nil then
							lightbar:SetAttribute(pluginSettings.Overrides.Sirens[sirenData.name], 1)
						end

						for _,v:siren in pairs(sirensByName) do
							if v.modifiers[sirenData.name] then
								playStopModified(v.name, sirenData.name)
							end
						end
					end
				end
			end
		elseif state == Enum.UserInputState.End then
			if sirensByKeybind[keycode] then
				local sirenData:siren|modifier = sirensByKeybind[keycode]
				if sirenData._type == "hold" then
					if soundPart[sirenData.name].Playing then
						stopSiren(sirenData.name)
					end
				end
			end
		end
	elseif eventType == "UpdateFunction" then
		local functionName, value = ...
		lightbar:SetAttribute(functionName, value)
	elseif eventType == "DoOverride" then
		local overrideType, value = ...
		if overrideType == "PBrake" and pluginSettings.Overrides.Chassis.ParkBrake ~= false then
			if typeof(pluginSettings.Overrides.Chassis.ParkBrake) == "string" then
				lightbar:SetAttribute(pluginSettings.Overrides.Chassis.ParkBrake, if value == true then 1 else 0)
			elseif typeof(pluginSettings.Overrides.Chassis.ParkBrake) == "table" then
				if value == true then
					lightbar:SetAttribute(`should{pluginSettings.Overrides.Chassis.ParkBrake[1]}`, true)
					lightbar:SetAttribute(
						pluginSettings.Overrides.Chassis.ParkBrake[1],
						if lightbar:GetAttribute(pluginSettings.Overrides.Chassis.ParkBrake[2]) > 0 then 1 else 0
					)
				else
					lightbar:SetAttribute(`should{pluginSettings.Overrides.Chassis.ParkBrake[1]}`, false)
					lightbar:SetAttribute(pluginSettings.Overrides.Chassis.ParkBrake[1], 0)
				end
			end
		elseif overrideType == "Brake" and pluginSettings.Overrides.Chassis.Brake ~= false then
			if typeof(pluginSettings.Overrides.Chassis.Brake) == "string" then
				lightbar:SetAttribute(pluginSettings.Overrides.Chassis.Brake, if value > 0 then 1 else 0)
			elseif typeof(pluginSettings.Overrides.Chassis.Brake) == "table" then
				if value > 0 then
					lightbar:SetAttribute(`should{pluginSettings.Overrides.Chassis.Brake[1]}`, true)
					lightbar:SetAttribute(
						pluginSettings.Overrides.Chassis.Brake[1],
						if lightbar:GetAttribute(pluginSettings.Overrides.Chassis.Brake[2]) > 0 then 1 else 0
					)
				else
					lightbar:SetAttribute(`should{pluginSettings.Overrides.Chassis.Brake[1]}`, false)
					lightbar:SetAttribute(pluginSettings.Overrides.Chassis.Brake[1], 0)
				end
			end
		elseif overrideType == "Gear" and pluginSettings.Overrides.Chassis.Reverse ~= false then
			if typeof(pluginSettings.Overrides.Chassis.Reverse) == "string" then
				lightbar:SetAttribute(pluginSettings.Overrides.Chassis.Reverse, if value == -1 then 1 else 0)
			elseif typeof(pluginSettings.Overrides.Chassis.Reverse) == "table" then
				if value > -1 then
					lightbar:SetAttribute(`should{pluginSettings.Overrides.Chassis.Reverse[1]}`, true)
					lightbar:SetAttribute(
						pluginSettings.Overrides.Chassis.Reverse[1],
						if lightbar:GetAttribute(pluginSettings.Overrides.Chassis.Reverse[2]) > 0 then 1 else 0
					)
				else
					lightbar:SetAttribute(`should{pluginSettings.Overrides.Chassis.Reverse[1]}`, false)
					lightbar:SetAttribute(pluginSettings.Overrides.Chassis.Reverse[1], 0)
				end
			end
		end
	end
end)