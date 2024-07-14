--[[
	Redon Tech 2023-2024
	EVC V2
--]]

--------------------------------------------------------------------------------
-- Init --
--------------------------------------------------------------------------------

local StudioService = game:GetService("StudioService")
local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")
local pluginRoot = script.Parent.Parent.Parent
local loadSave = { enabled = false, canExport = false, container = nil }
local plugin: Plugin = pluginRoot:WaitForChild("Plugin").Value
local Is_RBXM = plugin.Name:find(".rbxm") ~= nil

--------------------------------------------------------------------------------
-- UI Setup --
--------------------------------------------------------------------------------

local Components = script.Parent.Parent:WaitForChild("Components")
loadSave["topBarButton"] = require(Components:WaitForChild("topBarButton"))("loadSave", 3, "Load/Save", 0.104, false)

local loadSaveComponents = Components:WaitForChild("loadSave")
local reusedContent = Components:WaitForChild("reusedContent")
local confirmPrompt = require(Components:WaitForChild("popups"):WaitForChild("confirm"))
local importLocalSavePopup = require(Components:WaitForChild("popups"):WaitForChild("importLocalSave"))

local loadSaveContainer = require(loadSaveComponents:WaitForChild("container"))()

--------------------------------------------------------------------------------
-- Module Functions --
--------------------------------------------------------------------------------

local function loadSaveData(saveData: { string: any })
	for module, data in pairs(saveData) do
		-- local module = loadSave.modules
		-- if module and typeof(module["loadFromTable"]) == "function" then
		-- 	module["loadFromTable"](data)
		-- end
		local success, message = pcall(function()
			local requiredModule = loadSave.modules[module]
			-- print(module, data, requiredModule)
			if requiredModule and typeof(requiredModule["loadFromTable"]) == "function" then
				requiredModule["loadFromTable"](data)
			end
		end)

		if not success then
			warn(`[EVC] Error loading save data for module {module}: {message}\n{debug.traceback()}`)
		end
	end
end

local function saveSaveData(saveName: string, saveData: { string: any })
	local saves = plugin:GetSetting("savesV2")

	if saves == nil then
		saves = {}
	end

	saves[saveName] = saveData
	plugin:SetSetting("savesV2", saves)
end

local function updateSaves()
	local saves = plugin:GetSetting("savesV2")

	if saves == nil then
		saves = {}
	end

	local saveList = loadSaveContainer.MainLoadSave.SavesContainer
	for i, v in pairs(saveList:GetChildren()) do
		if v:IsA("Frame") then
			v:Destroy()
		end
	end

	for name, save in pairs(saves) do
		local saveFrame = require(loadSaveComponents.save)(name)
		saveFrame.Parent = saveList
		local connections = {}
		connections[#connections + 1] = saveFrame.SaveButton.MouseButton1Click:Connect(function()
			loadSave.container.Parent.PopUps.BackgroundTransparency = 0.5
			confirmPrompt(
				"Are you sure you want to overwrite this save?\n<b>This can not be undone</b>",
				function(confirm)
					loadSave.container.Parent.PopUps.BackgroundTransparency = 1
					if confirm then
						local saveData = {}
						for module, data in pairs(loadSave.modules) do
							if typeof(data["toTable"]) == "function" then
								saveData[module] = data["toTable"]()
							end
						end

						saveSaveData(name, saveData)
						updateSaves()
					end
				end
			).Parent =
				loadSave.container.Parent.PopUps
		end)

		connections[#connections + 1] = saveFrame.LoadButton.MouseButton1Click:Connect(function()
			loadSave.container.Parent.PopUps.BackgroundTransparency = 0.5
			confirmPrompt(
				"Are you sure you want to load this save, this will overwrite any unsaved data?\n<b>This can not be undone</b>",
				function(confirm)
					loadSave.container.Parent.PopUps.BackgroundTransparency = 1
					if confirm then
						loadSaveData(save)
					end
				end
			).Parent =
				loadSave.container.Parent.PopUps
		end)

		connections[#connections + 1] = saveFrame.ExportButton.MouseButton1Click:Connect(function()
			local success, message = pcall(function()
				local instanceToSave = Instance.new("Script")
				instanceToSave.Source = HttpService:JSONEncode(save)
				instanceToSave.Name = name
				instanceToSave.Parent = game
				local currentSelection = Selection:Get()
				Selection:Set({ instanceToSave })
				task.wait(0.1)
				local saved = plugin:PromptSaveSelection(`{name}`)
				task.wait(0.1)
				Selection:Set(currentSelection)
				instanceToSave:Destroy()
			end)

			if not success then
				warn(`[EVC] Error exporting save: {message}\n{debug.traceback()}`)
			end
		end)

		connections[#connections + 1] = saveFrame.DeleteButton.MouseButton1Click:Connect(function()
			loadSave.container.Parent.PopUps.BackgroundTransparency = 0.5
			confirmPrompt("Are you sure you want to delete this save?\n<b>This can not be undone</b>", function(confirm)
				loadSave.container.Parent.PopUps.BackgroundTransparency = 1
				if confirm then
					local saves = plugin:GetSetting("savesV2")

					if saves == nil then
						saves = {}
					end

					saves[name] = nil
					plugin:SetSetting("savesV2", saves)
					updateSaves()
				end
			end).Parent =
				loadSave.container.Parent.PopUps
		end)

		saveFrame.Destroying:Connect(function()
			for index, value in pairs(connections) do
				value:Disconnect()
			end
		end)
	end
