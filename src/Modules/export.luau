--[[
	Redon Tech 2023-2024
	EVC V2
--]]

--------------------------------------------------------------------------------
-- Init --
--------------------------------------------------------------------------------

local StudioService = game:GetService("StudioService")
local Selection = game:GetService("Selection")
local pluginRoot = script.Parent.Parent.Parent

local export = {enabled = false, canExport = false, container = nil}

local chassisExportConnections = {}
local chassisVersion = require(pluginRoot.src.ExportTemplates.Settings).PluginVersion
local settingsConverter = require(pluginRoot.src.Utils.settingsConverter)

--------------------------------------------------------------------------------
-- UI Setup --
--------------------------------------------------------------------------------

local Components = script.Parent.Parent:WaitForChild("Components")
export["topBarButton"] = require(Components:WaitForChild("topBarButton"))("export", 2, "Export", 0.104, false)

local exportComponents = Components:WaitForChild("export")
local reusedContent = Components:WaitForChild("reusedContent")
local confirmPrompt = require(Components:WaitForChild("popups"):WaitForChild("confirm"))

local exportContainer = require(exportComponents:WaitForChild("container"))()

--------------------------------------------------------------------------------
-- Module Functions --
--------------------------------------------------------------------------------
-- export.container.Parent.PopUps.BackgroundTransparency = 0.5
-- confirmPrompt("Are you sure you want to load this save, this will overwrite any unsaved data?\n<b>This can not be undone</b>", function(confirm)
-- 	export.container.Parent.PopUps.BackgroundTransparency = 1
-- 	if confirm then
-- 	end
-- end).Parent = export.container.Parent.PopUps

local function resetChassisExport()
	for _, connection in pairs(chassisExportConnections) do
		connection:Disconnect()
	end

	for _,v in pairs(exportContainer.ChassisPluginExports.FunctionsHolder:GetChildren()) do
		if v:IsA("TextButton") then
			v:Destroy()
		end
	end

	exportContainer.Selection.Visible = false
	exportContainer.ChassisPluginExports.Visible = false
	exportContainer.SelectExportOption.Visible = true
end

