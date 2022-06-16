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

script.Parent.ChassisPlugin.EVCPlugin_Client.Disabled = true
script.Parent.ChassisPlugin.EVCPlugin.Disabled = true

local function getName(name: string)
    if Is_RBXM then
        name ..= " (RBXM)"
    end
    return name
end

local Plugin_Name = getName("Emergency Vehicle Creator")
local Plugin_Description = "Create ELS for emergency vehicles!"
local Plugin_Icon = ""
local Widget_Name = getName("EVC")
local Button_Name = getName("EVC Button")

if not _G.RT then
    _G.RT = {Buttons = {}}
end

if not _G.RT.Buttons then
    _G.RT.Buttons = {}
end

if not _G.RT.RTToolbar then
    _G.RT.RTToolbar = plugin:CreateToolbar("Redon Tech Plugins")
end

--------------------------------------------------------------------------------
-- UI Init --
--------------------------------------------------------------------------------

local Config = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 1280, 720)
local GUI = plugin:CreateDockWidgetPluginGui(Widget_Name, Config)
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Global
GUI.Title = Plugin_Name
GUI.Name = Widget_Name

local Button = nil
if table.find(_G.RT.Buttons, Button_Name) then
    Button = _G.RT.Buttons[Button_Name]
else
    Button = _G.RT.RTToolbar:CreateButton(Button_Name, Plugin_Description, Plugin_Icon)
    _G.RT.Buttons[Button_Name] = Button
end

local MainFrame = require(script.Parent.Modules.gui).CreateGui()
MainFrame.Parent = GUI
MainFrame.Confirm.TextLabel.RichText = true -- GUI -> Script doesnt convert this
MainFrame.Creator.PointerHolder.Pointer:SetAttribute("max", 20)
MainFrame.Creator.PointerHolder.Pointer:SetAttribute("count", 1)
local Pointer = MainFrame.Creator.ScrollingFrame["2"]
Pointer.Parent = script
Pointer:SetAttribute("max", 20)
Pointer:SetAttribute("count", 1)
local SaveTemplate = MainFrame.SaveLoad.ScrollingFrame.Frame
SaveTemplate.Parent = script
SaveTemplate.TextBox.ClearTextOnFocus = false

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
        
        -- TBD: Reset everything to default
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

        connect1:Disconnect()
        connect2:Disconnect()
    end)

    connect2 = MainFrame.Confirm.No.MouseButton1Click:Connect(function()
        MainFrame.Confirm.Visible = false
        connect1:Disconnect()
        connect2:Disconnect()
    end)
end

local function resetcounters()
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
local function addbutton(v: GuiBase2d, frame: GuiBase2d)
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
        print(count, pointer:GetAttribute("max"))
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

    for i,v in pairs(column:GetChildren()) do
        addbutton(v, column)
    end
end

-- Add/remove columns
registercolumn(MainFrame.Creator.ScrollingFrame["1"])
-- for i,v in pairs(MainFrame.Creator.ScrollingFrame["1"]:GetChildren()) do
--     addbutton(v, MainFrame.Creator.ScrollingFrame["1"])
-- end

