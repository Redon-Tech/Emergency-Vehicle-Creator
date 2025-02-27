local root = script.Parent.Parent.Parent.Parent

local Fusion = require(root.Packages.fusion)
local RedonUI = require(root.Packages["redon-ui"])
local assets = require(root.Plugin.assets)
local types = require(root.Plugin.types)

return function(
	scope: types.Scope,
	props: {
		attachments: Fusion.UsedAs<{ Attachment }>,
		viewportSize: Fusion.UsedAs<Vector2>,
		currentLocation: Fusion.Value<string?>,
		currentlyConfiguring: Fusion.Value<string?>,
		lightParts: Fusion.UsedAs<{ { name: string, part: Instance } }>,
	}
)
	local currentTheme = RedonUI.theme.theme:now()
	--selene: allow(shadowing)
	return {
		scope:ForValues(props.attachments, function(_, scope: typeof(scope), value: Attachment)
			local children = {}
			local allAttachments = { value }
			for _, attachment in pairs(value:GetDescendants()) do
				if attachment:IsA("Attachment") then
					table.insert(allAttachments, attachment)
				end
			end
			for _, attachment in pairs(allAttachments) do
				table.insert(
					children,
					scope:New("BillboardGui") {
						Adornee = attachment,
						Size = scope:Computed(function(use)
							local base = use(props.viewportSize)
							return UDim2.fromScale(500 / base.X, 500 / base.Y)
						end),
						MaxDistance = 30,
						AlwaysOnTop = true,
						Name = value.Name,

						[Fusion.Children] = {
							scope:iconButton {
								Size = UDim2.fromScale(1, 1),
								BackgroundColor3 = currentTheme.colors.base,
								Border = 2,
								BorderColor3 = currentTheme.colors.text,
								CornerRadius = UDim.new(1, 0),
								Image = scope:Computed(function(use)
									if use(props.currentLocation) == value.Name then
										return assets.images.redonUI.remove
									end
									return assets.images.redonUI.add
								end),

								[Fusion.OnEvent "Activated"] = function()
									if scope.peek(props.currentLocation) == value.Name then
										props.currentLocation:set(nil)
									else
										props.currentLocation:set(value.Name)
									end
									props.currentlyConfiguring:set(nil)
								end :: unknown,

								[Fusion.Children] = {
									scope:New("UIAspectRatioConstraint") {},
								},
							},
						},
					}
				)
			end

			return children
		end),

		scope:ForValues(props.lightParts, function(_, scope: typeof(scope), value: { name: string, part: Instance })
			return scope:New("BillboardGui") {
				Adornee = value.part,
				Size = scope:Computed(function(use)
					local base = use(props.viewportSize)
					return UDim2.fromScale(500 / base.X, 250 / base.Y)
				end),
				MaxDistance = 15,
				AlwaysOnTop = true,
				Name = value.name,

				[Fusion.Children] = {
					scope:textLabel {
						Size = UDim2.fromScale(1, 1),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						BackgroundColor3 = currentTheme.colors.base,
						Text = value.name,
						TextScaled = true,
						MaxTextSize = 20,

						[Fusion.Children] = {
							scope:New("UIAspectRatioConstraint") {
								AspectRatio = 2,
							},

							scope:New("UIStroke") {
								ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
								Color = currentTheme.colors.crust,
								Thickness = 1,
							},
						},
					},
				},
			}
		end),
	} :: { Fusion.Child }
end
