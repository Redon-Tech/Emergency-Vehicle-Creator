--[[
	 _____               _                     _______                 _
	|  __ \             | |                   |__   __|               | |
	| |__) |   ___    __| |   ___    _ __        | |      ___    ___  | |__
	|  _  /   / _ \  / _  |  / _ \  |  _ \       | |     / _ \  / __| |  _ \
	| | \ \  |  __/ | (_| | | (_) | | | | |      | |    |  __/ | (__  | | | |
	|_|  \_\  \___|  \__,_|  \___/  |_| |_|      |_|     \___|  \___| |_| |_|
	Emergency Vehicle Handler
    Apart of EVC V3
--]]
--[[
	MIT License

	Copyright (c) 2022-2025 Redon Tech

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
--]]

if plugin then
	return
end

local UserInputService = game:GetService("UserInputService")
local CarReference = script.Parent:WaitForChild("Car")
local Values = script.Parent:WaitForChild("Values")
if CarReference:IsA("ObjectValue") == false then
	error("[EVH ERROR]: Car ObjectValue not valid")
end

local Car = CarReference.Value :: Model
local EVHEvent = Car:WaitForChild("EVHEvent") :: RemoteEvent
if EVHEvent:IsA("RemoteEvent") == false then
	error("[EVH ERROR]: EVHEvent RemoteEvent not valid")
end

-- Overrides setup
if Values:IsA("Folder") then
	local PBrake = Values:WaitForChild("PBrake")
	local Brake = Values:WaitForChild("Brake")
	local Gear = Values:WaitForChild("Gear")

	-- Parking Brake Override
	if PBrake:IsA("BoolValue") then
		PBrake:GetPropertyChangedSignal("Value"):Connect(function()
			EVHEvent:FireServer("Values", "PBrake", PBrake.Value)
		end)
		EVHEvent:FireServer("Values", "PBrake", PBrake.Value)
	else
		warn("[EVH WARNING]: PBrake BoolValue not valid, some overrides may not work")
	end

	-- Brake Override
	if Brake:IsA("NumberValue") then
		Brake:GetPropertyChangedSignal("Value"):Connect(function()
			EVHEvent:FireServer("Values", "Brake", Brake.Value)
		end)
		EVHEvent:FireServer("Values", "Brake", Brake.Value)
	else
		warn("[EVH WARNING]: Brake NumberValue not valid, some overrides may not work")
	end

	-- Reverse Override
	if Gear:IsA("NumberValue") then
		Gear:GetPropertyChangedSignal("Value"):Connect(function()
			EVHEvent:FireServer("Values", "Gear", Gear.Value)
		end)
		EVHEvent:FireServer("Values", "Gear", Gear.Value)
	else
		warn("[EVH WARNING]: Gear NumberValue not valid, some overrides may not work")
	end
else
	warn("[EVH WARNING]: Values Folder not valid, some overrides may not work")
end

-- Input Handling

local function input(InputObject: InputObject, gameProcessedEvent: boolean)
	if
		gameProcessedEvent == false
		and (
			InputObject.UserInputType == Enum.UserInputType.Keyboard
			or InputObject.UserInputType == Enum.UserInputType.Gamepad1
		)
	then
		EVHEvent:FireServer("Input", InputObject.UserInputState, InputObject.UserInputType, InputObject.KeyCode)
	end
end

UserInputService.InputBegan:Connect(input)
UserInputService.InputChanged:Connect(input)
UserInputService.InputEnded:Connect(input)

-- AG-Chassis Handling

local Events = Car:FindFirstChild("Events")
if Events then
	local SpecialEvent = Events:FindFirstChild("SpecialEvent") :: RemoteEvent
	if SpecialEvent and SpecialEvent:IsA("RemoteEvent") then
		SpecialEvent.OnClientEvent:Connect(function(EventType: string, ...)
			if EventType == "LIGHT" then
				EVHEvent:FireServer("AGSceneLights", ...)
			end
		end)
	end
end
