--!strict
-- Redon Tech Emergency Vehicle Creator, MIT License

local Fusion = require("../../../../Packages/fusion")
local RedonUI = require("../../../../Packages/redon-ui")
local types = require("../../../types")
local assets = require("../../../assets")
local UserInputHelper = require("../../../lib/UserInputHelper")
local createChildren = require("./createChildren")
local colorPicker = require("../../base/colorPicker")

local gamepadKeycodes = {
	Enum.KeyCode.None,
	Enum.KeyCode.ButtonX,
	Enum.KeyCode.ButtonY,
	Enum.KeyCode.ButtonA,
	Enum.KeyCode.ButtonB,
	Enum.KeyCode.ButtonR1,
	Enum.KeyCode.ButtonL1,
	Enum.KeyCode.ButtonR2,
	Enum.KeyCode.ButtonL2,
	Enum.KeyCode.ButtonR3,
	Enum.KeyCode.ButtonL3,
	Enum.KeyCode.ButtonStart,
	Enum.KeyCode.ButtonSelect,
	Enum.KeyCode.DPadLeft,
	Enum.KeyCode.DPadRight,
	Enum.KeyCode.DPadUp,
	Enum.KeyCode.DPadDown,
	Enum.KeyCode.Thumbstick1Up,
	Enum.KeyCode.Thumbstick1Down,
	Enum.KeyCode.Thumbstick1Left,
	Enum.KeyCode.Thumbstick1Right,
	Enum.KeyCode.Thumbstick2Up,
	Enum.KeyCode.Thumbstick2Down,
	Enum.KeyCode.Thumbstick2Left,
	Enum.KeyCode.Thumbstick2Right,
}

type InputProps<T> = {
	Value: Fusion.UsedAs<T>,
	OnChange: (T) -> (),
	Disabled: Fusion.UsedAs<boolean>?,
	Scale: Fusion.UsedAs<number>?,
	TextXAlignment: Enum.TextXAlignment?,
	Height: number?,
}

local Controls = {}

function Controls.button(scope: types.Scope, props: InputProps<string>): Instance
	local theme = RedonUI.theme.theme:now()

	return scope:textButton {
		Size = scope:Computed(function(use)
			return UDim2.new(1, 0, 0, (props.Height or 50) * (use(props.Scale) or 1))
		end),
		MaxSize = Vector2.new(300, 50),
		BackgroundColor3 = scope:Computed(function(use)
			return if use(props.Disabled) then theme.colors.base else theme.colors.crust
		end),
		BorderColor3 = scope:Computed(function(use)
			return if use(props.Disabled) then theme.colors.overlay0 else theme.colors.white
		end),
		Interactable = scope:Computed(function(use)
			return not use(props.Disabled)
		end),
		Reactive = true,
		CornerRadius = UDim.new(0, 5),
		Border = 1,
		Text = props.Value,
		TextScaled = true,
		MaxTextSize = 20,
		FontWeight = Enum.FontWeight.Regular,
		TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center,
		[Fusion.OnEvent "Activated"] = function()
			if not Fusion.peek(props.Disabled) then
				props.OnChange("")
			end
		end,
	}
end

function Controls.textInput(scope: types.Scope, props: InputProps<string>): Instance
	local theme = RedonUI.theme.theme:now()
	local draft = scope:Value(Fusion.peek(props.Value))
	scope:Observer(props.Value):onChange(function()
		draft:set(Fusion.peek(props.Value))
	end)

	return scope:textBox {
		Size = scope:Computed(function(use)
			return UDim2.new(1, 0, 0, (props.Height or 50) * (use(props.Scale) or 1))
		end),
		MaxSize = Vector2.new(300, 50),
		BackgroundColor3 = scope:Computed(function(use)
			return if use(props.Disabled) then theme.colors.base else theme.colors.crust
		end),
		BorderColor3 = scope:Computed(function(use)
			return if use(props.Disabled) then theme.colors.overlay0 else theme.colors.white
		end),
		Interactable = scope:Computed(function(use)
			return not use(props.Disabled)
		end),
		CornerRadius = UDim.new(0, 5),
		Border = 1,
		Text = draft,
		TextScaled = true,
		MaxTextSize = 20,
		FontWeight = Enum.FontWeight.Regular,
		TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left,
		PaddingTop = UDim.new(0.2, 0),
		PaddingBottom = UDim.new(0.2, 0),
		PaddingLeft = scope:Computed(function(use)
			return UDim.new(0, 10 * (use(props.Scale) or 1))
		end),
		PaddingRight = scope:Computed(function(use)
			return UDim.new(0, 10 * (use(props.Scale) or 1))
		end),
		[Fusion.Out "Text"] = draft :: unknown,
		[Fusion.OnEvent "FocusLost"] = function()
			local value = Fusion.peek(draft)
			draft:set(Fusion.peek(props.Value))
			if not Fusion.peek(props.Disabled) then
				props.OnChange(value)
			end
		end,
	}
