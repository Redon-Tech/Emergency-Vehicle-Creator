---
title: Rotators
authors:
  - Metolix
---

Rotators move a light through a sequence of angles.

A rotator section controls one light and contains a list of rotation steps.

## Creating a rotator section

Open a pattern and choose **Rotators**.

Click **Add Section**.

Enter the light name that should be controlled.

## Step types

Each step can be:
- **Angle**
- **Infinite**
- **Wait**

### Angle

An Angle step moves the light by the amount entered in **Angle**.

It also uses:
- **Color**
- **Velocity**

### Infinite

An Infinite step keeps the light rotating until the next step.

It uses:
- **Color**
- **Velocity**

### Wait

A Wait step pauses the sequence for the entered **Wait Time**.

## Preview

Use the play button to preview the sequence.

Use the pause button to stop it.

Use the refresh button to reset it.

The sequence loops while the preview is running.

## Editing steps

Add a step with the add control.

Delete a step with its delete control.

EVC asks for confirmation before deleting a step.

!!! note
    Rotator colors come from **Light Settings**.