local function chassisExport(model: Model, isAG: true)
	local installedAsAG = false
	local function normalInstall()
		local EVCPlugin_Client = Instance.new("LocalScript")
		EVCPlugin_Client.Name = "EVCPlugin_Client"
		EVCPlugin_Client.Source = pluginRoot.src.ExportTemplates.EVCPlugin_Client.Source
		EVCPlugin_Client.Parent = model["A-Chassis Tune"].Plugins
		local EVCRemote = Instance.new("RemoteEvent")
		EVCRemote.Name = "EVCRemote"
		EVCRemote.Parent = EVCPlugin_Client
		local EVCPlugin = Instance.new("Script")
		EVCPlugin.Name = "EVCPlugin"
		EVCPlugin.Source = pluginRoot.src.ExportTemplates.EVCPlugin.Source
		EVCPlugin.Parent = EVCRemote
		EVCPlugin.Enabled = false
		local Settings = pluginRoot.src.ExportTemplates.Settings:Clone()
		Settings.Parent = EVCRemote

		if model:FindFirstChild("Body") then
			if model.Body:FindFirstChild("Lightbar") == nil then
				local Lightbar = Instance.new("Model")
				Lightbar.Name = "Lightbar"
				Lightbar.Parent = model.Body
			end
			if model.Body.Lightbar:FindFirstChild("ModuleStore") == nil then
				local ModuleStore = Instance.new("Folder")
				ModuleStore.Name = "ModuleStore"
				ModuleStore.Parent = model.Body.Lightbar
				local Stages = Instance.new("Folder")
				Stages.Name = "Stages"
				Stages.Parent = ModuleStore
				local Traffic_Advisor = Instance.new("Folder")
				Traffic_Advisor.Name = "Traffic_Advisor"
				Traffic_Advisor.Parent = ModuleStore
			end
		end
	end
	local function agInstall()
		if model.Body.ELS:FindFirstChild("PTRNS") then
			model.Body.ELS.PTRNS:Destroy()
		end

		local PTRNS = Instance.new("Folder")
		PTRNS.Name = "PTRNS"
		PTRNS.Parent = model.Body.ELS
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

		local EVCPlugin = Instance.new("Script")
		EVCPlugin.Name = "EVCPlugin_AG"
		EVCPlugin.Source = pluginRoot.src.ExportTemplates.EVCPlugin_AG.Source
		EVCPlugin.Parent = PTRNS
		local Settings = pluginRoot.src.ExportTemplates.Settings:Clone()
		Settings.Parent = PTRNS

		if model.Body.ELS:FindFirstChild("ModuleStore") == nil then
			local ModuleStore = Instance.new("Folder")
			ModuleStore.Name = "ModuleStore"
			ModuleStore.Parent = model.Body.ELS
			local Stages = Instance.new("Folder")
			Stages.Name = "Stages"
			Stages.Parent = ModuleStore
			for i=1,5 do
				local Pattern = Instance.new("Folder")
				Pattern.Name = "Pattern"..i
				Pattern.Parent = Stages
			end
			local Traffic_Advisor = Instance.new("Folder")
			Traffic_Advisor.Name = "Traffic_Advisor"
			Traffic_Advisor.Parent = ModuleStore
			for i=1,5 do
				local Pattern = Instance.new("Folder")
				Pattern.Name = "Pattern"..i
				Pattern.Parent = Traffic_Advisor
			end
		end
	end
	local function installPlugin()
		if isAG then
			export.container.Parent.PopUps.BackgroundTransparency = 0.5
			confirmPrompt("Would you like to use the AG-Chassis plugin instead of the regular plugin?", function(confirm)
				export.container.Parent.PopUps.BackgroundTransparency = 1
				if confirm then
					installedAsAG = true
					agInstall()
				else
					installedAsAG = false
					normalInstall()
				end
			end).Parent = export.container.Parent.PopUps
			repeat
				task.wait(.1)
			until export.container.Parent.PopUps.BackgroundTransparency == 1
		else
			export.container.Parent.PopUps.BackgroundTransparency = 1
			normalInstall()
		end
	end

	if model["A-Chassis Tune"].Plugins:FindFirstChild("EVCPlugin_Client") then
		local currentSettings = require(model["A-Chassis Tune"].Plugins.EVCPlugin_Client.EVCRemote:WaitForChild("Settings"))
		local ver = currentSettings.PluginVersion
		local numberstring = string.gsub(ver, "%.", "")

		if tonumber(numberstring) < 200 then
			export.container.Parent.PopUps.BackgroundTransparency = 0.5
			confirmPrompt("The currently installed plugin on this chassis is still on version 1.\nWould you like to replace it with version 2?\n<b>Settings will be overwritten</b>", function(confirm)
				if confirm then
					model["A-Chassis Tune"].Plugins.EVCPlugin_Client:Destroy()
					installPlugin()
				else
					export.container.Parent.PopUps.BackgroundTransparency = 1
				end
			end).Parent = export.container.Parent.PopUps
			repeat
				task.wait(.1)
			until export.container.Parent.PopUps.BackgroundTransparency == 1
		end
	elseif model.Body:FindFirstChild("ELS") and model.Body.ELS:FindFirstChild("PTRNS") and model.Body.ELS.PTRNS:FindFirstChild("Settings") then
		local currentSettings = require(model.Body.ELS.PTRNS:WaitForChild("Settings"))
		-- print(currentSettings.PluginVersion)
		local ver = currentSettings.PluginVersion
		local numberstring = string.gsub(ver, "%.", "")

		-- print(tonumber(numberstring))
		if tonumber(numberstring) < 200 then
			export.container.Parent.PopUps.BackgroundTransparency = 0.5
			confirmPrompt("The currently installed plugin on this chassis is still on version 1.\nWould you like to replace it with version 2?\n<b>Settings will be overwritten</b>", function(confirm)
				if confirm then
					model.Body.ELS.PTRNS:Destroy()
					installPlugin()
				else
					export.container.Parent.PopUps.BackgroundTransparency = 1
				end
			end).Parent = export.container.Parent.PopUps
			repeat
				task.wait(.1)
			until export.container.Parent.PopUps.BackgroundTransparency == 1
		else
			installedAsAG = true
		end
	else
		export.container.Parent.PopUps.BackgroundTransparency = 0.5
		confirmPrompt("There is no installed plugin on this vehicle.\nWould you like to automatically install it?", function(confirm)
			if confirm then
				installPlugin()
			else
				export.container.Parent.PopUps.BackgroundTransparency = 1
			end
		end).Parent = export.container.Parent.PopUps
		repeat
			task.wait(.1)
		until export.container.Parent.PopUps.BackgroundTransparency == 1
	end

	local pluginSettings = nil
	local lightbar = nil
	if installedAsAG then
		pluginSettings = require(model.Body.ELS.PTRNS:WaitForChild("Settings"))
		lightbar = model.Body.ELS
	else
		pluginSettings = require(model["A-Chassis Tune"].Plugins.EVCPlugin_Client.EVCRemote:WaitForChild("Settings"))
		lightbar = model.Body[pluginSettings.LightbarName]
	end

	if pluginSettings.PluginVersion ~= chassisVersion then
		export.container.Parent.PopUps.BackgroundTransparency = 0.5
		confirmPrompt("The currently installed plugin on this chassis is out of date.\nWould you like to update it?", function(confirm)
			if confirm then
				if installedAsAG then
					local originalSettings = model.Body.ELS.PTRNS.Settings
					local newSettings = settingsConverter.convert(originalSettings)
					model.Body.ELS.PTRNS:Destroy()
					agInstall()
					model.Body.ELS.PTRNS.Settings:Destroy()
					newSettings.Parent = model.Body.ELS.PTRNS
					newSettings.Name = "Settings"
					export.container.Parent.PopUps.BackgroundTransparency = 1
				else
					local originalSettings = model["A-Chassis Tune"].Plugins.EVCPlugin_Client.EVCRemote.Settings
					local newSettings = settingsConverter.convert(originalSettings)
					model["A-Chassis Tune"].Plugins.EVCPlugin_Client:Destroy()
					normalInstall()
					model["A-Chassis Tune"].Plugins.EVCPlugin_Client.EVCRemote.Settings:Destroy()
					newSettings.Parent = model["A-Chassis Tune"].Plugins.EVCPlugin_Client.EVCRemote
					newSettings.Name = "Settings"
					export.container.Parent.PopUps.BackgroundTransparency = 1
				end
			else
				export.container.Parent.PopUps.BackgroundTransparency = 1
			end
		end).Parent = export.container.Parent.PopUps
		repeat
			task.wait(.1)
		until export.container.Parent.PopUps.BackgroundTransparency == 1
	end

	local function exportToPattern(folder: Folder, weight: number)
		local data = {}

		for module,moduleData in pairs(export.modules) do
			if typeof(moduleData["toTable"]) == "function" then
				data[module] = moduleData["toTable"]()
			end
		end

		local sectionsDevidedByWaitTimes = {}
		local firstWaitTime = nil

		if data["elsCreator"] then
			for sectionNumber,sectionData in pairs(data.elsCreator) do
				if sectionsDevidedByWaitTimes[sectionNumber] == nil then
					sectionsDevidedByWaitTimes[sectionNumber] = {waitTime = sectionData.WaitTime, elsCreator = {}, rotators = {}, faders = {}}
				end

				-- table.insert(sectionsDevidedByWaitTimes[sectionData.WaitTime].elsCreator, sectionData)
				sectionsDevidedByWaitTimes[sectionNumber].elsCreator[sectionNumber] = sectionData
				if firstWaitTime == nil then
					firstWaitTime = sectionNumber
				end
			end
		else
			sectionsDevidedByWaitTimes[1] = {elsCreator = {}, rotators = {}, faders = {}}
			if firstWaitTime == nil then
				firstWaitTime = 1
			end
		end

		if data["rotators"] then
			for sectionNumber,sectionData in pairs(data.rotators) do
				sectionsDevidedByWaitTimes[firstWaitTime].rotators[sectionNumber] = sectionData
			end
		end

		if data["faders"] then
			for sectionNumber,sectionData in pairs(data.faders) do
				-- table.insert(section.faders, sectionData)
				sectionsDevidedByWaitTimes[firstWaitTime].faders[sectionNumber] = sectionData
			end
		end
		-- print(data, sectionsDevidedByWaitTimes)
		for i,v in pairs(sectionsDevidedByWaitTimes) do
			local module = pluginRoot.src.ExportTemplates.Template:Clone()
			module.Name = `EVCExport|{DateTime:now():FormatLocalTime("lll", "en-US")}`

			local lightsString = ""
			local rotatorsString = ""
			local fadersString = ""

			for i,sections in pairs(v.elsCreator) do
				for columnNumber=1,rawlen(sections.Columns) do
					local columnData = sections.Columns[columnNumber]
					local name = columnData.Name
					if name == "" then name = `{i}Light{columnNumber}` end
					lightsString ..= `\n\t["{name}"] = `.."{\n\t\t"
					for rowNumber=1,#columnData.Rows do
						local rowData = columnData.Rows[rowNumber]
						lightsString ..= `{rowData},`
					end
					lightsString ..= "\n\t},"
				end
			end

			for i,sections in pairs(v.rotators) do
				if sections.Angles[1].Color ~= nil and sections.Angles[1].Angle ~= nil and sections.Angles[1].Velocity ~= nil and sections.Name ~= nil then
					local name = sections.Name
					if name == "" then name = `Rotator{i}` end
					rotatorsString ..= `\n\t["{name}"] = `.."{"
					for angleNumber=1,rawlen(sections.Angles) do
						local angleData = sections.Angles[angleNumber]
						if angleData.Color ~= nil or angleData.Angle ~= nil or angleData.Velocity ~= nil then
							rotatorsString ..= "\n\t\t["..angleNumber.."] = {\n\t\t\t"
							rotatorsString ..= `Color = {angleData.Color},\n\t\t\tAngle = {angleData.Angle},\n\t\t\tVelocity = {angleData.Velocity}`
							rotatorsString ..= "\n\t\t},"
						end
					end
					rotatorsString ..= "\n\t},"
				end
			end

			for _,sections in pairs(v.faders) do
				if sections.Name ~= nil and sections.Tweens[1].Color ~= nil and sections.Tweens[1].TransparencyGoal ~= nil and sections.Tweens[1].Time ~= nil and sections.Tweens[1].EasingStyle ~= nil and sections.Tweens[1].EasingDirection ~= nil and sections.Tweens[1].RepeatCount ~= nil and sections.Tweens[1].Reverses ~= nil and sections.Tweens[1].DelayTime ~= nil then
					local name = sections.Name
					if name == "" then name = `Fader{i}` end
					fadersString ..= `\n\t["{name}"] = `.."{"
					for tweenNumber=1,rawlen(sections.Tweens) do
						local tweenData = sections.Tweens[tweenNumber]
						if tweenData.Color ~= nil or tweenData.TransparencyGoal ~= nil or tweenData.Time ~= nil or tweenData.EasingStyle ~= nil or tweenData.EasingDirection ~= nil or tweenData.RepeatCount ~= nil or tweenData.Reverses ~= nil or tweenData.DelayTime ~= nil then
							fadersString ..= "\n\t\t["..tweenNumber.."] = {\n\t\t\t"
							fadersString ..= `Color = {tweenData.Color},\n\t\t\tTransparency = {tweenData.TransparencyGoal},\n\t\t\tTime = {tweenData.Time},\n\t\t\tEasingStyle = Enum.EasingStyle.{tweenData.EasingStyle},\n\t\t\tEasingDirection = Enum.EasingDirection.{tweenData.EasingDirection},\n\t\t\tRepeatCount = {tweenData.RepeatCount},\n\t\t\tReverses = {tweenData.Reverses},\n\t\t\tTimeDelay = {tweenData.DelayTime}`
							fadersString ..= "\n\t\t},"
						end
					end
					fadersString ..= "\n\t},"
				end
			end

			local source = module.Source
			-- print(i, weight, lightsString, rotatorsString, fadersString)
			source = source:gsub("WaitTime = 0.1", `WaitTime = {v.waitTime}`)
			source = source:gsub("Weight = 1", `Weight = {weight}`)
			source = source:gsub("Lights = {}", "Lights = {"..lightsString.."\n}")
			source = source:gsub("Rotators = {}", "Rotators = {"..rotatorsString.."\n}")
			source = source:gsub("Faders = {}", "Faders = {"..fadersString.."\n}")
			module.Source = source
			module.Parent = folder
		end

		resetChassisExport()
	end

	local patternConnections = {}
	local selectedPattern = nil

	local function selectPattern(v)
		selectedPattern = v
		for _, connection in pairs(patternConnections) do
			connection:Disconnect()
		end
		for _,frame in pairs(exportContainer.ChassisPluginExports.ExportsContainer:GetChildren()) do
			if frame:IsA("Frame") then
				frame:Destroy()
			end
		end
		
		for _,button in pairs(exportContainer.ChassisPluginExports.FunctionsHolder:GetChildren()) do
			if button.Name == v.Name then
				button:SetAttribute("Selected", true)
			else
				button:SetAttribute("Selected", false)
			end
		end

		for _,pattern in pairs(v:GetChildren()) do
			if pattern:IsA("Folder") then
				local name = `Pattern {pattern.Name:match("%d+")}`
				local patternFrame = require(exportComponents:WaitForChild("pattern"))(name)
				patternFrame.Parent = exportContainer.ChassisPluginExports.ExportsContainer

				patternConnections[#patternConnections+1] = patternFrame.OverwriteButton.MouseButton1Click:Connect(function()
					export.container.Parent.PopUps.BackgroundTransparency = 0.5
					confirmPrompt("Are you sure you want to overwrite this pattern?\n<b>This can not be undone</b>", function(confirm)
						export.container.Parent.PopUps.BackgroundTransparency = 1
						if confirm then
							for _,module in pairs(pattern:GetChildren()) do
								if module:IsA("ModuleScript") then
									module:Destroy()
								end
							end
							exportToPattern(pattern, exportContainer.ChassisPluginExports.FunctionsHolder[selectedPattern.Name].LayoutOrder)
						end
					end).Parent = export.container.Parent.PopUps
				end)

				patternConnections[#patternConnections+1] = patternFrame.AddToButton.MouseButton1Click:Connect(function()
					exportToPattern(pattern, exportContainer.ChassisPluginExports.FunctionsHolder[selectedPattern.Name].LayoutOrder)
				end)

				patternConnections[#patternConnections+1] = patternFrame.DeleteButton.MouseButton1Click:Connect(function()
					export.container.Parent.PopUps.BackgroundTransparency = 0.5
					confirmPrompt("Are you sure you want to delete this pattern?\n<b>This can not be undone</b>", function(confirm)
						export.container.Parent.PopUps.BackgroundTransparency = 1
						if confirm then
							pattern:Destroy()
							patternFrame:Destroy()
						end
					end).Parent = export.container.Parent.PopUps
				end)
			end
		end
	end

	for _,v in pairs(lightbar.ModuleStore:GetChildren()) do
		if v:IsA("Folder") then
			local buttonFunction = require(exportComponents:WaitForChild("function"))(v.Name:gsub("_", " "), v.Name)
			buttonFunction.Parent = exportContainer.ChassisPluginExports.FunctionsHolder
			buttonFunction.LayoutOrder = #exportContainer.ChassisPluginExports.FunctionsHolder:GetChildren()
			
			if selectedPattern == nil then
				selectPattern(v)
			end

			buttonFunction.MouseButton1Click:Connect(function()
				selectPattern(v)
			end)
		end
	end

	chassisExportConnections[#chassisExportConnections+1] = exportContainer.ChassisPluginExports.CreatePatternHolder.CreatePattern.MouseButton1Click:Connect(function()
		if exportContainer.ChassisPluginExports.CreatePatternHolder.PatternName.Text == nil or exportContainer.ChassisPluginExports.CreatePatternHolder.PatternName.Text == "" then return end
		local patternNumber = tonumber(exportContainer.ChassisPluginExports.CreatePatternHolder.PatternName.Text:match("%d+"))
		if patternNumber == nil then
			patternNumber = #selectedPattern:GetChildren()+1
		end

		for _,v in pairs(selectedPattern:GetChildren()) do
			if v:IsA("Folder") then
				local number = tonumber(v.Name:match("%d+"))
				if number ~= nil and number == patternNumber then
					patternNumber = #selectedPattern:GetChildren()+1
				end
			end
		end

		local pattern = Instance.new("Folder")
		pattern.Name = `Pattern{patternNumber}`
		pattern.Parent = selectedPattern

		selectPattern(selectedPattern)
	end)

	chassisExportConnections[#chassisExportConnections+1] = exportContainer.ChassisPluginExports.CreatePatternHolder.CreateFunction.MouseButton1Click:Connect(function()
		if exportContainer.ChassisPluginExports.CreatePatternHolder.PatternName.Text == nil or exportContainer.ChassisPluginExports.CreatePatternHolder.PatternName.Text == "" then return end
		if lightbar.ModuleStore:FindFirstChild(exportContainer.ChassisPluginExports.CreatePatternHolder.PatternName.Text:gsub(" ", "_")) then return end
		local folder = Instance.new("Folder")
		folder.Name = exportContainer.ChassisPluginExports.CreatePatternHolder.PatternName.Text:gsub(" ", "_")
		folder.Parent = lightbar.ModuleStore
		
		local buttonFunction = require(exportComponents:WaitForChild("function"))(folder.Name:gsub("_", " "), folder.Name)
		buttonFunction.Parent = exportContainer.ChassisPluginExports.FunctionsHolder
		buttonFunction.LayoutOrder = #exportContainer.ChassisPluginExports.FunctionsHolder:GetChildren()
		
		if selectedPattern == nil then
			selectPattern(folder)
		end

		buttonFunction.MouseButton1Click:Connect(function()
			selectPattern(folder)
		end)
	end)
	
	chassisExportConnections[#chassisExportConnections+1] = exportContainer.ChassisPluginExports.Destroying:Connect(function()
		for _, connection in pairs(patternConnections) do
			connection:Disconnect()
		end
		for _, connection in pairs(chassisExportConnections) do
			connection:Disconnect()
		end
	end)

	exportContainer.Selection.Visible = false
	exportContainer.ChassisPluginExports.Visible = true