end

function Controls.numberInput(scope: types.Scope, props: InputProps<number>): Instance
	return Controls.textInput(scope, {
		Value = scope:Computed(function(use)
			return tostring(use(props.Value))
		end),
		Disabled = props.Disabled,
		Scale = props.Scale,
		Height = props.Height,
		TextXAlignment = props.TextXAlignment,
		OnChange = function(text)
			local value = tonumber(text)
			if value ~= nil and value == value and math.abs(value) < math.huge then
				props.OnChange(value)
			end
		end,
	})
end

function Controls.keybindInput(scope: types.Scope, props: InputProps<Enum.KeyCode> & { Gamepad: boolean? }): Instance
	if props.Gamepad then
		return createChildren.Dropdown<<Enum.KeyCode>>(scope, {
			Selected = props.Value,
			Options = gamepadKeycodes,
			Format = function(keycode)
				return keycode.Name
			end,
			Height = 50,
			Scale = props.Scale,
			Disabled = props.Disabled,
			OnSelect = props.OnChange,
		})
	end
	local theme = RedonUI.theme.theme:now()
	local capturing = scope:Value(false)
	local input: TextBox
	input = scope:textBox {
		Size = scope:Computed(function(use)
			return UDim2.new(1, 0, 0, 50 * (use(props.Scale) or 1))
		end),
		MaxSize = Vector2.new(300, 50),
		BackgroundColor3 = theme.colors.crust,
		CornerRadius = UDim.new(0, 5),
		Border = 1,
		TextEditable = false,
		Interactable = scope:Computed(function(use)
			return not use(props.Disabled)
		end),
		TextScaled = true,
		MaxTextSize = 20,
		FontWeight = Enum.FontWeight.Regular,
		TextXAlignment = Enum.TextXAlignment.Left,
		PaddingTop = UDim.new(0.2, 0),
		PaddingBottom = UDim.new(0.2, 0),
		PaddingLeft = scope:Computed(function(use)
			return UDim.new(0, 10 * (use(props.Scale) or 1))
		end),
		PaddingRight = scope:Computed(function(use)
			return UDim.new(0, 10 * (use(props.Scale) or 1))
		end),
		Text = scope:Computed(function(use)
			return if use(capturing) then "Escape to cancel..." else use(props.Value).Name
		end),
		[Fusion.OnEvent "Focused"] = function()
			capturing:set(not Fusion.peek(props.Disabled))
			input:ReleaseFocus()
		end,
	} :: TextBox
	UserInputHelper.InputBegan(scope, function(event)
		if not Fusion.peek(capturing) then
			return
		end
		if event.KeyCode == Enum.KeyCode.Escape then
			capturing:set(false)
			return
		end
		if event.UserInputType == Enum.UserInputType.Keyboard then
			capturing:set(false)
			if not Fusion.peek(props.Disabled) then
				props.OnChange(event.KeyCode)
			end
		end
	end)
	return input
end

