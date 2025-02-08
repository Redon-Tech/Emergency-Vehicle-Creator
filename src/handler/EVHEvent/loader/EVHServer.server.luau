-- Redon Tech Emergency Vehicle Creator, MIT License
local version = script.Parent:WaitForChild("version").Value
require(script.Parent:WaitForChild("modules"):WaitForChild("main"))(version)
