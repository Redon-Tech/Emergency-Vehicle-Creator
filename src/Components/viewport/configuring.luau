--#selene: allow(shadowing)
local root = script.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local vehicle = require(root.Plugin.vehicle)
local log = require(root.Plugin.log)

return function(
	scope: types.Scope,
	props: {
		attachments: Fusion.UsedAs<{ Attachment }>,
		viewportSize: Fusion.Value<Vector2>,
		currentLocation: Fusion.Value<string?>,

		Mode: Fusion.Value<types.mode>,
		CurrentVehicle: Fusion.Value<Model | string?>,

		outfitting: Fusion.Value<Model?>,
		currentVehicleFolder: Fusion.Value<vehicle.vehicleFolder?>,
		currentEquipment: Fusion.Value<string>,
		currentlyConfiguring: Fusion.Value<string?>,
		currentOptionData: Fusion.Value<{ [string]: boolean | { [string]: boolean } }>,

		cleanupCustomization: () -> (),
		recomputeLightParts: () -> (),
	}
)
	local currentTheme = RedonUI.theme.theme:now()
	local function makeChildren(scope: typeof(scope), name: string, value: string?)
		return {
			scope:New("UIPadding") {
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			},

			scope:textLabel {
				Size = UDim2.new(1, -35, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Text = value or name,
				TextSize = 25,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontWeight = Enum.FontWeight.Regular,
				TextWrapped = true,
				BackgroundTransparency = 1,
			},

			scope:checkBox {
				Size = UDim2.fromOffset(25, 25),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				BackgroundColor3 = currentTheme.colors.crust,
				CornerRadius = UDim.new(0, 5),
				Border = 1,
				BorderColor3 = currentTheme.colors.white,
				SelectedColor3 = currentTheme.colors.blue,
				SelectedCheckColor3 = currentTheme.colors.crust,
				Reactive = true,

				Enabled = scope:Computed(function(use)
					local data = use(props.currentOptionData)[name]
					return if typeof(data) == "table" then data[value or name] else data
				end),

				[Fusion.OnEvent "Activated"] = function()
					local currentVehicleFolder = scope.peek(props.currentVehicleFolder)
					local currentLocation = scope.peek(props.currentLocation)
					local currentEquipment = scope.peek(props.currentEquipment)
					if currentVehicleFolder == nil or currentLocation == nil or currentEquipment == nil then
						log.warn("currentVehicleFolder, currentLocation, or currentEquipment is nil")
						return
					end

					-- Change the value of the current option and meet requirements
					local equipmentData = currentVehicleFolder.data.customization[currentLocation][currentEquipment]
					local data = scope.peek(props.currentOptionData)
					local current = data[name]
					local newValue
					if typeof(current) == "table" then
						if equipmentData.configuration[name].canHaveNone ~= true then
							log.debug("Force setting to true")
							newValue = true
						else
							newValue = not current[value or name]
							log.debug("Setting to", newValue)
						end

						if equipmentData.configuration[name].canSelectMultiple ~= true then
							log.debug("Clearing other options")
							for key, _ in pairs(current) do
								if key ~= value or name then
									current[key] = false
								end
							end
						end
						current[value or name] = newValue
					else
						newValue = not current
						data[name] = newValue
					end
					props.currentOptionData:set(data)

					-- Attempt to apply the new configuration
					local outfitting = scope.peek(props.outfitting)
					if outfitting == nil then
						log.warn("outfitting is nil")
						return
					end
					local currentEquipmentModel = outfitting:FindFirstChild(currentEquipment) :: Model?
					if currentEquipmentModel == nil or currentEquipmentModel:IsA("Model") == false then
						log.warn("currentEquipmentModel is nil or not a model", currentEquipment, outfitting)
						return
					end
					vehicle:changeConfiguration(currentVehicleFolder, currentEquipmentModel, {
						[name] = if typeof(current) == "table" then current else newValue,
					})
					props.recomputeLightParts()
				end,
			},
		}
	end

	return scope:New("ScrollingFrame") {
		Name = "Table",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(300, 390),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 50),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = currentTheme.colors.text,
		TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),

		[Fusion.Children] = Fusion.Child {
			scope:New("UIListLayout") {
				SortOrder = Enum.SortOrder.LayoutOrder,
			},

			scope:Computed(function(use, scope: typeof(scope)): Fusion.Child?
				local currentlyConfiguring = use(props.currentlyConfiguring)
				local currentVehicleFolder = scope.peek(props.currentVehicleFolder)
				local currentLocation = scope.peek(props.currentLocation)

				if currentlyConfiguring ~= nil and currentVehicleFolder ~= nil and currentLocation ~= nil then
					local rows: { [string]: vehicle.option | Instance } = scope.deepCopy(
						currentVehicleFolder.data.customization[currentLocation][currentlyConfiguring].configuration
					)
					local layoutLength = 0
					for _, value in pairs(rows) do
						if typeof(value) == "table" and value.layoutOrder > layoutLength then
							layoutLength = value.layoutOrder
						else
							layoutLength += 1
						end
					end
					if
						currentVehicleFolder.data.customization[currentLocation][currentlyConfiguring].hasLights
						== true
					then
						local lightPrefix = scope:Value("")
						local function newLightPrefix()
							local currentLocation = scope.peek(props.currentLocation)
							local currentEquipment = scope.peek(props.currentEquipment)
							local outfitting = scope.peek(props.outfitting)
							if outfitting == nil or currentLocation == nil or currentEquipment == nil then
								log.warn("outfitting, currentLocation, or currentEquipment is nil")
								return
							end
							local currentEquipmentModel = outfitting:FindFirstChild(currentEquipment) :: Model?
							if currentEquipmentModel == nil or currentEquipmentModel:IsA("Model") == false then
								log.warn("currentEquipmentModel is nil or not a model")
								return
							end
							local newPrefix = scope.peek(lightPrefix)

							currentEquipmentModel:SetAttribute("lightPrefix", newPrefix)
							vehicle:updateEquipmentLights(currentEquipmentModel)
							props.recomputeLightParts()
						end
						rows["Light Prefix"] = scope:base {
							Size = UDim2.fromOffset(300, 50),
							BackgroundTransparency = 1,

							[Fusion.Children] = {
								scope:New("UIPadding") {
									PaddingTop = UDim.new(0, 10),
									PaddingBottom = UDim.new(0, 10),
									PaddingLeft = UDim.new(0, 10),
									PaddingRight = UDim.new(0, 10),
								},

								scope:textBox {
									Size = UDim2.fromScale(1, 1),
									PlaceholderText = "Light name prefix",
									[Fusion.Out "Text"] = lightPrefix :: unknown,
									TextSize = 25,
									TextXAlignment = Enum.TextXAlignment.Left,
									FontWeight = Enum.FontWeight.Medium,
									TextWrapped = true,
									BackgroundColor3 = currentTheme.colors.crust,
									CornerRadius = UDim.new(0, 10),
									Border = 1,
									BorderColor3 = currentTheme.colors.text,

									[Fusion.OnEvent "FocusLost"] = function()
										newLightPrefix()
									end,
								},
							},
						}
					end

					return scope:ForPairs(
						rows,
						function(_, scope: typeof(scope), name: string, data: vehicle.option | Instance)
							local children = {}
							if typeof(data) == "table" and data.type == "select" and data.choices ~= nil then
								table.insert(
									children,
									scope:textLabel {
										Size = UDim2.fromOffset(280, 20),
										Text = name:gsub("_", " "),
										Position = UDim2.fromOffset(10, 0),
										TextXAlignment = Enum.TextXAlignment.Left,
										FontWeight = Enum.FontWeight.Medium,
										TextSize = 20,
									}
								)
								table.insert(
									children,
									scope:base {
										Size = UDim2.fromScale(1, 0),
										Position = UDim2.fromOffset(0, 20),
										AutomaticSize = Enum.AutomaticSize.Y,
										BackgroundTransparency = 1,

										[Fusion.Children] = Fusion.Child {
											scope:New("UIListLayout") {},

											scope:ForPairs(
												data.choices,
												function(_, scope: typeof(scope), key: number, value: string)
													return key,
														scope:base {
															Size = UDim2.fromOffset(300, 50),
															BackgroundColor3 = if key % 2 == 0
																then currentTheme.colors.base
																else currentTheme.colors.mantle,
															LayoutOrder = key,

															[Fusion.Children] = makeChildren(scope, name, value),
														}
												end
											),
										},
									}
								)
							elseif typeof(data) == "table" then
								table.insert(
									children,
									scope:base {
										Size = UDim2.fromOffset(300, 50),
										BackgroundTransparency = 1,

										[Fusion.Children] = makeChildren(scope, name),
									}
								)
							else
								table.insert(
									children,
									scope:textLabel {
										Size = UDim2.fromOffset(280, 20),
										Text = name:gsub("_", " "),
										Position = UDim2.fromOffset(10, 0),
										TextXAlignment = Enum.TextXAlignment.Left,
										FontWeight = Enum.FontWeight.Medium,
										TextSize = 20,
									}
								)
								table.insert(
									children,
									scope:base {
										Size = UDim2.fromScale(1, 0),
										Position = UDim2.fromOffset(0, 20),
										AutomaticSize = Enum.AutomaticSize.Y,
										BackgroundTransparency = 1,

										[Fusion.Children] = data,
									}
								)
							end

							local order = if typeof(data) == "table" then data.layoutOrder else layoutLength + 1
							return order,
								scope:base {
									ClassName = "Frame",
									Size = UDim2.fromOffset(300, 50),
									BackgroundColor3 = scope:Computed(function(_)
										return order % 2 == 0 and currentTheme.colors.base or currentTheme.colors.mantle
									end),
									AutomaticSize = Enum.AutomaticSize.Y,
									ClipsDescendants = true,
									LayoutOrder = order,

									[Fusion.Children] = children,
								}
						end
					)
				else
					return nil
				end
			end),
		},
	}
end