function Controls.colorInput(scope: types.Scope, props: InputProps<Color3>): Instance
	local theme = RedonUI.theme.theme:now()
	return scope:textButton {
		Size = scope:Computed(function(use)
			return UDim2.new(1, 0, 0, 50 * (use(props.Scale) or 1))
		end),
		MaxSize = Vector2.new(300, 50),
		BackgroundColor3 = theme.colors.crust,
		CornerRadius = UDim.new(0, 5),
		Border = 1,
		TextScaled = true,
		MaxTextSize = 20,
		FontWeight = Enum.FontWeight.Regular,
		TextLabelSize = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = scope:Computed(function(use)
			local color: Color3 = use(props.Value)
			return ("%d, %d, %d"):format(color.R * 255, color.G * 255, color.B * 255)
		end),
		Reactive = true,
		[Fusion.OnEvent "Activated"] = function()
			local color = colorPicker(scope, { id = "evcColorPicker", initialColor = Fusion.peek(props.Value) })
			if color ~= nil then
				props.OnChange(color)
			end
		end :: unknown,
		[Fusion.Children] = Fusion.Child {
			scope:New("UIPadding") {
				PaddingTop = UDim.new(0.2, 0),
				PaddingBottom = UDim.new(0.2, 0),
				PaddingLeft = scope:Computed(function(use)
					return UDim.new(0, 10 * (use(props.Scale) or 1))
				end),
				PaddingRight = scope:Computed(function(use)
					return UDim.new(0, 10 * (use(props.Scale) or 1))
				end),
			},
			scope:base {
				Size = scope:Computed(function(use)
					local size = 30 * (use(props.Scale) or 1)
					return UDim2.fromOffset(size, size)
				end),
				Position = UDim2.fromScale(1, 0.5),
				AnchorPoint = Vector2.new(1, 0.5),
				CornerRadius = UDim.new(1, 0),
				BackgroundColor3 = props.Value,
			},
		},
	}
end

function Controls.actions(
	scope: types.Scope,
	props: {
		OnEdit: (() -> ())?,
		OnDelete: () -> (),
		OnDownload: (() -> ())?,
		Scale: Fusion.UsedAs<number>?,
		Height: Fusion.UsedAs<number>?,
	}
): Instance
	local theme = RedonUI.theme.theme:now()
	local function icon(image: string, hoveredImage: string, order: number, callback: () -> ()): Instance
		local hovered = scope:Value(false)
		return scope:iconButton {
			Size = scope:Computed(function(use)
				local scale = use(props.Scale) or 1
				return UDim2.fromOffset((if order == 2 then 36 else 40) * scale, (use(props.Height) or 50) * scale)
			end),
			BackgroundTransparency = 1,
			Image = scope:Computed(function(use)
				return if use(hovered) then hoveredImage else image
			end),
			MouseEnter = function()
				hovered:set(true)
			end,
			MouseLeave = function()
				hovered:set(false)
			end,
			ScaleType = Enum.ScaleType.Fit,
			Reactive = true,
			LayoutOrder = order,
			[Fusion.OnEvent "Activated"] = callback,
		}
	end
	return scope:New("Frame") {
		Size = UDim2.new(),
		AutomaticSize = Enum.AutomaticSize.XY,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		BackgroundTransparency = 1,
		[Fusion.Children] = Fusion.Child {
			scope:New("UIListLayout") {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = scope:Computed(function(use)
					return UDim.new(0, 15 * (use(props.Scale) or 1))
				end),
			},
			if props.OnEdit ~= nil
				then scope:textButton {
					Size = scope:Computed(function(use)
						local scale = use(props.Scale) or 1
						return UDim2.fromOffset(200 * scale, (use(props.Height) or 50) * scale)
					end),
					MaxSize = Vector2.new(200, 50),
					BackgroundColor3 = theme.colors.crust,
					CornerRadius = UDim.new(0, 5),
					Border = 1,
					Text = "Edit",
					TextScaled = true,
					MaxTextSize = 30,
					FontWeight = Enum.FontWeight.Medium,
					TextXAlignment = Enum.TextXAlignment.Center,
					Shadow = true,
					ShadowColor3 = theme.colors.mantle,
					ButtonGlow = true,
					ButtonGlowColor3 = theme.colors.mantle,
					Reactive = true,
					LayoutOrder = 1,
					[Fusion.OnEvent "Activated"] = props.OnEdit,
				}
				else {},
			if props.OnDownload ~= nil
				then icon(assets.images.redonUI.download, assets.images.redonUI.downloadFilled, 2, props.OnDownload)
				else {},
			icon(assets.images.redonUI.trash, assets.images.redonUI.trashFilled, 3, props.OnDelete),
		},
	}
end

return Controls
