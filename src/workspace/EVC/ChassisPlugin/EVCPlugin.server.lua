local Lighting = game:GetService("Lighting")
--[[
Redon Tech 2022
EVC
--]]

--------------------------------------------------------------------------------
-- Init --
--------------------------------------------------------------------------------

local Car = script.Parent.Parent
local Event = script.Parent
local Settings = require(script.Parent.Settings)
local Body = Car:WaitForChild("Body")
local Lightbar = Body:WaitForChild(Settings.LightbarLocation)
if not Lightbar then
	error("EVC: No lightbar avaliable")
end

local Coros = {
	Lightbar = {},
	Traffic_Advisor = {},
}

local Connections = {
	Lights = {}
}

local Lights = {}

Lightbar:SetAttribute("stage", 0)
Lightbar:SetAttribute("traffic_advisor", 0)
Lightbar:SetAttribute("siren", "off")
Lightbar:SetAttribute("max_stages", 0)
Lightbar:SetAttribute("max_traffic_advisor", 0)

for i,v in pairs(Lightbar.ModuleStore.Stages:GetChildren()) do
	if v:FindFirstChildWhichIsA("Folder") then
		Lightbar:SetAttribute("max_stages", Lightbar:GetAttribute("max_stages") + 1)
	end
end

for i,v in pairs(Lightbar.ModuleStore.Traffic_Advisor:GetChildren()) do
	if v:FindFirstChildWhichIsA("Folder") then
		Lightbar:SetAttribute("max_traffic_advisor", Lightbar:GetAttribute("max_traffic_advisor") + 1)
	end
end

--------------------------------------------------------------------------------
-- Handling --
--------------------------------------------------------------------------------

-- Value changes
Lightbar:GetAttributeChangedSignal("stage"):Connect(function()
	print(Lightbar:GetAttribute("stage"))
	for i,v in pairs(Coros.Lightbar) do
		print(v)
		coroutine.close(v)
	end

	for i,v in pairs(Lightbar.ModuleStore.Stages["Stage".. Lightbar:GetAttribute("stage")]:GetChildren()) do
		print(v)
		if v:IsA("ModuleScript") then
			local Module = require(v)
			for name,colors in pairs(Module.Lights) do
				local light = Lights[name]
				if (
					light.running_module.Value == nil
					or require(light.running_module.Value).Settings.Weight < Module.Settings.Weight
				) then
					light.running_module.Value = v
				end
			end
			table.insert(Coros.Lightbar, coroutine.create(function()
				while task.wait(Module.Settings.WaitTime) do
					if v:GetAttribute("max_count") == v:GetAttribute("count") then
						v:SetAttribute("count", 1)
					else
						v:SetAttribute("count", v:GetAttribute("count") + 1)
					end
				end
			end))
		end
	end
end)

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

		local size = 0
		for name,colors in pairs(Module.Lights) do
			size = #colors
			local light = Lightbar[name]
			if not Lights[name] then
				Lights[name] = {
					running_module = Instance.new("ObjectValue"),
				}
			end
			LightFunction(light, 0, Module.Settings.Colors)
			Lights[name].running_module:GetPropertyChangedSignal("Value"):Connect(function()
				if Connections.Lights[name] then
					Connections.Lights[name]:Disconnect()
				end

				if Lights[name].running_module.Value ~= nil then
					Connections.Lights[name] = Lights[name].running_module.Value:GetAttributeChangedSignal("count"):Connect(function()
						LightFunction(light, colors[light:GetAttribute("count")], Module.Settings.Colors)
					end)
				else
					LightFunction(light, 0, Module.Settings.Colors)
				end
			end)
		end
		v:SetAttribute("max_count", size)
	end
end

-- User Input
Event.OnServerEvent:Connect(function(player: Player, State: Enum, Type: Enum, KeyCode: Enum)
	if player.Character == Car.DriveSeat.Occupant.Parent then
		if State == Enum.UserInputState.Begin then
			if KeyCode == Settings.Keybinds.Lights then
				local stage = Lightbar:GetAttribute("stage")
				if stage == Lightbar:GetAttribute("max_stages") then
					Lightbar:SetAttribute("stage", 0)
				else
					Lightbar:SetAttribute("stage", stage + 1)
				end
			elseif KeyCode == Settings.Keybinds.TrafficAdvisor then
				local traffic_advisor = Lightbar:GetAttribute("traffic_advisor")
				if traffic_advisor == Lightbar:GetAttribute("max_traffic_advisor") then
					Lightbar:SetAttribute("traffic_advisor", 0)
				else
					Lightbar:SetAttribute("traffic_advisor", traffic_advisor + 1)
				end
			end
		end
	end
end)