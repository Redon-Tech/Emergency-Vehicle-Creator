--#selene: allow(shadowing)
-- Redon Tech Emergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent
local plugin = root:FindFirstAncestorWhichIsA("Plugin")

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local log = require(root.Plugin.log)
local LuaEncode = require(root.Packages.LuaEncode)
local Selection = game:GetService("Selection")
local popup = require(root.Plugin.Components.popup)
local utils = require(root.Plugin.utils)
local assets = require(root.Plugin.assets)
local chassisHandler = require(root.Plugin.chassisHandler)

local function testSaveName(name: string, saves: { string }, currentDepth: number): string
	local actualName = if currentDepth == 0 then name else `{name} ({currentDepth})`
	local index = table.find(saves, actualName)
	if index ~= nil then
		return testSaveName(name, saves, currentDepth + 1)
	end
	return actualName
end

type v2Save = {
	faders: {
		{
			Name: string,
			Tweens: {
				{
					EasingDirection: Enum.EasingDirection,
					DelayTime: number,
					RepeatCount: number,
					EasingStyle: Enum.EasingStyle,
					Time: number,
					TransparencyGoal: number,
					Color: number,
					Reverses: boolean,
				}
			},
		}
	},
	rotators: { { Name: string, Angles: { { Angle: number, Color: number, Velocity: number } } } },
	elsCreator: { { WaitTime: number, Columns: { { Name: string, Rows: { number } } } } },
}

type props = {
	CurrentPattern: Fusion.Value<types.selectedPattern?>,
	CurrentVehicle: Fusion.Value<Model | string?>,
}

