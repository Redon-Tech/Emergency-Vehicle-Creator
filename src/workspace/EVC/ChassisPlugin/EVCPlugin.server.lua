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
local Lightbar = Body:WaitForChild(Settings.Lightbar)
if not Lightbar then
    error("EVC: No lightbar avaliable")
end

Lightbar:SetAttribute("stage", 0)
Lightbar:SetAttribute("traffic_advisor", 0)
Lightbar:SetAttribute("siren", "off")

for i,v in pairs(Lightbar.ModuleStore.Stages:GetChildren()) do
    if v:FindFirstChildWhichIsA("ModuleScript") then
        Lightbar:SetAttribute("max_stages", Lightbar:GetAttribute("max_stages") + 1)
    end
end

for i,v in pairs(Lightbar.ModuleStore.Traffic_Advisor:GetChildren()) do
    if v:FindFirstChildWhichIsA("ModuleScript") then
        Lightbar:SetAttribute("max_traffic_advisor", Lightbar:GetAttribute("max_traffic_advisor") + 1)
    end
end

--------------------------------------------------------------------------------
-- Handling --
--------------------------------------------------------------------------------

-- Value changes
Lightbar:GetAttributeChangedSignal("stage"):Connect(function(value)
    for i,v in pairs(Lightbar.ModuleStore.Stages["Stage".. Lightbar:GetAttribute("stage")]:GetChildren()) do
        if v:IsA("ModuleScript") then
        end
    end
end)

-- User Input
Event.OnServerEvent:Connect(function(player: Player, input: InputObject)
    if player == Car.DriveSeat.Occupant then
        if input.UserInputState == Enum.UserInputState.Begin then
            if input.KeyCode == Settings.Keybinds.Lights then
                local stage = Lightbar:GetAttribute("stage")
                if stage == Lightbar:GetAttribute("max_stages") then
                    Lightbar:SetAttribute("stage", 0)
                else
                    Lightbar:SetAttribute("stage", stage + 1)
                end
            end
        end
    end
end)