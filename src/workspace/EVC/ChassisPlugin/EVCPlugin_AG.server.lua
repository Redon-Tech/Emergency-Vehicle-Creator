if not game:GetService("RunService"):IsRunning() then return end -- Prevents error spamming in studio
--[[
Redon Tech 2022
EVC
AG-Chassis Addon
--]]

--------------------------------------------------------------------------------
-- Init --
--------------------------------------------------------------------------------

local Settings = require(script.Parent.Settings)
local Lightbar = script.Parent.Parent

local Coros = {
	Lightbar = {},
	Traffic_Advisor = {},
}

local Connections = {
	Lights = {}
}

local Lights = {}

local CurrentStage = 0
local CurrentTraffic_Advisor = 0

--------------------------------------------------------------------------------
-- Handling --
--------------------------------------------------------------------------------

-- Value changes
local stageChange, TAChange
function stageChange(calledBy: boolean?)
	local stage = if script.Parent.ELSRunning.Value then script.Parent.PatternNumber.Value + 1 else 0
	for i,v in pairs(Coros.Lightbar) do
		coroutine.close(v)
		Coros.Lightbar[i] = nil
	end

	if CurrentStage > 0 or Lightbar.ModuleStore.Stages:FindFirstChild("Stage0") then
		for i,v in pairs(Lightbar.ModuleStore.Stages["Stage".. CurrentStage]:GetChildren()) do
			if v:IsA("ModuleScript") then
				local Module = require(v)
				for name,colors in pairs(Module.Lights) do
					local light = Lights[name]
					if light ~= nil and light.running_module.Value ~= nil then
						light.running_module.Value = nil
					end
				end
			end
		end
		if not calledBy then
			TAChange(true)
		end
	end

	if stage > 0 or Lightbar.ModuleStore.Stages:FindFirstChild("Stage0") then
		for i,v in pairs(Lightbar.ModuleStore.Stages["Stage".. stage]:GetChildren()) do
			if v:IsA("ModuleScript") then
				local Module = require(v)
				for name,colors in pairs(Module.Lights) do
					local light = Lights[name]
					if light ~= nil and (
						light.running_module.Value == nil
						or require(light.running_module.Value).Settings.Weight < Module.Settings.Weight
					) then
						light.running_module.Value = v
					end
				end
				local coro = coroutine.create(function()
					v:SetAttribute("count", 1)
					while task.wait(Module.Settings.WaitTime) do
						if v:GetAttribute("max_count") == v:GetAttribute("count") or v:GetAttribute("count") == nil then
							v:SetAttribute("count", 1)
						else
							v:SetAttribute("count", tonumber(v:GetAttribute("count")) + 1)
						end
					end
				end)
				Coros.Lightbar[v] = coro
				coroutine.resume(coro)
			end
		end
	end

	CurrentStage = stage
end

function TAChange(calledBy: boolean?)
	local traffic_advisor = if script.Parent.TARunning.Value then script.Parent.TAPatternNumber.Value + 1 else 0
	for i,v in pairs(Coros.Traffic_Advisor) do
		coroutine.close(v)
		Coros.Traffic_Advisor[i] = nil
	end

	if CurrentTraffic_Advisor > 0 or Lightbar.ModuleStore.Traffic_Advisor:FindFirstChild("TA0") then
		for i,v in pairs(Lightbar.ModuleStore.Traffic_Advisor["TA".. CurrentTraffic_Advisor]:GetChildren()) do
			if v:IsA("ModuleScript") then
				local Module = require(v)
				for name,colors in pairs(Module.Lights) do
					local light = Lights[name]
					if light ~= nil and light.running_module.Value ~= nil then
						light.running_module.Value = nil
					end
				end
			end
		end
		if not calledBy then
			stageChange(true)
		end
	end

	if traffic_advisor > 0 or Lightbar.ModuleStore.Traffic_Advisor:FindFirstChild("TA0") then
		for i,v in pairs(Lightbar.ModuleStore.Traffic_Advisor["TA".. traffic_advisor]:GetChildren()) do
			if v:IsA("ModuleScript") then
				local Module = require(v)
				for name,colors in pairs(Module.Lights) do
					local light = Lights[name]
					if light ~= nil and (
						light.running_module.Value == nil
						or require(light.running_module.Value).Settings.Weight < Module.Settings.Weight
					) then
						light.running_module.Value = v
					end
				end
				local coro = coroutine.create(function()
					v:SetAttribute("count", 1)
					while task.wait(Module.Settings.WaitTime) do
						if v:GetAttribute("max_count") == v:GetAttribute("count") or v:GetAttribute("count") == nil then
							v:SetAttribute("count", 1)
						else
							v:SetAttribute("count", tonumber(v:GetAttribute("count")) + 1)
						end
					end
				end)
				Coros.Traffic_Advisor[v] = coro
				coroutine.resume(coro)
			end
		end
	end

	CurrentTraffic_Advisor = traffic_advisor
