<h1 align="center"> <img src="/docs/assets/EVC.png" alt="Icon" height=35 vertical-align="middle" /> Emergency Vehicle Creator </h1>

<div align="center">
  
  [![Install on Roblox](https://img.shields.io/badge/Install%20on-Roblox-00A2FF?style=for-the-badge&logo=robloxstudio&logoColor=ffffff&labelColor=302d41)](https://create.roblox.com/store/asset/9953321418/)
  [![Static Badge](https://img.shields.io/badge/Documentation-cba6f7?style=for-the-badge&logo=materialformkdocs&logoColor=ffffff&labelColor=302d41)](https://evc.redon.tech)
  [![Discord](https://img.shields.io/discord/536555061510144020?label=discord&logo=discord&logoColor=rgb(255,255,255)&labelColor=302d41&style=for-the-badge)](https://discord.gg/Eb384Xw)
  [![Latest Release](https://img.shields.io/github/v/release/redon-tech/Emergency-Vehicle-Creator?logo=githubactions&logoColor=rgb(255,255,255)&labelColor=302d41&style=for-the-badge)](https://github.com/Redon-Tech/Emergency-Vehicle-Creator/releases)

</div>

---

![Beautiful screenshot of rotator creator](/docs/assets/img/EVC-Dropshadow.png)

# Unleash your creativity

Emergency Vehicle Creator is a plugin that allows you to easily create emergency vehicles in Roblox Studio.

Version 3 is designed to be more user-friendly and efficient than ever before.

No coding required, just your creativity. Start creating your vehicles today.

## Interested?

Installing is easy, just get it from the [Roblox marketplace](https://create.roblox.com/store/asset/9953321418/) or download and manually install from the [latest release](https://github.com/Redon-Tech/Emergency-Vehicle-Creator/releases/latest).

---

## Contributing & Issues

Coming Soon

Emergency Vehicle Handler Outline
```
Emergency Vehicle Handler
  EVHEvent
    loader
      modules
        TODO
      EVHServer (Only runs in studio)
      EVHClient
    configuration
      lightFunction
      functions
      sirens
      lightGroups
```
[tree gen](https://tree.nathanfriend.com/?s=(%27op0s!(%27fancy!true~fullPath!false~trailingSlash!true~rootDot!false)~2(%272%27.Emergency%20Vehicle%20Handler.-EVHEv3loader*modules*-TODO6Server%20%7BOnly%20runs%20in%20studio%7D6Cli3configura04F5*f5s*sirens4Groups%27)~version!%271%27)*.----%20%20.%5Cn0tion2source!3ent.--4*light5unc06*EVH%01654320.-*)

Known Bugs:
- [ ] Need an UIAspectRatio Constraint somewhere
- [ ] ~~Sirens delete two when you delete one~~
- [ ] Renaming a fader doesnt rename it properly on the export sometimes
- [ ] Flashers fake bloom zindex problem
- [ ] Settings menu dropdowns text is small
- [ ] If no colors are available, completely fucks everything
- [ ] V2 to V3 scrambles everything around in the menu (it also needs to ensure that each activation has two keybinds)
- [ ] Sometimes setting weight or pattern higher can cause problems
- [x] Going to vehicle setup can sometimes cause return to to be set to vehicle setup instead of main menu
- [ ] Color selector appears on ui reload
- [x] Explorer badges not working
- [x] No credits
- [ ] Light prefix needs to take the name of lights from the original customization model then replace it with the new name
- [ ] Does not like name without numbers (or not hitting enter)