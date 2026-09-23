---
title: Faders
authors:
  - Metolix
---

# Faders

Faders smoothly change a light over time.

A fader section controls one light and contains a list of steps.

## Create a fader

1. Open a pattern.
2. Open **Faders**.
3. Click **Add Section**.
4. Enter the light name you want to control.

You can add multiple steps to a section.

## Step types

### Simple

A Simple step changes the light to a target transparency over a set amount of time.

It uses:

- **Time**
- **Goal**
- **Color**

### Advanced

Advanced steps have the same settings as Simple steps, plus:

- **Easing Style**
- **Easing Direction**

These control how the change happens.

### Wait

A Wait step does not change the light.

It waits for the amount of time entered in **Time**, then moves to the next step.

## Preview

Use **Play** to start the preview.

Use **Pause** to stop it.

Use **Refresh** to reset it.

The preview loops through the steps.

## Edit steps

Use the add control to add a step.

Use the delete control to remove one.

When you change a step type, settings that do not apply to the new type are removed.

!!! note
    Fader colors come from **Light Settings**.
