-- Redon Tech Emnergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent
local plugin = root:FindFirstAncestorWhichIsA("Plugin")

local Selection = game:GetService("Selection")

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local assets = require(root.Plugin.assets)
local vehicle = require(root.Plugin.vehicle)
local version = require(root.Plugin.version)

type props = {
	CurrentPanel: Fusion.Value<types.menuPanels>,
	CurrentVehicle: Fusion.Value<Instance | string?>,
	Mode: Fusion.Value<types.mode>,
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

	local currentSelection: Fusion.Value<Instance?> = scope:Value(nil)

	local selectionConnection: RBXScriptConnection? = nil
	local function listenForSelection()
		if selectionConnection ~= nil then
			selectionConnection:Disconnect()
			selectionConnection = nil
		end

		currentSelection:set(Selection:Get()[1])
		selectionConnection = Selection.SelectionChanged:Connect(function()
			currentSelection:set(Selection:Get()[1])
		end)
	end

	return scope:base {
		Name = "Home",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = scope:Computed(function(use)
			local enabled = use(props.CurrentPanel) == "Home"
			if enabled then
				listenForSelection()
			elseif selectionConnection ~= nil then
				selectionConnection:Disconnect()
			end
			return enabled
		end),

		[Fusion.Children] = Fusion.Child {
			scope:textLabel {
				Name = "Title",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 10),
				Size = UDim2.fromOffset(400, 150),

				Text = "Emergency Vehicle Creator\nV3",
				FontWeight = Enum.FontWeight.Medium,
				TextScaled = true,

				TextYAlignment = Enum.TextYAlignment.Top,
			},

			scope:textLabel {
				Name = "VehicleSelection",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 185),
				Size = UDim2.fromOffset(400, 36),

				Text = scope:Computed(function(use)
					local selection = use(currentSelection)
					if selection == nil then
						return "Select a Vehicle"
					end
					return `Selecting {selection.Name}`
				end),
				TextColor = scope:Computed(function(use)
					local selection = use(currentSelection)
					if selection ~= nil and vehicle:isValidVehicle(selection) == false then
						return "peach"
					end
					return "text"
				end :: any), -- TODO: Update type cast when RedonUI exports the type
				FontWeight = Enum.FontWeight.Bold,
				TextScaled = true,

				[Fusion.Children] = {
					scope:New("UITextSizeConstraint") {
						MaxTextSize = 30,
					},
				},
			},

			scope:textButton {
				Name = "CreateVehicle",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 271),
				Size = UDim2.fromOffset(350, 80),
				BackgroundColor3 = Color3.new(1, 1, 1),
				Gradient = ColorSequence.new(currentTheme.colors.sky, currentTheme.colors.sapphire),
				BorderColor = "text" :: any, -- TODO
				Border = 3,
				CornerRadius = UDim.new(0, 25),

				Text = scope:Computed(function(use)
					local selection = use(currentSelection)
					if selection ~= nil and vehicle:isValidVehicle(selection) ~= false then
						return "Edit Vehicle"
					end
					return "Create Vehicle"
				end),
				FontWeight = Enum.FontWeight.Bold,
				TextSize = 40,
				TextColor = "mantle" :: any, -- TODO

				Reactive = true,
				ButtonGlow = true,
				ButtonGlowColor = if currentTheme.colors.white == Color3.new(1, 1, 1) then "text" else "base",
				Shadow = true,
				ShadowColor = "sky",
			},

			scope:textButton {
				Name = "Continue",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 401),
				Size = UDim2.fromOffset(350, 80),
				BackgroundColor3 = Color3.new(1, 1, 1),
				Gradient = ColorSequence.new(currentTheme.colors.sky, currentTheme.colors.sapphire),
				BorderColor = "text" :: any, -- TODO
				Border = 3,
				CornerRadius = UDim.new(0, 25),

				Text = "Continue Without",
				FontWeight = Enum.FontWeight.Bold,
				TextSize = 40,
				TextColor = "mantle" :: any, -- TODO

				Reactive = true,
				ButtonGlow = true,
				ButtonGlowColor = if currentTheme.colors.white == Color3.new(1, 1, 1) then "text" else "base" :: any, -- TODO
				Shadow = true,
				ShadowColor = "sky" :: any, -- TODO
			},

			--selene: allow(shadowing)
			scope:ForValues({ 231, 361 }, function(_, scope: typeof(scope), value: number)
				return scope:textLabel {
					Name = "or",
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.new(0.5, 0, 0, value),
					Size = UDim2.fromOffset(400, 30),

					Text = "or",
					FontWeight = Enum.FontWeight.Regular,
					TextSize = 25,

					Visible = if value == 231
						then scope:Computed(function(use)
							local selection = use(currentSelection)
							return selection == nil or vehicle:isValidVehicle(selection) == false
						end)
						else true,
				}
			end),

			scope:base {
				Name = "SecondaryButtons",
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 531),
				Size = UDim2.fromOffset(350, 80),
				BackgroundTransparency = 1,

				[Fusion.Children] = Fusion.Child {
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
								ImageColor = "text" :: any, -- TODO
								BackgroundColor = "crust" :: any, -- TODO
								Border = 3,
								BorderColor = "text" :: any, -- TODO
								Reactive = true,
								CornerRadius = UDim.new(0, 25),
								LayoutOrder = if panel == "Settings" then 1 elseif panel == "Help" then 2 else 3,
								Shadow = true,
								ShadowColor = "crust" :: any, -- TODO

								[Fusion.OnEvent "Activated"] = function()
									props.CurrentPanel:set(panel :: types.menuPanels)
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
						TextColor = "peach" :: any, -- TODO
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
						TextColor = "text" :: any, -- TODO
					},
				},
			},
		},
	}
end
