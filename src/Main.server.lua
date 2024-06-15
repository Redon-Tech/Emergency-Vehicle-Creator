--[[
Redon Tech 2023-2024
EVC V2
--]]
if not game:GetService("RunService"):IsEdit() then return end
--------------------------------------------------------------------------------
-- Init --
--------------------------------------------------------------------------------

local Is_RBXM = plugin.Name:find(".rbxm") ~= nil
local HttpService = game:GetService("HttpService")
local pluginRoot = script.Parent.Parent
local pluginValue = Instance.new("ObjectValue")
pluginValue.Name = "Plugin"
pluginValue.Value = plugin
pluginValue.Parent = pluginRoot

local function getName(name: string)
	if Is_RBXM then
		name ..= " (RBXM)"
	end
	return name
end

local Plugin_Version = "2.1.0"
local Plugin_Name = getName("Emergency Vehicle Creator V2")
local Plugin_Description = "Easily create amazing ELS for emergency vehicles!"
local Plugin_Icon = "http://www.roblox.com/asset/?id=9953243250"
local Widget_Name = getName("EVC V2")
local Button_Name = getName("EVC Menu V2")
local Packages = pluginRoot:WaitForChild("packages")
local Components = script.Parent:WaitForChild("Components")
local Modules = script.Parent:WaitForChild("Modules")
local Utils = script.Parent:WaitForChild("Utils")


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
-- UI Setup --
--------------------------------------------------------------------------------

local Config = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 1280, 720)
local GUI = plugin:CreateDockWidgetPluginGui(Widget_Name, Config)
GUI.Title = Plugin_Name
GUI.Name = Widget_Name
Button:SetActive(GUI.Enabled)


GUI:GetPropertyChangedSignal("Enabled"):Connect(function()
	Button:SetActive(GUI.Enabled)
end)

local Container = require(Components.container)()
Container.Parent = GUI
Container:WaitForChild("TopBar"):WaitForChild("Title").Text = Plugin_Name
Container:WaitForChild("Content")
local ContainerObjectValue = Instance.new("ObjectValue")
ContainerObjectValue.Name = "Container"
ContainerObjectValue.Value = Container
ContainerObjectValue.Parent = pluginRoot

local versionWarning = Container.VersionWarning

--------------------------------------------------------------------------------
-- Plugin Functions --
--------------------------------------------------------------------------------

-- Containers
local containers = {}
containers["elsCreator"] = require(Modules.elsCreator)
containers["elsCreator"].topBarButton.TextButton.Parent = Container.TopBar.CenterContainer
containers["rotators"] = require(Modules.rotators)
containers["rotators"].topBarButton.TextButton.Parent = Container.TopBar.CenterContainer
containers["faders"] = require(Modules.faders)
containers["faders"].topBarButton.TextButton.Parent = Container.TopBar.CenterContainer

containers["export"] = require(Modules.export)
containers["export"].topBarButton.TextButton.Parent = Container.TopBar.RightContainer
containers["export"].modules = containers
containers["loadSave"] = require(Modules.loadSave)
containers["loadSave"].topBarButton.TextButton.Parent = Container.TopBar.RightContainer
containers["loadSave"].modules = containers

local function hideContainers()
	for i,v in pairs(containers) do
		v.StopDisplay()
		v.topBarButton.setEnabled(false)
	end
end

local function enableContainer(container: table)
	hideContainers()
	container.Display(Container.Content)
	container.topBarButton.setEnabled(true)
end

-- Container Buttons
for i,v in pairs(containers) do
	v.topBarButton.TextButton.MouseButton1Click:Connect(function()
		enableContainer(v)
	end)
end

-- Handle Input
Container.InputBegan:Connect(function(input: InputObject)
	for i,v in pairs(containers) do
		if v["InputBegan"] then
			v.InputBegan(input)
		end
	end
end)

Container.InputChanged:Connect(function(input: InputObject)
	for i,v in pairs(containers) do
		if v["InputChanged"] then
			v.InputChanged(input)
		end
	end
end)

Container.InputEnded:Connect(function(input: InputObject)
	for i,v in pairs(containers) do
		if v["InputEnded"] then
			v.InputEnded(input)
		end
	end
end)

-- Version Check
local latestVersion = HttpService:RequestAsync({
	Url = "https://api.github.com/repos/Redon-Tech/Emergency-Vehicle-Creator/releases/latest",
	Method = "GET"
})

if latestVersion.Success then
	local latestVersionJSON = HttpService:JSONDecode(latestVersion.Body)
	if latestVersionJSON.tag_name ~= Plugin_Version and plugin:GetSetting("VersionWarning") ~= latestVersionJSON.tag_name then
		versionWarning.Text = `Plugin version out of date. Latest {latestVersionJSON.tag_name}, Current {Plugin_Version}. Click to dismiss warning.`
		versionWarning.Visible = true
		
		versionWarning.MouseButton1Click:Connect(function()
			versionWarning.Visible = false
			plugin:SetSetting("VersionWarning", latestVersionJSON.tag_name)
		end)
	end
else
	warn("[EVC]: Failed to check for latest version.")
end

-- Handle Theme Changes
-- local originalTheme = settings().Studio.Theme

-- settings().Studio.ThemeChanged:Connect(function()
-- 	if settings().Studio.Theme ~= originalTheme then
-- 		local newTheme = settings().Studio.Theme
-- 		for i,v in pairs(GUI:GetDescendants()) do
			
-- 		end
-- 	end
-- end)

--------------------------------------------------------------------------------
-- Plugin Starup --
--------------------------------------------------------------------------------

enableContainer(containers["elsCreator"])
Button.Click:Connect(function()
	GUI.Enabled = not GUI.Enabled
end)