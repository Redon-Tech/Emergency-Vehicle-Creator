---
title: Faders
authors:
  - Metolix
---

Faders change a light transparency over time.

A fader section is tied to one light and contains a list of steps.

## Creating a fader section

Open a pattern and choose **Faders**.

Click **Add Section**.

Enter the light name that should be controlled.

Each section can contain multiple steps.

## Step types

Each step has one of three types:
- **Simple**
- **Advanced**
- **Wait**

### Simple

A Simple step changes the light to a target transparency over a set time.

It uses:
- **Time**
- **Goal**
- **Color**

### Advanced

Advanced steps use the same basic values as Simple steps, but also let you choose:
- **Easing Style**
- **Easing Direction**

These values control how the transparency changes during the step.

### Wait

A Wait step does not change the light.

It waits for the amount of time entered in **Time** before moving to the next step.

## Preview

Use the play button to start the preview.

Use the pause button to stop it.

The refresh button resets the preview.

The preview loops through the steps.

## Editing steps

Add a step with the add control at the bottom of a fader section.

Delete a step with its delete control.

Changing a step type removes controls that do not apply to the new type.

!!! note
    Fader colors use the colors from **Light Settings**.