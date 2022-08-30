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
	error("EVC: No lightbar avaliable on car ".. Car.Name)
end
local Sounds = Lightbar:WaitForChild(Settings.SirenLocation)
if not Sounds then
	error("EVC: No sound location avaliable on car ".. Car.Name)
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
	if v:IsA("Folder") then
		Lightbar:SetAttribute("max_stages", Lightbar:GetAttribute("max_stages") + 1)
	end
end

for i,v in pairs(Lightbar.ModuleStore.Traffic_Advisor:GetChildren()) do
	if v:IsA("Folder") then
		Lightbar:SetAttribute("max_traffic_advisor", Lightbar:GetAttribute("max_traffic_advisor") + 1)
	end
end

local CurrentStage = 0

--------------------------------------------------------------------------------
-- Handling --
--------------------------------------------------------------------------------

-- Value changes
Lightbar:GetAttributeChangedSignal("stage"):Connect(function()
	local stage = Lightbar:GetAttribute("stage")
	print(stage)
	for i,v in pairs(Coros.Lightbar) do
		print(v)
		coroutine.close(v)
		print(coroutine.status(v))
		table.remove(Coros.Lightbar, i)
	end

	if CurrentStage > 0 or Lightbar.ModuleStore.Stages:FindFirstChild("Stage0") then
		for i,v in pairs(Lightbar.ModuleStore.Stages["Stage".. CurrentStage]:GetChildren()) do
			print(v)
			if v:IsA("ModuleScript") then
				local Module = require(v)
				for name,colors in pairs(Module.Lights) do
					local light = Lights[name]
					if light.running_module.Value ~= nil then
						light.running_module.Value = nil
					end
				end
			end
		end
	end

	if stage > 0 or Lightbar.ModuleStore.Stages:FindFirstChild("Stage0") then
		for i,v in pairs(Lightbar.ModuleStore.Stages["Stage".. stage]:GetChildren()) do
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
				local coro = coroutine.create(function()
					while task.wait(Module.Settings.WaitTime) do
						print(v:GetAttribute("max_count"), v:GetAttribute("count"))
						if v:GetAttribute("max_count") == v:GetAttribute("count") or v:GetAttribute("count") == nil then
							v:SetAttribute("count", 1)
						else
							v:SetAttribute("count", tonumber(v:GetAttribute("count")) + 1)
						end
					end
				end)
				table.insert(Coros.Lightbar, coro)
				coroutine.resume(coro)
			end
		end
	end

	CurrentStage = stage
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
						LightFunction(light, colors[tonumber(Lights[name].running_module.Value:GetAttribute("count"))], Module.Settings.Colors)
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
			elseif table.find(Settings.Sirens, KeyCode) then
				local siren = Settings.Sirens[KeyCode]
				if siren._Type == "Hold" or siren._Type == "Siren" then
					if Sounds:FindFirstChild(siren.Name) then
						local sound = Sounds[siren.Name]
						if sound.Playing then
							sound:Stop()
						else
							if siren.OverrideOtherSounds then
								for i,v in pairs(Sounds:GetDescendants()) do
									if v:IsA("Sound") then
										v:Stop()
									end
								end
							end
							sound:Play()
						end
					else
						warn("EVC: Siren missing ".. siren.Name .." on car ".. Car.Name)
					end
				elseif siren._Type == "Modifier" then
					if siren.Enabled then
						for i,v in pairs(Settings.Sirens) do
							if v.Modifier and v.Modifier.Options.PlayOnModifierChange and v.Modifier._Type == siren.Name then
								if v.Modifier.Options.PlayNonModified then
									if Sounds:FindFirstChild(v.Modifier.Name) and Sounds:FindFirstChild(v.Name) then
										local ModifiedSound = Sounds[v.Modifier.Name]
										local Sound = Sounds[v.Name]
										ModifiedSound.TimePosition = Sound.TimePosition + v.Modifier.Options.Delay
										ModifiedSound:Play()
									end
								else
									if Sounds:FindFirstChild(v.Modifier.Name) and Sounds:FindFirstChild(v.Name) then
										local ModifiedSound = Sounds[v.Modifier.Name]
										local Sound = Sounds[v.Name]
										ModifiedSound.TimePosition = Sound.TimePosition + v.Modifier.Options.Delay
										ModifiedSound:Play()
										Sound:Stop()
									end
								end
							end
						end
					else
						for i,v in pairs(Settings.Sirens) do
							if v.Modifier and v.Modifier.Options.PlayOnModifierChange and v.Modifier._Type == siren.Name then
								if v.Modifier.Options.PlayNonModified then
									if Sounds:FindFirstChild(v.Modifier.Name) then
										local ModifiedSound = Sounds[v.Modifier.Name]
										ModifiedSound:Stop()
									end
								else
									if Sounds:FindFirstChild(v.Modifier.Name) and Sounds:FindFirstChild(v.Name) then
										local ModifiedSound = Sounds[v.Modifier.Name]
										local Sound = Sounds[v.Name]
										Sound.TimePosition = ModifiedSound.TimePosition - v.Modifier.Options.Delay
										Sound:Play()
										ModifiedSound:Stop()
									end
								end
							end
						end
					end
				end
			end
		end
	end
end)