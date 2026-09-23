---
title: Siren Configuration
authors:
  - Metolix
---

The EVH siren configuration is a Luau table.

A normal siren looks like this:

```lua
{
    type = "Siren",
    name = "Wail",
    keybinds = {
        Enum.KeyCode.R,
        Enum.KeyCode.Unknown,
    },
    behavoir = "Overrides Other Sounds",
    modifiers = {},
}
```

A Hold siren uses the same fields but has `type = "Hold"`.

A modifier entry is different. It uses:

```lua
{
    type = "Modifier",
    name = "default",
    keybinds = {
        Enum.KeyCode.T,
        Enum.KeyCode.Unknown,
    },
}
```

## Siren behavior

Normal and Hold sirens use:
- `Overrides Other Sounds`
- `Plays Simultaneously`

The first keybind is the keyboard or controller input used by the configuration.

An `Unknown` key means that slot has no usable key assigned.

## Modifiers

Normal and Hold sirens can contain a `modifiers` table.

Each modifier contains:
- `name`
- `modifiedSirenName`
- `parentSoundBehavior`
- `behavoir`
- `delay`

The available values are:
- `Play Parent Sound`
- `Plays Simultaneously`
- `Play Automatically`
- `Require Parent Replay`

!!! warning
    EVC-generated configuration files say not to modify them directly. Use the plugin unless you are working on EVH or understand the configuration format.