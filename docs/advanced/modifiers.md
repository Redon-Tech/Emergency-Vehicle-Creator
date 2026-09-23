---
title: Modifiers
authors:
  - Metolix
---

Modifiers are part of the siren system.

A modifier lets a siren use another sound while keeping control over how the original siren behaves.

Modifiers are added from the **Sirens** page.

## Modifier settings

| Setting | What it controls |
| --- | --- |
| Siren | The modifier sound to use |
| Modified Siren Name | The sound object that will be played |
| Play Parent Sound | Keep the original siren playing |
| Plays Simultaneously | Allow the original and modified sound to play together |
| Play Automatically | Start the modified sound when the modifier is triggered |
| Require Parent Replay | Wait for the parent siren to be triggered again |
| Delay | Time before the modified sound starts |

A modifier must refer to a modifier-type siren that exists in the vehicle configuration.

## Example

A normal siren can have a modifier that plays a different sound after a delay.

The parent behavior decides whether the normal siren continues.

The play behavior decides whether the modified sound starts automatically or waits for the parent to be played again.

Modifiers can be removed from the Sirens page with the delete control.