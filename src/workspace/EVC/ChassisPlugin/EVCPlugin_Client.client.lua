--[[
Redon Tech 2022
EVC
--]]

--------------------------------------------------------------------------------
-- Init --
--------------------------------------------------------------------------------

local Car = script.Parent.Car.Value
local Event = Car:WaitForChild("EVCRemote")
local UserInputService = game:GetService("UserInputService")

--------------------------------------------------------------------------------
-- Handling --
--------------------------------------------------------------------------------

local function input(input: InputObject, gameProcessedEvent: BoolValue)
    if not gameProcessedEvent then
        Event:FireServer(input)
    end
end

UserInputService.InputBegan:Connect(input)
UserInputService.InputChanged:Connect(input)
UserInputService.InputEnded:Connect(input)