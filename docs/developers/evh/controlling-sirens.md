---
  title: Controlling Sirens
  authors:
    - parker02311
---

??? warning "Documentation is a Work in Progress"
    This documentation is a work in progress and may be missing information or contain errors.
    If you need help please contact us on our [Discord server](https://redon.tech/discord)!

    If you know about this topic and want to help us, please consider contributing to this page on [GitHub](https://github.com/Redon-Tech/Emergency-Vehicle-Creator).

Working with sirens is a more complicated topic with EVH. You can read the status of sirens on the client and server, but **changing sirens is a client-side only** operation.

## Reading the current siren state
Unlike functions, sirens are not stored as attributes on the vehicle. Instead, you must use the sound properties to get the current siren state.

Here's a code snippet showing how to get the current siren state of a vehicle:
```lua
-- Client or server-side script
local siren = ... -- reference to the siren sound object

local isSirenOn = siren.IsPlaying
print("Is siren on: ", isSirenOn)
```

To do something whenever the siren state changes, you can use the `GetPropertyChangedSignal` function like so:
```lua
-- Assuming same context as above
siren:GetPropertyChangedSignal("IsPlaying"):Connect(function()
    local isSirenOn = siren.IsPlaying
    print("Siren state changed. Is siren on: ", isSirenOn)
end)
```

## Setting the siren state
As mentioned earlier, changing the siren state is a client-side only operation. This must be done via the RemoteEvent.

Here's a code snippet showing how to change the siren:
```lua
-- Client-side script
local car = ... -- reference to the vehicle model
local evhEvent = car:WaitForChild("EVHEvent")

-- Toggle standard siren
evhEvent:FireServer("Input", Enum.UserInputState.Begin, Enum.UserInputType.Keyboard, Enum.KeyCode.R) -- replace 'R' with your siren keybind

-- Turn hold siren on
evhEvent:FireServer("Input", Enum.UserInputState.Begin, Enum.UserInputType.Keyboard, Enum.KeyCode.H) -- replace 'H' with your hold siren keybind
-- Turn hold siren off
evhEvent:FireServer("Input", Enum.UserInputState.End, Enum.UserInputType.Keyboard, Enum.KeyCode.H) -- replace 'H' with your hold siren keybind
```

## :material-check-circle: All Done!
If you need to dynamically load sirens and keybinds, please see the [Reading Siren Configurations](config/sirens.md) section in the documentation for more information.

![](https://media1.tenor.com/m/DdGHNuDwnqoAAAAd/its-as-shrimple-as-that-shrimple.gif)