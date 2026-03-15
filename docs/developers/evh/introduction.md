---
  authors:
    - parker02311
---

??? warning "Documentation is a Work in Progress"
    This documentation is a work in progress and may be missing information or contain errors.
    If you need help please contact us on our [Discord server](https://redon.tech/discord)!

    If you know about this topic and want to help us, please consider contributing to this page on [GitHub](https://github.com/Redon-Tech/Emergency-Vehicle-Creator).

Emergency Vehicle Handler (EVH from here on out) is designed to be extremely modular and expandable.

The backbone of how this works is through how EVH loads when the game starts. EVH will conduct the following steps when the game starts:

1. Immediately call the client side to initialize itself.
2. The client will then check to see if ther are already any EVH systems running.
3. If there are, it will do a version check to see if this version is newer than the one already running.
    1. If it is newer, this one will also load fully but only iteract with its own vehicles.
4. If there are no other EVH systems running, it will fully initialize itself.
    1. This version will also be responsible for handling all older vehicles running older versions of EVH.


This means it is entirely possible to fully replace EVH in your game for all vehicles. Allowing for full control over functionality.

However, most people will simply want to just control what patterns are running, what sirens are on, etc. Thankfully, EVH was designed with this in mind.

!!! danger "New Programmers Beware"
    EVH is a very complex system. It is highly recommended that you have a good understanding of programming and Lua before attempting to modify or expand EVH.

    If you are simply interested on controlling patterns, sirens, etc. please see the [Patterns](./patterns.md) and [Controlling Sirens](./controlling-sirens.md) documentation.