MainFrame.Creator.ScrollingFrame.Last.Devider.add.MouseButton1Down:Connect(function()
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

MainFrame.Creator.ScrollingFrame.Last.Devider.subtract.MouseButton1Down:Connect(function()
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
        for i,v in pairs(MainFrame.Creator.ScrollingFrame:GetChildren()) do
            if v.Name ~= "Last" and v:IsA("Frame") and largest == nil or #largest:GetChildren() < #v:GetChildren() then
                largest = v
            end
        end

        if not largest then
            largest = MainFrame.Creator.ScrollingFrame["1"]
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
    MainFrame.Creator.ScrollingFrame.CanvasSize = UDim2.fromOffset(MainFrame.Creator.ScrollingFrame.UIGridLayout.AbsoluteContentSize.X + Padding.X.Offset + Size.X.Offset, largest.UIListLayout.AbsoluteContentSize.Y)
    MainFrame.Creator.PointerHolder.CanvasSize = UDim2.fromOffset(0, largest.UIListLayout.AbsoluteContentSize.Y)

    local number = #MainFrame.Creator.ScrollingFrame:GetChildren() - 2
    if number > 1 then
        MainFrame.Creator.ScrollingFrame.Last.Devider.subtract.Visible = true
    else
        MainFrame.Creator.ScrollingFrame.Last.Devider.subtract.Visible = false
    end
end

MainFrame.Creator.ScrollingFrame.ChildAdded:Connect(ScrollingFrameChildrenChanged)
MainFrame.Creator.ScrollingFrame.ChildRemoved:Connect(ScrollingFrameChildrenChanged)

local function VisabilityChanged()
    if MainFrame.Confirm.Visible or MainFrame.SaveLoad.Visible then
        Usable = false
    else
        Usable = true
    end
end

MainFrame.Confirm:GetPropertyChangedSignal("Visible"):Connect(VisabilityChanged)
MainFrame.SaveLoad:GetPropertyChangedSignal("Visible"):Connect(VisabilityChanged)

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
    if skipconfirm then
        pointer:SetAttribute("max", pointer:GetAttribute("max") - 1)
        pointer[#pointer:GetChildren() - 5]:Destroy()
        for i,v in pairs(MainFrame.Creator.ScrollingFrame:GetChildren()) do
            if v.Name ~= "Last" and v:IsA("Frame") and tonumber(v.Name) >= start and tonumber(v.Name) < last then
                v[#v:GetChildren() - 3]:Destroy()
            end
        end
        ScrollingFrameChildrenChanged()
    end
    resetcounters()

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
    print(Saves)
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

            clone.Delete.MouseButton1Down:Connect(function()
                MainFrame.Confirm.Visible = true
                MainFrame.SaveLoad.Visible = false
                MainFrame.Confirm.TextLabel.Text = "Are you sure you want to delete the save <b>".. i .."</b>? This cannot be undone."
                local connect1, connect2 = nil, nil

                connect1 = MainFrame.Confirm.Yes.MouseButton1Click:Connect(function()
                    MainFrame.Confirm.Visible = false
                    MainFrame.SaveLoad.Visible = true
                    
                    local Saves = plugin:GetSetting("saves")
                    print(Saves)
                    Saves[i] = nil
                    print(Saves)
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
                    print(Data)
                    Saves[i] = Data
                    print(Saves)
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
                        end
                    end
                    --TBF doesnt remove rows
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

MainFrame.SaveLoad.Save.MouseButton1Down:Connect(function()
    local Saves = plugin:GetSetting("saves")
    if not Saves then
        Saves = {}
    end
    local Name do
        print(MainFrame.SaveLoad.PatternName.Text)
        if MainFrame.SaveLoad.PatternName.Text == "" or MainFrame.SaveLoad.PatternName.Text == nil then
            print("unname")
            Name = "Unnamed"
        else
            print("name")
            Name = MainFrame.SaveLoad.PatternName.Text
        end
    end
    print(Name)
    local function checkname()
        if Saves[Name] then
            print("overwritting name", Name)
            Name = Name.. " (Copy)"
            checkname()
        end
    end
    checkname()
    print(Saves, Name)

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
    print(Data)
    Saves[Name] = Data
    print(Saves)
    plugin:SetSetting("saves", Saves)
    SavesUpdate()
end)

MainFrame.SaveLoad.Cancel.MouseButton1Down:Connect(function()
    MainFrame.SaveLoad.Visible = false
end)

-- Buttons
for i,v in pairs(MainFrame.Creator.Info.Buttons:GetChildren()) do
    if table.find(ButColors, v.Name) then
        v.MouseButton1Down:Connect(function()
            changecolor(table.find(ButColors, v.Name))
        end)
    end
end

MainFrame.Creator.Info.Buttons.Reset.MouseButton1Down:Connect(function()
    if not Usable then
        return
    end
    reset()
end)

MainFrame.Creator.Info.Buttons.Lock.MouseButton1Down:Connect(function()
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

MainFrame.Creator.Info.Save.MouseButton1Down:Connect(function()
    if not Usable and MainFrame.Visible == false then
        return
    end
    MainFrame.SaveLoad.Visible = not MainFrame.SaveLoad.Visible
end)

Button.Click:Connect(function()
    GUI.Enabled = not GUI.Enabled
end)

GUI:GetPropertyChangedSignal("Enabled"):Connect(function()
    Button:SetActive(GUI.Enabled)
    Pause = true
end)

-- 16 is not a valid member of Frame "4"
-- line 885? = clone.Name = position

local function update(coro: table, pointer: GuiBase2d, waittime: TextBox)
    local point = pointer["1"].Pointer
    local main do
        if pointer.Parent == MainFrame.Creator.PointerHolder then
            main = true
        else
            main = false
        end
    end

    pointer.Destroying:Connect(function()
        coro["run"] = false
    end)

    if not main then
        MainFrame.Creator.PointerHolder.Pointer:GetAttributeChangedSignal("count"):Connect(function()
            if tonumber(waittime.Text) == tonumber(MainFrame.Creator.Info.BPM.Text) then
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
            print(size, clonerows)
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

    clone.Bottom.add.MouseButton1Down:Connect(function()
        Pause = true
        addrow(clone, tonumber(clone.Name + 1))
    end)
    clone.Bottom.subtract.MouseButton1Down:Connect(function()
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

    clone.Parent = MainFrame.Creator.ScrollingFrame
end

coros[0] = {
    pointer = MainFrame.Creator.PointerHolder.Pointer,
    waittime = MainFrame.Creator.Info.BPM,
    run = true,
    thread = coroutine.create(update)
}
coroutine.resume(coros[0].thread, coros[0], coros[0].pointer, coros[0].waittime)

MainFrame.Creator.PointerHolder.Pointer.Bottom.add.MouseButton1Down:Connect(function()
    Pause = true
    addrow(MainFrame.Creator.PointerHolder.Pointer, 1)
end)
MainFrame.Creator.PointerHolder.Pointer.Bottom.subtract.MouseButton1Down:Connect(function()
    Pause = true
    removerow(MainFrame.Creator.PointerHolder.Pointer, 1)
end)