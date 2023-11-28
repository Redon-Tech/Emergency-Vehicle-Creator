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

--------------------------------------------------------------------------------
-- Init --
--------------------------------------------------------------------------------

local error = function(...)
	error(`"[EVC]" {...} \n {debug.traceback()}`)
end
local warn = function(...)
	warn("[EVC]", ...)
end

local car:Model = script.Parent.Parent.Parent.Parent
local pluginSettings = require(script.Parent.Settings)
local body:Model = car:WaitForChild("Body")
local lightbar:Model = body:WaitForChild("ELS")

local TweenService = game:GetService("TweenService")

local lights:{string:lightInstance} = {}
local lightbarFunctions:{name:lightbarFunction} = {}
local coroutines = {}
local rotatorThreads:{string:rotatorLightThread} = {}
local tweenThreads:{string:tweenLightThread} = {}

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
								if lights[lightName].running_module == pattern and lightData[pattern.count] ~= nil and lightbar:FindFirstChild(lightName) then
									pattern.moduleSettings.light(lightbar[lightName], lightData[pattern.count], pattern.moduleSettings.colors)
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
	if lightbar:FindFirstChild(`motor{lightName}`) == nil then
		local motorPart = Instance.new("Part")
		motorPart.Name = `motor{lightName}`
		motorPart.Size = Vector3.new(.1,.1,.1)
		motorPart.CFrame = lightbar[lightName].CFrame
		motorPart.Transparency = 1
		local weld = Instance.new("Weld")
		weld.Part0 = car.DriveSeat
		weld.Part1 = motorPart
		weld.C0 = car.DriveSeat.CFrame:Inverse()*car.DriveSeat.CFrame 
		weld.C1 = motorPart.CFrame:Inverse()*car.DriveSeat.CFrame 
		weld.Parent = car.DriveSeat

		local Center = if lightbar[lightName]:FindFirstChild("inverse") ~= nil then CFrame.new(lightbar[lightName].inverse.Position) else CFrame.new(lightbar[lightName].Position)
		local XYZ = if lightbar[lightName]:FindFirstChild("inverse") ~= nil then CFrame.Angles(lightbar[lightName].inverse.CFrame:toEulerAnglesXYZ()) else CFrame.Angles(lightbar[lightName].CFrame:toEulerAnglesXYZ())
		local motor = Instance.new("Motor6D")
		motor.Name = "Motor"
		motor.Part0 = motorPart
		motor.Part1 = lightbar[lightName]
		motor.C0 = (motorPart.CFrame:Inverse() * Center) * XYZ
		motor.C1 = (lightbar[lightName].CFrame:Inverse() * Center) * XYZ
		motor.Parent = motorPart

		for i,v in pairs(car.DriveSeat:GetChildren()) do
			if v:IsA("Weld") and v.Part1 == lightbar[lightName] then
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

for _,func:Folder in pairs(lightbar.ModuleStore:GetChildren()) do
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

										patternModule.moduleSettings.light(lightbar[lightName], lightData[rotatorTable.currentRunner].color, patternModule.moduleSettings.colors)
										motor.Motor.MaxVelocity = lightData[rotatorTable.currentRunner].velocity
										motor.Motor.DesiredAngle = math.rad(lightData[rotatorTable.currentRunner].angle)
									end
								end
							end

							patternModule.moduleSettings.light(lightbar[lightName], 0, patternModule.moduleSettings.colors)
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
									--lightbar[lightName].Color = patternModule.moduleSettings.colors[lightData.color]
									patternModule.moduleSettings.light(lightbar[lightName], lightData.color, patternModule.moduleSettings.colors)
									local tweenInfo = TweenInfo.new(
										lightData.timeTaken,
										lightData.easingStyle,
										lightData.easingDirection,
										lightData.repeatCount,
										lightData.reverses
									)
									faderTable.tween = TweenService:Create(lightbar[lightName], tweenInfo, {Transparency = lightData.transparency})
									faderTable.tween:Play()
									faderTable.tween.Completed:Wait()
								end
							end

							patternModule.moduleSettings.light(lightbar[lightName], 0, patternModule.moduleSettings.colors)
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
			else
				for _,pattern in pairs(funcTable.patterns) do
					for _,patternModule:patternModule in pairs(pattern.modules) do
						for lightName,lightData in pairs(patternModule.lights) do
							if lightbar:FindFirstChild(lightName) then
								patternModule.moduleSettings.light(lightbar[lightName], 0, patternModule.moduleSettings.colors)
							end
						end
						for lightName,lightData in pairs(patternModule.rotators) do
							if lightbar:FindFirstChild(lightName) then
								patternModule.moduleSettings.light(lightbar[lightName], 0, patternModule.moduleSettings.colors)
							end
						end
						for lightName,lightData in pairs(patternModule.faders) do
							if lightbar:FindFirstChild(lightName) then
								patternModule.moduleSettings.light(lightbar[lightName], 0, patternModule.moduleSettings.colors)
							end
						end
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
									if patternModuleTable.lights[lightName] == nil and typeof(lightData) == "table" and lightbar:FindFirstChild(lightName) then
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
									if patternModuleTable.rotators[lightName] == nil and typeof(lightData) == "table" and lightbar:FindFirstChild(lightName) then
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
									if patternModuleTable.faders[lightName] == nil and typeof(lightData) == "table" and lightbar:FindFirstChild(lightName) then
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

local function patternChange()
	if script.Parent.ELSRunning.Value then
		lightbar:SetAttribute("Stages", script.Parent.PatternNumber.Value+1)
	else
		lightbar:SetAttribute("Stages", 0)
	end
end
script.Parent.PatternNumber:GetPropertyChangedSignal("Value"):Connect(patternChange)
script.Parent.ELSRunning:GetPropertyChangedSignal("Value"):Connect(patternChange)

local function taChange()
	if script.Parent.TARunning.Value then
		lightbar:SetAttribute("Traffic_Advisor", script.Parent.TAPatternNumber.Value+1)
	else
		lightbar:SetAttribute("Traffic_Advisor", 0)
	end
end
script.Parent.TAPatternNumber:GetPropertyChangedSignal("Value"):Connect(taChange)
script.Parent.TARunning:GetPropertyChangedSignal("Value"):Connect(taChange)