---
title: Siren Setup
authors:
  - Metolix
---

The Sirens page controls the sirens used by the vehicle.

## Adding a siren

Enter a name in **New Siren Name** and click **Add**.

If the name is empty, EVC uses **Wail**. If the name is already used, EVC gives the new siren a unique name.

Each siren has a type:
- **Siren** — a normal siren that is switched on and off.
- **Hold** — a siren that stays on while its keybind is held.
- **Modifier** — changes the behavior of another siren.

## Siren behavior

Normal and Hold sirens have two behavior options:
- **Overrides Other Sounds** — the siren takes control over other sounds.
- **Plays Simultaneously** — the siren can play with other sounds.

You can assign one or more keybinds to a siren.

The default sirens are:

| Name | Type | Key |
| --- | --- | --- |
| Wail | Siren | R |
| Yelp | Siren | T |
| Priority | Siren | Y |
| Horn | Hold | H |

The default configuration also includes controller keybind slots. An `Unknown` key means no controller key is assigned.

## Siren modifiers

A modifier belongs to a normal or Hold siren.

Click **Add Modifier** on a siren to add one.

A modifier has:
- **Siren** — the modifier that will be used.
- **Modified Siren Name** — the sound name that will be played.
- **Play Parent Sound** or **Plays Simultaneously** — controls whether the original siren also plays.
- **Play Automatically** or **Require Parent Replay** — controls when the modified sound starts.
- **Delay** — the delay before the modified sound is played.

Modifiers are useful when one siren needs to use another sound without replacing the main siren setup.

## Removing sirens and modifiers

Deleting a siren removes its configuration.

Deleting a modifier removes only that modifier.

Both actions ask for confirmation before deleting the data.

!!! note
    Siren names are used by other parts of the configuration. If you rename a siren, check any rules that refer to it.