--[[
	Redon Tech 2023-2024
	EVC V2

	MIT License
	Copyright (c) 2022-2024 Redon Tech
--]]

--------------------------------------------------------------------------------
-- Types --
--------------------------------------------------------------------------------

type elsLight = { number }

type rotatorLight = {
	color: number,
	angle: number,
	velocity: number,
}

type faderLight = {
	color: number,
	transparency: number,
	timeTaken: number,
	easingStyle: Enum.EasingStyle,
	easingDirection: Enum.EasingDirection,
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
		colors: { [number]: Color3 },
		light: (BasePart, number, { [number]: Color3 }) -> nil,
	},
	lights: { [string]: { elsLight } },
	rotators: { [string]: { [number]: { rotatorLight } } },
	faders: { [string]: { [number]: { faderLight } } },
	count: number,
	max_count: number,
}

type pattern = {
	modules: { patternModule },
}

type lightbarFunction = {
	patterns: { [number]: pattern },
	currentPattern: number,
	maxPattern: number,
}

type lightInstance = {
	running_module: patternModule?,
	possible_modules: { patternModule },
}

type runningCoroutine = {
	thread: thread,
	running_patterns: { patternModule },
}

type rotatorLightThread = {
	thread: thread?,
	currentRunner: number,
	run: boolean,
}

type tweenLightThread = {
	thread: thread?,
	tween: Tween?,
	currentRunner: number,
	run: boolean,
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
	modifiers: { [string]: sirenModifier },
}

type sirenSetting = {
	_Type: string,
	Name: string,
	OverrideOtherSounds: boolean,
	Modifiers: { [string]: sirenModifier }?,
}

