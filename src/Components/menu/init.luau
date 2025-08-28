-- Redon Tech Emergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)

local widget = require(script.Parent.base.widget)
local components = {
	widget = widget,
}

local home = require(script.home)
local help = require(script.help)
local credits = require(script.credits)
local settings = require(script.settings)
local vehicle = require(script.vehicle)
local scriptInjectionRequired = require(script.scriptInjectionRequired)
local panels: { [number]: (scope: types.Scope, props: any) -> Fusion.Child } = {
	[1] = home,
	[2] = help,
	[3] = credits,
	[4] = settings,
	[5] = vehicle,
	[6] = scriptInjectionRequired,
}
local panelByName = {
	Home = 1,
	Help = 2,
	Credits = 3,
	Settings = 4,
	Vehicle = 5,
	["Permission Needed"] = 6,
}

type props = {
	Name: string,
	Version: string,

	Enabled: Fusion.UsedAs<boolean>,
	Mode: Fusion.UsedAs<types.mode>,
	CurrentVehicle: Fusion.Value<Model | string?>,
	PossibleVehicle: Fusion.Value<Model?>,
}

--[[
	Menu
	Creates the main menu for the plugin
]]
return function(baseScope: types.Scope, props: props)
	local scope = Fusion.innerScope(baseScope, components)
	local currentTheme = RedonUI.theme.theme:now()

	local currentPanel = scope:Value("Home")
	local lastPanelIndex = scope:Value(1)
	local currentPanelIndex = scope:Value(1)
	scope:Observer(currentPanel):onChange(function()
		local newPanel = scope.peek(currentPanel)
		local newIndex = panelByName[newPanel]
		local currentIndex = scope.peek(currentPanelIndex)
		lastPanelIndex:set(currentIndex)
		currentPanelIndex:set(newIndex)
	end)

	return scope:widget {
		pluginGuiId = `{props.Name}_Menu`,
		InitialDockState = Enum.InitialDockState.Float,
		InitialEnabled = false,
		MinHeight = 450,
		MinWidth = 240,
		FloatingYSize = 450,
		FloatingXSize = 240,
		InitialEnabledShouldOverrideRestore = true,

		Title = scope:Computed(function(use)
			return `EVC {use(currentPanel)} ({use(props.Version)})`
		end),

		Enabled = scope:Computed(function(use)
			return use(props.Enabled) == true and use(props.Mode) == "menu"
		end),

		[Fusion.Children] = {
			scope:base {
				Name = "Main",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = currentTheme.colors.base,

				[Fusion.Children] = {
					scope:New("Frame") {
						Name = "Container",
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromOffset(400, 750),
						BackgroundTransparency = 1,
						ClipsDescendants = true,

						[Fusion.Children] = Fusion.Child {
							scope:New("UIScale") { Scale = 0.6 },

							-- selene: allow(shadowing)
							scope:ForPairs(panels, function(_, scope: typeof(scope), key, panel)
								return key,
									scope:base {
										Name = tostring(key),
										Size = UDim2.fromScale(1, 1),
										Position = scope:Spring(
											scope:Computed(function(use)
												local currentIndex = use(currentPanelIndex)
												if currentIndex == key then
													return UDim2.fromScale(0, 0)
												elseif currentIndex > key then
													return UDim2.fromScale(-1, 0)
												else
													return UDim2.fromScale(1, 0)
												end
											end),
											20,
											0.75
										),
										Visible = scope:Computed(function(use)
											return use(currentPanelIndex) == key or use(lastPanelIndex) == key
										end),
										BackgroundTransparency = 1,

										[Fusion.Children] = {
											panel(scope, {
												CurrentPanel = currentPanel,
												Version = props.Version,
												CurrentVehicle = props.CurrentVehicle,
												PossibleVehicle = props.PossibleVehicle,
												Mode = props.Mode,
											}),
										},
									}
							end),
						},
					},
				},
			},

			scope:textLabel {
				Name = "Version",
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 1),
				Size = UDim2.fromOffset(240, 10),
				BackgroundTransparency = 1,

				Text = `Version {props.Version}`,
				FontWeight = Enum.FontWeight.Regular,
				TextSize = 9,
			},
		},
	}
end
