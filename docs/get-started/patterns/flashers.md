---
title: Flashers
authors:
  - Metolix
---

Flashers turn lights on and off in steps.

A flasher section is a grid. Each column represents a light and each row is one step in the pattern.

## Creating a flasher section

Open a pattern and choose the **Flashers** page.

Click **Add Section**.

Each section has:
- light columns
- rows
- a wait time between rows

The first section is created with no light data, so you need to add lights to it.

## Setting a light

Each column has a light name.

Enter the exact light name used by the vehicle.

The rows below the name are the steps for that light.

Choose a color for a row to turn the light on with that color.

A row set to **None** turns the light off.

You can draw across the grid:
- **Left click** adds the selected color.
- **Right click** clears the row.
- When drawing is locked, drawing can be limited to the selected column.

## Wait time

Wait time controls how long each row is shown before the next row is used.

Lower values make the pattern run faster.

A wait time of zero is supported. In that case the flasher advances one step per frame.

## Preview

Use the play button at the top of the page to preview the pattern.

The refresh button resets the preview.

Changes made while editing update the vehicle configuration.

## Adding and removing sections

Use **Add Section** to add another flasher section.

Delete a section with its delete control. EVC asks for confirmation before removing it.

A pattern can contain multiple flasher sections.

!!! note
    Flashers use the color list from **Light Settings**. Add or change a color there before using it in a pattern.