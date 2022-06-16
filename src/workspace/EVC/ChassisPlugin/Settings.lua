--[[
Redon Tech 2022
EVC
--]]

--------------------------------------------------------------------------------
-- Settings --
--------------------------------------------------------------------------------

return {
    -- The name of the lightbar in body
    LightbarLocation = "Lightbar",

    -- The name of the siren location inside the lightbar location
    SirenLocation = "middle", 

    -- The airhorn name inside the siren location
    AirhornLocation = "Horn",

    -- All the selectable sirens and there respected keybinds
    -- Modifier keys are planned for a future update
    Sirens = {
        [Enum.KeyCode.R] = "Wail",
        [Enum.KeyCode.T] = "Yelp",
        [Enum.KeyCode.Y] = "Priority"
    },

    -- All the keybinds for any other functionality the system has
    -- Currently only the following functions are avaliable:
    --      - Lights: Changes the current stage
    --      - TrafficAdvisor: Changes the current traffic advisor direction
    Keybinds = {
        ["Lights"] = Enum.KeyCode.J,
        ["TrafficAdvisor"] = Enum.KeyCode.K
    },
}