end

script.Parent.ELSRunning:GetPropertyChangedSignal("Value"):Connect(stageChange)
script.Parent.PatternNumber:GetPropertyChangedSignal("Value"):Connect(stageChange)
script.Parent.TARunning:GetPropertyChangedSignal("Value"):Connect(TAChange)
script.Parent.TAPatternNumber:GetPropertyChangedSignal("Value"):Connect(TAChange)

-- Module Registration
for i,v in pairs(Lightbar.ModuleStore:GetDescendants()) do
	if v:IsA("ModuleScript") then
		local Module = require(v)
		local LightFunction do
			if Module.Settings.Light ~= nil then
				LightFunction = Module.Settings.Light
			else
				LightFunction = Settings.Light
			end
		end
		local ColorTable do
			if Module.Settings.Colors ~= nil then
				ColorTable = Module.Settings.Colors
			else
				ColorTable = Settings.Colors
			end
		end

		local size = 0
		for name,colors in pairs(Module.Lights) do
			size = #colors
			local light = Lightbar:FindFirstChild(name)
			if light and not Lights[name] then
				Lights[name] = {
					running_module = Instance.new("ObjectValue"),
					last_running_module = Instance.new("ObjectValue"),
					light = light,
				}
				LightFunction(light, 0, ColorTable)
			end
		end
		v:SetAttribute("max_count", size)
	end
end

for name,value in pairs(Lights) do
	value.running_module:GetPropertyChangedSignal("Value"):Connect(function()
		if value.running_module.Value then
			local Module = require(value.running_module.Value)
			local light = value.light

			local LightFunction do
				if Module.Settings.Light ~= nil then
					LightFunction = Module.Settings.Light
				else
					LightFunction = Settings.Light
				end
			end
			local ColorTable do
				if Module.Settings.Colors ~= nil then
					ColorTable = Module.Settings.Colors
				else
					ColorTable = Settings.Colors
				end
			end
			local Colors = Module.Lights[name]

			LightFunction(light, 0, ColorTable)
			if Connections.Lights[name] then
				Connections.Lights[name]:Disconnect()
			end
	
			Connections.Lights[name] = Lights[name].running_module.Value:GetAttributeChangedSignal("count"):Connect(function()
				LightFunction(light, Colors[tonumber(Lights[name].running_module.Value:GetAttribute("count"))], ColorTable)
			end)
			value.last_running_module.Value = value.running_module.Value
		else
			local Module = require(value.last_running_module.Value)
			local light = value.light

			local LightFunction do
				if Module.Settings.Light ~= nil then
					LightFunction = Module.Settings.Light
				else
					LightFunction = Settings.Light
				end
			end
			local ColorTable do
				if Module.Settings.Colors ~= nil then
					ColorTable = Module.Settings.Colors
				else
					ColorTable = Settings.Colors
				end
			end

			LightFunction(light, 0, ColorTable)
			if Connections.Lights[name] then
				Connections.Lights[name]:Disconnect()
			end
		end
	end)
end