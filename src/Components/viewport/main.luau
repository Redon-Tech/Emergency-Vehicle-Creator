--#selene: allow(shadowing)
local root = script.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local assets = require(root.Plugin.assets)
local types = require(root.Plugin.types)
local vehicle = require(root.Plugin.vehicle)
local log = require(root.Plugin.log)
local configuring = require(script.Parent.configuring)

local function construct(
	scope: types.Scope,
	currentVehicle: vehicle.vehicleFolder,
	outfitting: Model,
	props: { [string]: any }
)
	local currentTheme = RedonUI.theme.theme:now()
	return scope:ForPairs(
		currentVehicle.data.customization,
		function(_, scope: typeof(scope), key: string, value: { [string]: vehicle.equipmentData })
			return key,
				scope:base {
					Name = key,
					ClassName = "Frame",
					Size = UDim2.fromScale(1, 0),
					BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.Y,
					Visible = scope:Computed(function(use)
						return use(props.currentLocation) == key and use(props.currentlyConfiguring) == nil
					end),

					[Fusion.Children] = Fusion.Child {
						scope:New("UIListLayout") {
							SortOrder = Enum.SortOrder.LayoutOrder,
						},

						scope:ForPairs(
							value,
							function(_, scope: typeof(scope), name: string, data: vehicle.equipmentData)
								local isHovered = scope:Value(false)
								return data.layoutOrder,
									scope:base {
										ClassName = "Frame",
										Size = UDim2.fromOffset(300, 50),
										BackgroundColor3 = scope:Computed(function(_)
											return data.layoutOrder % 2 == 0 and currentTheme.colors.base
												or currentTheme.colors.mantle
										end),
										AutomaticSize = Enum.AutomaticSize.Y,
										ClipsDescendants = true,
										LayoutOrder = data.layoutOrder,

										[Fusion.Children] = {
											scope:base {
												ClassName = "ImageLabel",
												Image = data.icon,
												Size = UDim2.fromOffset(40, 40),
												AnchorPoint = Vector2.new(0, 0.5),
												Position = UDim2.new(0, 5, 0.5, 0),
												ScaleType = Enum.ScaleType.Crop,
												BackgroundTransparency = 1,
											},

											scope:textLabel {
												Size = UDim2.fromOffset(200, 50),
												Position = UDim2.fromOffset(50, 0),
												Text = name,
												TextSize = 25,
												FontWeight = scope:Computed(function(use)
													return if use(props.currentEquipment) == name
														then Enum.FontWeight.Bold
														else Enum.FontWeight.Regular
												end),
												TextWrapped = true,
												TextXAlignment = Enum.TextXAlignment.Left,
												AutomaticSize = Enum.AutomaticSize.Y,

												[Fusion.Children] = {
													scope:New("UIPadding") {
														PaddingTop = UDim.new(0, 10),
														PaddingBottom = UDim.new(0, 10),
													},
												},
											},

											scope:iconButton {
												ClassName = "ImageLabel",
												Size = UDim2.fromOffset(25, 25),
												Position = UDim2.new(1, -10, 0.5, 0),
												AnchorPoint = Vector2.new(1, 0.5),
												BackgroundTransparency = 1,
												Image = scope:Computed(function(use)
													return if use(isHovered)
														then assets.images.redonUI.createFilled
														else assets.images.redonUI.create
												end),
												ScaleType = Enum.ScaleType.Fit,
												Reactive = true,

												MouseEnter = function()
													isHovered:set(true)
												end,

												MouseLeave = function()
													isHovered:set(false)
												end,

												[Fusion.OnEvent "Activated"] = function()
													local currentLocation = scope.peek(props.currentLocation)
													if currentLocation == nil then
														return
													end
													if scope.peek(props.currentEquipment) ~= name then
														if
															vehicle:changeEquipment(
																currentVehicle,
																outfitting,
																currentLocation,
																name
															) == false
														then
															log.warn("failed to change equipment")
															return
														end
														props.currentEquipment:set(name)
													end
													props.currentlyConfiguring:set(name)
												end,
											},
										},
									}
							end
						),
					},
				}
		end
	)
