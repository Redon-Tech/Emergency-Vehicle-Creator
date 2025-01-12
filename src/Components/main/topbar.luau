--#selene: allow(shadowing)
-- Redon Tech Emnergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)
local popup = require(root.Plugin.Components.popup)

type props = {
	UnsavedChanges: Fusion.Value<boolean>,
	Mode: Fusion.Value<types.mode>,
	CurrentPanel: Fusion.Value<types.mainPanels>,
	CurrentPage: Fusion.Value<types.pages?>,
	ReturnTo: Fusion.Value<types.returnTo>,
	CurrentVehicle: Fusion.Value<Model | string?>,
}

local pageButtons: {
	[types.pages]: {
		panel: types.mainPanels,
		order: number,
		position: Fusion.Value<Vector2>,
		size: Fusion.Value<Vector2>,
	},
} =
	{
		["Functions"] = { panel = "Vehicle Setup", order = 1 },
		["Sirens"] = { panel = "Vehicle Setup", order = 2 },
		["Light Settings"] = { panel = "Vehicle Setup", order = 3 },
		["Flashers"] = { panel = "ELS Setup", order = 1 },
		["Faders"] = { panel = "ELS Setup", order = 2 },
		["Rotators"] = { panel = "ELS Setup", order = 3 },
	}