type modifier = {
	_type: string,
	keybind: EnumItem,
	name: string,
	enabled: boolean,
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

if script.Parent == nil or script.Parent:IsA("RemoteEvent") == false then
	error("EVCPlugin must be a child of a RemoteEvent under EVCPlugin_Client inside Plugins on a A-Chassis Vehicle")
end
local event = script.Parent :: RemoteEvent

if event.Parent == nil or event.Parent:IsA("Model") == false then
	error("EVCPlugin must be a child of a RemoteEvent under EVCPlugin_Client inside Plugins on a A-Chassis Vehicle")
end
local car = event.Parent :: Model

local pluginSettings = require(event:WaitForChild("Settings"))
local body: Model = car:WaitForChild("Body")
local misc: Model = car:WaitForChild("Misc")
local lightbarInstance: Instance? = body:WaitForChild(pluginSettings.LightbarName)
if lightbarInstance == nil or lightbarInstance:IsA("Model") == false then
	error(`No lightbar found`)
end
local lightbar: Model = lightbarInstance :: Model

local soundPart: Instance? = lightbar:FindFirstChild(pluginSettings.SirenName) :: Instance?

local TweenService = game:GetService("TweenService")
local JointsService = game:GetService("JointsService")
local RunService = game:GetService("RunService")

local lightParts: { [string]: BasePart } = {}
local lights: { [string]: lightInstance } = {}
local lightbarFunctions: { [string]: lightbarFunction } = {}
local coroutines = {}
local rotatorThreads: { [string]: rotatorLightThread } = {}
local tweenThreads: { [string]: tweenLightThread } = {}
local sirensByKeybind: { [EnumItem]: siren | modifier } = {}
local sirensByName: { [string]: siren } = {}
local modifiers: { [string]: modifier } = {}
local dependentOverrides: { [string]: { { string | number } } } = {}
local faders: { [Instance]: { lightos: { GuiObject }, lights: { Light }, guis: { SurfaceGui } } } = {}

--------------------------------------------------------------------------------
-- Functions --
--------------------------------------------------------------------------------

local function findFirstDescendant(instance: Instance, name: string): Instance?
	for _, child in pairs(instance:GetDescendants()) do
		if child.Name == name then
			return child
		end
	end
	return nil
end

-- Checks

local moduleStoreFolder: Instance? = lightbar:FindFirstChild("ModuleStore")
if moduleStoreFolder == nil or moduleStoreFolder:IsA("Folder") == false then
	error(`No modulestore found`)
end
local moduleStore: Folder = moduleStoreFolder :: Folder
if soundPart == nil then
	warn(`No soundpart found will be unable to play any sirens`)
end

for _, part in pairs(lightbar:GetDescendants()) do
	if part:IsA("BasePart") and lightParts[part.Name] == nil then
		lightParts[part.Name] = part
	elseif part:IsA("BasePart") then
		warn(`Duplicate lightPart ({part.Name}) in {lightbar.Name} (Body)`)
	end
end

for _, v in pairs(pluginSettings.AdditionalLightbarLocations.Body) do
	local model = findFirstDescendant(body, v)
	if model ~= nil then
		for _, part in pairs(model:GetDescendants()) do
			if part:IsA("BasePart") and lightParts[part.Name] == nil then
				lightParts[part.Name] = part
			elseif part:IsA("BasePart") then
				warn(`Duplicate lightPart ({part.Name}) in {model.Name} (Body)`)
			end
		end
	end
end

for _, v in pairs(pluginSettings.AdditionalLightbarLocations.Misc) do
	local model = findFirstDescendant(misc, v)
	if model ~= nil then
		for _, part in pairs(model:GetDescendants()) do
			if part:IsA("BasePart") and lightParts[part.Name] == nil then
				lightParts[part.Name] = part
			elseif part:IsA("BasePart") then
				warn(`Duplicate lightPart ({part.Name}) in {model.Name} (Misc)`)
			end
		end
	end
end

-- Spinup Coroutine
local function spinupCoroutine(waitTime: number, patterns: {})
	if patterns == nil or waitTime == nil then
		return
	end
	if coroutines[waitTime] ~= nil then
		return
	end

	coroutines[waitTime] = {
		running_patterns = patterns,
		thread = coroutine.create(function()
			while task.wait(waitTime) do
				if rawlen(coroutines[waitTime].running_patterns) == 0 then
					break
				else
					task.defer(function()
						for _, pattern: patternModule in pairs(coroutines[waitTime].running_patterns) do
							if pattern.count >= pattern.max_count then
								pattern.count = 1
							else
								pattern.count += 1
							end

							for lightName, lightData in pairs(pattern.lights) do
								if
									lights[lightName].running_module == pattern
									and lightData[pattern.count] ~= nil
									and lightParts[lightName]
								then
									pattern.moduleSettings.light(
										lightParts[lightName],
										lightData[pattern.count],
										pattern.moduleSettings.colors
									)
								end
							end
						end
					end)
				end
			end

			coroutines[waitTime] = nil
			return "Killed"
		end),
	}

	coroutine.resume(coroutines[waitTime].thread)
end

-- Setup Functions
local function registerLight(lightName: string)
	if lights[lightName] == nil then
		lights[lightName] = {
			running_module = nil,
			possible_modules = {},
		}
	end
end

local function registerRotator(lightName: string)
	if lightbar:FindFirstChild(`motor{lightName}`) == nil and lightParts[lightName] then
		local motorPart = Instance.new("Part")
		motorPart.Name = `motor{lightName}`
		motorPart.Size = Vector3.new(0.1, 0.1, 0.1)
		motorPart.CFrame = lightParts[lightName].CFrame
		motorPart.Transparency = 1
		local weld = Instance.new("Weld")
		weld.Part0 = car.DriveSeat
		weld.Part1 = motorPart
		weld.C0 = car.DriveSeat.CFrame:Inverse() * car.DriveSeat.CFrame
		weld.C1 = motorPart.CFrame:Inverse() * car.DriveSeat.CFrame
		weld.Parent = car.DriveSeat

		local inversePart: Instance? = lightParts[lightName]:FindFirstChild("inverse")
		local inverse: BasePart? = nil
		if inversePart ~= nil and inversePart:IsA("BasePart") then
			inverse = inversePart
		end

		local Center = if inverse ~= nil
			then CFrame.new(inverse.Position)
			else CFrame.new(lightParts[lightName].Position)
		local XYZ = if inverse ~= nil
			then CFrame.Angles(inverse.CFrame:ToEulerAnglesXYZ())
			else CFrame.Angles(lightParts[lightName].CFrame:ToEulerAnglesXYZ())
		local motor = Instance.new("Motor6D")
		motor.Name = "Motor"
		motor.Part0 = motorPart
		motor.Part1 = lightParts[lightName]
		motor.C0 = (motorPart.CFrame:Inverse() * Center) * XYZ
		motor.C1 = (lightParts[lightName].CFrame:Inverse() * Center) * XYZ
		motor:SetAttribute("C1", motor.C1)
		motor.Parent = motorPart

		for i, v in pairs(lightParts[lightName]:GetChildren()) do
			if v:IsA("WeldConstraint") and v.Part1 == car.DriveSeat then
				v:Destroy()
			end
		end

		for i, v in pairs(car.DriveSeat:GetChildren()) do
			if v:IsA("Weld") and v.Part1 == lightParts[lightName] then
				v:Destroy()
			end
		end

		for i, v in pairs(JointsService:GetDescendants()) do
			if v:IsA("Weld") and v.Part1 == lightParts[lightName] then
				v:Destroy()
			end
		end

		motorPart.Parent = lightbar
	end
end

local function registerFader(lightPart: BasePart)
	local data = {
		lightos = {},
		lights = {},
		guis = {},
	}

	for _, v in pairs(lightPart:GetDescendants()) do
		if v:IsA("GuiObject") then
			v:SetAttribute("defaultTransparency", v.ImageTransparency)
			table.insert(data.lightos, v)
		elseif v:IsA("Light") then
			v:SetAttribute("defaultBrightness", v.Brightness)
			table.insert(data.lights, v)
		elseif v:IsA("SurfaceGui") then
			table.insert(data.guis, v)
		end
	end

	faders[lightPart] = data
end

local function setLightRunningModule(lightName: string, module: patternModule, skipPossibleModules: boolean?)
	local light: lightInstance = lights[lightName]

	if light.running_module == nil or light.running_module.moduleSettings.weight < module.moduleSettings.weight then
		if light.running_module ~= nil then
			local runningModuleParent = light.running_module.instance.Parent
			local moduleParent = module.instance.Parent
			local runningModuleParentParent = runningModuleParent.Parent
			local moduleParentParent = moduleParent.Parent

			if runningModuleParentParent ~= moduleParentParent then
				table.insert(light.possible_modules, light.running_module)
			end
		end
		light.running_module = module
		if tweenThreads[lightName] ~= nil and tweenThreads[lightName].tween ~= nil then
			local tween = tweenThreads[lightName].tween :: Tween
			tween:Cancel()
		end
		if table.find(light.possible_modules, module) then
			table.remove(light.possible_modules, table.find(light.possible_modules, module))
		end
	elseif skipPossibleModules ~= true then
		table.insert(light.possible_modules, module)
	end
end

for _, func in pairs(moduleStore:GetChildren()) do
	if func:IsA("Folder") and lightbarFunctions[func.Name] == nil then
		local funcTable: lightbarFunction = {
			patterns = {},
			currentPattern = 0,
			maxPattern = 0,
		}

		lightbar:GetAttributeChangedSignal(func.Name):Connect(function()
			local patternNumber: unknown? = lightbar:GetAttribute(func.Name)
			if typeof(patternNumber) ~= "number" then
				return
			end

			if patternNumber > funcTable.maxPattern then
				lightbar:SetAttribute(func.Name, 0)
				return
			end

			if funcTable.patterns[funcTable.currentPattern] ~= nil then
				local currentPattern: pattern = funcTable.patterns[funcTable.currentPattern]

				for _, patternModule: patternModule in pairs(currentPattern.modules) do
					for lightName, lightData in pairs(patternModule.lights) do
						if lights[lightName].running_module == patternModule then
							lights[lightName].running_module = nil

							if rawlen(lights[lightName].possible_modules) > 0 then
								local highestWeight = {
									weight = 0,
									module = nil,
								}
								for _, module in ipairs(lights[lightName].possible_modules) do
									if module.moduleSettings.weight > highestWeight.weight then
										highestWeight.weight = module.moduleSettings.weight
										highestWeight.module = module
									end
								end
								setLightRunningModule(lightName, highestWeight.module)
							end
						else
							table.remove(
								lights[lightName].possible_modules,
								table.find(lights[lightName].possible_modules, patternModule)
							)
						end
					end

					for lightName, lightData in pairs(patternModule.rotators) do
						if lights[lightName].running_module == patternModule then
							lights[lightName].running_module = nil

							if rawlen(lights[lightName].possible_modules) > 0 then
								local highestWeight = {
									weight = 0,
									module = nil,
								}
								for _, module in ipairs(lights[lightName].possible_modules) do
									if module.moduleSettings.weight > highestWeight.weight then
										highestWeight.weight = module.moduleSettings.weight
										highestWeight.module = module
									end
								end
								setLightRunningModule(lightName, highestWeight.module)
							end
						else
							table.remove(
								lights[lightName].possible_modules,
								table.find(lights[lightName].possible_modules, patternModule)
							)
						end
					end

					for lightName, lightData in pairs(patternModule.faders) do
						if lights[lightName].running_module == patternModule then
							lights[lightName].running_module = nil

							if rawlen(lights[lightName].possible_modules) > 0 then
								local highestWeight = {
									weight = 0,
									module = nil,
								}
								for _, module in ipairs(lights[lightName].possible_modules) do
									if module.moduleSettings.weight > highestWeight.weight then
										highestWeight.weight = module.moduleSettings.weight
										highestWeight.module = module
									end
								end
								setLightRunningModule(lightName, highestWeight.module)
							end
						else
							table.remove(
								lights[lightName].possible_modules,
								table.find(lights[lightName].possible_modules, patternModule)
							)
						end
					end
				end
			end

			if funcTable.patterns[patternNumber] ~= nil then
				local pattern: pattern = funcTable.patterns[patternNumber]

				for _, patternModule: patternModule in pairs(pattern.modules) do
					for lightName, lightData in pairs(patternModule.lights) do
						setLightRunningModule(lightName, patternModule)
					end
					for lightName, lightData in pairs(patternModule.rotators) do
						setLightRunningModule(lightName, patternModule)
						local rotatorTable: rotatorLightThread = {
							currentRunner = 0,
							run = true,
						}
						rotatorThreads[lightName] = rotatorTable
						rotatorThreads[lightName].thread = task.defer(function()
							local motorPart = lightbar[`motor{lightName}`]
							if motorPart == nil then
								rotatorThreads[lightName] = nil
								return
							end
							local motor: Motor6D = motorPart:WaitForChild("Motor") :: Motor6D
							local defaultC1 = motor:GetAttribute("C1")
							local currentRad = 0
							local currentTarget = 0
							local desiredAngle = 0
							local currentVelocity = 0

							local connection
							connection = RunService.Heartbeat:Connect(function()
								if rotatorTable.run == false then
									connection:Disconnect()
									rotatorThreads[lightName] = nil
									motor.C1 = defaultC1
									desiredAngle = 0
									patternModule.moduleSettings.light(
										lightParts[lightName],
										0,
										patternModule.moduleSettings.colors
									)
									return
								elseif lights[lightName].running_module == patternModule and lightParts[lightName] then
									if -desiredAngle ~= currentTarget then
										currentTarget = -desiredAngle
									end
									if currentVelocity ~= motor.MaxVelocity then
										currentVelocity = motor.MaxVelocity
									end

									local diff = currentTarget - currentRad
									if math.abs(diff) < 0.05 then
										motor.C1 = defaultC1 * CFrame.Angles(0, 0, currentTarget)

										if rotatorTable.currentRunner >= rawlen(lightData) then
											rotatorTable.currentRunner = 1
										else
											rotatorTable.currentRunner += 1
										end

										patternModule.moduleSettings.light(
											lightParts[lightName],
											lightData[rotatorTable.currentRunner].color,
											patternModule.moduleSettings.colors
										)
										motor.MaxVelocity = lightData[rotatorTable.currentRunner].velocity
										desiredAngle = math.rad(lightData[rotatorTable.currentRunner].angle)
									else
										currentRad += if diff > 0 then currentVelocity else -currentVelocity
										if math.abs(currentVelocity) > math.abs(currentTarget) then
											currentRad = currentTarget
										end
										if math.abs(currentRad) > math.abs(currentTarget) then
											currentRad = currentTarget
										end
										motor.C1 = defaultC1 * CFrame.Angles(0, 0, currentRad)
									end
								else
									rotatorTable.currentRunner = 0
									currentRad = 0
									currentTarget = 0
									desiredAngle = 0
									currentVelocity = 0
								end
							end)
						end)
					end
					for lightName, lightData in pairs(patternModule.faders) do
						setLightRunningModule(lightName, patternModule)
						local faderTable: tweenLightThread = {
							currentRunner = 0,
							run = true,
						}
						tweenThreads[lightName] = faderTable
						tweenThreads[lightName].thread = task.defer(function()
							local fader = faders[lightParts[lightName]]
							local hasBeenOverridden = false
							while task.wait(1 / 3) do
								if faderTable.run == false then
									break
								elseif lights[lightName].running_module == patternModule and lightParts[lightName] then
									if hasBeenOverridden == true then
										hasBeenOverridden = false
									end
									if faderTable.currentRunner >= rawlen(lightData) then
										faderTable.currentRunner = 1
									else
										faderTable.currentRunner += 1
									end

									local lightData: faderLight = lightData[faderTable.currentRunner]
									if lightData.color ~= 0 then
										lightParts[lightName].Color =
											patternModule.moduleSettings.colors[lightData.color]
										for _, lighto in pairs(fader.lightos) do
											lighto.Visible = true
											lighto.ImageColor3 = patternModule.moduleSettings.colors[lightData.color]
										end
										for _, light in pairs(fader.lights) do
											light.Enabled = true
											light.Color = patternModule.moduleSettings.colors[lightData.color]
										end
										for _, gui in pairs(fader.guis) do
											gui.Enabled = true
										end
									end
									-- patternModule.moduleSettings.light(lightbar[lightName], lightData.color, patternModule.moduleSettings.colors)
									local tweenInfo = TweenInfo.new(
										lightData.timeTaken,
										lightData.easingStyle,
										lightData.easingDirection,
										lightData.repeatCount,
										lightData.reverses
									)
									faderTable.tween = TweenService:Create(
										lightParts[lightName],
										tweenInfo,
										{ Transparency = lightData.transparency }
									)
									if faderTable.tween ~= nil then
										faderTable.tween:Play()
										local temporaryConnection
										temporaryConnection = lightParts[lightName]
											:GetPropertyChangedSignal("Transparency")
											:Connect(function()
												local transparency = lightParts[lightName].Transparency
												for _, lighto in pairs(fader.lightos) do
													lighto.ImageTransparency = transparency
												end
												for _, light in pairs(fader.lights) do
													light.Brightness = light:GetAttribute("defaultBrightness")
														* (1 - transparency)
												end
											end)
										faderTable.tween.Completed:Wait()
										if temporaryConnection ~= nil then
											temporaryConnection:Disconnect()
										end
									end
								elseif hasBeenOverridden == false then
									hasBeenOverridden = true
									for _, lighto in pairs(fader.lightos) do
										lighto.ImageTransparency = lighto:GetAttribute("defaultTransparency")
									end
									for _, light in pairs(fader.lights) do
										light.Brightness = light:GetAttribute("defaultBrightness")
									end
								end
							end

							for _, lighto in pairs(fader.lightos) do
								lighto.ImageTransparency = lighto:GetAttribute("defaultTransparency")
							end
							for _, light in pairs(fader.lights) do
								light.Brightness = light:GetAttribute("defaultBrightness")
							end
							patternModule.moduleSettings.light(
								lightParts[lightName],
								0,
								patternModule.moduleSettings.colors
							)
							tweenThreads[lightName] = nil
							return "Killed"
						end)
					end

					if coroutines[patternModule.moduleSettings.waitTime] then
						table.insert(coroutines[patternModule.moduleSettings.waitTime].running_patterns, patternModule)
					else
						spinupCoroutine(patternModule.moduleSettings.waitTime, { patternModule })
					end
				end

				if dependentOverrides[func.Name] ~= nil then
					for _, override in pairs(dependentOverrides[func.Name]) do
						if
							lightbar:GetAttribute(override[1]) == 0
							and lightbar:GetAttribute(`should{override[1]}`) == true
							and patternNumber > override[2] - 1
						then
							lightbar:SetAttribute(override[1], 1)
						end
					end
				end
			else
				for _, pattern in pairs(funcTable.patterns) do
					for _, patternModule: patternModule in pairs(pattern.modules) do
						for lightName, lightData in pairs(patternModule.lights) do
							if lightParts[lightName] then
								patternModule.moduleSettings.light(
									lightParts[lightName],
									0,
									patternModule.moduleSettings.colors
								)
							end
						end
						for lightName, lightData in pairs(patternModule.rotators) do
							if rotatorThreads[lightName] then
								rotatorThreads[lightName].run = false
							end

							if lightParts[lightName] then
								patternModule.moduleSettings.light(
									lightParts[lightName],
									0,
									patternModule.moduleSettings.colors
								)
							end
						end
						for lightName, lightData in pairs(patternModule.faders) do
							if tweenThreads[lightName] then
								tweenThreads[lightName].run = false
							end

							if lightParts[lightName] then
								patternModule.moduleSettings.light(
									lightParts[lightName],
									0,
									patternModule.moduleSettings.colors
								)
							end
						end
					end
				end

				if dependentOverrides[func.Name] ~= nil then
					for _, override in pairs(dependentOverrides[func.Name]) do
						lightbar:SetAttribute(override[1], 0)
					end
				end
			end

			if funcTable.patterns[funcTable.currentPattern] ~= nil then
				local currentPattern: pattern = funcTable.patterns[funcTable.currentPattern]

				for _, patternModule: patternModule in pairs(currentPattern.modules) do
					if
						table.find(coroutines[patternModule.moduleSettings.waitTime].running_patterns, patternModule)
					then
						table.remove(
							coroutines[patternModule.moduleSettings.waitTime].running_patterns,
							table.find(
								coroutines[patternModule.moduleSettings.waitTime].running_patterns,
								patternModule
							)
						)
					end
				end
			end

			funcTable.currentPattern = patternNumber
		end)

		-- Setup Patterns
		for _, patternCont in pairs(func:GetChildren()) do
			local patternNumber = tonumber(patternCont.Name:match("%d+"))
			if patternCont:IsA("Folder") and patternNumber and funcTable.patterns[patternNumber] == nil then
				local pattern: pattern = {
					modules = {},
				}

				for _, patternModule in pairs(patternCont:GetChildren()) do
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
							local patternModuleTable: patternModule = {
								instance = patternModule,
								data = data,
								moduleSettings = moduleSettings,
								lights = {},
								rotators = {},
								faders = {},
								count = 0,
								max_count = 0,
							}

							if data["Lights"] ~= nil then
								for lightName, lightData in pairs(data.Lights) do
									registerLight(lightName)
									if
										patternModuleTable.lights[lightName] == nil
										and typeof(lightData) == "table"
										and lightParts[lightName]
									then
										patternModuleTable.lights[lightName] = lightData
										patternModuleTable.max_count = rawlen(lightData)
									else
										warn(`Duplicate light ({lightName}) in {func.Name}.{patternModule.Name}.Lights`)
									end
								end
							end

							if data["Rotators"] ~= nil then
								for lightName, lightData in pairs(data.Rotators) do
									registerLight(lightName)
									registerRotator(lightName)
									if
										patternModuleTable.rotators[lightName] == nil
										and typeof(lightData) == "table"
										and lightParts[lightName]
									then
										local lightDataTable = {}
										for i, v in pairs(lightData) do
											lightDataTable[i] = {
												color = v.Color,
												angle = v.Angle,
												velocity = v.Velocity,
											}
										end
										patternModuleTable.rotators[lightName] = lightDataTable
									else
										warn(
											`Duplicate rotator ({lightName}) in {func.Name}.{patternModule.Name}.Rotators`
										)
									end
								end
							end

							if data["Faders"] ~= nil then
								for lightName, lightData in pairs(data.Faders) do
									registerLight(lightName)
									if
										patternModuleTable.faders[lightName] == nil
										and typeof(lightData) == "table"
										and lightParts[lightName]
									then
										registerFader(lightParts[lightName])
										local lightDataTable = {}
										for i, v in pairs(lightData) do
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
for _, override in pairs(pluginSettings.Overrides.Chassis) do
	if typeof(override) == "table" then
		if override[1] ~= nil and override[2] ~= nil then
			if dependentOverrides[override[2]] == nil then
				dependentOverrides[override[2]] = {}
			end
			local dependentPattern = override[3] or 1
			table.insert(dependentOverrides[override[2]], { override[1], dependentPattern })
		end
	end
end

for _, override in pairs(pluginSettings.Overrides.Sirens) do
	if typeof(override) == "table" then
		if override[1] ~= nil and override[2] ~= nil then
			if dependentOverrides[override[2]] == nil then
				dependentOverrides[override[2]] = {}
			end
			local dependentPattern = override[3] or 1
			table.insert(dependentOverrides[override[2]], { override[1], dependentPattern })
		end
	end
end

-- Siren System
for keybind: EnumItem, siren: sirenSetting in pairs(pluginSettings.Sirens) do
	if
		siren._Type ~= nil
		and (siren._Type == "Siren" or siren._Type == "Hold")
		and siren.Name ~= nil
		and siren.OverrideOtherSounds ~= nil
	then
		local sirenData: siren = {
			_type = siren._Type:lower(),
			keybind = keybind,
			name = siren.Name,
			overrideOtherSounds = siren.OverrideOtherSounds,
			modifiers = {},
		}

		if siren.Modifiers ~= nil then
			for name, modifier in pairs(siren.Modifiers) do
				if
					name ~= nil
					and modifier ~= nil
					and modifier.Name ~= nil
					and modifier.PlayNonModified ~= nil
					and modifier.PlayOnModifierChange ~= nil
					and modifier.Delay ~= nil
				then
					local modifierData: sirenModifier = {
						modifierName = name,
						name = modifier.Name,
						playNonModified = modifier.PlayNonModified,
						playOnModifierChange = modifier.PlayOnModifierChange,
						timeDelay = modifier.Delay,
					}

					sirenData.modifiers[name] = modifierData
				end
			end
		end

		sirensByKeybind[keybind] = sirenData
		sirensByName[sirenData.name] = sirenData
	elseif siren._Type ~= nil and siren._Type == "Modifier" and siren.Name ~= nil then
		local modifierData: modifier = {
			_type = "modifier",
			keybind = keybind,
			name = siren.Name,
			enabled = false,
		}

		modifiers[modifierData.name] = modifierData
		sirensByKeybind[keybind] = modifiers[modifierData.name]
	end
end

local function playStopModified(name, modifiedName)
	if soundPart == nil then
		return
	end
	local soundPart: Instance = soundPart

	local sirenData: siren = sirensByName[name]
	local modifiedData: sirenModifier = sirenData.modifiers[modifiedName]
	local modifierData: modifier = modifiers[modifiedName]
	local soundInstance: Instance? = soundPart:FindFirstChild(name)
	if soundInstance == nil or soundInstance:IsA("Sound") == false then
		return
	end
	local sound: Sound = soundInstance :: Sound

	local modifiedSoundInstance: Instance? = soundPart:FindFirstChild(modifiedData.name)
	if modifiedSoundInstance == nil or modifiedSoundInstance:IsA("Sound") == false then
		return
	end
	local modifiedSound: Sound = modifiedSoundInstance :: Sound

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

local function stopSiren(name)
	if soundPart == nil then
		return
	end
	local soundPart: Instance = soundPart

	local sirenData: siren = sirensByName[name]
	local soundInstance: Instance? = soundPart:FindFirstChild(name)
	if soundInstance == nil or soundInstance:IsA("Sound") == false then
		return
	end
	local sound: Sound = soundInstance :: Sound

	if sirenData.overrideOtherSounds then
		if sirenData._type == "hold" then
			for _, v in pairs(soundPart:GetChildren()) do
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

	for modifiedName, data: sirenModifier in pairs(sirenData.modifiers) do
		if soundPart:FindFirstChild(data.name) then
			playStopModified(name, modifiedName)
		end
	end
end

local function playSiren(name)
	if soundPart == nil then
		return
	end
	local soundPart: Instance = soundPart

	local sirenData: siren = sirensByName[name]
	local soundInstance: Instance? = soundPart:FindFirstChild(name)
	if soundInstance == nil or soundInstance:IsA("Sound") == false then
		return
	end
	local sound: Sound = soundInstance :: Sound

	if sirenData.overrideOtherSounds then
		if sirenData._type == "hold" then
			for _, v in pairs(soundPart:GetChildren()) do
				if v:IsA("Sound") and v ~= sound and sirensByName[v.Name] then
					if v:GetAttribute("OriginalVolume") == nil then
						v:SetAttribute("OriginalVolume", v.Volume)
					end
					v.Volume = 0
				end
			end
		else
			for _, v in pairs(soundPart:GetChildren()) do
				if v:IsA("Sound") and v ~= sound and sirensByName[v.Name] then
					stopSiren(v.Name)
				end
			end
		end
	end

	local originalVolume = sound:GetAttribute("OriginalVolume")
	if typeof(originalVolume) == "number" then
		sound.Volume = originalVolume
	end
	sound:Play()

	if pluginSettings.Overrides.Sirens[sirenData.name] ~= nil then
		if typeof(pluginSettings.Overrides.Sirens[sirenData.name]) == "string" then
			lightbar:SetAttribute(pluginSettings.Overrides.Sirens[sirenData.name], 1)
		elseif typeof(pluginSettings.Overrides.Sirens[sirenData.name]) == "table" then
			local dependency = lightbar:GetAttribute(pluginSettings.Overrides.Sirens[sirenData.name][2])
			if typeof(dependency) ~= "number" then
				return
			end
			local dependencyPattern = pluginSettings.Overrides.Sirens[sirenData.name][3]
			if dependencyPattern == nil then
				dependencyPattern = 1
			end
			lightbar:SetAttribute(`should{pluginSettings.Overrides.Sirens[sirenData.name][1]}`, true)
			lightbar:SetAttribute(
				pluginSettings.Overrides.Sirens[sirenData.name][1],
				if dependency > dependencyPattern - 1 then 1 else 0
			)
		end
	end

	for modifiedName, data: sirenModifier in pairs(sirenData.modifiers) do
		if soundPart:FindFirstChild(data.name) then
			playStopModified(name, modifiedName)
		end
	end
end

-- Default State
for functionName, state in pairs(pluginSettings.DefaultFunctionState) do
	lightbar:SetAttribute(functionName, state)
end

-- Input Handler
event.OnServerEvent:Connect(function(player, eventType: string, ...)
	if player.Character ~= car.DriveSeat.Occupant.Parent then
		return
	end

	if eventType == "Input" then
		local state: EnumItem, _inputType: EnumItem, keycode: EnumItem = ...
		if
			pluginSettings.SecondaryKeybinds[keycode] ~= nil
			and typeof(pluginSettings.SecondaryKeybinds[keycode]) == "EnumItem"
		then
			keycode = pluginSettings.SecondaryKeybinds[keycode]
		end

		if state == Enum.UserInputState.Begin then
			if pluginSettings.Keybinds[keycode] then
				if typeof(lightbar:GetAttribute(pluginSettings.Keybinds[keycode])) ~= "number" then
					return
				end
				local currentState = lightbar:GetAttribute(pluginSettings.Keybinds[keycode])
				if typeof(currentState) ~= "number" then
					return
				end
				lightbar:SetAttribute(pluginSettings.Keybinds[keycode], currentState + 1)
			elseif sirensByKeybind[keycode] then
				if soundPart == nil then
					return
				end
				local soundPart: Instance = soundPart

				local sirenData: siren | modifier = sirensByKeybind[keycode]
				if sirenData._type == "siren" or sirenData._type == "hold" then
					local soundInstance: Instance? = soundPart:FindFirstChild(sirenData.name)
					if soundInstance ~= nil and soundInstance:IsA("Sound") then
						local sound: Sound = soundInstance :: Sound
						if sound.Playing and sirenData._type ~= "hold" then
							stopSiren(sirenData.name)
						else
							playSiren(sirenData.name)
						end
					end
				elseif sirenData._type == "modifier" then
					local modifierData: modifier = sirenData :: modifier

					if modifierData.enabled then
						modifierData.enabled = false
						if pluginSettings.Overrides.Sirens[modifierData.name] ~= nil then
							lightbar:SetAttribute(pluginSettings.Overrides.Sirens[modifierData.name], 0)
						end

						for _, v: siren in pairs(sirensByName) do
							if v.modifiers[modifierData.name] then
								playStopModified(v.name, modifierData.name)
							end
						end
					else
						modifierData.enabled = true
						if pluginSettings.Overrides.Sirens[modifierData.name] ~= nil then
							lightbar:SetAttribute(pluginSettings.Overrides.Sirens[modifierData.name], 1)
						end

						for _, v: siren in pairs(sirensByName) do
							if v.modifiers[modifierData.name] then
								playStopModified(v.name, modifierData.name)
							end
						end
					end
				end
			end
		elseif state == Enum.UserInputState.End then
			if sirensByKeybind[keycode] then
				if soundPart == nil then
					return
				end
				local soundPart: Instance = soundPart

				local sirenData: siren | modifier = sirensByKeybind[keycode]
				if sirenData._type == "hold" then
					local soundInstance: Instance? = soundPart:FindFirstChild(sirenData.name)
					if soundInstance ~= nil and soundInstance:IsA("Sound") then
						local sound: Sound = soundInstance :: Sound
						if sound.Playing then
							stopSiren(sirenData.name)
						end
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
					local dependency = lightbar:GetAttribute(pluginSettings.Overrides.Chassis.ParkBrake[2])
					if typeof(dependency) ~= "number" then
						return
					end
					local dependencyPattern = pluginSettings.Overrides.Chassis.ParkBrake[3]
					if dependencyPattern == nil then
						dependencyPattern = 1
					end
					lightbar:SetAttribute(`should{pluginSettings.Overrides.Chassis.ParkBrake[1]}`, true)
					lightbar:SetAttribute(
						pluginSettings.Overrides.Chassis.ParkBrake[1],
						if dependency > dependencyPattern - 1 then 1 else 0
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
					local dependency = lightbar:GetAttribute(pluginSettings.Overrides.Chassis.Brake[2])
					if typeof(dependency) ~= "number" then
						return
					end
					local dependencyPattern = pluginSettings.Overrides.Chassis.Brake[3]
					if dependencyPattern == nil then
						dependencyPattern = 1
					end
					lightbar:SetAttribute(`should{pluginSettings.Overrides.Chassis.Brake[1]}`, true)
					lightbar:SetAttribute(
						pluginSettings.Overrides.Chassis.Brake[1],
						if dependency > dependencyPattern - 1 then 1 else 0
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
				if value < 0 then
					local dependency = lightbar:GetAttribute(pluginSettings.Overrides.Chassis.Reverse[2])
					if typeof(dependency) ~= "number" then
						return
					end
					local dependencyPattern = pluginSettings.Overrides.Chassis.Reverse[3]
					if dependencyPattern == nil then
						dependencyPattern = 1
					end
					lightbar:SetAttribute(`should{pluginSettings.Overrides.Chassis.Reverse[1]}`, true)
					lightbar:SetAttribute(
						pluginSettings.Overrides.Chassis.Reverse[1],
						if dependency > dependencyPattern - 1 then 1 else 0
					)
				else
					lightbar:SetAttribute(`should{pluginSettings.Overrides.Chassis.Reverse[1]}`, false)
					lightbar:SetAttribute(pluginSettings.Overrides.Chassis.Reverse[1], 0)
				end
			end
		end
	end
end)
