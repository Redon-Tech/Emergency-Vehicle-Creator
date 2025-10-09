-- Redon Tech Emergency Vehicle Creator, MIT License
local log = require(script.Parent.log)
local types = require(script.Parent.types)
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Fusion = require(script.Parent.Parent.Packages.fusion)

-- TEMPLATES
local scriptTemplate = [[
--\[\[
	Emergency Vehicle Creator
    Support not provided for these files.

	Redon Tech 2023-2025
	EVC V3
--\]\]

local Car = script.Parent.Parent.Parent
local Lightbar = script.Parent

local RunService = game:GetService("RunService")
REPLACE_WITH_TWEENSERVICE

-- Colors, feel free to change
local Colors = {
    Color3.fromRGB(110, 153, 202), -- Blue
    Color3.fromRGB(190, 104, 98), -- Red
    Color3.fromRGB(226, 155, 64), -- Yellow
    Color3.fromRGB(255, 255, 255), -- White
    Color3.fromRGB(0, 255, 0), -- Green
    Color3.fromRGB(170, 0, 170), -- Purple
}

-- By default this light function will work with most light types, modify to make it if need be
local function light(LightName, Color)
	local Light = Lightbar[LightName]
	if Color == 0 then
		for i, v in pairs(Light:GetDescendants()) do
			if v:IsA("GuiObject") then
				v.Visible = false
			elseif v:IsA("Light") or v:IsA("SurfaceGui") then
				v.Enabled = false
			elseif v:IsA("ParticleEmitter") then
				v.Transparency = NumberSequence.new(1)
			end
		end
		Light.Transparency = 1
	else
		for i, v in pairs(Light:GetDescendants()) do
			if v:IsA("GuiObject") then
				v.Visible = true
				v.ImageColor3 = Colors[Color]
			elseif v:IsA("Light") then
				v.Enabled = true
				v.Color = Colors[Color]
			elseif v:IsA("SurfaceGui") then
				v.Enabled = true
			elseif v:IsA("ParticleEmitter") then
				v.Transparency = NumberSequence.new(0)
				v.Color = ColorSequence.new(Colors[Color])
			end
		end
		Light.Transparency = 0
		Light.Color = Colors[Color]
	end
end

REPLACE_WITH_ROTATOR_REGISTER

-- Main Loop
--------------
-- To use the function above do
--      light("L1", 0)
-- The above will turn off said light
--      light("L1", 1)
-- The above will turn on said light and change its color to said color defined in the color table
--------------
while RunService.Heartbeat:Wait() do
]]

-- TODO: get around to implementing rotators/faders
scriptTemplate:gsub("REPLACE_WITH_ROTATOR_REGISTER", "")
scriptTemplate:gsub("REPLACE_WITH_TWEENSERVICE", "")

export type customExport = {
	export: (flashers: { types.flasherSection }) -> (),
}

local customExport = {} :: customExport

function customExport.export(flashers)
	local model = Instance.new("Model")
	model.Name = "EVC_Export"

	local lights = {}
	for sectionId, sectionData in flashers do
		local container = Instance.new("Script")
		container.Name = `Script_{sectionId}`
		local code = scriptTemplate

		for rowId = 1, sectionData.rowCount do
			code ..= `\n\n\t-- Row {rowId}`

			for _, columnData in sectionData.columns do
				code ..= `\t\nlight("{columnData.lightName}", {columnData.rows[rowId]})`
			end

			code ..= `\t\ntask.wait({sectionData.waitTime})`
		end

		container.Source = code
		container.Parent = model

		for _, columnData in sectionData.columns do
			if not table.find(lights, columnData.lightName) then
				table.insert(lights, columnData.lightName)
			end
		end
	end

	local offset = Vector3.new(0, 10, 0)
	for _, lightname in lights do
		local part = Instance.new("Part")
		part.Parent = model
		part.Name = lightname
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Material = Enum.Material.Neon
		part.BrickColor = BrickColor.new("Institutional white")
		part.Anchored = true
		part.CanCollide = false
		part.Size = Vector3.new(0.75, 0.3, 0.1)
		offset += Vector3.new(0.85, 0, 0)
		part.Position = offset
	end

	model.Parent = workspace
	ChangeHistoryService:SetWaypoint("EVC Custom Export")
end

return customExport