end


exportContainer.SelectExportOption.Options.ChassisPlugin.MouseButton1Click:Connect(function()
	resetChassisExport()
	
	exportContainer.SelectExportOption.Visible = false
	exportContainer.Selection.Visible = true
	
	chassisExportConnections[#chassisExportConnections+1] = Selection.SelectionChanged:Connect(function()
		if #Selection:Get() > 0 then
			exportContainer.Selection.Selection.Text = `<b>Currently Selecting:</b> {Selection:Get()[1].Name}`
		else
			exportContainer.Selection.Selection.Text = "<b>Currently Selecting:</b> Nothing"
		end
	end)
	if #Selection:Get() > 0 then
		exportContainer.Selection.Selection.Text = `<b>Currently Selecting:</b> {Selection:Get()[1].Name}`
	else
		exportContainer.Selection.Selection.Text = "<b>Currently Selecting:</b> Nothing"
	end
	
	chassisExportConnections[#chassisExportConnections+1] = exportContainer.Selection.Options.SelectButton.MouseButton1Click:Connect(function()
		if #Selection:Get() > 0 then
			local selection = Selection:Get()[1]
			if selection:FindFirstChild("A-Chassis Tune") and selection["A-Chassis Tune"]:FindFirstChild("AG-Chassis [Loader]") and selection.Body:FindFirstChild("ELS") then
				for _, connection in pairs(chassisExportConnections) do
					connection:Disconnect()
				end
				
				chassisExport(selection, true)
				elseif selection:FindFirstChild("A-Chassis Tune") and selection["A-Chassis Tune"]:FindFirstChild("Plugins") then
					for _, connection in pairs(chassisExportConnections) do
						connection:Disconnect()
					end
					
					chassisExport(selection, false)
			end
		end
	end)
	
	chassisExportConnections[#chassisExportConnections+1] = exportContainer.Selection.Options.CancelButton.MouseButton1Click:Connect(function()
		resetChassisExport()
	end)
	
	chassisExportConnections[#chassisExportConnections+1] = exportContainer.Selection.Destroying:Connect(function()
		for _, connection in pairs(chassisExportConnections) do
			connection:Disconnect()
		end
	end)
end)

