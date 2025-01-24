-- Redon Tech Emergency Vehicle Creator, MIT License
local root = script.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local types = require(root.Plugin.types)

type action = {
	text: Fusion.UsedAs<string>,
	type: "standard" | "primary" | "danger",
	callback: (popup: Instance) -> (),
	key: Fusion.UsedAs<number>,
	keybind: Enum.KeyCode?,
}
export type popup = {
	currentContainer: Fusion.Value<Frame>?,
	container: (self: popup, scope: types.Scope) -> (Fusion.Child, Fusion.Value<boolean>),
	addPopup: (
		self: popup,
		scope: types.Scope,
		props: {
			title: Fusion.UsedAs<string>,
			description: Fusion.UsedAs<string>,
			forceDescriptionSize: Fusion.UsedAs<UDim2>?,
			actions: { action },
		}
	) -> (),
	removePopup: (self: popup, newPopup: Instance) -> (),
	enabled: Fusion.Value<boolean>,
	currentPopup: Instance?,
	parentScope: types.Scope,
	keybinds: { [Enum.KeyCode]: (popup: Instance) -> () },
}
local popup = {} :: popup

function popup.addPopup(self, scope, props)
	if self.currentContainer == nil then
		return
	end
	if self.currentPopup ~= nil then
		self.currentPopup:Destroy()
		self.currentPopup = nil
	end
	local currentContainer = scope.peek(self.currentContainer)
	local currentTheme = RedonUI.theme.theme:now()
	local newPopup
	local keybinds = {}
	for _, action in ipairs(props.actions) do
		if action.keybind ~= nil then
			keybinds[action.keybind] = action.callback
		end
	end
	self.keybinds = keybinds
	newPopup = self.parentScope:base {
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = currentTheme.colors.base,
		Border = 2,
		CornerRadius = UDim.new(0, 15),
		ZIndex = 5001,

		[Fusion.Children] = {
			self.parentScope:New("UIPadding") {
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
			},

			self.parentScope:New("UIListLayout") {
				Padding = UDim.new(0, 15),
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				SortOrder = Enum.SortOrder.LayoutOrder,
			},

			self.parentScope:textLabel {
				Size = UDim2.fromOffset(300, 50),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0),
				Text = props.title,
				TextScaled = true,
				MaxTextSize = 30,
				FontWeight = Enum.FontWeight.Bold,
				LayoutOrder = 1,
				ZIndex = 5001,
			},

			self.parentScope:textLabel {
				Size = if props.forceDescriptionSize ~= nil
					then props.forceDescriptionSize
					else UDim2.fromOffset(400, 50),
				AnchorPoint = Vector2.new(0, 0),
				Position = UDim2.new(0, 0, 0, 65),
				Text = props.description,
				RichText = true,
				TextScaled = props.forceDescriptionSize ~= nil,
				TextSize = 20,
				FontWeight = Enum.FontWeight.Regular,
				MaxTextSize = 20,
				TextWrapped = true,
				TextYAlignment = Enum.TextYAlignment.Top,
				AutomaticSize = if props.forceDescriptionSize == nil
					then Enum.AutomaticSize.Y
					else Enum.AutomaticSize.None,
				LayoutOrder = 2,
				ZIndex = 5001,
			},

			self.parentScope:base {
				Size = UDim2.fromOffset(300, 50),
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 1),
				BackgroundTransparency = 1,
				LayoutOrder = 3,
				ZIndex = 5001,

				[Fusion.Children] = Fusion.Child {
					self.parentScope:New("UIListLayout") {
						Padding = UDim.new(0, 15),
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
					},

					--selene: allow(shadowing)
					self.parentScope:ForValues(props.actions, function(_, newScope: types.Scope, value: action)
						local BackgroundColor = if value.type == "primary"
							then currentTheme.colors.sky
							elseif value.type == "danger" then currentTheme.colors.red
							else currentTheme.colors.crust
						local TextColor = if value.type == "standard"
							then currentTheme.colors.text
							else currentTheme.colors.crust
						local ShadowColor = if value.type == "primary"
							then currentTheme.colors.sky
							elseif value.type == "danger" then currentTheme.colors.red
							else currentTheme.colors.crust
						local ButtonGlowColor = if value.type == "primary"
							then if currentTheme.colors.white == Color3.new(1, 1, 1)
								then currentTheme.colors.text
								else currentTheme.colors.base
							else currentTheme.colors.maroon
						return newScope:textButton {
							Size = UDim2.fromOffset(175, 35),
							Text = value.text,
							TextScaled = true,
							MaxTextSize = 25,
							TextColor3 = TextColor,
							BackgroundColor3 = BackgroundColor,
							ButtonGlowColor3 = ButtonGlowColor,
							ShadowColor3 = ShadowColor,
							ButtonGlow = if value.type == "standard" then false else true,
							Shadow = true,
							Border = 2,
							CornerRadius = UDim.new(0, 10),
							[Fusion.OnEvent "Activated"] = function()
								local mt = getmetatable(scope :: Fusion.Scope)
								if typeof(mt) == "table" and mt._FUSION_POISONED then
									return
								end
								value.callback(newPopup)
							end :: unknown,
							LayoutOrder = value.key,

							Reactive = true,
							ZIndex = 5002,
						}
					end),
				},
			},
		},
	}
	self.enabled:set(true)
	newPopup.Parent = currentContainer
	self.currentPopup = newPopup
end

function popup.removePopup(self, _)
	self.keybinds = {}
	self.enabled:set(false)
end

function popup.container(self, scope)
	self.parentScope = scope
	local currentTheme = RedonUI.theme.theme:now()
	self.enabled = scope:Value(false)
	local container = scope:base {
		Size = UDim2.fromScale(2, 2),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = currentTheme.colors.crust,
		BackgroundTransparency = scope:Spring(
			scope:Computed(function(use)
				return if use(self.enabled) == false then 1 else 0.5
			end),
			20,
			1
		),
		Position = scope:Spring(
			scope:Computed(function(use)
				return if use(self.enabled) == false then UDim2.fromScale(0.5, 1.5) else UDim2.fromScale(0.5, 0.5)
			end),
			20,
			0.6
		),
		ZIndex = 5001,

		[Fusion.OnEvent "InputBegan"] = function(input)
			if self.currentPopup ~= nil and self.keybinds[input.KeyCode] ~= nil then
				local mt = getmetatable(scope :: Fusion.Scope)
				if typeof(mt) == "table" and mt._FUSION_POISONED then
					return
				end
				self.keybinds[input.KeyCode](self.currentPopup)
			end
		end :: unknown,

		[Fusion.Children] = {
			scope:New("UIListLayout") {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			},

			scope:New("UIGradient") {
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.1, 0),
					NumberSequenceKeypoint.new(0.9, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
			},
		},
	} :: Frame

	self.currentContainer = scope:Value(container)
	return container, self.enabled
end

return popup