end

loadSaveContainer.MainLoadSave.ControlsHolder.CreateSave.MouseButton1Click:Connect(function()
	local name = loadSaveContainer.MainLoadSave.ControlsHolder.SaveName.Text

	if name == "" then
		name = "Untitled"
	end

	local saves = plugin:GetSetting("savesV2")

	if saves == nil then
		saves = {}
	end

	local currenNameWithCount = name
	local function checkName(checkDepth)
		if saves[currenNameWithCount] ~= nil then
			currenNameWithCount = `{name} ({checkDepth})`
			checkName(checkDepth + 1)
		end
	end
	checkName(1)
	name = currenNameWithCount

	local saveData = {}
	for module, data in pairs(loadSave.modules) do
		if typeof(data["toTable"]) == "function" then
			saveData[module] = data["toTable"]()
		end
	end

	saveSaveData(name, saveData)
	updateSaves()
end)

loadSaveContainer.MainLoadSave.ControlsHolder.ImportSave.MouseButton1Click:Connect(function()
	local success, message = pcall(function()
		local file = StudioService:PromptImportFile({ "lua" })

		if file then
			local saveData = HttpService:JSONDecode(file:GetBinaryContents())
			local name = file.Name:gsub(".lua", "")

			local saves = plugin:GetSetting("savesV2")

			if saves == nil then
				saves = {}
			end

			local currenNameWithCount = name
			local function checkName(checkDepth)
				if saves[currenNameWithCount] ~= nil then
					currenNameWithCount = `{name} ({checkDepth})`
					checkName(checkDepth + 1)
				end
			end
			checkName(1)
			name = currenNameWithCount

			saveSaveData(name, saveData)
			updateSaves()
		end
	end)

	if not success then
		warn(`[EVC] Error importing save: {message}\n{debug.traceback()}`)
	end
end)

