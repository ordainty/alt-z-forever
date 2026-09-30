---
title: Install
nav_order: 2
---

# Install

## From CurseForge or Wago

Install it with your addon manager, the same as any other addon. The manager keeps it up to date for you too.

## By hand

1. Download the latest zip from the [releases page](https://github.com/ordainty/alt-z-forever/releases).
2. Unzip it into your WoW: Forever folder, under `Interface\AddOns\`.
3. Check the folder name. It needs to be `alt-z-forever`, with `alt-z-forever.toc` directly inside. If the name's different, or there's an extra folder wrapped around it, the game can't find the addon.
4. Start the game. If it's already running, restart it, because `/reload` doesn't pick up a new addon.
5. On the character select screen, select **AddOns** and make sure Alt+Z Forever is on.

Your WoW: Forever folder lives inside your World of Warcraft install. Right now it's called `_classic_beta_`, and that name changes when Forever leaves beta. A typical path looks like this:

```
World of Warcraft\_classic_beta_\Interface\AddOns\alt-z-forever\
```

## Updating

If you use an addon manager, update it there. To update by hand, close the game, delete the old `alt-z-forever` folder and unzip the new one in its place. Your settings live outside the addon folder, so they survive the update.

## Starting over

For a clean slate, type `/azf reset`. It puts every setting back to its default, and it doesn't ask first. **Reset to defaults** in the settings window does the same thing, but it checks with you before it goes ahead.

To remove the addon, delete the `alt-z-forever` folder.
