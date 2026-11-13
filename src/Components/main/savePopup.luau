-- Redon Tech Emergency Vehicle Creator, MIT License
local Fusion = require("../../../Packages/fusion")
local RedonUI = require("../../../Packages/redon-ui")
local SaveLibrary = require("../../lib/SaveLibrary")
local types = require("../../types")
local popup = require("../popup")
local assets = require("../../assets")

export type Props<T> = {
	Title: string,
	Collection: SaveLibrary.Collection<T>,
	GetValue: (() -> T?)?,
	LoadAdds: boolean?,
	OnLoad: (T) -> (),
}

return function<T>(scope: types.Scope, props: Props<T>): Instance
	local currentTheme = RedonUI.theme.theme:now()
	local collection = props.Collection
	local names = scope:Value({}) :: Fusion.Value<{ string }>
	local message = scope:Value("")
	local newSaveName = scope:Value("")
	local savePopup: Instance
	local busy = false

	local function refresh()
		local savedNames, problem = collection:list()
		if savedNames then
			names:set(savedNames)
		else
			message:set(problem or "Could not list saves")
		end
	end

	local function save(name: string, overwrite: boolean?): boolean
		local value = if props.GetValue then props.GetValue() else nil
		if value == nil then
			message:set("Select a " .. props.Title:lower() .. " before saving")
			return false
		end
		local saved, problem = collection:save(name, value, { overwrite = overwrite })
		message:set(problem or "")
		if saved then
			refresh()
		end
		return saved
	end

	refresh()
	savePopup = scope:base {
		Size = UDim2.fromScale(0.234375, 0.4282407407),
		BackgroundColor3 = currentTheme.colors.base,
		Border = 1,
		CornerRadius = UDim.new(0, 15),
		ZIndex = 5001,
		[Fusion.OnEvent "AncestryChanged"] = function(_, parent)
			if parent then
				refresh()
			end
		end :: unknown,
		[Fusion.Children] = {
			scope:base {
				Size = UDim2.fromScale(1, 0.0540540541),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.0162162162),
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
						Visible = props.GetValue ~= nil,
						Text = newSaveName,
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
						Visible = props.GetValue ~= nil,
						TextScaled = true,
						MaxTextSize = 25,
						FontWeight = Enum.FontWeight.Bold,
						LayoutOrder = 2,
						Reactive = true,
						[Fusion.OnEvent "Activated"] = function()
							if not busy and save(scope.peek(newSaveName)) then
								newSaveName:set("")
							end
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
						[Fusion.OnEvent "Activated"] = function()
							if busy then
								return
							end
							busy = true
							local report, problem = collection:importFile()
							busy = false
							if not report then
								message:set(problem or "Could not import file")
								return
							end
							if report.cancelled then
								return
							end
							local failures = {}
							for _, failure in report.failures do
								table.insert(failures, failure.name .. ": " .. failure.message)
							end
							message:set(table.concat(failures, "\n"))
							refresh()
						end,
					},
				},
			},
			scope:list {
				Size = UDim2.fromScale(1, 0.72),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.0864864865),
				BackgroundColor3 = currentTheme.colors.base,
				AlternateColor3 = currentTheme.colors.mantle,
				PrimaryColor = "Alternate" :: "Alternate",
				RowSize = UDim2.fromScale(1, 0.0810810811),
				Rows = scope:ForPairs(names, function(_, rowScope: types.Scope, index: number, name: string)
					local nameValue = rowScope:Value(name)
					local isDownloadHovered = rowScope:Value(false)
					local isTrashHovered = rowScope:Value(false)
					return index,
						rowScope:base {
							Name = name,
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
							[Fusion.Children] = {
								rowScope:textBox {
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
										local newName = rowScope.peek(nameValue)
										if busy or newName == name then
											return
										end
										local renamed, problem = collection:rename(name, newName)
										message:set(problem or "")
										if not renamed then
											nameValue:set(name)
										end
										refresh()
									end,
								},
								rowScope:base {
									Size = UDim2.fromScale(0.6722222222, 1),
									AnchorPoint = Vector2.new(1, 0.5),
									Position = UDim2.fromScale(0.9833333333, 0.5),
									BackgroundTransparency = 1,
									[Fusion.Children] = {
										rowScope:New("UIListLayout") {
											Padding = UDim.new(0.0166666667, 0),
											FillDirection = Enum.FillDirection.Horizontal,
											HorizontalAlignment = Enum.HorizontalAlignment.Right,
											VerticalAlignment = Enum.VerticalAlignment.Center,
											SortOrder = Enum.SortOrder.LayoutOrder,
										},
										rowScope:textButton {
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
												if busy then
													return
												end
												popup:removePopup()
												popup:addPopup(scope, {
													title = "Load " .. props.Title,
													description = if props.LoadAdds
														then "Add this save to the list?"
														else "Replace the current "
															.. props.Title:lower()
															.. " with this save?",
													actions = {
														{
															text = "Cancel",
															type = "primary",
															key = 1,
															keybind = Enum.KeyCode.Escape,
															callback = function()
																popup:removePopup()
																popup:customPopup(scope, savePopup)
															end,
														},
														{
															text = "Load",
															type = "danger",
															key = 2,
															callback = function()
																popup:removePopup()
																popup:customPopup(scope, savePopup)
																local value, problem = collection:load(name)
																if value == nil then
																	message:set(problem or "Could not load save")
																	return
																end
																local loaded, loadError = pcall(function()
																	props.OnLoad(value)
																	return true
																end)
																message:set(if loaded then "" else tostring(loadError))
																if loaded then
																	popup:removePopup()
																end
															end,
														},
													},
												})
											end,
										},
										rowScope:textButton {
											Size = UDim2.fromScale(0.2479338843, 0.6666666667),
											BackgroundColor3 = currentTheme.colors.crust,
											CornerRadius = UDim.new(0.2, 0),
											Border = 1,
											TextScaled = true,
											MaxTextSize = 20,
											FontWeight = Enum.FontWeight.Regular,
											Text = "Save",
											Visible = props.GetValue ~= nil,
											TextXAlignment = Enum.TextXAlignment.Center,
											LayoutOrder = 2,
											Reactive = true,
											[Fusion.OnEvent "Activated"] = function()
												if busy then
													return
												end
												popup:removePopup()
												popup:addPopup(scope, {
													title = "Overwrite Save",
													description = "Replace this save with the current "
														.. props.Title:lower()
														.. "?",
													actions = {
														{
															text = "Cancel",
															type = "primary",
															key = 1,
															keybind = Enum.KeyCode.Escape,
															callback = function()
																popup:removePopup()
																popup:customPopup(scope, savePopup)
															end,
														},
														{
															text = "Overwrite",
															type = "danger",
															key = 2,
															callback = function()
																popup:removePopup()
																popup:customPopup(scope, savePopup)
																save(name, true)
															end,
														},
													},
												})
											end,
										},
										rowScope:iconButton {
											Size = UDim2.fromScale(0.0595041322, 0.7666666667),
											BackgroundTransparency = 1,
											Image = rowScope:Computed(function(use)
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
											[Fusion.OnEvent "Activated"] = function()
												if busy then
													return
												end
												busy = true
												local _, problem = collection:exportFile(name)
												busy = false
												message:set(problem or "")
											end,
										},
										rowScope:iconButton {
											Size = UDim2.fromScale(0.0661157025, 0.7666666667),
											BackgroundTransparency = 1,
											Image = rowScope:Computed(function(use)
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
												if busy then
													return
												end
												popup:removePopup()
												popup:addPopup(scope, {
													title = "Delete Save",
													description = "Permanently delete this save?",
													actions = {
														{
															text = "Cancel",
															type = "primary",
															key = 1,
															keybind = Enum.KeyCode.Escape,
															callback = function()
																popup:removePopup()
																popup:customPopup(scope, savePopup)
															end,
														},
														{
															text = "Delete",
															type = "danger",
															key = 2,
															callback = function()
																popup:removePopup()
																popup:customPopup(scope, savePopup)
																local _, problem = collection:delete(name)
																message:set(problem or "")
																refresh()
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
			scope:textLabel {
				Size = UDim2.fromScale(0.96, 0.10),
				Position = UDim2.fromScale(0.02, 0.815),
				BackgroundTransparency = 1,
				Text = message,
				TextColor3 = currentTheme.colors.red,
				TextWrapped = true,
				RichText = false,
				TextScaled = true,
				MaxTextSize = 18,
				TextXAlignment = Enum.TextXAlignment.Left,
			},
			scope:textButton {
				Size = UDim2.fromScale(0.3333333333, 0.0540540541),
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 0.9837837838),
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
					if not busy then
						popup:removePopup()
					end
				end,
			},
		},
	} :: Instance
	return savePopup
end