exportContainer.SelectExportOption.Options.CustomCode.MouseButton1Click:Connect(function()
	local success, message = pcall(function()
		local data = {}

		for module,moduleData in pairs(export.modules) do
			if typeof(moduleData["toTable"]) == "function" then
				data[module] = moduleData["toTable"]()
			end
		end
		-- print(data)
		local model = Instance.new("Model")
		model.Parent = workspace
		model.Name = "EVC Custom Code Export"
		local offset = Vector3.new(0, 10, 0)

		if data.elsCreator ~= nil then
			for sectionNumber,sectionData in pairs(data.elsCreator) do
				local newScript = Instance.new("Script")
				newScript.Name = `EmergencyLights{sectionNumber}`
				newScript.Parent = model
				newScript.Source = pluginRoot.src.ExportTemplates.CustomCode.lights.Source
				local scriptSource = newScript.Source
				scriptSource = scriptSource:gsub("%[username%]", StudioService:GetUserId())
				scriptSource = scriptSource:gsub("local Lightbar = script.Parent", `local waitTime = {sectionData.WaitTime}\nlocal Lightbar = script.Parent`)

				local lights = {}
				local maxRows = {}
				for columnNumber,columnData in pairs(sectionData.Columns) do
					if columnData.Name == "" then
						columnData.Name = if sectionNumber > 1 then `{sectionNumber}Light{columnNumber}` else `Light{columnNumber}`
						sectionData.Columns[columnNumber].Name = columnData.Name
					end
					if table.find(lights, columnData.Name) == nil then
						table.insert(lights, columnData.Name)
					end
					maxRows = rawlen(columnData.Rows)
				end

				local lightLoopString = ""
				for row=1,maxRows do
					lightLoopString ..= `\n\t-- {row}`
					for column=1,rawlen(sectionData.Columns) do
						lightLoopString ..= `\n\tlight("{sectionData.Columns[column].Name}", {sectionData.Columns[column].Rows[row]})`
					end
					lightLoopString ..= `\n\ttask.wait(waitTime)`
				end

				scriptSource = scriptSource:gsub("--%[lights%]", lightLoopString)

				for _,lightname in pairs(lights) do
					local part = Instance.new("Part")
					part.Parent = model
					part.Name = lightname
					part.TopSurface = Enum.SurfaceType.Smooth
					part.BottomSurface = Enum.SurfaceType.Smooth
					part.Material = Enum.Material.Neon
					part.BrickColor = BrickColor.new("Institutional white")
					part.Anchored = true
					part.CanCollide = false
					part.Size = Vector3.new(0.75, 0.3, 0.1)
					offset += Vector3.new(0.85, 0, 0)
					part.Position = offset
				end

				newScript.Source = scriptSource
			end
		end
	end)
	if not success then
		warn(message, "\n", debug.traceback())
	end
end)

export.Display = function(container: Frame)
	exportContainer.Parent = container
	export.container = container
	export.enabled = true
end

export.StopDisplay = function()
	resetChassisExport()

	exportContainer.Parent = nil
	export.container = nil
	export.enabled = false
end

pluginRoot.Destroying:Connect(function()
	export.enabled = false
end)

return export