local function loadLegacySave(saveData: { string: any })
	local data = { elsCreator = {} }

	local sections = {
		[1] = {
			WaitTime = 0.1,
			Columns = {},
			Remove = 0,
		},
	}
	local organizedData = {}

	for i, v in pairs(saveData) do
		if i == "BPM" then
			sections[1].WaitTime = tonumber(v)
		else
			organizedData[tonumber(i)] = v
		end
	end

	for i = 1, #organizedData do
		local v = organizedData[i]
		if v.Spacer == true then
			sections[#sections + 1] = {
				WaitTime = tonumber(v.BPM),
				Columns = {},
				Remove = i,
			}
		else
			local columnData = { Name = "", Rows = {} }
			for row, rowData in pairs(v.Rows) do
				columnData.Rows[tonumber(row)] = rowData
			end

			sections[#sections].Columns[i - sections[#sections]["Remove"]] = columnData
		end
	end

	data.elsCreator = sections

	loadSaveData(data)
end

local function updateLegacySaves()
	local saves = plugin:GetSetting("saves")

	if saves == nil then
		saves = {}
	end

	local saveList = loadSaveContainer.MainLegacySaves.SavesContainer
	for i, v in pairs(saveList:GetChildren()) do
		if v:IsA("Frame") then
			v:Destroy()
		end
	end

	for name, save in pairs(saves) do
		local saveFrame = require(loadSaveComponents.saveLegacy)(name)
		saveFrame.Parent = saveList
		local connection = saveFrame.LoadButton.MouseButton1Click:Connect(function()
			loadSave.container.Parent.PopUps.BackgroundTransparency = 0.5
			confirmPrompt(
				"Are you sure you want to load this save, this will overwrite any unsaved data?\n<b>This can not be undone</b>",
				function(confirm)
					loadSave.container.Parent.PopUps.BackgroundTransparency = 1
					if confirm then
						loadLegacySave(save)
					end
				end
			).Parent =
				loadSave.container.Parent.PopUps
		end)

		saveFrame.Destroying:Connect(function()
			connection:Disconnect()
		end)
	end
end

if Is_RBXM == false then
	loadSaveContainer.MainLegacySaves.ImportLegacySaves.Visible = false
else
	loadSaveContainer.MainLegacySaves.ImportLegacySaves.MouseButton1Click:Connect(function()
		loadSave.container.Parent:WaitForChild("PopUps").BackgroundTransparency = 0.5
		importLocalSavePopup(
			"Select a settings file to import",
			`%LocalAppData%\\Roblox\\{StudioService:GetUserId()}\\InstalledPlugins\\9953321418`,
			function(confirm)
				loadSave.container.Parent:WaitForChild("PopUps").BackgroundTransparency = 1
				if confirm then
					local success, message = pcall(function()
						local file = StudioService:PromptImportFile({ "json" })
						if file then
							local data = HttpService:JSONDecode(file:GetBinaryContents())

							if data then
								local currentSaves = plugin:GetSetting("saves")
								if currentSaves == nil then
									currentSaves = {}
								end

								if data["saves"] ~= nil then
									for i, v in pairs(data["saves"]) do
										if v["BPM"] ~= nil then
											currentSaves[i] = v
										end
									end
								end

								plugin:SetSetting("saves", currentSaves)
								updateLegacySaves()
							end
						end
					end)

					if not success then
						warn(`[EVC] Error importing legacy saves: {message}\n{debug.traceback()}`)
					end
				end
			end
		).Parent =
			loadSave.container.Parent.PopUps
	end)
end

loadSaveContainer.MainLegacySaves:GetPropertyChangedSignal("Visible"):Connect(function()
	loadSaveContainer.MainLoadSave.ShowLegacySaves.Visible = not loadSaveContainer.MainLegacySaves.Visible
end)

loadSaveContainer.MainLegacySaves.HideLegacySaves.MouseButton1Click:Connect(function()
	loadSaveContainer.MainLegacySaves.Visible = false
	plugin:SetSetting("legacySavesHidden", true)
end)

loadSaveContainer.MainLoadSave.ShowLegacySaves.MouseButton1Click:Connect(function()
	loadSaveContainer.MainLegacySaves.Visible = true
	plugin:SetSetting("legacySavesHidden", false)
end)

local showLegacySaves = plugin:GetSetting("legacySavesHidden")
if showLegacySaves == false then
	loadSaveContainer.MainLegacySaves.Visible = false
else
	loadSaveContainer.MainLoadSave.ShowLegacySaves.Visible = false
end

loadSave.Display = function(container: Frame)
	-- controls.Parent = container
	updateLegacySaves()
	updateSaves()

	loadSaveContainer.Parent = container
	loadSave.container = container
	loadSave.enabled = true
end

loadSave.StopDisplay = function()
	-- controls.Parent = nil
	loadSaveContainer.Parent = nil
	loadSave.container = nil
	loadSave.enabled = false
end

pluginRoot.Destroying:Connect(function()
	loadSave.enabled = false
end)

return loadSave
