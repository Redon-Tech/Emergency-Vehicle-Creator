-- Redon Tech Emergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local chassisHandler = require(root.Plugin.chassisHandler)
local log = require(root.Plugin.log)

local widget = require(script.Parent.base.widget)
local topbar = require(script.topbar)
local components = {
	widget = widget,
	topbar = topbar,
}

local functions = require(script.setup.functions)
local sirens = require(script.setup.sirens)
local lightSettings = require(script.setup.lightSettings)
local flashers = require(script.els.flashers)
local faders = require(script.els.faders)
local rotators = require(script.els.rotators)

type props = {
	Name: string,
	Version: string,

	Enabled: Fusion.UsedAs<boolean>,
	Mode: Fusion.Value<types.mode>,
	CurrentVehicle: Fusion.Value<Model | string?>,
	PossibleVehicle: Fusion.Value<Model?>,

	ReturnTo: Fusion.Value<types.returnTo>,
	PopupShown: Fusion.Value<boolean>,
}

--[[
	Main
	Creates the main app for the plugin
]]
return function(baseScope: types.Scope, props: props): Fusion.Child
	local scope = Fusion.innerScope(baseScope, components)
	local currentTheme = RedonUI.theme.theme:now()

	local currentPanel = scope:Value("Vehicle Setup")
	local currentPage = scope:Value(nil)
	local unsavedChanges = scope:Value(false)
	local currentPattern = scope:Value(nil)
	local installPluginOrUpgrade: Fusion.Value<boolean?> = scope:Value(nil)

	scope:Observer(props.PossibleVehicle):onChange(function()
		local currentPossibleVehicle = scope.peek(props.PossibleVehicle)
		if currentPossibleVehicle ~= nil then
			local currentConfiguration = chassisHandler:getConfiguration(currentPossibleVehicle)
			if currentConfiguration ~= nil then
				log.debug("Found vehicle configuration for possible vehicle")
				props.CurrentVehicle:set(currentPossibleVehicle)
				props.PossibleVehicle:set(nil)
				currentPanel:set("Vehicle Setup")
				currentPage:set("Functions")
			else
				local hasOldPlugin = chassisHandler:hasEVCChassisPluginInstalled(currentPossibleVehicle)
				if hasOldPlugin then
					installPluginOrUpgrade:set(true)
				else
					installPluginOrUpgrade:set(false)
				end
				currentPanel:set("Vehicle Setup")
				currentPage:set("Functions")
			end
		end
	end)

	local AbsoluteSize = scope:Value(Vector2.one)
	return scope:widget {
		pluginGuiId = `{props.Name}_Main`,
		InitialDockState = Enum.InitialDockState.Float,
		InitialEnabled = false,
		FloatingYSize = 648,
		FloatingXSize = 1152,
		InitialEnabledShouldOverrideRestore = true,
		[Fusion.Out "AbsoluteSize"] = AbsoluteSize,

		Title = scope:Computed(function(use)
			return `EVC {use(currentPanel)} ({use(props.Version)}) {if use(unsavedChanges)
				then "Unsaved Changes*"
				else ""}`
		end),

		Enabled = scope:Computed(function(use)
			local enable = use(props.Enabled) == true and use(props.Mode) == "main"
			if enable and scope.peek(props.CurrentVehicle) ~= nil then
				currentPanel:set("Vehicle Setup")
				currentPage:set("Functions")
			elseif enable and scope.peek(props.PossibleVehicle) == nil then
				currentPattern:set({
					functionId = 0,
					patternId = 0,
					pattern = {
						flashers = {},
						faders = {},
						rotators = {},
					},
				})
				currentPanel:set("ELS Setup")
				currentPage:set("Flashers")
			end
			return enable
		end),

		[Fusion.Children] = {
			scope:base {
				Name = "Main",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = currentTheme.colors.base,
				Interactable = scope:Computed(function(use)
					return not use(props.PopupShown)
				end),

				[Fusion.Children] = Fusion.Child {
					scope:topbar {
						UnsavedChanges = unsavedChanges,
						CurrentPanel = currentPanel :: any,
						CurrentPage = currentPage,
						CurrentVehicle = props.CurrentVehicle,
						PossibleVehicle = props.PossibleVehicle,
						ReturnTo = props.ReturnTo,
						Mode = props.Mode,
						CurrentPattern = currentPattern,
					},

					functions(scope, {
						UnsavedChanges = unsavedChanges,
						CurrentPanel = currentPanel :: any,
						CurrentPage = currentPage,
						Mode = props.Mode,
						CurrentVehicle = props.CurrentVehicle,
						CurrentPattern = currentPattern,
						ReturnTo = props.ReturnTo,
					}),

					sirens(scope, {
						UnsavedChanges = unsavedChanges,
						CurrentPanel = currentPanel :: any,
						CurrentPage = currentPage,
						Mode = props.Mode,
						CurrentVehicle = props.CurrentVehicle,
					}),

					lightSettings(scope, {
						UnsavedChanges = unsavedChanges,
						CurrentPanel = currentPanel :: any,
						CurrentPage = currentPage,
						Mode = props.Mode,
						CurrentVehicle = props.CurrentVehicle,
					}),

					flashers(scope, {
						UnsavedChanges = unsavedChanges,
						CurrentPanel = currentPanel :: any,
						CurrentPage = currentPage,
						Mode = props.Mode,
						CurrentVehicle = props.CurrentVehicle,
						CurrentPattern = currentPattern,
						Enabled = props.Enabled,
					}),

					faders(scope, {
						UnsavedChanges = unsavedChanges,
						CurrentPanel = currentPanel :: any,
						CurrentPage = currentPage,
						Mode = props.Mode,
						CurrentVehicle = props.CurrentVehicle,
						CurrentPattern = currentPattern,
						Enabled = props.Enabled,
					}),

					rotators(scope, {
						UnsavedChanges = unsavedChanges,
						CurrentPanel = currentPanel :: any,
						CurrentPage = currentPage,
						Mode = props.Mode,
						CurrentVehicle = props.CurrentVehicle,
						CurrentPattern = currentPattern,
						Enabled = props.Enabled,
					}),

					scope:base {
						Size = UDim2.fromScale(2, 2),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = currentTheme.colors.crust,
						BackgroundTransparency = scope:Spring(
							scope:Computed(function(use)
								return if use(installPluginOrUpgrade) == nil then 1 else 0.5
							end),
							20,
							1
						),
						Position = scope:Spring(
							scope:Computed(function(use)
								return if use(installPluginOrUpgrade) == nil
									then UDim2.fromScale(0.5, 1.5)
									else UDim2.fromScale(0.5, 0.5)
							end),
							20,
							0.6
						),
						ZIndex = 4000,

						[Fusion.Children] = {
							scope:New("UIListLayout") {
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								VerticalAlignment = Enum.VerticalAlignment.Center,
							},

							scope:base {
								AutomaticSize = Enum.AutomaticSize.XY,
								BackgroundColor3 = currentTheme.colors.base,
								Border = 2,
								CornerRadius = UDim.new(0, 15),
								Visible = scope:Computed(function(use)
									return use(installPluginOrUpgrade) ~= nil
								end),

								[Fusion.Children] = {
									scope:New("UIPadding") {
										PaddingTop = UDim.new(0, 10),
										PaddingBottom = UDim.new(0, 10),
										PaddingLeft = UDim.new(0, 10),
										PaddingRight = UDim.new(0, 10),
									},

									scope:New("UIListLayout") {
										Padding = UDim.new(0, 15),
										FillDirection = Enum.FillDirection.Vertical,
										HorizontalAlignment = Enum.HorizontalAlignment.Center,
										VerticalAlignment = Enum.VerticalAlignment.Top,
										SortOrder = Enum.SortOrder.LayoutOrder,
									},

									scope:textLabel {
										Size = UDim2.fromOffset(300, 50),
										AnchorPoint = Vector2.new(0.5, 0),
										Position = UDim2.fromScale(0.5, 0),
										Text = "Install Emergency Vehicle Handler",
										TextScaled = true,
										MaxTextSize = 30,
										FontWeight = Enum.FontWeight.Bold,
										LayoutOrder = 1,
									},

									scope:textLabel {
										Size = UDim2.fromOffset(400, 50),
										AnchorPoint = Vector2.new(0, 0),
										Position = UDim2.new(0, 0, 0, 65),
										Text = scope:Computed(function(use)
											if use(installPluginOrUpgrade) == true then
												return "Would you like to automatically update your EVC Chassis Plugin to Emergency Vehicle Handler?\n\n<b>Backup your vehicle before upgrading, data loss may occur.</b>"
											end

											return "Would you like to install Emergency Vehicle Handler?"
										end),
										RichText = true,
										TextScaled = true,
										TextSize = 20,
										FontWeight = Enum.FontWeight.Regular,
										MaxTextSize = 20,
										TextWrapped = true,
										TextYAlignment = Enum.TextYAlignment.Top,
										AutomaticSize = Enum.AutomaticSize.Y,
										LayoutOrder = 2,
									},

									scope:base {
										Size = UDim2.fromOffset(300, 50),
										AnchorPoint = Vector2.new(0.5, 1),
										Position = UDim2.fromScale(0.5, 1),
										BackgroundTransparency = 1,
										LayoutOrder = 3,

										[Fusion.Children] = Fusion.Child {
											scope:New("UIListLayout") {
												Padding = UDim.new(0, 15),
												FillDirection = Enum.FillDirection.Horizontal,
												HorizontalAlignment = Enum.HorizontalAlignment.Center,
												VerticalAlignment = Enum.VerticalAlignment.Center,
												SortOrder = Enum.SortOrder.LayoutOrder,
											},

											scope:textButton {
												Size = UDim2.fromOffset(175, 35),
												Text = "Cancel",
												TextScaled = true,
												MaxTextSize = 25,
												TextColor3 = currentTheme.colors.crust,
												BackgroundColor3 = currentTheme.colors.red,
												ButtonGlowColor3 = currentTheme.colors.maroon,
												ShadowColor3 = currentTheme.colors.red,
												ButtonGlow = true,
												Shadow = true,
												Border = 2,
												CornerRadius = UDim.new(0, 10),
												[Fusion.OnEvent "Activated"] = function()
													props.PossibleVehicle:set(nil)
													installPluginOrUpgrade:set(nil)
													props.Mode:set("main")
												end :: unknown,
												LayoutOrder = 1,

												Reactive = true,
											},

											scope:textButton {
												Size = UDim2.fromOffset(175, 35),
												Text = scope:Computed(function(use)
													if use(installPluginOrUpgrade) == true then
														return "Upgrade"
													end

													return "Install"
												end),
												TextScaled = true,
												MaxTextSize = 25,
												TextColor3 = currentTheme.colors.crust,
												BackgroundColor3 = currentTheme.colors.sky,
												ButtonGlowColor3 = currentTheme.colors.text,
												ShadowColor3 = currentTheme.colors.sky,
												ButtonGlow = true,
												Shadow = true,
												Border = 2,
												CornerRadius = UDim.new(0, 10),
												[Fusion.OnEvent "Activated"] = function()
													local currentPossibleVehicle = scope.peek(props.PossibleVehicle)
													if currentPossibleVehicle ~= nil then
														local installed =
															chassisHandler:installPlugin(currentPossibleVehicle)
														if installed then
															props.CurrentVehicle:set(currentPossibleVehicle)
															props.PossibleVehicle:set(nil)
															installPluginOrUpgrade:set(nil)
														else
															log.warn("Failed to install plugin")
															props.PossibleVehicle:set(nil)
															installPluginOrUpgrade:set(nil)
															props.Mode:set("main")
														end
													end
												end :: unknown,
												LayoutOrder = 1,

												Reactive = true,
											},
										},
									},
								},
							},
						},
					},
				},
			},

			scope:textLabel {
				Name = "Version",
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 5, 1, -5),
				Size = UDim2.fromOffset(240, 12),
				BackgroundTransparency = 1,

				Text = props.Version,
				TextSize = 9,
				FontWeight = Enum.FontWeight.Regular,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Bottom,
				TextTransparency = 0.5,
			},

			props[Fusion.Children],
		},
	}
end
