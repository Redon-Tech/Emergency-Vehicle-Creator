---
title: Activations
authors:
  - Metolix
---

Activations decide how a function is turned on and which pattern it uses.

A function can have more than one activation.

## Standard

A Standard activation is controlled by one or more keybinds.

It has two modes:
- **Cycle**: moves through the patterns in the function.
- **Set Pattern**: selects one pattern number.

For **Set Pattern**, enter the pattern number you want the keybind to select.

For **Cycle**, the pattern number field is not used.

You can add more than one keybind to an activation.

The default Standard activation uses **J** and **DPadLeft**.

## Default

A Default activation selects the pattern that should be used by default.

Choose the pattern number you want the function to use.

## Override

An Override activation makes a function react to another vehicle state.

The available modes are:
- **Siren Override**
- **Park**
- **Brake**
- **Reverse**

For **Siren Override**, choose the siren that should trigger the override.

You can also set a dependent function and dependent pattern. These let the override use another function pattern as part of the rule.

## AG-Event

AG-Event activations are available for AG-Chassis and MG-Chassis vehicles.

The available events are:
- **Stages**
- **Traffic Advisor**
- **Scene**
- **Ally Left**
- **Ally Right**
- **Rear Scene**

These activations do not use a keybind or pattern number.

## Editing activations

Open a function and switch from **Patterns** to **Activation**.

Change the activation type first. The controls shown below it change based on the selected type.

Delete an activation with the delete control on its row.

Changing an activation marks the vehicle as having unsaved changes.

!!! note
    Pattern numbers are zero-based in the configuration. The first pattern is pattern `0` in the exported configuration.