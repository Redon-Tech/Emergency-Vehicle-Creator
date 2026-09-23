---
title: Siren Configuration
authors:
  - Metolix
---

The EVH siren configuration is a Luau table. This page explains the fields used by EVH and how siren modifiers are stored.

## Normal sirens

A normal siren has a name, type, keybinds, behavior, and a list of modifiers.

\`\`\`lua
{
    type = "Siren",
    name = "Wail",
    keybinds = {
        Enum.KeyCode.R,
        Enum.KeyCode.Unknown,
    },
    behavoir = "Overrides Other Sounds",
    modifiers = {},
}
\`\`\`

The \`type\` is \`Siren\` for a normal siren.

A \`Hold\` siren uses the same fields but has \`type = "Hold"\`. The sound is active while its input is held.

The \`behavoir\` field can be:

- \`Overrides Other Sounds\` — other sirens are stopped or muted while this siren is active.
- \`Plays Simultaneously\` — the siren can play at the same time as other sounds.

The first keybind is the keyboard or controller input used by the configuration. An \`Unknown\` key means that slot has no usable key assigned.

## Modifier sirens

A modifier siren is a separate siren entry with \`type = "Modifier"\`.

\`\`\`lua
{
    type = "Modifier",
    name = "default",
    keybinds = {
        Enum.KeyCode.T,
        Enum.KeyCode.Unknown,
    },
}
\`\`\`

A modifier siren is **not** the same thing as a modifier inside a normal siren.

- The **Modifier siren type** is a named siren entry that can be enabled or disabled.
- A **modifier table** inside a normal or Hold siren tells EVH which modifier siren to use and what it should do to the parent siren.

## Modifier tables

Normal and Hold sirens can contain a \`modifiers\` table.

Each entry contains:

\`\`\`lua
{
    name = "default",
    modifiedSirenName = "Airhorn",
    parentSoundBehavior = "Play Parent Sound",
    behavoir = "Play Automatically",
    delay = 0,
}
\`\`\`

### Fields

- \`name\` — the name of the modifier siren entry.
- \`modifiedSirenName\` — the sound that is played by the modifier.
- \`parentSoundBehavior\` — controls what happens to the original siren.
  - \`Play Parent Sound\` stops the original siren while the modified sound is active.
  - \`Plays Simultaneously\` lets both sounds play.
- \`behavoir\` — controls when the modified sound starts.
  - \`Play Automatically\` starts it as soon as the modifier is enabled.
  - \`Require Parent Replay\` waits until the parent siren is triggered again.
- \`delay\` — controls the delay applied to the modified sound.

When a modifier is disabled, EVH stops the modified sound. If the modifier was suppressing the parent siren, EVH can resume the parent sound using the configured delay.

!!! warning
    EVC-generated configuration files say not to modify them directly. Use the plugin unless you are working on EVH or understand the configuration format.