--[[
	savePopup
	Creates the save menu for the popup created by hitting save/load
]]
return function(scope: types.Scope, props: props): Instance
	local currentTheme = RedonUI.theme.theme:now()

	local initialSettings: { [string]: types.pattern } = {}
	local getSuccess, getData = pcall(function()
		return plugin:GetSetting("RT_EVC_Saves")
	end)
	if getSuccess == true and getData ~= nil then
		initialSettings = getData
	else
		log.warn("Failed to get setting, using default")
	end

	local getV2Success, getV2Data: { [string]: v2Save }? = pcall(function()
		return plugin:GetSetting("savesV2")
	end)
	if getV2Success == true and getV2Data ~= nil then
		plugin:SetSetting("RT_EVC_OLDV2Saves", getV2Data)
		local saveNames: { string } = {}
		for saveName, _ in initialSettings do
			table.insert(saveNames, saveName)
		end

		for saveName, data in getV2Data do
			saveName = testSaveName(saveName, saveNames, 0)
			local newPattern: types.pattern = {
				flashers = {},
				faders = {},
				rotators = {},
			}

			for _, fader in data.faders do
				local newFader: types.faderSection = {
					lightName = fader.Name,
					data = {},
				}
				for _, tween in fader.Tweens do
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
					local newTween: types.faderData = {
						type = "Advanced",
						time = tween.Time,
						goal = tween.TransparencyGoal,
						color = tween.Color,
						easingStyle = tween.EasingStyle,
						easingDirection = tween.EasingDirection,
					}
					table.insert(newFader.data, newTween)
				end
				if #newFader.data == 0 then
					continue
				end
				table.insert(newPattern.faders, newFader)
			end

			for _, rotator in data.rotators do
				local newRotator: types.rotatorSection = {
					lightName = rotator.Name,
					data = {},
				}
				for _, angle in rotator.Angles do
					if angle.Angle == nil or angle.Color == nil or angle.Velocity == nil then
						continue
					end
					local newAngle: types.rotatorData = {
						type = "Angle",
						color = angle.Color,
						velocity = angle.Velocity,
						angle = angle.Angle,
					}
					table.insert(newRotator.data, newAngle)
				end
				if #newRotator.data == 0 then
					continue
				end
				table.insert(newPattern.rotators, newRotator)
			end

			for _, els in data.elsCreator do
				local newEls: types.flasherSection = {
					waitTime = els.WaitTime,
					columns = {},
					rowCount = 0,
				}
				for _, column in els.Columns do
					local newColumn = {
						lightName = column.Name,
						rows = column.Rows,
					}
					table.insert(newEls.columns, newColumn)
					newEls.rowCount = math.max(newEls.rowCount, #column.Rows)
				end
				table.insert(newPattern.flashers, newEls)
			end

			initialSettings[saveName] = newPattern
		end
		plugin:SetSetting("RT_EVC_Saves", initialSettings)
		plugin:SetSetting("savesV2", nil)
		log.warn("Converted saves to new format")
	end

	local currentConfiguration = nil
	scope:Observer(props.CurrentVehicle):onChange(function()
		local currentVehicle = scope.peek(props.CurrentVehicle)
		if typeof(currentVehicle) == "Instance" then
			currentConfiguration = chassisHandler:getConfiguration(currentVehicle)
		end
	end)

	local saves: Fusion.Value<{ [string]: types.pattern }> = scope:Value(initialSettings)
	local sortedSaves: Fusion.Value<{ string }> = scope:Value({})
	local initialSortedSaves = {}
	for saveName, _ in initialSettings do
		table.insert(initialSortedSaves, saveName)
	end
	table.sort(initialSortedSaves)
	sortedSaves:set(initialSortedSaves)

	scope:Observer(saves):onChange(function()
		local currentSaves = scope.peek(saves)
		local saveNames = {}
		for saveName, _ in currentSaves do
			table.insert(saveNames, saveName)
		end
		table.sort(saveNames)
		sortedSaves:set(saveNames)
		local success, data = pcall(function()
			plugin:SetSetting("RT_EVC_Saves", currentSaves)
			return plugin:GetSetting("RT_EVC_Saves")
		end)

		if success == false or utils.compareTables(data, currentSaves) == false then
			log.warn("Failed to save saves", success, data, currentSaves)
			local secondSuccess, _ = pcall(function()
				local saveScript = Instance.new("Script")
				saveScript.Name = "FAILED TO SAVE PLEASE SAVE THIS EMERGENCY BACKUP"
				saveScript.Source = "--EMERGENCY SAVE, CONTACT SUPPORT FOR HELP TO GET SAVES BACK\nreturn "
					.. LuaEncode(currentSaves, {})
				saveScript.Parent = game
				local currentSelection = Selection:Get()
				Selection:Set({ saveScript })
				task.wait(0.1)
				plugin:PromptSaveSelection(saveScript.Name)
				task.wait(0.1)
				Selection:Set(currentSelection)
				saveScript:Destroy()
			end)

			if secondSuccess == true then
				log.error("FAILED TO SAVE SAVES, EMERGENCY BACKUP CREATED")
			else
				log.info(currentSaves)
				log.error("FAILED TO CREATE EMERGENCY BACKUP, PLEASE COPY AND PASTE THE ABOVE TABLE INSTEAD")
			end
		end
	end)

	local newSaveName = scope:Value("")
	-- Parent Size: 3840, 2160
	local savePopup: Fusion.Value<Instance?> = scope:Value(nil)
	return savePopup:set(scope:base {
		Size = UDim2.fromScale(0.234375, 0.4282407407), -- 900, 925
		BackgroundColor3 = currentTheme.colors.base,
		Border = 1,
		CornerRadius = UDim.new(0, 15),
		ZIndex = 5001,

		[Fusion.Children] = {
			scope:base {
				Size = UDim2.fromScale(1, 0.0540540541), -- x, 50
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.0162162162), -- x, 15
				BackgroundTransparency = 1,

				[Fusion.Children] = {
					scope:New("UIListLayout") {
						Padding = UDim.new(0.0333333333, 0),
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
					},

					scope:textBox {
						Size = UDim2.fromScale(0.3333333333, 1),
						MaxSize = Vector2.new(300, 50),
						BackgroundColor3 = currentTheme.colors.crust,
						CornerRadius = UDim.new(0.2, 0),
						Border = 1,
						PlaceholderText = "New Save Name",
						[Fusion.Out "Text"] = newSaveName,
						TextScaled = true,
						MaxTextSize = 30,
						FontWeight = Enum.FontWeight.Regular,
						TextXAlignment = Enum.TextXAlignment.Left,
						LayoutOrder = 1,
						PaddingBottom = UDim.new(0.2, 0),
						PaddingTop = UDim.new(0.2, 0),
						PaddingLeft = UDim.new(0.0333333333, 0),
						PaddingRight = UDim.new(0.0333333333, 0),
					},

					scope:textButton {
						Size = UDim2.fromScale(0.1944444444, 1),
						MaxSize = Vector2.new(175, 50),
						BackgroundColor3 = currentTheme.colors.crust,
						CornerRadius = UDim.new(0.2, 0),
						Border = 2,
						Text = "Add",
						TextScaled = true,
						MaxTextSize = 25,
						FontWeight = Enum.FontWeight.Bold,
						LayoutOrder = 2,
						Reactive = true,

						[Fusion.OnEvent "Activated"] = function()
							local currentPattern = scope.peek(props.CurrentPattern)
							if currentPattern == nil then
								return
							end

							local currentSaves = scope.peek(saves)
							local saveNames = {}
							for saveName, _ in currentSaves do
								table.insert(saveNames, saveName)
							end
							local name = scope.peek(newSaveName)
							name = name:gsub('[\\"%.\n]', "")
							name = testSaveName(name, saveNames, 0)
							currentSaves[name] = currentPattern.pattern

							-- local currentPopup = scope.peek(savePopup)
							-- if currentPopup then
							-- 	currentPopup.Parent = nil
							-- 	popup:removePopup()
							-- end

							saves:set(currentSaves)
						end,
					},

					scope:textButton {
						Size = UDim2.fromScale(0.1944444444, 1),
						MaxSize = Vector2.new(175, 50),
						BackgroundColor3 = currentTheme.colors.crust,
						CornerRadius = UDim.new(0.2, 0),
						Border = 2,
						Text = "Import",
						TextScaled = true,
						MaxTextSize = 25,
						FontWeight = Enum.FontWeight.Bold,
						LayoutOrder = 3,
						Reactive = true,
					},
				},
			},

			scope:list {
				Size = UDim2.fromScale(1, 0.8108108108), -- x, 750
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.0864864865), -- x, 80
				BackgroundColor3 = currentTheme.colors.base,
				AlternateColor3 = currentTheme.colors.mantle,
				PrimaryColor = "Alternate" :: "Alternate",
				RowSize = UDim2.fromScale(1, 0.0810810811),
				Rows = scope:ForPairs(saves, function(use, scope: typeof(scope), name: string, value: types.pattern)
					local key = table.find(use(sortedSaves), name)
					if key == nil then
						return 1, {} :: Fusion.Child
					end
					local nameValue = scope:Value(name)

					local isDownloadHovered = scope:Value(false)
					local isTrashHovered = scope:Value(false)
					return key,
						scope:base {
							Name = name,
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,

							[Fusion.Children] = {
								scope:textBox {
									Size = UDim2.fromScale(0.2777777778, 0.6666666667),
									AnchorPoint = Vector2.new(0, 0.5),
									Position = UDim2.fromScale(0.0166666667, 0.5),
									BackgroundColor3 = currentTheme.colors.crust,
									CornerRadius = UDim.new(0.2, 0),
									Border = 1,
									TextScaled = true,
									MaxTextSize = 20,
									FontWeight = Enum.FontWeight.Regular,
									MaxSize = Vector2.new(300, 50),
									PaddingBottom = UDim.new(0.2, 0),
									PaddingTop = UDim.new(0.2, 0),
									PaddingLeft = UDim.new(0.04, 0),
									PaddingRight = UDim.new(0.04, 0),
									Text = nameValue,
									[Fusion.Out "Text"] = nameValue :: unknown,
									TextXAlignment = Enum.TextXAlignment.Left,
									[Fusion.OnEvent "FocusLost"] = function()
										local currentSaves = scope.peek(saves)
										local newName = scope.peek(nameValue)
										if newName == name then
											return
										end
										local saveNames = {}
										for saveName, _ in currentSaves do
											table.insert(saveNames, saveName)
										end
										newName = newName:gsub('[\\"%.\n]', "")
										newName = testSaveName(newName, saveNames, 0)
										nameValue:set(newName)
										currentSaves[newName] = currentSaves[name]
										currentSaves[name] = nil
										saves:set(currentSaves)
									end,
								},

								scope:base {
									Size = UDim2.fromScale(0.6722222222, 1), -- 605, y
									AnchorPoint = Vector2.new(1, 0.5),
									Position = UDim2.fromScale(0.9833333333, 0.5),
									BackgroundTransparency = 1,

									[Fusion.Children] = {
										scope:New("UIListLayout") {
											Padding = UDim.new(0.0166666667, 0),
											FillDirection = Enum.FillDirection.Horizontal,
											HorizontalAlignment = Enum.HorizontalAlignment.Right,
											VerticalAlignment = Enum.VerticalAlignment.Center,
											SortOrder = Enum.SortOrder.LayoutOrder,
										},

										scope:textButton {
											Size = UDim2.fromScale(0.2479338843, 0.6666666667),
											BackgroundColor3 = currentTheme.colors.crust,
											CornerRadius = UDim.new(0.2, 0),
											Border = 1,
											TextScaled = true,
											MaxTextSize = 20,
											FontWeight = Enum.FontWeight.Regular,
											Text = "Load",
											TextXAlignment = Enum.TextXAlignment.Center,
											LayoutOrder = 1,
											Reactive = true,

											[Fusion.OnEvent "Activated"] = function()
												local currentPopup = scope.peek(savePopup)
												local currentPattern = scope.peek(props.CurrentPattern)
												if currentPopup == nil or currentPattern == nil then
													return
												end
												-- currentPopup.Parent = nil
												popup:removePopup()
												popup:addPopup(scope, {
													title = "Load Pattern",
													description = `Are you sure you want to load {scope.peek(nameValue)}?\n<b>All currently unsaved data will be lost.</b>`,
													actions = {
														{
															text = "Cancel",
															type = "primary",
															key = 1,
															callback = function(newPopup)
																popup:removePopup(newPopup)
																popup:customPopup(scope, currentPopup)
															end,
															keybind = Enum.KeyCode.Escape,
														},
														{
															text = "Load",
															type = "danger",
															key = 2,
															callback = function(newPopup)
																popup:removePopup(newPopup)
																props.CurrentPattern:set({
																	functionId = currentPattern.functionId,
																	patternId = currentPattern.patternId,
																	pattern = value,
																})
																if currentConfiguration ~= nil then
																	currentConfiguration.functions[currentPattern.functionId].patterns[currentPattern.patternId] =
																		value
																end
															end,
														},
													},
												})
											end,
										},

										scope:textButton {
											Size = UDim2.fromScale(0.2479338843, 0.6666666667),
											BackgroundColor3 = currentTheme.colors.crust,
											CornerRadius = UDim.new(0.2, 0),
											Border = 1,
											TextScaled = true,
											MaxTextSize = 20,
											FontWeight = Enum.FontWeight.Regular,
											Text = "Save",
											TextXAlignment = Enum.TextXAlignment.Center,
											LayoutOrder = 2,
											Reactive = true,

											[Fusion.OnEvent "Activated"] = function()
												local currentPopup = scope.peek(savePopup)
												local currentPattern = scope.peek(props.CurrentPattern)
												local currentSaves = scope.peek(saves)
												if currentPopup == nil or currentPattern == nil then
													return
												end
												-- currentPopup.Parent = nil
												popup:removePopup()
												popup:addPopup(scope, {
													title = "Overwrite Save",
													description = `Are you sure you want to overwrite {scope.peek(
														nameValue
													)}?\n<b>All currently saved data will be lost.</b>`,
													actions = {
														{
															text = "Cancel",
															type = "primary",
															key = 1,
															callback = function(newPopup)
																popup:removePopup(newPopup)
																popup:customPopup(scope, currentPopup)
															end,
															keybind = Enum.KeyCode.Escape,
														},
														{
															text = "Overwrite",
															type = "danger",
															key = 2,
															callback = function(newPopup)
																popup:removePopup(newPopup)
																popup:customPopup(scope, currentPopup)
																currentSaves[name] = currentPattern.pattern
																saves:set(currentSaves)
															end,
														},
													},
												})
											end,
										},

										scope:iconButton {
											Size = UDim2.fromScale(0.0595041322, 0.7666666667),
											BackgroundTransparency = 1,
											Image = scope:Computed(function(use)
												return if use(isDownloadHovered)
													then assets.images.redonUI.downloadFilled
													else assets.images.redonUI.download
											end),
											Reactive = true,
											ScaleType = Enum.ScaleType.Fit,
											LayoutOrder = 3,

											MouseEnter = function()
												isDownloadHovered:set(true)
											end,

											MouseLeave = function()
												isDownloadHovered:set(false)
											end,

											[Fusion.OnEvent "Activated"] = function() end,
										},

										scope:iconButton {
											Size = UDim2.fromScale(0.0661157025, 0.7666666667),
											BackgroundTransparency = 1,
											Image = scope:Computed(function(use)
												return if use(isTrashHovered)
													then assets.images.redonUI.trashFilled
													else assets.images.redonUI.trash
											end),
											Reactive = true,
											ScaleType = Enum.ScaleType.Fit,
											LayoutOrder = 4,

											MouseEnter = function()
												isTrashHovered:set(true)
											end,

											MouseLeave = function()
												isTrashHovered:set(false)
											end,

											[Fusion.OnEvent "Activated"] = function()
												local currentPopup = scope.peek(savePopup)
												local currentSaves = scope.peek(saves)
												if currentPopup == nil then
													return
												end
												-- currentPopup.Parent = nil
												popup:removePopup()
												popup:addPopup(scope, {
													title = "Delete Save",
													description = `Are you sure you want to delete {scope.peek(
														nameValue
													)}?\n<b>All currently saved data will be lost.</b>`,
													actions = {
														{
															text = "Cancel",
															type = "primary",
															key = 1,
															callback = function(newPopup)
																popup:removePopup(newPopup)
																popup:customPopup(scope, currentPopup)
															end,
															keybind = Enum.KeyCode.Escape,
														},
														{
															text = "Delete",
															type = "danger",
															key = 2,
															callback = function(newPopup)
																popup:removePopup(newPopup)
																popup:customPopup(scope, currentPopup)
																currentSaves[name] = nil
																saves:set(currentSaves)
															end,
														},
													},
												})
											end,
										},
									},
								},
							},
						}
				end),
			},

			scope:base {
				Size = UDim2.fromScale(1, 0.0540540541), -- x, 50
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 0.9837837838), -- x, 15
				BackgroundTransparency = 1,

				[Fusion.Children] = {
					scope:textButton {
						Size = UDim2.fromScale(0.3333333333, 1),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						MaxSize = Vector2.new(175, 50),
						BackgroundColor3 = currentTheme.colors.crust,
						CornerRadius = UDim.new(0.2, 0),
						Border = 2,
						Text = "Done",
						TextScaled = true,
						MaxTextSize = 30,
						FontWeight = Enum.FontWeight.Bold,
						Reactive = true,

						[Fusion.OnEvent "Activated"] = function()
							local currentPopup = scope.peek(savePopup)
							if currentPopup then
								-- currentPopup.Parent = nil
								popup:removePopup()
							end
						end,
					},
				},
			},
		},
	}) :: Instance
end
