--[[
Redon Tech 2022
EVC
--]]

--------------------------------------------------------------------------------
-- Init --
--------------------------------------------------------------------------------

local Studio = settings():GetService("Studio")
local Is_RBXM = plugin.Name:find(".rbxm") ~= nil
local Functions = require(script.Parent.Modules.functions)
local Selection = game:GetService("Selection")

script.Parent.ChassisPlugin.EVCPlugin_Client.Disabled = true
script.Parent.ChassisPlugin.EVCPlugin.Disabled = true
script.Parent.ChassisPlugin.EVCPlugin_AG.Disabled = true

local function getName(name: string)
	if Is_RBXM then
		name ..= " (RBXM)"
	end
	return name
end

local Plugin_Name = getName("Emergency Vehicle Creator")
local Plugin_Description = "Create ELS for emergency vehicles!"
local Plugin_Icon = "http://www.roblox.com/asset/?id=9953243250"
local Widget_Name = getName("EVC")
local Button_Name = getName("EVC Menu")
local Standard_Script_Template =[[
local Lightbar = script.Parent

-- Colors, change this if you wish
local Colors = {
	[1] = Color3.fromRGB(63, 112, 202),
	[2] = Color3.fromRGB(255, 89, 89),
	[3] = Color3.fromRGB(218, 133, 65),
	[4] = Color3.fromRGB(255, 255, 255),
	[5] = Color3.fromRGB(75, 151, 75),
	[6] = Color3.fromRGB(170, 0, 170),
}

-- By default this color function will work with most light types, modify it to your needs
local function light(light, color)
	if color == 0 then
		for i,v in pairs(Lightbar[light]:GetDescendants()) do
			if v:IsA("GuiObject") then
				v.Visible = true
			elseif v:IsA("SurfaceGui") or v:IsA("Light") then
				v.Enabled = false
			elseif v:IsA("ParticleEmitter") then
				v.Transparency = NumberSequence.new(1)
			end
		end
		Lightbar[light].Transparency = 1
	else
		for i,v in pairs(Lightbar[light]:GetDescendants()) do
			if v:IsA("ImageLabel") or v:IsA("ImageButton") then
				v.ImageColor3 = Colors[color]
				v.Visible = true
			elseif v:IsA("Light") then
				v.Color = Colors[color]
				v.Enabled = true
			elseif v:IsA("ParticleEmitter") then
				v.Color = ColorSequence.new(Colors[color])
				v.Transparency = NumberSequence.new(0)
			elseif v:IsA("SurfaceGui") then
				v.Enabled = true
			end
		end
		Lightbar[light].Color = Colors[color]
		Lightbar[light].Transparency = 0
	end
end

-- Main Loop
--------------
-- To use the function above do
--      light("L1", 0)
-- The above will turn off said light
--      light("L1", 1)
-- The above will turn on said light and change its color to said color defined in the color table
--------------
while task.wait() do
]]
-- TBD: Get all plugins of Redon Tech to be on the same toolbar
-- if not _G.RT then
-- 	_G.RT = {Buttons = {}}
-- end

-- if not _G.RT["Buttons"] then
-- 	_G.RT["Buttons"] = {}
-- end

-- if _G.RT["RTToolbar"] then
-- 	_G.RT["RTToolbar"] = nil
-- end
-- _G.RT["RTToolbar"] = plugin:CreateToolbar("Redon Tech Plugins")

if _G.RTPlugins and typeof(_G.RTPlugins) == "table" then
	if _G.RTPlugins.Buttons[Plugin_Name] then
		Button = _G.RTPlugins.Buttons[Plugin_Name]
	else
		_G.RTPlugins.Buttons[Plugin_Name] = _G.RTPlugins.ToolBar:CreateButton(Button_Name, Plugin_Description, Plugin_Icon)
		Button = _G.RTPlugins.Buttons[Plugin_Name]
	end
else
	_G.RTPlugins = {
		ToolBar = plugin:CreateToolbar("Redon Tech Plugins"),
		Buttons = {}
	}

	_G.RTPlugins.Buttons[Plugin_Name] = _G.RTPlugins.ToolBar:CreateButton(Button_Name, Plugin_Description, Plugin_Icon)
	Button = _G.RTPlugins.Buttons[Plugin_Name]
end

--------------------------------------------------------------------------------
-- UI Init --
--------------------------------------------------------------------------------

local Config = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 1280, 720)
local GUI = plugin:CreateDockWidgetPluginGui(Widget_Name, Config)
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Global
GUI.Title = Plugin_Name
GUI.Name = Widget_Name

-- local Button = nil
-- if _G.RT["Buttons"][Button_Name] then
-- 	_G.RT["Buttons"][Button_Name] = nil
-- end
-- Button = _G.RT.RTToolbar:CreateButton(Button_Name, Plugin_Description, Plugin_Icon)
-- _G.RT["Buttons"][Button_Name] = Button

local MainFrame = require(script.Parent.Modules.gui).CreateGui()
MainFrame.Parent = GUI
MainFrame.Confirm.TextLabel.RichText = true -- GUI -> Script doesnt convert this
MainFrame.Creator.Info.Thanks.RichText = true
MainFrame.Creator.Info.Credits.RichText = true
for i,v in pairs(MainFrame.Controls:GetChildren()) do
	if v:IsA("TextLabel") then
		v.RichText = true
	end
end
MainFrame.Creator.PointerHolder.Pointer:SetAttribute("max", 20)
MainFrame.Creator.PointerHolder.Pointer:SetAttribute("count", 1)
local Pointer = MainFrame.Creator.ScrollingFrame["2"]
Pointer.Parent = script
Pointer:SetAttribute("max", 20)
Pointer:SetAttribute("count", 1)
local SaveTemplate = MainFrame.SaveLoad.ScrollingFrame.Frame
SaveTemplate.Parent = script
SaveTemplate.TextBox.ClearTextOnFocus = false
local StageTemplate = MainFrame.Export.SelectStage.ScrollingFrame.Frame
StageTemplate.Parent = script

MainFrame.Creator.ScrollingFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
	MainFrame.Creator.PointerHolder.CanvasPosition = Vector2.new(0, MainFrame.Creator.ScrollingFrame.CanvasPosition.Y)
end)

MainFrame.Creator.PointerHolder:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
	MainFrame.Creator.ScrollingFrame.CanvasPosition = Vector2.new(MainFrame.Creator.ScrollingFrame.CanvasPosition.X, MainFrame.Creator.PointerHolder.CanvasPosition.Y)
end)

--------------------------------------------------------------------------------
-- Handling --
--------------------------------------------------------------------------------

MainFrame:WaitForChild("Creator")
MainFrame:WaitForChild("Confirm")

local Locked, Pause, Usable = true, true, true
local MouseDown, Mouse2Down, Exportable = false, false, false
local Color = 1
local Starting, spacer = nil, nil
local RepColors = {
	[0] = Color3.fromRGB(40, 40, 40),
	[1] = Color3.fromRGB(47, 71, 255),
	[2] = Color3.fromRGB(185, 58, 60),
	[3] = Color3.fromRGB(253, 194, 66),
	[4] = Color3.fromRGB(255, 255, 255),
	[5] = Color3.fromRGB(75, 255, 75),
	[6] = Color3.fromRGB(188, 12, 211),
}
local ButColors = {
	[1] = "Blue",
	[2] = "Red",
	[3] = "Amber",
	[4] = "White",
	[5] = "Green",
	[6] = "Purple",
}
local coros = {}

--Color Change Handler
local function changecolor(new_color: number)
	Color = new_color
	for i,v in pairs(MainFrame.Creator.Info.Buttons:GetChildren()) do
		if table.find(ButColors, v.Name) then
			v.TextColor3 = RepColors[table.find(ButColors, v.Name)]
		end
	end

	local ButColor = ButColors[new_color]
	if MainFrame.Creator.Info.Buttons[ButColor] then
		MainFrame.Creator.Info.Buttons[ButColor].TextColor3 = Color3.fromRGB(100, 100, 100)
	end
end
changecolor(1)

