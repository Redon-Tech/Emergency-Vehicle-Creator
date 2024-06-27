--[[
Redon Tech 2023-2024
EVC V2
--]]

local columnFrame = require(script.Parent.Parent.reusedContent.columnFrame)
local optionsChildren = require(script.Parent.optionsChildren)
local dropdown = require(script.Parent.dropdown)
local buttons = require(script.Parent.buttons)

return function(sectionNumer: number, colors: { number:Color3 }, colorLabels: { number:string })
	local section = Instance.new("ScrollingFrame")
	section.Name = "Section"..sectionNumer
	section.BackgroundTransparency = 1
	section.BorderSizePixel = 0
	section.LayoutOrder = sectionNumer
	section.Size = UDim2.fromOffset(240, 400) -- 126
	section.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	section.CanvasSize = UDim2.new()
	section.ScrollBarThickness = 5
	section.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	section.Selectable = false

	local uIListLayout = Instance.new("UIListLayout")
	uIListLayout.Name = "UIListLayout"
	uIListLayout.Padding = UDim.new(0, 5)
	uIListLayout.FillDirection = Enum.FillDirection.Horizontal
	uIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uIListLayout.Parent = section

	local dropdownColumn = columnFrame("Dropdown", 0)
	dropdownColumn.UIListLayout:Destroy()
	dropdown(colors, colorLabels).Parent = dropdownColumn

	local optionsColumn = columnFrame("Options", 1)
	optionsChildren(optionsColumn)

	local buttonsColumn = columnFrame("Buttons", 2)
	buttons(buttonsColumn)

	dropdownColumn.Parent = section
	optionsColumn.Parent = section
	buttonsColumn.Parent = section

	local function updateCanvas()
		section.CanvasSize = UDim2.fromOffset(0, optionsColumn.UIListLayout.AbsoluteContentSize.Y)
	end
	optionsColumn.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

	return section
end