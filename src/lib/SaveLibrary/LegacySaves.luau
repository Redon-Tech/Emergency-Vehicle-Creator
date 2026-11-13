-- Redon Tech Emergency Vehicle Creator, MIT License
local utils = require("../utils")

local Types = require("./Types")
local Schemas = require("./Schemas")
local types = require("../../types")
local log = require("../../log")
local typed = require("../../../Packages/typed")
local LegacySaves = {}

local function enumValue(enumType: Enum, value: any): any
	if typeof(value) == "EnumItem" then
		return value
	end
	assert(type(value) == "string", "Expected a saved enum name")
	local name = value:match("([%w_]+)$")
	return (enumType :: any)[name]
end

local function patternFromV2(value: any): any
	assert(
		type(value) == "table"
			and type(value.elsCreator) == "table"
			and type(value.faders) == "table"
			and type(value.rotators) == "table",
		"Invalid V2 save"
	)
	local pattern = { flashers = {}, faders = {}, rotators = {} }
	for _, section in value.elsCreator do
		local flasher = { waitTime = section.WaitTime, rowCount = 0, columns = {} }
		for _, column in section.Columns do
			flasher.rowCount = math.max(flasher.rowCount, #column.Rows)
			table.insert(flasher.columns, { lightName = column.Name, rows = table.clone(column.Rows) })
		end
		for _, column in flasher.columns do
			while #column.rows < flasher.rowCount do
				table.insert(column.rows, 0)
			end
		end
		table.insert(pattern.flashers, flasher)
	end
	for _, section in value.faders do
		if section.Name == nil or section.Tweens == nil then
			continue
		end
		local fader = { lightName = section.Name, data = {} }
		for _, tween in section.Tweens do
			if
				tween.EasingDirection == nil
				or tween.DelayTime == nil
				or tween.RepeatCount == nil
				or tween.EasingStyle == nil
				or tween.Time == nil
				or tween.TransparencyGoal == nil
				or tween.Color == nil
				or tween.Reverses == nil
			then
				continue
			end
			if tween.DelayTime == 0 or tween.RepeatCount == 0 or tween.Reverses == false then
				log.warn(
					"V2 fader tween has zero delay, repeat count, or reverses property, V3 faders do not support these properties"
				)
			end
			table.insert(fader.data, {
				type = "Advanced",
				time = tween.Time,
				goal = tween.TransparencyGoal,
				color = tween.Color,
				easingStyle = enumValue(Enum.EasingStyle, tween.EasingStyle),
				easingDirection = enumValue(Enum.EasingDirection, tween.EasingDirection),
			})
		end
		if #fader.data > 0 then
			table.insert(pattern.faders, fader)
		end
	end
	for _, section in value.rotators do
		if section.Name == nil or section.Angles == nil then
			continue
		end
		local rotator = { lightName = section.Name, data = {} }
		for _, angle in section.Angles do
			if angle.Angle == nil or angle.Color == nil or angle.Velocity == nil then
				continue
			end
			table.insert(
				rotator.data,
				{ type = "Angle", angle = angle.Angle, color = angle.Color, velocity = angle.Velocity }
			)
		end
		if #rotator.data > 0 then
			table.insert(pattern.rotators, rotator)
		end
	end
	return pattern
end

local function patternFromV3(value: any): any
	assert(
		type(value) == "table"
			and type(value.flashers) == "table"
			and type(value.faders) == "table"
			and type(value.rotators) == "table",
		"Invalid V3 pattern"
	)
	local pattern = { flashers = {}, faders = {}, rotators = {} }
	for _, section in value.flashers do
		local flasher = {
			waitTime = section.waitTime or 0.1,
			rowCount = section.rowCount,
			columns = {},
		}
		for _, column in section.columns do
			table.insert(flasher.columns, { lightName = column.lightName, rows = table.clone(column.rows) })
		end
		table.insert(pattern.flashers, flasher)
	end
	for _, section in value.faders do
		local fader = { lightName = section.lightName, data = {} }
		for _, step in section.data do
			local converted: any = { type = step.type, time = step.time }
			if step.type ~= "Wait" then
				converted.goal = step.goal
				converted.color = step.color
			end
			if step.type == "Advanced" then
				converted.easingStyle = enumValue(Enum.EasingStyle, step.easingStyle)
				converted.easingDirection = enumValue(Enum.EasingDirection, step.easingDirection)
			end
			table.insert(fader.data, converted)
		end
		table.insert(pattern.faders, fader)
	end
	for _, section in value.rotators do
		local rotator = { lightName = section.lightName, data = {} }
		for _, step in section.data do
			local converted: any = { type = step.type }
			if step.type == "Wait" then
				converted.time = step.time
			else
				converted.color = step.color
				converted.velocity = step.velocity
				if step.type == "Angle" then
					converted.angle = step.angle
				end
			end
			table.insert(rotator.data, converted)
		end
		table.insert(pattern.rotators, rotator)
	end
	return pattern
end

function LegacySaves.convert(value: unknown): (types.pattern?, string?)
	local success, result = pcall(function()
		if type(value) == "table" and (value :: { [string]: unknown }).elsCreator ~= nil then
			return patternFromV2(value)
		end
		return patternFromV3(value)
	end)
	if not success then
		return nil, tostring(result)
	end
	local parsed = Schemas.pattern.parse(result)
	if not parsed.ok then
		return nil, typed.formatIssues(parsed.issues)
	end
	return parsed.value, nil
end

--- Migrates each legacy entry independently. Completed entries are not imported again.
function LegacySaves.migrate(plugin: Plugin, patterns: Types.Collection<types.pattern>): Types.ImportReport
	local report: Types.ImportReport = { imported = {}, failures = {}, cancelled = false }
	for _, sourceKey in { "savesV2", "RT_EVC_OLDV2Saves", "RT_EVC_Saves" } do
		local success, problem = pcall(function(): boolean
			local saves = plugin:GetSetting(sourceKey)
			if saves == nil then
				return true
			end
			assert(type(saves) == "table", "Legacy saves must be a table")
			local markerKey = "RT_EVC_Saves_Migrated_" .. sourceKey
			local completed = plugin:GetSetting(markerKey) or {}
			if completed == true then
				return true
			end
			assert(type(completed) == "table", "Invalid migration record")
			for name, value in saves do
				if type(name) ~= "string" then
					table.insert(
						report.failures,
						{ name = tostring(name), message = "Legacy save name must be a string" }
					)
					continue
				end
				if completed[name] then
					continue
				end
				local imported, importError = pcall(function()
					local pattern, conversionError = LegacySaves.convert(value)
					assert(pattern, conversionError)
					local names, listError = patterns:list()
					assert(names, listError)
					local destination = name
					local checkedNames = {}
					local exists = false
					while table.find(names, destination) do
						local existing = patterns:load(destination)
						if existing and utils.compareTables(existing, pattern) then
							exists = true
							break
						end
						table.insert(checkedNames, destination)
						destination = utils.getUniqueString(name, checkedNames)
					end
					if not exists then
						local saved, saveError = patterns:save(destination, pattern)
						assert(saved, saveError)
						table.insert(report.imported, destination)
					end
					completed[name] = destination
					plugin:SetSetting(markerKey, completed)
				end)
				if not imported then
					table.insert(report.failures, { name = name, message = tostring(importError) })
				end
			end
			return true
		end)
		if not success then
			table.insert(report.failures, { name = sourceKey, message = tostring(problem) })
		end
	end
	return report
end

return LegacySaves
