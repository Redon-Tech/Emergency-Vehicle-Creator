---
title: Pre-Outfitted Vehicles
authors:
  - Metolix
---

EVC can edit a vehicle that is already set up for EVC.

The plugin checks whether a selected vehicle is already customizable before opening the vehicle editor.

A vehicle is considered customizable when:
- it has the **EVCHandled** attribute set to true
- it has a **Body** model
- the Body contains an **Outfitting** model
- Outfitting contains a **BasePoint**

EVC adds the `EVCHandled` attribute to vehicles it creates.

## Editing an existing vehicle

1. Select the vehicle in Roblox Studio.
2. Open EVC.
3. Click **Edit Vehicle** when the selected vehicle is recognized as an EVC vehicle.
4. Make your changes.
5. Use **Export** to save the configuration.

If the selected vehicle is not already handled by EVC, the plugin opens the normal vehicle setup flow instead.

!!! note
    These are the current checks in EVC's vehicle code. A vehicle can have the right chassis type and still not be recognized as an EVC-customizable vehicle if its EVC setup is missing.