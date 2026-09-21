-- IMPORTANT!
-- Please ensure this script has the Sandboxed property disabled!!

--[[
	 _____               _                     _______                 _
	|  __ \             | |                   |__   __|               | |
	| |__) |   ___    __| |   ___    _ __        | |      ___    ___  | |__
	|  _  /   / _ \  / _  |  / _ \  |  _ \       | |     / _ \  / __| |  _ \
	| | \ \  |  __/ | (_| | | (_) | | | | |      | |    |  __/ | (__  | | | |
	|_|  \_\  \___|  \__,_|  \___/  |_| |_|      |_|     \___|  \___| |_| |_|
	Emergency Vehicle Handler - Loader
    Apart of EVC V3

Why this file?
Roblox introduced a system called script capabilities. This file allows us to ensure that EVH is loaded with proper permissions to ensure it works even if models are inserted from the toolbox.
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

local source = require(74320766382099)

-- Set our "version" to infinite so it never gets overtaken
local versionInstance = Instance.new("NumberValue")
versionInstance.Name = "version"
versionInstance.Value = math.huge
versionInstance.Parent = script

-- Script Capabilties Disable
for _, v in pairs(source:GetDescendants()) do
	if v:IsA("Instance") then
		v.Sandboxed = false
	end
end

-- Trigger the start of handshaking
local initiator = source.EVHClient
local newContainer = Instance.new("Folder")
newContainer.Name = "EmergencyVehicleHandler_Latest"
newContainer.Parent = workspace
versionInstance.Parent = newContainer
initiator.Parent = newContainer
source.modules.Parent = newContainer
initiator.Enabled = true

-- Cleanup
script:Destroy()