local addbutton
local resetcounters
local function reset(skipconfirm)
	if skipconfirm then
		for i,v in pairs(MainFrame.Creator.ScrollingFrame:GetChildren()) do
			if v.Name == "1" or v.Name == "Last" or v.Name == "UIGridLayout" then else
				v:Destroy()
			end
		end
		for i,v in pairs(MainFrame.Creator.ScrollingFrame["1"]:GetChildren()) do
			if v.Name ~= "Top" and v:IsA("ImageLabel") then
				v:SetAttribute("Color", 0)
				v.ImageColor3 = RepColors[0]
			end
		end
		Exportable = false
		return
	end

	MainFrame.Confirm.Visible = true
	MainFrame.Confirm.TextLabel.Text = "Are you sure you want to reset? <b>Any unsaved progress will be lost!</b>"
	local connect1, connect2 = nil, nil

	connect1 = MainFrame.Confirm.Yes.MouseButton1Click:Connect(function()
		MainFrame.Confirm.Visible = false

		changecolor(1)
		for i,v in pairs(MainFrame.Creator.ScrollingFrame:GetChildren()) do
			if v.Name == "1" or v.Name == "Last" or v.Name == "UIGridLayout" then else
				v:Destroy()
			end
		end
		for i,v in pairs(MainFrame.Creator.ScrollingFrame["1"]:GetChildren()) do
			if v.Name ~= "Top" and v:IsA("ImageLabel") then
				v:SetAttribute("Color", 0)
				v.ImageColor3 = RepColors[0]
			end
		end
		MainFrame.Creator.ScrollingFrame["1"].Top.ImageColor3 = RepColors[0]
		local count = #MainFrame.Creator.ScrollingFrame["1"]:GetChildren() - 3
		if count ~= 20 then
			if count > 20 then
				local diff = count - 20
				for i = 1, diff do
					MainFrame.Creator.ScrollingFrame["1"][#MainFrame.Creator.ScrollingFrame["1"]:GetChildren() - 3]:Destroy()
				end
			elseif count < 20 then
				local diff = 20 - count
				for i = 1, diff do
					local clone = MainFrame.Creator.ScrollingFrame["1"]["1"]:Clone()
					clone.Name = #MainFrame.Creator.ScrollingFrame["1"]:GetChildren() - 2
					clone.LayoutOrder = #MainFrame.Creator.ScrollingFrame["1"]:GetChildren()
					clone.Parent = MainFrame.Creator.ScrollingFrame["1"]
					addbutton(clone, MainFrame.Creator.ScrollingFrame["1"])
				end
			end
		end
		local count = #MainFrame.Creator.PointerHolder.Pointer:GetChildren() - 5
		resetcounters()
		if count ~= 20 then
			if count > 20 then
				local diff = count - 20
				for i = 1, diff do
					MainFrame.Creator.PointerHolder.Pointer[#MainFrame.Creator.PointerHolder.Pointer:GetChildren() - 5]:Destroy()
				end
			elseif count < 20 then
				local diff = 20 - count
				for i = 1, diff do
					local pointer_clone = MainFrame.Creator.PointerHolder.Pointer["2"]:Clone()
					pointer_clone.Name = #MainFrame.Creator.PointerHolder.Pointer:GetChildren() - 4
					pointer_clone.LayoutOrder = #MainFrame.Creator.PointerHolder.Pointer:GetChildren()
					pointer_clone.Parent = MainFrame.Creator.PointerHolder.Pointer
				end
			end
		end
		MainFrame.Creator.PointerHolder.Pointer:SetAttribute("max", 20)
		Exportable = false

		connect1:Disconnect()
		connect2:Disconnect()
	end)

	connect2 = MainFrame.Confirm.No.MouseButton1Click:Connect(function()
		MainFrame.Confirm.Visible = false
		connect1:Disconnect()
		connect2:Disconnect()
	end)
end

resetcounters = function()
	Pause = true
	MainFrame.Creator.PointerHolder.Pointer[MainFrame.Creator.PointerHolder.Pointer:GetAttribute("count")].Pointer.Parent = MainFrame.Creator.PointerHolder.Pointer["1"]
	MainFrame.Creator.PointerHolder.Pointer:SetAttribute("count", 1)
	for i,v in pairs(MainFrame.Creator.ScrollingFrame:GetChildren()) do
		if v:GetAttribute("spacer") then
			v[v:GetAttribute("count")].Pointer.Parent = v["1"]
			v:SetAttribute("count", 1)
		end
	end
end

-- Roblox forces us to use frames within plugins to get userinput
-- Because of this we use the mainframe to get inputs
MainFrame.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.R and Usable then
		reset()
	elseif input.KeyCode == Enum.KeyCode.P and Usable then
		Pause = not Pause
		if Pause then
			MainFrame.Creator.Info.Buttons.Pause.ImageLabel.ImageColor3 = Color3.fromRGB(255, 255, 255)
		else
			MainFrame.Creator.Info.Buttons.Pause.ImageLabel.ImageColor3 = Color3.fromRGB(100, 100, 100)
		end
	elseif input.KeyCode == Enum.KeyCode.Space and Usable then
		spacer()
	elseif input.KeyCode == Enum.KeyCode.One and Usable then
		changecolor(1)
	elseif input.KeyCode == Enum.KeyCode.Two and Usable then
		changecolor(2)
	elseif input.KeyCode == Enum.KeyCode.Three and Usable then
		changecolor(3)
	elseif input.KeyCode == Enum.KeyCode.Four and Usable then
		changecolor(4)
	elseif input.KeyCode == Enum.KeyCode.Five and Usable then
		changecolor(5)
	elseif input.KeyCode == Enum.KeyCode.Six and Usable then
		changecolor(6)
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		MouseDown = true
		Mouse2Down = false
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		Mouse2Down = true
		MouseDown = false
	end
end)

MainFrame.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		MouseDown = false
		Mouse2Down = false
		Starting = nil
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		Mouse2Down = false
		MouseDown = false
		Starting = nil
	end
end)

-- Column button handler
addbutton = function(v: GuiBase2d, frame: GuiBase2d)
	if v.Name ~= "Top" and v:IsA("ImageLabel") then
		v:SetAttribute("Color", 0)
		v.ImageColor3 = RepColors[0]
		local enter

		v.MouseEnter:Connect(function()
			if MouseDown and Starting == nil and Usable then
				Exportable = true
				Starting = frame
				v:SetAttribute("Color", Color)
				v.ImageColor3 = RepColors[Color]
			elseif MouseDown and (Starting == frame or not Locked) and Usable then
				Exportable = true
				v:SetAttribute("Color", Color)
				v.ImageColor3 = RepColors[Color]
			elseif Mouse2Down and Starting == nil and Usable then
				Starting = frame
				v:SetAttribute("Color", 0)
				v.ImageColor3 = RepColors[0]
			elseif Mouse2Down and (Starting == frame or not Locked) and Usable then
				v:SetAttribute("Color", 0)
				v.ImageColor3 = RepColors[0]
			else
				enter = MainFrame.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 and Usable then
						Exportable = true
						Starting = frame
						v:SetAttribute("Color", Color)
						v.ImageColor3 = RepColors[Color]
					elseif input.UserInputType == Enum.UserInputType.MouseButton2 and Usable then
						Starting = frame
						v:SetAttribute("Color", 0)
						v.ImageColor3 = RepColors[0]
					end
				end)
			end
		end)

		v.MouseLeave:Connect(function()
			if enter then
				enter:Disconnect()
				enter = nil
			end
		end)

		local connect = nil

		local function spacerchange()
			if connect then
				connect:Disconnect()
				connect = nil
			end

			local pointer do
				if v.Parent:GetAttribute("pointer") == 0 then
					pointer = MainFrame.Creator.PointerHolder.Pointer
				else
					pointer = MainFrame.Creator.ScrollingFrame[v.Parent:GetAttribute("pointer")]
				end
			end

			connect = pointer:GetAttributeChangedSignal("count"):Connect(function()
				local count = pointer:GetAttribute("count")
				if count == tonumber(v.Name) then
					v.Parent.Top.ImageColor3 = v.ImageColor3
				end
			end)
		end

		v.Parent:GetAttributeChangedSignal("pointer"):Connect(spacerchange)
		spacerchange()

		v.Destroying:Connect(function()
			if connect then
				connect:Disconnect()
				connect = nil
			end
		end)
	end
end