end

return function(
	baseScope: types.Scope,
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
		ReturnTo: Fusion.Value<types.returnTo>,
	}
)
	local currentTheme = RedonUI.theme.theme:now()
	local scope = baseScope:innerScope({ configuring = configuring })

	return scope:base {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = scope:Computed(function(use)
			return typeof(use(props.CurrentVehicle)) == "Instance"
		end),

		[Fusion.Children] = {
			scope:base {
				ClassName = "ScrollingFrame",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.0092592593),
				Size = UDim2.fromScale(1, 0.0462962963),
				BackgroundTransparency = 1,
				CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.X,
				ScrollBarThickness = 2,
				HorizontalScrollBarInset = Enum.ScrollBarInset.None,
				ClipsDescendants = false,

				[Fusion.Children] = {
					scope:New("UIListLayout") {
						Padding = UDim.new(0.0052083333, 0),
						SortOrder = Enum.SortOrder.LayoutOrder,
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					},

					scope:textButton {
						Name = "Cancel",
						Size = UDim2.new(0.078125, 0, 1, 0),
						BackgroundColor3 = currentTheme.colors.crust,
						Border = 2,
						BorderColor3 = currentTheme.colors.text,
						CornerRadius = UDim.new(0.2, 0),
						Text = "Go Back",
						TextScaled = true,
						FontWeight = Enum.FontWeight.Bold,
						Reactive = true,

						[Fusion.OnEvent "Activated"] = function()
							if scope.peek(props.currentVehicleFolder) == nil then
								log.warn("Please wait until the vehicle is fully loaded before using any inputs")
								return
							end
							props.cleanupCustomization()
							props.Mode:set("menu")
							props.CurrentVehicle:set(nil)
						end :: unknown,

						MaxTextSize = 35,
					},

					scope:textButton {
						Name = "Continue",
						Size = UDim2.new(0.078125, 0, 1, 0),
						BackgroundColor3 = currentTheme.colors.crust,
						Border = 2,
						BorderColor3 = currentTheme.colors.text,
						CornerRadius = UDim.new(0.2, 0),
						Text = "Continue",
						TextScaled = true,
						FontWeight = Enum.FontWeight.Bold,
						Reactive = true,

						[Fusion.OnEvent "Activated"] = function()
							if scope.peek(props.currentVehicleFolder) == nil then
								log.warn("Please wait until the vehicle is fully loaded before using any inputs")
								return
							end
							props.cleanupCustomization()
							props.ReturnTo:set("customizer")
							props.Mode:set("main")
						end :: unknown,

						MaxTextSize = 35,
					},
				},
			},

			scope:base {
				Name = "Modify",
				Size = UDim2.fromOffset(300, 500),
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0),
				BackgroundColor3 = currentTheme.colors.base,
				CornerRadius = UDim.new(0, 15),

				[Fusion.Children] = Fusion.Child {
					scope:New("UIScale") {
						Scale = scope:Computed(function(use)
							return use(props.viewportSize).X / 1920
						end),
					},

					scope:textLabel {
						Size = UDim2.fromOffset(280, 30),
						AnchorPoint = Vector2.new(0.5, 0),
						Position = UDim2.new(0.5, 0, 0, 10),
						Text = scope:Computed(function(use)
							local currentLocation = use(props.currentLocation)
							return if currentLocation ~= nil then currentLocation:gsub("_", " ") else ""
						end),
						TextScaled = true,
						FontWeight = Enum.FontWeight.Bold,

						MaxTextSize = 25,
					},

					scope:base {
						Size = UDim2.fromOffset(250, 40),
						AnchorPoint = Vector2.new(0.5, 1),
						Position = UDim2.new(0.5, 0, 1, -10),
						BackgroundTransparency = 1,

						[Fusion.Children] = Fusion.Child {
							scope:textButton {
								Size = UDim2.fromOffset(115, 40),
								BackgroundColor3 = currentTheme.colors.crust,
								Border = 2,
								Shadow = true,
								ShadowColor3 = currentTheme.colors.crust,
								CornerRadius = UDim.new(0, 10),
								Text = "Return",
								TextScaled = true,
								FontWeight = Enum.FontWeight.Medium,
								Reactive = true,
								Visible = scope:Computed(function(use)
									return use(props.currentlyConfiguring) ~= nil
								end),

								[Fusion.OnEvent "Activated"] = function()
									props.currentlyConfiguring:set(nil)
								end :: unknown,

								MaxTextSize = 25,
							},

							scope:textButton {
								Size = UDim2.fromOffset(115, 40),
								AnchorPoint = Vector2.new(1, 0),
								Position = UDim2.fromScale(1, 0),
								BackgroundColor3 = currentTheme.colors.blue,
								Border = 2,
								Shadow = true,
								ShadowColor3 = currentTheme.colors.blue,
								ButtonGlow = true,
								ButtonGlowColor3 = if currentTheme.colors.white == Color3.new(1, 1, 1)
									then currentTheme.colors.text
									else currentTheme.colors.base,
								CornerRadius = UDim.new(0, 10),
								Text = "Done",
								TextColor3 = currentTheme.colors.mantle,
								TextScaled = true,
								FontWeight = Enum.FontWeight.Medium,
								Reactive = true,
								Visible = scope:Computed(function(use)
									return use(props.currentlyConfiguring) ~= nil
								end),

								[Fusion.OnEvent "Activated"] = function()
									props.currentlyConfiguring:set(nil)
									props.currentLocation:set(nil)
									props.currentEquipment:set("")
								end :: unknown,

								MaxTextSize = 25,
							},

							scope:textButton {
								Size = UDim2.fromScale(1, 1),
								BackgroundColor3 = currentTheme.colors.crust,
								Border = 2,
								Shadow = true,
								ShadowColor3 = currentTheme.colors.crust,
								CornerRadius = UDim.new(0, 10),
								Text = "Remove Current",
								TextScaled = true,
								FontWeight = Enum.FontWeight.Medium,
								Reactive = true,
								Visible = scope:Computed(function(use)
									return use(props.currentEquipment) ~= "" and use(props.currentlyConfiguring) == nil
								end),

								[Fusion.OnEvent "Activated"] = function()
									local currentLocation = scope.peek(props.currentLocation)
									local currentVehicle = scope.peek(props.currentVehicleFolder)
									local outfitting = scope.peek(props.outfitting)
									if currentLocation == nil or currentVehicle == nil or outfitting == nil then
										return
									end
									if
										vehicle:changeEquipment(currentVehicle, outfitting, currentLocation)
										== false
									then
										log.warn("failed to change equipment")
										return
									end
									props.currentEquipment:set("")
									props.currentlyConfiguring:set(nil)
								end :: unknown,

								MaxTextSize = 25,
							},
						},
					},

					scope:textLabel {
						Size = UDim2.fromOffset(280, 50),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Text = "Select Equipment Location To Modify",
						TextSize = 20,
						FontWeight = Enum.FontWeight.Regular,
						TextWrapped = true,

						Visible = scope:Computed(function(use)
							return use(props.currentLocation) == nil
						end),
					},

					scope:New("ScrollingFrame") {
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

						[Fusion.Children] = {
							scope:Computed(function(use, scope: typeof(scope))
								local currentVehicle = use(props.currentVehicleFolder)
								local outfitting = use(props.outfitting)
								return if currentVehicle ~= nil and outfitting ~= nil
									then construct(scope, currentVehicle, outfitting, props)
									else nil
							end),
						},
					},

					scope:configuring {
						attachments = props.attachments,
						viewportSize = props.viewportSize,
						currentLocation = props.currentLocation,

						Mode = props.Mode,
						CurrentVehicle = props.CurrentVehicle,

						outfitting = props.outfitting,
						currentVehicleFolder = props.currentVehicleFolder,
						currentEquipment = props.currentEquipment,
						currentlyConfiguring = props.currentlyConfiguring,
						currentOptionData = props.currentOptionData,

						cleanupCustomization = props.cleanupCustomization,
					},
				},
			},
		},
	}
end
