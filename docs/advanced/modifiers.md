---
title: Modifiers
authors:
  - Metolix
  - parker02311
---

## What are modifiers?

Modifiers let one siren use another sound while control is managed from the original siren settings. For example, a rumbler is a modifier.

---

## How modifiers work

A modifier uses two siren entries:

1. A **Modifier** type siren, this controls how to enable the modifier.
2. A normal or Hold siren with a modifier entry that points to the sound you want to play.

For example, you could have a normal **Wail** siren and an **Wail Rumbler** modifier siren. The Wail siren can have a modifier that plays the rumbler sound when the modifier is enabled.

The modifier can either replace the parent siren or let both sounds play at the same time.

## Modifier settings

| Setting                   | What it does                                                                        |
| ------------------------- | ----------------------------------------------------------------------------------- |
| **Siren**                 | Which modifier enables this modified sound.                                         |
| **Modified Siren Name**   | Chooses the sound that will play.                                                   |
| **Play Parent Sound**     | Stops the original siren while the modified sound is active.                        |
| **Plays Simultaneously**  | Lets the original and modified sounds play together.                                |
| **Play Automatically**    | Starts the modified sound when the modifier is enabled.                             |
| **Require Parent Replay** | Waits for the parent siren to be triggered again before playing the modified sound. |
| **Delay**                 | Applies a delay to the modified sound.                                              |

## Example

Suppose you have:

- **Wail** as the parent siren.
- **Wail Rumbler** as a Modifier siren.

You can add a modifier to Wail that uses the rumbler sound.

If **Play Parent Sound** is selected, the Wail sound is stopped while the rumbler is active.

If **Plays Simultaneously** is selected, Wail continues playing while the rumbler plays.

With **Play Automatically**, the rumbler starts as soon as the modifier is enabled.

With **Require Parent Replay**, the modifier waits for Wail to be triggered again before playing the rumbler.

## Removing a modifier

Open the **Sirens** page and use the delete control for the modifier you want to remove.