local function registercolumn(column)
	local mypos = column.LayoutOrder
	local highest = 0 -- Index, Value
	for i,v in pairs(MainFrame.Creator.ScrollingFrame:GetChildren()) do
		if v.Name ~= "Last" and v:IsA("Frame") then
			i = tonumber(v.LayoutOrder)

			if i < mypos and v:GetAttribute("spacer") and i > highest then
				highest = i
			end
		end
	end
	column:SetAttribute("pointer", highest)

	local count = #column:GetChildren() - 3
	local pointer do
		if highest == 0 then
			pointer = MainFrame.Creator.PointerHolder.Pointer
		else
			pointer = MainFrame.Creator.ScrollingFrame[highest]
		end
	end

	if count ~= pointer:GetAttribute("max") then
		if count > pointer:GetAttribute("max") then
			local diff = count - pointer:GetAttribute("max")
			for i = 1, diff do
				column[#column:GetChildren() - 3]:Destroy()
			end
		elseif count < pointer:GetAttribute("max") then
			local diff = pointer:GetAttribute("max") - count
			for i = 1, diff do
				local clone = column["1"]:Clone()
				clone.Name = #column:GetChildren() - 2
				clone.LayoutOrder = #column:GetChildren()
				clone.Parent = column
				addbutton(clone, column)
			end
		end
	end

	column.Top:GetPropertyChangedSignal("ImageColor3"):Connect(function()
		local enabled = if column.Top.ImageColor3 == RepColors[0] then false else true
		column.Top.Light.ImageColor3 = column.Top.ImageColor3
		column.Top.Light.Visible = enabled
		column.Top.Light1.ImageColor3 = column.Top.ImageColor3
		column.Top.Light1.Visible = enabled
		column.Top.Light2.ImageColor3 = column.Top.ImageColor3
		column.Top.Light2.Visible = enabled
	end)

	for i,v in pairs(column:GetChildren()) do
		addbutton(v, column)
	end
end

-- Add/remove columns
registercolumn(MainFrame.Creator.ScrollingFrame["1"])
-- for i,v in pairs(MainFrame.Creator.ScrollingFrame["1"]:GetChildren()) do
--     addbutton(v, MainFrame.Creator.ScrollingFrame["1"])
-- end

MainFrame.Creator.ScrollingFrame.Last.Devider.add.MouseButton1Click:Connect(function()
	if not Usable then
		return
	end

	local clone = MainFrame.Creator.ScrollingFrame["1"]:Clone()
	clone.Name = #MainFrame.Creator.ScrollingFrame:GetChildren() - 1
	clone.LayoutOrder = #MainFrame.Creator.ScrollingFrame:GetChildren() - 1
	-- for i,v in pairs(clone:GetChildren()) do
	--     addbutton(v, clone)
	-- end
	clone.Parent = MainFrame.Creator.ScrollingFrame
	registercolumn(clone)
end)

MainFrame.Creator.ScrollingFrame.Last.Devider.subtract.MouseButton1Click:Connect(function()
	if not Usable then
		return
	end

	MainFrame.Confirm.Visible = true
	local number = #MainFrame.Creator.ScrollingFrame:GetChildren() - 2
	MainFrame.Confirm.TextLabel.Text = "Are you sure you want to destroy column <b>".. number .."</b>?"
	local connect1, connect2 = nil, nil

	connect1 = MainFrame.Confirm.Yes.MouseButton1Click:Connect(function()
		MainFrame.Confirm.Visible = false

		MainFrame.Creator.ScrollingFrame["" .. number]:Destroy()

		connect1:Disconnect()
		connect2:Disconnect()
	end)

	connect2 = MainFrame.Confirm.No.MouseButton1Click:Connect(function()
		MainFrame.Confirm.Visible = false
		connect1:Disconnect()
		connect2:Disconnect()
	end)
end)

local function ScrollingFrameChildrenChanged()
	local Desired = Vector2.new(0.005, 0)
	local Desired_Size = Vector2.new(0.066, 1)

	MainFrame:WaitForChild("Creator", 5) -- No comment, just errors without this

	local largest do
		largest = MainFrame.Creator.PointerHolder.Pointer

		for i,v in pairs(MainFrame.Creator.ScrollingFrame:GetChildren()) do
			if v.Name ~= "Last" and v:IsA("Frame") and largest == nil or #largest:GetChildren() < #v:GetChildren() then
				largest = v
			end
		end
	end
	local AbsoluteSize = MainFrame.Creator.ScrollingFrame.AbsoluteSize
	local Padding = Desired * AbsoluteSize
	Padding = UDim2.fromOffset(Padding.X, Padding.Y)
	local Size = Desired_Size * AbsoluteSize
	Size = UDim2.fromOffset(Size.X, Size.Y)
	MainFrame.Creator.ScrollingFrame.UIGridLayout.CellPadding = Padding
	MainFrame.Creator.ScrollingFrame.UIGridLayout.CellSize = Size
	MainFrame.Creator.PointerHolder.UIGridLayout.CellPadding = Padding
	MainFrame.Creator.PointerHolder.UIGridLayout.CellSize = Size
	local y = largest.UIListLayout.AbsoluteContentSize.Y + (largest.UIListLayout.AbsoluteContentSize.Y - GUI.AbsoluteSize.Y)
	MainFrame.Creator.ScrollingFrame.CanvasSize = UDim2.fromOffset(MainFrame.Creator.ScrollingFrame.UIGridLayout.AbsoluteContentSize.X + Padding.X.Offset + Size.X.Offset, y)
	MainFrame.Creator.PointerHolder.CanvasSize = UDim2.fromOffset(0, y)

	local number = #MainFrame.Creator.ScrollingFrame:GetChildren() - 2
	if number > 1 then
		MainFrame.Creator.ScrollingFrame.Last.Devider.subtract.Visible = true
	else
		MainFrame.Creator.ScrollingFrame.Last.Devider.subtract.Visible = false
	end
end
ScrollingFrameChildrenChanged()
MainFrame.Creator.ScrollingFrame.ChildAdded:Connect(ScrollingFrameChildrenChanged)
MainFrame.Creator.ScrollingFrame.ChildRemoved:Connect(ScrollingFrameChildrenChanged)
GUI:GetPropertyChangedSignal("AbsoluteSize"):Connect(ScrollingFrameChildrenChanged)

local function LoadSaveChildrenChange()
	local Desired = Vector2.new(0.0112107623318386, 0.0200803212851406)
	local Desired_Size = Vector2.new(1, 0.125)

	MainFrame:WaitForChild("SaveLoad", 5) -- No comment, just errors without this

	local AbsoluteSize = MainFrame.SaveLoad.ScrollingFrame.AbsoluteSize
	local Padding = Desired * AbsoluteSize
	Padding = UDim2.fromOffset(Padding.X, Padding.Y)
	local Size = Desired_Size * AbsoluteSize
	Size = UDim2.fromOffset(Size.X, Size.Y)
	MainFrame.SaveLoad.ScrollingFrame.UIGridLayout.CellPadding = Padding
	MainFrame.SaveLoad.ScrollingFrame.UIGridLayout.CellSize = Size
	MainFrame.SaveLoad.ScrollingFrame.UIGridLayout.CellPadding = Padding
	MainFrame.SaveLoad.ScrollingFrame.UIGridLayout.CellSize = Size
	MainFrame.SaveLoad.ScrollingFrame.CanvasSize = UDim2.fromOffset(0, MainFrame.SaveLoad.ScrollingFrame.UIGridLayout.AbsoluteContentSize.Y + Padding.Y.Offset + Size.Y.Offset)
end
LoadSaveChildrenChange()
MainFrame.SaveLoad.ScrollingFrame.ChildAdded:Connect(LoadSaveChildrenChange)
MainFrame.SaveLoad.ScrollingFrame.ChildRemoved:Connect(LoadSaveChildrenChange)
GUI:GetPropertyChangedSignal("AbsoluteSize"):Connect(LoadSaveChildrenChange)

local function VisibilityChanged()
	if (
		MainFrame.Confirm.Visible
			or MainFrame.SaveLoad.Visible
			or MainFrame.Export.Visible
			or MainFrame.Controls.Visible
		) then
		Usable = false
	else
		Usable = true
	end
end

MainFrame.Confirm:GetPropertyChangedSignal("Visible"):Connect(VisibilityChanged)
MainFrame.SaveLoad:GetPropertyChangedSignal("Visible"):Connect(VisibilityChanged)
MainFrame.Export:GetPropertyChangedSignal("Visible"):Connect(VisibilityChanged)
MainFrame.Controls:GetPropertyChangedSignal("Visible"):Connect(VisibilityChanged)

-- Add/Remove Rows

local function addrow(pointer: Frame, start: number)
	if not Usable then
		return
	end
	if pointer:GetAttribute("max") == 98 then
		return
	end
	resetcounters()
	-- TBD: Reset all points

	local last do
		for i,v in pairs(MainFrame.Creator.ScrollingFrame:GetChildren()) do
			if v.Name ~= "Last" and v:IsA("Frame") and tonumber(v.Name) >= start and v:GetAttribute("spacer") then
				last = tonumber(v.Name)
				break
			end
		end

		if not last then
			last = 99
		end
	end

	-- Here we have to account for 3 children above and one below
	-- This is why we dont add to the layout order
	local pointer_clone = Pointer["2"]:Clone()
	pointer_clone.Name = #pointer:GetChildren() - 4
	pointer_clone.LayoutOrder = #pointer:GetChildren()
	pointer_clone.Parent = pointer
	pointer:SetAttribute("max", pointer:GetAttribute("max") + 1)
	for i,v in pairs(MainFrame.Creator.ScrollingFrame:GetChildren()) do
		if v.Name ~= "Last" and v:IsA("Frame") and tonumber(v.Name) >= start and tonumber(v.Name) < last then
			local clone = v["1"]:Clone()
			clone.Name = #v:GetChildren() - 2
			clone.LayoutOrder = #v:GetChildren()
			clone.Parent = v
			addbutton(clone, v)
		end
	end
	ScrollingFrameChildrenChanged()
end

local function removerow(pointer: Frame, start: number, skipconfirm)
	if not Usable then
		return
	end
	if pointer:GetAttribute("max") == 3 then
		return
	end
	local last do
		for i,v in pairs(MainFrame.Creator.ScrollingFrame:GetChildren()) do
			if v.Name ~= "Last" and v:IsA("Frame") and tonumber(v.Name) >= start and v:GetAttribute("spacer") then
				last = tonumber(v.Name)
				break
			end
		end

		if not last then
			last = 99
		end
	end
	resetcounters()
	if skipconfirm then
		pointer:SetAttribute("max", pointer:GetAttribute("max") - 1)
		pointer[#pointer:GetChildren() - 5]:Destroy()
		for i,v in pairs(MainFrame.Creator.ScrollingFrame:GetChildren()) do
			if v.Name ~= "Last" and v:IsA("Frame") and tonumber(v.Name) >= start and tonumber(v.Name) < last then
				v[#v:GetChildren() - 3]:Destroy()
			end
		end
		ScrollingFrameChildrenChanged()
		return
	end

	MainFrame.Confirm.Visible = true
	MainFrame.Confirm.TextLabel.Text = "Are you sure you want to destroy the <b>last row</b> on columns <b>".. start .." - ".. last .."</b>?"
	local connect1, connect2 = nil, nil

	connect1 = MainFrame.Confirm.Yes.MouseButton1Click:Connect(function()
		MainFrame.Confirm.Visible = false

		pointer:SetAttribute("max", pointer:GetAttribute("max") - 1)
		pointer[#pointer:GetChildren() - 5]:Destroy()
		for i,v in pairs(MainFrame.Creator.ScrollingFrame:GetChildren()) do
			if v.Name ~= "Last" and v:IsA("Frame") and tonumber(v.Name) >= start and tonumber(v.Name) < last then
				v[#v:GetChildren() - 3]:Destroy()
			end
		end
		ScrollingFrameChildrenChanged()

		connect1:Disconnect()
		connect2:Disconnect()
	end)

	connect2 = MainFrame.Confirm.No.MouseButton1Click:Connect(function()
		MainFrame.Confirm.Visible = false
		connect1:Disconnect()
		connect2:Disconnect()
	end)
end

-- Save/Load

local function SavesUpdate()
	local Saves = plugin:GetSetting("saves")
	if Saves then
		for i,v in pairs(MainFrame.SaveLoad.ScrollingFrame:GetChildren()) do
			if v:IsA("ImageLabel") then
				v:Destroy()
			end
		end

		for i,v in pairs(Saves) do
			local clone = SaveTemplate:Clone()
			clone.Name = i
			clone.TextBox.Text = i
			clone.Parent = MainFrame.SaveLoad.ScrollingFrame

			clone.Delete.MouseButton1Click:Connect(function()
				MainFrame.Confirm.Visible = true
				MainFrame.SaveLoad.Visible = false
				MainFrame.Confirm.TextLabel.Text = "Are you sure you want to delete the save <b>".. i .."</b>? This cannot be undone."
				local connect1, connect2 = nil, nil

				connect1 = MainFrame.Confirm.Yes.MouseButton1Click:Connect(function()
					MainFrame.Confirm.Visible = false
					MainFrame.SaveLoad.Visible = true

					local Saves = plugin:GetSetting("saves")
					Saves[i] = nil
					plugin:SetSetting("saves", Saves)

					connect1:Disconnect()
					connect2:Disconnect()
					SavesUpdate()
				end)

				connect2 = MainFrame.Confirm.No.MouseButton1Click:Connect(function()
					MainFrame.Confirm.Visible = false
					MainFrame.SaveLoad.Visible = true
					connect1:Disconnect()
					connect2:Disconnect()
				end)
			end)

			clone.Overwrite.MouseButton1Click:Connect(function()
				MainFrame.Confirm.Visible = true
				MainFrame.SaveLoad.Visible = false
				MainFrame.Confirm.TextLabel.Text = "Are you sure you want to overwrite the save <b>".. i .."</b>? This cannot be undone."
				local connect1, connect2 = nil, nil

				connect1 = MainFrame.Confirm.Yes.MouseButton1Click:Connect(function()
					MainFrame.Confirm.Visible = false
					MainFrame.SaveLoad.Visible = true

					local Data = {}
					Data.BPM = MainFrame.Creator.Info.BPM.Text
					for i,v in pairs(MainFrame.Creator.ScrollingFrame:GetChildren()) do
						if v.Name ~= "Last" and v:IsA("Frame") then
							Data[v.Name] = {}
							if v:GetAttribute("spacer") then
								Data[v.Name].Spacer = true
								Data[v.Name].BPM = v.Top.TextBox.Text
								Data[v.Name].Size = #v:GetChildren() - 5
							else
								Data[v.Name].Spacer = false
								Data[v.Name].Rows = {}
								for _,row in pairs(v:GetChildren()) do
									if row:IsA("ImageLabel") and row.Name ~= "Top" then
										Data[v.Name].Rows[row.Name] = row:GetAttribute("Color")
									end
								end
							end
						end
					end

					Saves[i] = Data
					plugin:SetSetting("saves", Saves)
					SavesUpdate()

					connect1:Disconnect()
					connect2:Disconnect()
					SavesUpdate()
				end)

				connect2 = MainFrame.Confirm.No.MouseButton1Click:Connect(function()
					MainFrame.Confirm.Visible = false
					MainFrame.SaveLoad.Visible = true
					connect1:Disconnect()
					connect2:Disconnect()
				end)
			end)

			clone.Load.MouseButton1Click:Connect(function()
				MainFrame.Confirm.Visible = true
				MainFrame.SaveLoad.Visible = false
				MainFrame.Confirm.TextLabel.Text = "Are you sure you want to load the save <b>".. i .."</b>? This will remove all current data."
				local connect1, connect2 = nil, nil

				connect1 = MainFrame.Confirm.Yes.MouseButton1Click:Connect(function()
					MainFrame.Confirm.Visible = false
					MainFrame.SaveLoad.Visible = false

					reset(true)
					resetcounters()
					Pause = true
					local Saves = plugin:GetSetting("saves")
					local Data = Saves[i]
					for i,v in pairs(Data) do
						if v.Spacer then
							spacer(v.BPM, v.Size, tonumber(i))
						elseif i == "1" then
							local Count = 0
							for i,v in pairs(v.Rows) do
								Count += 1
							end
							local PointerRows = MainFrame.Creator.PointerHolder.Pointer:GetAttribute("max")
							if Count ~= PointerRows then
								if Count > PointerRows then
									local diff = Count - PointerRows
									for i = 1, diff do
										addrow(MainFrame.Creator.PointerHolder.Pointer, 1)
									end
								elseif Count < PointerRows then
									local diff = PointerRows - Count
									for i = 1, diff do
										removerow(MainFrame.Creator.PointerHolder.Pointer, 1, true)
									end
								end
							end
						end
					end

					for i,v in pairs(Data) do
						if i == "BPM" then
							MainFrame.Creator.Info.BPM.Text = v
						elseif i == "1" then
							local Column = MainFrame.Creator.ScrollingFrame:FindFirstChild("1")
							registercolumn(Column)
							for rownum,row in pairs(v.Rows) do
								Column[rownum]:SetAttribute("Color", row)
								Column[rownum].ImageColor3 = RepColors[row]
							end
						else
							if not v.Spacer then
								local clone = MainFrame.Creator.ScrollingFrame["1"]:Clone()
								clone.Name = tonumber(i)
								clone.LayoutOrder = tonumber(i)
								clone.Parent = MainFrame.Creator.ScrollingFrame
								registercolumn(clone)
								for rownum,row in pairs(v.Rows) do
									clone[rownum]:SetAttribute("Color", row)
									clone[rownum].ImageColor3 = RepColors[row]
								end
							end
						end
					end

					connect1:Disconnect()
					connect2:Disconnect()
					SavesUpdate()
				end)

				connect2 = MainFrame.Confirm.No.MouseButton1Click:Connect(function()
					MainFrame.Confirm.Visible = false
					MainFrame.SaveLoad.Visible = true
					connect1:Disconnect()
					connect2:Disconnect()
				end)
			end)

			clone.TextBox.FocusLost:Connect(function(entered)
				if entered then
					local Saves = plugin:GetSetting("saves")
					local Data = Saves[i]
					Saves[i] = nil
					Saves[clone.TextBox.Text] = Data
					plugin:SetSetting("saves", Saves)
					SavesUpdate()
				end
			end)
		end
	end
end
SavesUpdate()

MainFrame.SaveLoad.Save.MouseButton1Click:Connect(function()
	local Saves = plugin:GetSetting("saves")
	if not Saves then
		Saves = {}
	end
	local Name do
		if MainFrame.SaveLoad.PatternName.Text == "" or MainFrame.SaveLoad.PatternName.Text == nil then
			Name = "Unnamed"
		else
			Name = MainFrame.SaveLoad.PatternName.Text
		end
	end

	local function checkname()
		if Saves[Name] then
			Name = Name.. " (Copy)"
			checkname()
		end
	end
	checkname()

	local Data = {}
	Data.BPM = MainFrame.Creator.Info.BPM.Text
	for i,v in pairs(MainFrame.Creator.ScrollingFrame:GetChildren()) do
		if v.Name ~= "Last" and v:IsA("Frame") then
			Data[v.Name] = {}
			if v:GetAttribute("spacer") then
				Data[v.Name].Spacer = true
				Data[v.Name].BPM = v.Top.TextBox.Text
				Data[v.Name].Size = #v:GetChildren() - 5
			else
				Data[v.Name].Spacer = false
				Data[v.Name].Rows = {}
				for _,row in pairs(v:GetChildren()) do
					if row:IsA("ImageLabel") and row.Name ~= "Top" then
						Data[v.Name].Rows[row.Name] = row:GetAttribute("Color")
					end
				end
			end
		end
	end

	Saves[Name] = Data
	plugin:SetSetting("saves", Saves)
	SavesUpdate()
end)

MainFrame.SaveLoad.Cancel.MouseButton1Click:Connect(function()
	MainFrame.SaveLoad.Visible = false
end)

-- Export
MainFrame.Export.Select.Standard.MouseButton1Click:Connect(function()
	MainFrame.Export.AGDetect.Visible = false
	MainFrame.Export.Complete.Visible = false
	MainFrame.Export.Failed.Visible = false
	MainFrame.Export.InstallPlugin.Visible = false
	MainFrame.Export.Select.Visible = false
	MainFrame.Export.SelectCar.Visible = false
	MainFrame.Export.SelectName.Visible = false
	MainFrame.Export.SelectStage.Visible = false
	for i,v in pairs(MainFrame.Creator.Info:GetChildren()) do
		if v:IsA("GuiBase2d") and v.Name ~= "Title" then
			v.Visible = false
		end
	end

	local connections = {}
	local function cancel()
		MainFrame.Export.Visible = false
		for i,v in pairs(MainFrame.Creator.ScrollingFrame:GetChildren()) do
			if v:FindFirstChild("Top") and v.Top:FindFirstChild("TextBox") and not v:GetAttribute("spacer") then
				v.Top.TextBox:Destroy()
			end
		end
		for i,v in pairs(MainFrame.Creator.Info:GetChildren()) do
			if v:IsA("GuiBase2d") and v.Name ~= "Title" then
				v.Visible = true
			end
		end

		for i,v in pairs(connections) do
			v:Disconnect()
		end

		Usable = true
	end

	MainFrame.Export.Select.Visible = false
	resetcounters()
	for i,v in pairs(MainFrame.Creator.ScrollingFrame:GetChildren()) do
		if v:IsA("Frame") and v.Name ~= "Last" and not v:GetAttribute("spacer") then
			v.Top.ImageColor3 = RepColors[0]
			local TextBox = Instance.new("TextBox")
			TextBox.Size = UDim2.new(1,0,1,0)
			TextBox.AnchorPoint = Vector2.new(0.5,0.5)
			TextBox.Position = UDim2.new(0.5,0,0.5,0)
			TextBox.BackgroundTransparency = 1
			TextBox.ZIndex = 4
			TextBox.Font = Enum.Font.Arial
			TextBox.TextScaled = true
			TextBox.PlaceholderText = "Light".. v.Name
			TextBox.Text = ""
			TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
			TextBox.Parent = v.Top

			connections[v] = TextBox.FocusLost:Connect(function(enterPressed)
				if enterPressed then
					if MainFrame.Creator.ScrollingFrame:FindFirstChild(tonumber(v.Name) + 1) and not MainFrame.Creator.ScrollingFrame[tonumber(v.Name) + 1]:GetAttribute("spacer") then
						MainFrame.Creator.ScrollingFrame[tonumber(v.Name) + 1].Top.TextBox:CaptureFocus()
						game:GetService("RunService").Heartbeat:Wait()
						MainFrame.Creator.ScrollingFrame[tonumber(v.Name) + 1].Top.TextBox.Text = ""
					elseif MainFrame.Creator.ScrollingFrame:FindFirstChild(tonumber(v.Name) + 1) and MainFrame.Creator.ScrollingFrame[tonumber(v.Name) + 1]:GetAttribute("spacer") then
						if MainFrame.Creator.ScrollingFrame:FindFirstChild(tonumber(v.Name) + 2) and not MainFrame.Creator.ScrollingFrame[tonumber(v.Name) + 2]:GetAttribute("spacer") then
							MainFrame.Creator.ScrollingFrame[tonumber(v.Name) + 2].Top.TextBox:CaptureFocus()
							game:GetService("RunService").Heartbeat:Wait()
							MainFrame.Creator.ScrollingFrame[tonumber(v.Name) + 2].Top.TextBox.Text = ""
						end
					end
				end
			end)
		end
	end
	MainFrame.Export.SelectName.Visible = true

	connections.SelectNameDone = MainFrame.Export.SelectName.Done.MouseButton1Click:Connect(function()
		MainFrame.Export.SelectName.Visible = false

		local CurrentPointer = MainFrame.Creator.PointerHolder.Pointer
		local Data = {
			[CurrentPointer] = {}
		}
		for i=1, #MainFrame.Creator.ScrollingFrame:GetChildren() - 2 do
			local v = MainFrame.Creator.ScrollingFrame[i]
			if v:GetAttribute("spacer") and tonumber(v.Top.TextBox.Text) ~= tonumber(MainFrame.Creator.Info.BPM) then
				CurrentPointer = v
				Data[CurrentPointer] = {}
			elseif v:GetAttribute("spacer") then
				CurrentPointer = MainFrame.Creator.PointerHolder.Pointer
			else
				Data[CurrentPointer][i] = {
					LightName = if v.Top.TextBox.Text == nil or v.Top.TextBox.Text == "" then v.Top.TextBox.PlaceholderText else v.Top.TextBox.Text,
					Rows = {}
				}
				for _,row in pairs(v:GetChildren()) do
					if row:IsA("ImageLabel") and row.Name ~= "Top" then
						Data[CurrentPointer][i].Rows[tonumber(row.Name)] = row:GetAttribute("Color")
					end
				end
				v.Top.TextBox:Destroy()
			end
		end

		local Model = Instance.new("Model")
		Model.Name = "Emergency Vehicle Creator Export"
		for pointer,value in pairs(Data) do
			local NewScript = Instance.new("Script")
			local BPM
			if pointer == MainFrame.Creator.PointerHolder.Pointer then
				NewScript.Name = "Controller1"
				BPM = MainFrame.Creator.Info.BPM.Text
			else
				NewScript.Name = "Controller".. pointer.Name
				BPM = pointer.Top.TextBox.Text
			end
			local Code = "local WaitTime = ".. BPM .."\n".. Standard_Script_Template
			local TableLength = Functions.tablevaluelen(value)
			local LastInTable = TableLength
			local FirstInTable = TableLength - (Functions.tablelen(value) - 1)

			local Length = 0
			for _,column in pairs(value) do
				if #column.Rows > Length then
					Length = #column.Rows
				end
			end

			for light=1, Length do
				for i=FirstInTable, LastInTable do
					Code ..= "	light(\"".. value[i].LightName .."\", ".. value[i].Rows[light] ..")\n"
				end
				Code ..= "	wait(WaitTime)\n"
			end
			Code ..= "end\n\n-- This code was automatically generated by Emergency Vehicle Creator"
			NewScript.Source = Code
			NewScript.Parent = Model

			for i=FirstInTable, LastInTable do
				local part = Instance.new("Part")
				part.Parent = Model
				part.Name = value[i].LightName
				part.TopSurface = Enum.SurfaceType.Smooth
				part.BottomSurface = Enum.SurfaceType.Smooth
				part.Material = Enum.Material.Neon
				part.BrickColor = BrickColor.new("Institutional white")
				part.Anchored = true
				part.CanCollide = false
				part.Size = Vector3.new(0.75, 0.3, 0.1)
				part.Position = Vector3.new((0.75 * i) + (0.1 * i), 10, 0)
			end
		end
		Model.Parent = workspace
		Selection:Set({Model})

		for i,v in pairs(MainFrame.Creator.Info:GetChildren()) do
			if v:IsA("GuiBase2d") and v.Name ~= "Title" then
				v.Visible = true
			end
		end
		Usable = true
	end)

	connections.SelectNameCancel = MainFrame.Export.SelectName.Cancel.MouseButton1Click:Connect(function()
		MainFrame.Export.SelectName.Visible = false
		cancel()
	end)
end)

MainFrame.Export.Select.Plugin.MouseButton1Click:Connect(function()
	MainFrame.Export.AGDetect.Visible = false
	MainFrame.Export.Complete.Visible = false
	MainFrame.Export.Failed.Visible = false
	MainFrame.Export.InstallPlugin.Visible = false
	MainFrame.Export.Select.Visible = false
	MainFrame.Export.SelectCar.Visible = false
	MainFrame.Export.SelectName.Visible = false
	MainFrame.Export.SelectStage.Visible = false
	for i,v in pairs(MainFrame.Creator.Info:GetChildren()) do
		if v:IsA("GuiBase2d") and v.Name ~= "Title" then
			v.Visible = false
		end
	end

	local connections = {}
	local function cancel()
		MainFrame.Export.Visible = false
		for i,v in pairs(MainFrame.Creator.ScrollingFrame:GetChildren()) do
			if v:FindFirstChild("Top") and v.Top:FindFirstChild("TextBox") and not v:GetAttribute("spacer") then
				v.Top.TextBox:Destroy()
			end
		end
		for i,v in pairs(MainFrame.Creator.Info:GetChildren()) do
			if v:IsA("GuiBase2d") and v.Name ~= "Title" then
				v.Visible = true
			end
		end

		for i,v in pairs(connections) do
			v:Disconnect()
		end

		Usable = true
	end

	MainFrame.Export.Select.Visible = false
	resetcounters()
	for i,v in pairs(MainFrame.Creator.ScrollingFrame:GetChildren()) do
		if v:IsA("Frame") and v.Name ~= "Last" and not v:GetAttribute("spacer") then
			v.Top.ImageColor3 = RepColors[0]
			local TextBox = Instance.new("TextBox")
			TextBox.Size = UDim2.new(1,0,1,0)
			TextBox.AnchorPoint = Vector2.new(0.5,0.5)
			TextBox.Position = UDim2.new(0.5,0,0.5,0)
			TextBox.BackgroundTransparency = 1
			TextBox.ZIndex = 4
			TextBox.Font = Enum.Font.Arial
			TextBox.TextScaled = true
			TextBox.PlaceholderText = "Light".. v.Name
			TextBox.Text = ""
			TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
			TextBox.Parent = v.Top

			connections[v] = TextBox.FocusLost:Connect(function(enterPressed)
				if enterPressed then
					if MainFrame.Creator.ScrollingFrame:FindFirstChild(tonumber(v.Name) + 1) and not MainFrame.Creator.ScrollingFrame[tonumber(v.Name) + 1]:GetAttribute("spacer") then
						MainFrame.Creator.ScrollingFrame[tonumber(v.Name) + 1].Top.TextBox:CaptureFocus()
						game:GetService("RunService").Heartbeat:Wait()
						MainFrame.Creator.ScrollingFrame[tonumber(v.Name) + 1].Top.TextBox.Text = ""
					elseif MainFrame.Creator.ScrollingFrame:FindFirstChild(tonumber(v.Name) + 1) and MainFrame.Creator.ScrollingFrame[tonumber(v.Name) + 1]:GetAttribute("spacer") then
						if MainFrame.Creator.ScrollingFrame:FindFirstChild(tonumber(v.Name) + 2) and not MainFrame.Creator.ScrollingFrame[tonumber(v.Name) + 2]:GetAttribute("spacer") then
							MainFrame.Creator.ScrollingFrame[tonumber(v.Name) + 2].Top.TextBox:CaptureFocus()
							game:GetService("RunService").Heartbeat:Wait()
							MainFrame.Creator.ScrollingFrame[tonumber(v.Name) + 2].Top.TextBox.Text = ""
						end
					end
				end
			end)
		end
	end
	MainFrame.Export.SelectName.Visible = true

	local function installLights(Selection: Model, AG: boolean?)
		local SelectStage = MainFrame.Export.SelectStage
		local Settings, Lightbar
		if AG then
			Settings = require(Selection.Body.ELS.PTRNS.Settings)
			Lightbar = Selection.Body.ELS
		else
			Settings = require(Selection["A-Chassis Tune"].Plugins.EVCPlugin_Client.EVCRemote.Settings)
			Lightbar = Selection.Body[Settings.LightbarLocation]
		end
		if Lightbar and Lightbar:FindFirstChild("ModuleStore") then else
			MainFrame.Export.Failed.Visible = true
			MainFrame.Export.Failed.TextLabel.Text = "Unable to find ModuleStore. Canceling export."
			task.wait(5)
			MainFrame.Export.Failed.TextLabel.Text = "The model you selected was not a valid A-Chassis or AG-Chassis car. Canceling export."
			MainFrame.Export.Failed.Visible = false
			cancel()
			return
		end

		local function finalInstall(Stage: Folder)
			local CurrentPointer = MainFrame.Creator.PointerHolder.Pointer
			local Data = {
				[CurrentPointer] = {}
			}
			for i=1, #MainFrame.Creator.ScrollingFrame:GetChildren() - 2 do
				local v = MainFrame.Creator.ScrollingFrame[i]
				if v:GetAttribute("spacer") and tonumber(v.Top.TextBox.Text) ~= tonumber(MainFrame.Creator.Info.BPM) then
					CurrentPointer = v
					Data[CurrentPointer] = {}
				elseif v:GetAttribute("spacer") then
					CurrentPointer = MainFrame.Creator.PointerHolder.Pointer
				else
					Data[CurrentPointer][i] = {
						LightName = if v.Top.TextBox.Text == nil or v.Top.TextBox.Text == "" then v.Top.TextBox.PlaceholderText else v.Top.TextBox.Text,
						Rows = {}
					}
					for _,row in pairs(v:GetChildren()) do
						if row:IsA("ImageLabel") and row.Name ~= "Top" then
							Data[CurrentPointer][i].Rows[tonumber(row.Name)] = row:GetAttribute("Color")
						end
					end
					v.Top.TextBox:Destroy()
				end
			end
			
			for pointer,value in pairs(Data) do
				local Module = script.Parent.ChassisPlugin.Template:Clone()
				Module.Name = "EVCExport|".. DateTime:now():FormatLocalTime("lll", "en-US") .. "|" .. if pointer == MainFrame.Creator.PointerHolder.Pointer then "1" else pointer.Name
				local BPM = if pointer == MainFrame.Creator.PointerHolder.Pointer then MainFrame.Creator.Info.BPM.Text else pointer.Top.TextBox.Text

				local LightsString = ""
				local TableLength = Functions.tablevaluelen(value)
				-- for i=First Value In Table, Last Value In Table do
				for i=TableLength-(Functions.tablelen(value)-1), TableLength do
					local v = value[i]
					LightsString = LightsString .. "\n\t[\"" .. v.LightName .. "\"] = {\n\t\t"
					for _,row in pairs(v.Rows) do
						LightsString = LightsString .. row .. ","
					end
					LightsString = LightsString .. "\n\t},"
				end

				local Source = Module.Source
				Source = string.gsub(Source, "WaitTime = 0.1,", "WaitTime = ".. BPM ..",")
				Source = string.gsub(Source, "Lights = {}", "Lights = {".. LightsString .."\n}")
				if string.find(Stage.Name, "TA") then
					Source = string.gsub(Source, "Weight = 1,", "Weight = 2,")
				end
				Module.Source = Source
				Module.Parent = Stage
			end
			cancel()
		end

		local function clearStages()
			for i,v in pairs(SelectStage.ScrollingFrame:GetChildren()) do
				if v:IsA("ImageLabel") then
					v:Destroy()
				end
			end
		end
		
		local stageConnections = {}
		local function selectStage(Stage: boolean)

			local function loadStage(StageFolder: Folder)
				for i,v in pairs(StageFolder:GetChildren()) do
					local Template = StageTemplate:Clone()
					Template.Name = v.Name
					Template.TextBox.Text = v.Name
					Template.Parent = SelectStage.ScrollingFrame
					Template.Visible = true

					connections[v.Name.. "Add"] = Template.Add.MouseButton1Click:Connect(function()
						SelectStage.Visible = false
						finalInstall(StageFolder[v.Name])
					end)

					connections[v.Name.. "Overwrite"] = Template.Overwrite.MouseButton1Click:Connect(function()
						SelectStage.Visible = false
						MainFrame.Confirm.Visible = true
						MainFrame.Confirm.TextLabel.Text = "Are you sure you want to overwrite stage ".. v.Name .."? <b>All patterns will be lost!</b>"
						MainFrame.Confirm.Yes.MouseButton1Click:Connect(function()
							MainFrame.Confirm.TextLabel.Text = "Are you sure you want to reset? <b>Any unsaved progress will be lost!</b>"
							MainFrame.Confirm.Visible = false
							for i,v in pairs(v:GetChildren()) do
								if v:IsA("ModuleScript") then
									v:Destroy()
								end
							end
							finalInstall(StageFolder[v.Name])
						end)
						MainFrame.Confirm.No.MouseButton1Click:Connect(function()
							MainFrame.Confirm.TextLabel.Text = "Are you sure you want to reset? <b>Any unsaved progress will be lost!</b>"
							MainFrame.Confirm.Visible = false
							SelectStage.Visible = true
						end)
					end)

					connections[v.Name.. "Delete"] = Template.Delete.MouseButton1Click:Connect(function()
						SelectStage.Visible = false
						MainFrame.Confirm.Visible = true
						MainFrame.Confirm.TextLabel.Text = "Are you sure you want to delete this stage ".. v.Name .."?"
						MainFrame.Confirm.Yes.MouseButton1Click:Connect(function()
							MainFrame.Confirm.TextLabel.Text = "Are you sure you want to reset? <b>Any unsaved progress will be lost!</b>"
							MainFrame.Confirm.Visible = false
							SelectStage.Visible = true
							v:Destroy()
							selectStage(Stage)
						end)
						MainFrame.Confirm.No.MouseButton1Click:Connect(function()
							MainFrame.Confirm.TextLabel.Text = "Are you sure you want to reset? <b>Any unsaved progress will be lost!</b>"
							MainFrame.Confirm.Visible = false
							SelectStage.Visible = true
						end)
					end)
				end

				for i,v in pairs(stageConnections) do
					v:Disconnect()
				end

				if AG then
					SelectStage.PatternName.Visible = false
					SelectStage.Save.Visible = false
				else
					SelectStage.PatternName.Visible = true
					SelectStage.Save.Visible = true
					-- Have to run on Up otherwise it will create a random folder in the "Stage" folder
					connections.SaveStage = SelectStage.Save.MouseButton1Up:Connect(function()
						if SelectStage.PatternName.Text ~= "" and tonumber(SelectStage.PatternName.Text) then
							local NewFolder = Instance.new("Folder")
							local Name = if Stage then "Stage" else "TA"
							NewFolder.Name = Name .. tonumber(SelectStage.PatternName.Text)
							NewFolder.Parent = StageFolder
							SelectStage.PatternName.Text = ""
							selectStage(Stage)
						end
					end)
				end
			end
			if Stage then
				clearStages()
				SelectStage.Stage.TextColor3 = Color3.fromRGB(255, 255, 255)
				SelectStage.TrafficAdvisor.TextColor3 = Color3.fromRGB(200, 200, 200)
				loadStage(Lightbar.ModuleStore.Stages)
			else
				clearStages()
				SelectStage.Stage.TextColor3 = Color3.fromRGB(200, 200, 200)
				SelectStage.TrafficAdvisor.TextColor3 = Color3.fromRGB(255, 255, 255)
				loadStage(Lightbar.ModuleStore.Traffic_Advisor)
			end
		end
		selectStage(true)

		connections.StageOption = SelectStage.Stage.MouseButton1Click:Connect(function()
			selectStage(true)
		end)

		connections.TAOption = SelectStage.TrafficAdvisor.MouseButton1Click:Connect(function()
			selectStage(false)
		end)
		

		SelectStage.Visible = true
	end

	local function normalInstall(Selection: Model, AGInstall: boolean?)
		if AGInstall then
			if Selection.Body:FindFirstChild("ELS") and Selection.Body.ELS:FindFirstChild("PTRNS") and Selection.Body.ELS.PTRNS:FindFirstChild("EVCPlugin_AG") then
				installLights(Selection, true)
			else
				MainFrame.Export.AGDetect.Visible = true
				connections.AGDetectDone = MainFrame.Export.AGDetect.Done.MouseButton1Click:Connect(function()
					-- ELS
					if not Selection.Body:FindFirstChild("ELS") then
						local ELS = Instance.new("Folder")
						ELS.Name = "ELS"
						ELS.Parent = Selection.Body
						-- ModuleStore
						local ModuleStore = Instance.new("Folder")
						ModuleStore.Name = "ModuleStore"
						ModuleStore.Parent = ELS
						local Stages = Instance.new("Folder")
						Stages.Name = "Stages"
						Stages.Parent = ModuleStore
						local Traffic_Advisor = Instance.new("Folder")
						Traffic_Advisor.Name = "Traffic_Advisor"
						Traffic_Advisor.Parent = ModuleStore
						for i=1, 5 do
							local Stage = Instance.new("Folder")
							Stage.Name = "Stage" .. i
							Stage.Parent = Stages
						end
						for i=1, 5 do
							local Stage = Instance.new("Folder")
							Stage.Name = "TA" .. i
							Stage.Parent = Traffic_Advisor
						end
						-- PTRNS
						local PTRNS = Instance.new("Folder")
						PTRNS.Name = "PTRNS"
						PTRNS.Parent = ELS
						local ELSRunning = Instance.new("BoolValue")
						ELSRunning.Name = "ELSRunning"
						ELSRunning.Value = false
						ELSRunning.Parent = PTRNS
						local PatternNumber = Instance.new("IntValue")
						PatternNumber.Name = "PatternNumber"
						PatternNumber.Value = 0
						PatternNumber.Parent = PTRNS
						local TARunning = Instance.new("BoolValue")
						TARunning.Name = "TARunning"
						TARunning.Value = false
						TARunning.Parent = PTRNS
						local TAPatternNumber = Instance.new("IntValue")
						TAPatternNumber.Name = "TAPatternNumber"
						TAPatternNumber.Value = 0
						TAPatternNumber.Parent = PTRNS
						-- Colors
						local Colors = Instance.new("Folder")
						Colors.Name = "Colors"
						Colors.Parent = ELS
						local blue = Instance.new("Color3Value")
						blue.Name = "blue"
						blue.Value = Color3.fromRGB(47, 71, 255)
						blue.Parent = Colors
						local red = Instance.new("Color3Value")
						red.Name = "red"
						red.Value = Color3.fromRGB(185, 58, 60)
						red.Parent = Colors
						local yellow = Instance.new("Color3Value")
						yellow.Name = "yellow"
						yellow.Value = Color3.fromRGB(253, 194, 66)
						yellow.Parent = Colors
					else
						if not Selection.Body.ELS:FindFirstChild("ModuleStore") then
							local ModuleStore = Instance.new("Folder")
							ModuleStore.Name = "ModuleStore"
							ModuleStore.Parent = Selection.Body.ELS
							local Stages = Instance.new("Folder")
							Stages.Name = "Stages"
							Stages.Parent = ModuleStore
							local Traffic_Advisor = Instance.new("Folder")
							Traffic_Advisor.Name = "Traffic_Advisor"
							Traffic_Advisor.Parent = ModuleStore
							for i=1, 5 do
								local Stage = Instance.new("Folder")
								Stage.Name = "Stage" .. i
								Stage.Parent = Stages
							end
							for i=1, 5 do
								local Stage = Instance.new("Folder")
								Stage.Name = "TA" .. i
								Stage.Parent = Traffic_Advisor
							end
						end
					end
					-- ELS.PTRNS
					local Server = script.Parent.ChassisPlugin.EVCPlugin_AG:Clone()
					Server.Parent = Selection.Body.ELS.PTRNS
					Server.Enabled = true
					local Settings = script.Parent.ChassisPlugin.Settings:Clone()
					Settings.Parent = Selection.Body.ELS.PTRNS

					MainFrame.Export.AGDetect.Visible = false
					installLights(Selection, true)
				end)

				connections.AGDetectCancel = MainFrame.Export.AGDetect.Cancel.MouseButton1Click:Connect(function()
					MainFrame.Export.AGDetect.Visible = false
					normalInstall(Selection)
				end)
			end
		else
			if Selection["A-Chassis Tune"].Plugins:FindFirstChild("EVCPlugin_Client") then
				installLights(Selection)
			else
				MainFrame.Export.InstallPlugin.Visible = true
				MainFrame.Export.InstallPlugin.Done.MouseButton1Click:Connect(function()
					local Client = script.Parent.ChassisPlugin.EVCPlugin_Client:Clone()
					Client.Parent = Selection["A-Chassis Tune"].Plugins
					Client.Enabled = true
					local RemoteEvent = Instance.new("RemoteEvent")
					RemoteEvent.Name = "EVCRemote"
					RemoteEvent.Parent = Client
					local Server = script.Parent.ChassisPlugin.EVCPlugin:Clone()
					Server.Parent = RemoteEvent
					Server.Enabled = false
					local Settings = script.Parent.ChassisPlugin.Settings:Clone()
					Settings.Parent = RemoteEvent
					-- Lightbar
					if not Selection.Body:FindFirstChild("Lightbar") then
						local Lightbar = Instance.new("Model")
						Lightbar.Name = "Lightbar"
						Lightbar.Parent = Selection.Body
						local ModuleStore = Instance.new("Folder")
						ModuleStore.Name = "ModuleStore"
						ModuleStore.Parent = Selection.Body.Lightbar
						local Stages = Instance.new("Folder")
						Stages.Name = "Stages"
						Stages.Parent = ModuleStore
						local Traffic_Advisor = Instance.new("Folder")
						Traffic_Advisor.Name = "Traffic_Advisor"
						Traffic_Advisor.Parent = ModuleStore
					else
						if not Selection.Body.Lightbar:FindFirstChild("ModuleStore") then
							local ModuleStore = Instance.new("Folder")
							ModuleStore.Name = "ModuleStore"
							ModuleStore.Parent = Selection.Body.Lightbar
							local Stages = Instance.new("Folder")
							Stages.Name = "Stages"
							Stages.Parent = ModuleStore
							local Traffic_Advisor = Instance.new("Folder")
							Traffic_Advisor.Name = "Traffic_Advisor"
							Traffic_Advisor.Parent = ModuleStore
						end
					end
	
					MainFrame.Export.InstallPlugin.Visible = false
					installLights(Selection)
				end)
	
				MainFrame.Export.InstallPlugin.Cancel.MouseButton1Click:Connect(function()
					MainFrame.Export.InstallPlugin.Visible = false
					cancel()
				end)
			end
		end
	end

	connections.SelectNameDone = MainFrame.Export.SelectName.Done.MouseButton1Click:Connect(function()
		MainFrame.Export.SelectName.Visible = false
		
		if game:GetService("Selection"):Get()[1] then
			MainFrame.Export.SelectCar.Car.Text = "Selecting: ".. game:GetService("Selection"):Get()[1].Name
		else
			MainFrame.Export.SelectCar.Car.Text = "Selecting: None"
		end
		connections.SelectionChanged = game:GetService("Selection").SelectionChanged:Connect(function()
			if game:GetService("Selection"):Get()[1] then
				MainFrame.Export.SelectCar.Car.Text = "Selecting: ".. game:GetService("Selection"):Get()[1].Name
			else
				MainFrame.Export.SelectCar.Car.Text = "Selecting: None"
			end
		end)
		MainFrame.Export.SelectCar.Visible = true

		connections.SelectCarDone = MainFrame.Export.SelectCar.Done.MouseButton1Click:Connect(function()
			local Selection = game:GetService("Selection"):Get()[1]
			MainFrame.Export.SelectCar.Visible = false
			if (
				Selection:FindFirstChild("A-Chassis Tune")
				and Selection:FindFirstChild("DriveSeat")
				and Selection:FindFirstChild("Body")
				and Selection:IsA("Model")
			) then
				if Selection:FindFirstChild("A-Chassis Tune") and Selection["A-Chassis Tune"]:FindFirstChild("AG-Chassis [Loader]") then
					normalInstall(Selection, true)
				else
					normalInstall(Selection)
				end
			else
				MainFrame.Export.Failed.Visible = true
				MainFrame.Export.Failed.TextLabel.Text = "The model you selected was not a valid A-Chassis or AG-Chassis car. Canceling export."
				task.wait(5)
				MainFrame.Export.Failed.Visible = false
				cancel()
			end
		end)

		connections.SelectCarCancel = MainFrame.Export.SelectCar.Cancel.MouseButton1Click:Connect(function()
			MainFrame.Export.SelectCar.Visible = false
			cancel()
		end)
	end)

	connections.SelectNameCancel = MainFrame.Export.SelectName.Cancel.MouseButton1Click:Connect(function()
		MainFrame.Export.SelectName.Visible = false
		cancel()
	end)
end)

-- Buttons
for i,v in pairs(MainFrame.Creator.Info.Buttons:GetChildren()) do
	if table.find(ButColors, v.Name) then
		v.MouseButton1Click:Connect(function()
			changecolor(table.find(ButColors, v.Name))
		end)
	end
end

MainFrame.Creator.Info.Buttons.Reset.MouseButton1Click:Connect(function()
	if not Usable then
		return
	end
	reset()
end)

MainFrame.Creator.Info.Buttons.Lock.MouseButton1Click:Connect(function()
	if not Usable then
		return
	end
	if Locked then
		Locked = false
		MainFrame.Creator.Info.Buttons.Lock.ImageLabel.ImageColor3 = Color3.fromRGB(100, 100, 100)
	else
		Locked = true
		MainFrame.Creator.Info.Buttons.Lock.ImageLabel.ImageColor3 = Color3.fromRGB(255, 255, 255)
	end
end)

MainFrame.Creator.Info.Save.MouseButton1Click:Connect(function()
	if not Usable and MainFrame.SaveLoad.Visible == false then
		return
	end
	MainFrame.SaveLoad.Visible = not MainFrame.SaveLoad.Visible
end)

MainFrame.Creator.Info.Export.MouseButton1Click:Connect(function()
	for i,v in pairs(MainFrame.Creator.ScrollingFrame:GetChildren()) do
		if v:FindFirstChild("Top") and v.Top:FindFirstChild("TextBox") and not v:GetAttribute("spacer") then
			v.Top.TextBox:Destroy()
		end
	end
	for i,v in pairs(MainFrame.Creator.Info:GetChildren()) do
		if v:IsA("GuiBase2d") and v.Name ~= "Title" then
			v.Visible = true
		end
	end

	Usable = true
	if not Usable and MainFrame.Export.Visible == false then
		return
	end
	MainFrame.Export.Visible = not MainFrame.Export.Visible
	MainFrame.Export.Select.Visible = true
	MainFrame.Export.SelectName.Visible = false
	MainFrame.Export.Complete.Visible = false
end)

MainFrame.Creator.Info.Buttons.Pause.MouseButton1Click:Connect(function()
	Pause = not Pause
	if Pause then
		MainFrame.Creator.Info.Buttons.Pause.ImageLabel.ImageColor3 = Color3.fromRGB(255, 255, 255)
	else
		MainFrame.Creator.Info.Buttons.Pause.ImageLabel.ImageColor3 = Color3.fromRGB(100, 100, 100)
	end
end)

MainFrame.Creator.Info.Controls.MouseButton1Click:Connect(function()
	if not Usable and MainFrame.Controls.Visible == false then
		return
	end
	MainFrame.Controls.Visible = not MainFrame.Controls.Visible
end)

Button.Click:Connect(function()
	GUI.Enabled = not GUI.Enabled
end)

GUI:GetPropertyChangedSignal("Enabled"):Connect(function()
	Button:SetActive(GUI.Enabled)
	Pause = true
end)

local function update(coro: table, pointer: GuiBase2d, waittime: TextBox)
	local point = pointer["1"].Pointer
	local main do
		if pointer.Parent == MainFrame.Creator.PointerHolder then
			main = true
		else
			main = false
		end
	end

	waittime.Focused:Connect(function()
		Pause = true
		resetcounters()
	end)

	waittime.FocusLost:Connect(function()
		if tonumber(waittime.Text) >= 0.001 and tonumber(waittime.Text) <= 10 then
			Pause = false
			resetcounters()
		elseif tonumber(waittime.Text) < 0.001 then
			waittime.Text = "0.001"
			Pause = false
			resetcounters()
		elseif tonumber(waittime.Text) > 10 then
			waittime.Text = "10"
			Pause = false
			resetcounters()
		end
	end)

	pointer.Destroying:Connect(function()
		coro["run"] = false
	end)

	if not main then
		MainFrame.Creator.PointerHolder.Pointer:GetAttributeChangedSignal("count"):Connect(function()
			if tonumber(waittime.Text) == tonumber(MainFrame.Creator.Info.BPM.Text) and coro["run"] then
				local lastcount = pointer:GetAttribute("count")
				if lastcount == pointer:GetAttribute("max") then
					pointer:SetAttribute("count", 1)
				else
					pointer:SetAttribute("count", lastcount + 1)
				end

				point.Parent = pointer[pointer:GetAttribute("count")]
			end
		end)
	end

	while task.wait(tonumber(waittime.Text)) do
		if coro["run"] and not Pause and (main or tonumber(waittime.Text) ~= tonumber(MainFrame.Creator.Info.BPM.Text)) then
			local lastcount = pointer:GetAttribute("count")
			if lastcount == pointer:GetAttribute("max") then
				pointer:SetAttribute("count", 1)
			else
				pointer:SetAttribute("count", lastcount + 1)
			end

			point.Parent = pointer[pointer:GetAttribute("count")]
		elseif coro["run"] == false then
			break
		end
	end

	table.remove(coros, table.find(coros, coro))
end

spacer = function(waittime, size, position)
	local clone = Pointer:Clone()
	clone.Name = #MainFrame.Creator.ScrollingFrame:GetChildren() - 1
	clone.LayoutOrder = #MainFrame.Creator.ScrollingFrame:GetChildren() - 1
	clone:SetAttribute("spacer", true)
	clone.Top.TextBox.Text = MainFrame.Creator.Info.BPM.Text
	if position then
		clone.Name = position
		clone.LayoutOrder = position
	end
	if waittime then
		clone.Top.TextBox.Text = waittime
	end
	if size then
		local clonerows = #clone:GetChildren() - 5
		if size ~= clonerows then
			if size > clonerows then
				local diff = size - clonerows
				for i = 1, diff do
					addrow(clone, tonumber(clone.Name + 1))
				end
			elseif size < clonerows then
				local diff = clonerows - size
				for i = 1, diff do
					removerow(clone, tonumber(clone.Name + 1), true)
				end
			end
		end
	end

	clone.Bottom.add.MouseButton1Click:Connect(function()
		Pause = true
		addrow(clone, tonumber(clone.Name + 1))
	end)
	clone.Bottom.subtract.MouseButton1Click:Connect(function()
		Pause = true
		removerow(clone, tonumber(clone.Name + 1))
	end)

	coros[Functions.tablelen(coros) + 1] = {
		pointer = clone,
		waittime = clone.Top.TextBox,
		run = true,
		thread = coroutine.create(update)
	}
	coroutine.resume(coros[Functions.tablelen(coros)].thread, coros[Functions.tablelen(coros)], clone, clone.Top.TextBox)
	clone.Destroying:Connect(function()
		coros[Functions.tablelen(coros)]["run"] = false
		coroutine.close(coros[Functions.tablelen(coros)].thread)
	end)

	clone.Parent = MainFrame.Creator.ScrollingFrame
end

coros[0] = {
	pointer = MainFrame.Creator.PointerHolder.Pointer,
	waittime = MainFrame.Creator.Info.BPM,
	run = true,
	thread = coroutine.create(update)
}
coroutine.resume(coros[0].thread, coros[0], coros[0].pointer, coros[0].waittime)

MainFrame.Creator.PointerHolder.Pointer.Bottom.add.MouseButton1Click:Connect(function()
	Pause = true
	addrow(MainFrame.Creator.PointerHolder.Pointer, 1)
end)
MainFrame.Creator.PointerHolder.Pointer.Bottom.subtract.MouseButton1Click:Connect(function()
	Pause = true
	removerow(MainFrame.Creator.PointerHolder.Pointer, 1)
end)