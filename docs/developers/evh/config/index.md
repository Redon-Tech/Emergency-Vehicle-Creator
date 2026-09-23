---
title: Reading Configuration Files
authors:
  - Metolix
---

EVC stores the vehicle configuration in ModuleScripts used by EVH.

The main configuration files are:
- `functions.luau`
- `sirens.luau`
- `lightSettings.luau`

They are inside the vehicle's EVH configuration.

The files return Luau tables. EVH reads these tables when the vehicle loads.

## Functions

The functions configuration contains:
- function name
- function weight
- patterns
- activations

Each pattern contains:
- flashers
- faders
- rotators

A Standard activation contains a mode, pattern number, and keybinds.

## Sirens

The siren configuration contains:
- type
- name
- keybinds
- behavior
- modifiers for normal sirens

See [Siren Configuration](sirens.md) for the exact structure.

## Light settings

The light settings configuration contains:
- version
- colors
- enabled light effects
- part transparency
- light groups

## Important

The generated configuration files contain a warning not to modify them directly. For normal vehicle editing, use EVC and export the changes instead.

Direct changes are for developers who understand how EVH loads the configuration.