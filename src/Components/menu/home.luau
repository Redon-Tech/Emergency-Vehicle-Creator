-- Redon Tech Emnergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local assets = require(root.Plugin.assets)

type props = {
	CurrentPanel: Fusion.Value<types.menuPanels>,
}

local secondaryButtons: { [types.menuPanels]: string } = {
	["Settings"] = assets.images.home.settings,
	["Help"] = assets.images.home.help,
	["Credits"] = assets.images.home.credits,
}

--[[
	Home
	Creates the home page for the main menu
]]
return function(scope: types.Scope, props: props): Fusion.Child
	local currentTheme = RedonUI.theme.theme:now()

	return scope:base {
		Name = "Home",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = scope:Computed(function(use)
			return use(props.CurrentPanel) == "Home"
		end),

		[Fusion.Children] = {
			scope:textLabel {
				Name = "Title",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 10),
				Size = UDim2.fromOffset(400, 150),

				Text = "Emergency Vehicle Creator\nV3",
				FontWeight = Enum.FontWeight.Bold,
				TextScaled = true,

				TextYAlignment = Enum.TextYAlignment.Top,
			},

			scope:textButton {
				Name = "CreateVehicle",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 208),
				Size = UDim2.fromOffset(350, 80),
				Gradient = ColorSequence.new(currentTheme.colors.sky, currentTheme.colors.sapphire),
				Border = 3,
				CornerRadius = UDim.new(0, 25),

				Text = "Create Vehicle",
				FontWeight = Enum.FontWeight.Medium,
				TextSize = 35,
				TextColor = "mantle",

				Reactive = true,
				ButtonGlow = true,
				ButtonGlowColor = "text",
				Shadow = true,
				ShadowColor = "sky",
			},

			scope:textButton {
				Name = "Continue",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 338),
				Size = UDim2.fromOffset(350, 80),
				Gradient = ColorSequence.new(currentTheme.colors.sky, currentTheme.colors.sapphire),
				Border = 3,
				CornerRadius = UDim.new(0, 25),

				Text = "Continue Without",
				FontWeight = Enum.FontWeight.Medium,
				TextSize = 35,
				TextColor = "mantle",

				Reactive = true,
				ButtonGlow = true,
				ButtonGlowColor = "text",
				Shadow = true,
				ShadowColor = "sky",
			},

			scope:base {
				Name = "SecondaryButtons",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 531),
				Size = UDim2.fromOffset(350, 80),
				BackgroundTransparency = 1,

				[Fusion.Children] = {
					scope:New("UIListLayout") {
						Padding = UDim.new(0, 55),
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
					},

					-- selene: allow(shadowing)
					scope:ForPairs(secondaryButtons, function(_, scope: typeof(scope), panel, icon)
						return panel,
							scope:iconButton {
								Name = panel,
								Size = UDim2.fromOffset(80, 80),
								Image = icon,
								ImageColor = "text",
								BackgroundColor = "crust",
								Border = 3,
								BorderColor = "text",
								Reactive = true,
								CornerRadius = UDim.new(0, 25),
								LayoutOrder = if panel == "Settings" then 1 elseif panel == "Help" then 2 else 3,
								Shadow = true,
								ShadowColor = "crust",

								[Fusion.OnEvent "Activated"] = function()
									props.CurrentPanel:set(panel)
								end,
							}
					end),
				},
			},

			scope:base {
				Name = "VersionWarning",
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -41),
				Size = UDim2.fromOffset(400, 73),
				BackgroundTransparency = 1,
				Visible = if version:isOutdated() then true else false,

				[Fusion.Children] = {
					scope:textLabel {
						Name = "WARNING",
						AnchorPoint = Vector2.new(0.5, 0),
						Position = UDim2.fromScale(0.5, 0),
						Size = UDim2.fromOffset(400, 30),

						Text = "WARNING!",
						FontWeight = Enum.FontWeight.Regular,
						TextSize = 30,
						TextColor = "peach",
					},

					scope:textLabel {
						Name = "Version",
						AnchorPoint = Vector2.new(0.5, 0),
						Position = UDim2.new(0.5, 0, 0, 37),
						Size = UDim2.fromOffset(400, 60),

						Text = `You are running an outdated version of the plugin, please update to the latest version ({version.latestVersion}) to ensure a great experience!`,
						FontWeight = Enum.FontWeight.Regular,
						TextSize = 20,
						TextWrapped = true,
						TextColor = "text",
					},
				},
			},
		},
	}
end