local SPRING_SPEED = 20
local SPRING_DAMPING = 0.75
--[[
	Topbar
	Creates the topbar for the main app
]]
return function(scope: types.Scope, props: props): Fusion.Child
	local currentTheme = RedonUI.theme.theme:now()
	for _, value in pairs(pageButtons) do
		value.position = scope:Value(Vector2.new(0, 0))
		value.size = scope:Value(Vector2.new(0, 0))
	end

	local topbarSize = scope:Value(Vector2.one)
	local topbarPosition = scope:Value(Vector2.one)
	local selectorSizeAnimation = scope:Spring(
		scope:Computed(function(use)
			local currentPage = use(props.CurrentPage)
			if currentPage == nil then
				return UDim2.new(0, 0, 0, 0)
			end

			local currentSize: Vector2? = use(pageButtons[currentPage :: types.pages].size)
			if currentSize == nil then
				return UDim2.new(0, 0, 0, 0)
			end

			return UDim2.new(0, currentSize.X + 10, 0.2, 0)
		end),
		SPRING_SPEED,
		1
	)
	local selectorPositionAnimation = scope:Spring(
		scope:Computed(function(use)
			local currentPage = use(props.CurrentPage)
			if currentPage == nil then
				return UDim2.new(-1, 0, 0, 0)
			end

			local currentPosition: Vector2? = use(pageButtons[currentPage :: types.pages].position)
			if currentPosition == nil or currentPosition.X == 0 then
				return UDim2.new(-1, 0, 0, 0)
			end

			local baseSize = use(topbarSize)
			if baseSize.X == 0 then
				return UDim2.new(-1, 0, 0, 0)
			end
			return UDim2.new((currentPosition.X / baseSize.X) - (5 / baseSize.X), 0, 0.9, 0)
		end),
		SPRING_SPEED,
		SPRING_DAMPING
	)
	return scope:base {
		Name = "Topbar",
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 0.0462962963),
		BackgroundColor3 = currentTheme.colors.mantle,
		ClipsDescendants = true,
		[Fusion.Out "AbsoluteSize"] = topbarSize :: unknown,
		[Fusion.Out "AbsolutePosition"] = topbarPosition,

		[Fusion.Children] = {
			scope:textButton {
				Size = UDim2.fromOffset(75, 30),
				TextLabelSize = UDim2.fromScale(1, 1),
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				TextScaled = true,
				Text = scope:Computed(function(use)
					return if use(props.UnsavedChanges) == true then "Save*" else "Save"
				end),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextColor3 = currentTheme.colors.text,
				FontWeight = Enum.FontWeight.Medium,
				MaxTextSize = 20,
				Reactive = true,
				AnimateSize = false,

				[Fusion.OnEvent "Activated"] = function()
					popup:addPopup(scope, {
						title = "Save Changes",
						description = "Would you like to save your changes?",
						actions = {
							{
								text = "Cancel",
								type = "standard",
								key = 1,
								callback = function(newPopup)
									popup:removePopup(newPopup)
									print("cancel")
								end,
							},
							{
								text = "Save",
								type = "primary",
								key = 2,
								callback = function(newPopup)
									popup:removePopup(newPopup)
									print("save")
								end,
							},
						},
					})
				end,
			},

			scope:textButton {
				Size = UDim2.fromOffset(300, 30),
				TextLabelSize = UDim2.fromScale(1, 1),
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0),
				TextScaled = true,
				Text = scope:Computed(function(use)
					local returnTo = use(props.ReturnTo)
					if returnTo == "menu" then
						returnTo = "Main Menu"
					elseif returnTo == "customizer" then
						returnTo = "Customization"
					elseif returnTo == "vehicleSetup" then
						returnTo = "Vehicle Setup"
					end
					return `<- Return To {returnTo}`
				end),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = currentTheme.colors.text,
				FontWeight = Enum.FontWeight.Medium,
				MaxTextSize = 20,
				Reactive = true,
				AnimateSize = false,

				[Fusion.OnEvent "Activated"] = function()
					local returnTo = scope.peek(props.ReturnTo)
					if returnTo == "menu" then
						props.Mode:set("menu")
					elseif returnTo == "customizer" then
						props.Mode:set("viewport")
					elseif returnTo == "vehicleSetup" then
						props.CurrentPanel:set("Vehicle Setup")
						props.CurrentPage:set("Functions")
						if scope.peek(props.CurrentVehicle) ~= nil then
							props.ReturnTo:set("customizer")
						else
							props.ReturnTo:set("menu")
						end
					end
				end,
			},

			scope:base {
				ClassName = "ScrollingFrame",
				Name = "Buttons",
				Position = UDim2.fromOffset(310, 0),
				Size = UDim2.new(1, -620, 1, 0),
				BackgroundTransparency = 1,
				CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.X,
				ScrollBarThickness = 0,

				[Fusion.Children] = Fusion.Child {
					scope:New("UIListLayout") {
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0.015625, 0),
					},

					scope:ForPairs(pageButtons, function(_, scope: typeof(scope), key, value)
						local desiredButtonPosition = scope:Value(UDim2.fromOffset(0, 0))
						local animatedButtonPosition = scope:Spring(desiredButtonPosition, 30, 1)
						local isHovered = scope:Value(false)
						return key,
							scope:base {
								Size = UDim2.new(0, 0, 1, -2),
								AutomaticSize = Enum.AutomaticSize.X,
								LayoutOrder = value.order,
								BackgroundTransparency = 1,
								[Fusion.Out "AbsolutePosition"] = value.position :: unknown,
								[Fusion.Out "AbsoluteSize"] = value.size,
								MaxSize = Vector2.new(185, 36),

								[Fusion.Children] = {
									scope:textLabel {
										Size = UDim2.fromScale(0, 1),
										ClassName = "TextButton",
										Position = animatedButtonPosition,
										Text = key,
										TextScaled = true,
										AutomaticSize = Enum.AutomaticSize.X,
										TextColor3 = scope:Computed(function(use)
											return if use(props.CurrentPage) == key
												then currentTheme.colors.blue
												else currentTheme.colors.text
										end),
										FontFace = scope:Computed(function(use)
											return if use(props.CurrentPage) == key
												then currentTheme.font[Enum.FontWeight.Bold]
												else currentTheme.font[Enum.FontWeight.Medium]
										end),
										BackgroundTransparency = 1,
										Visible = scope:Computed(function(use)
											return use(props.CurrentPanel) == value.panel
										end),
										MaxTextSize = 20,

										[Fusion.OnEvent "MouseEnter"] = function()
											desiredButtonPosition:set(UDim2.fromOffset(0, -3))
											isHovered:set(true)
										end,

										[Fusion.OnEvent "MouseLeave"] = function()
											desiredButtonPosition:set(UDim2.fromOffset(0, 0))
											isHovered:set(false)
										end,

										[Fusion.OnEvent "MouseButton1Down"] = function()
											desiredButtonPosition:set(UDim2.fromOffset(0, 3))
										end,

										[Fusion.OnEvent "MouseButton1Up"] = function()
											if scope.peek(isHovered) == true then
												desiredButtonPosition:set(UDim2.fromOffset(0, -3))
											else
												desiredButtonPosition:set(UDim2.fromOffset(0, 0))
											end
										end,

										[Fusion.OnEvent "Activated"] = function()
											props.CurrentPage:set(key :: any)
										end,
									},
								},
							}
					end),
				},
			},

			scope:base {
				CornerRadius = UDim.new(0.5, 0),
				BackgroundColor3 = currentTheme.colors.blue,
				Size = selectorSizeAnimation,
				AnchorPoint = Vector2.new(0, 0),
				Position = selectorPositionAnimation,

				-- [Fusion.Children] = {
				-- 	scope:New("UIScale") { Scale = 1.6666666667 },
				-- },
			},
		},
	}
end
