---
title: Settings
nav_order: 4
---

# Settings

Type `/azf menu`, or just `/azf`, to open the settings window, or select the addon's button on the minimap. You can also get there from the game's own options: go to **AddOns > Alt+Z Forever** and select **Open settings**. The list down the left side jumps to each part of the window.

Changes take effect as soon as you make them, and every character on your account shares them. WoW writes them to disk when you log out or `/reload`, so if the game crashes, you lose anything you've changed since then. That's why the window offers to reload for you when you close it after a change.

![The settings window: Keys, General and About]({{ '/assets/settings-window.png' | relative_url }})

## Keys

Here you can see the addon's four keys and what each one's bound to. A key without a binding shows "not set". Select **Open key bindings** to jump to Blizzard's key bindings panel. See [Keybinds and commands]({{ site.baseurl }}{% link keybinds-and-commands.md %}).

## General

- **Faded opacity**: how visible faded elements are, from 0 to 100%. At 0, they're gone completely.
- **Wait before fading**: how long elements stay up after combat ends or you start moving.
- **Fade-out time**: how long the fade itself takes.
- **Fade-in time**: how long elements take to come back. Hovering always brings them back instantly.
- **Tooltips follow the mouse**: shows corner tooltips at your cursor.
- **Fade when you're away (AFK)** and **AFK fade after**: see [AFK fade]({{ site.baseurl }}{% link how-it-works.md %}#afk-fade).
- **Minimap button**: shows a button on the minimap that opens this window. Drag it to move it around the minimap. It fades with the minimap.

## About

The addon's **CurseForge** link. Choose **Select** next to it, then press Ctrl+C to copy it.

## Elements

Your elements live in five sections: **Action bars**, **Unit frames**, **Party and raid**, **Minimap, quests and buffs**, and **Everything else**. Select a section's title to open it, or use **Expand all** and **Collapse all** to open or close them all at once.

### The four switches

Every element has the same four switches.

| Switch | When it's on |
|---|---|
| **Always shown** | The element never fades. |
| **In combat** | The element shows in combat. When it's off, the element stays faded in combat unless you hover it. |
| **Standing still** | The element shows when you stop moving, out of combat. |
| **Moving** | The element shows while you move, out of combat. |

Hover a column heading if you need a reminder. Focus in Unit frames and the three cooldown viewers in Action bars start out as always shown.

Under the headings there's a **Select all** row. Each box in it turns that switch on for every element in the section, or off again if they're all on already.

### Hover group and stay-up time

Each section opens with these settings:

- **Hover one, show all**: hover any element and the whole group comes back. Not every section has one. See [Hover groups]({{ site.baseurl }}{% link how-it-works.md %}#hover-groups).
- **Keep showing after hover**: how many seconds the group stays up after the mouse leaves.
- **Then hide at once**: when that time's up, the group disappears instead of fading out.

### Extra options

**Unit frames** has three more:

- **Show while you have a target**: keeps your target and player frames up for as long as you have a target.
- **Target shows for**: how long those frames show after you pick a target. It matters when the setting above is off, and for the player frame after you clear your target.
- **Turn off the cast bar**: this one isn't a fade. It switches your cast bar off completely, and you need to `/reload` to get it back.

**Minimap, quests and buffs** adds **Show buffs when a new buff arrives** and **Always show auras at 2+ stacks**. [How it works]({{ site.baseurl }}{% link how-it-works.md %}#auras-that-stay-visible) explains both.

**Everything else** holds **Chat**, **RestedXP Guides** and **Other frames**. Other frames covers anything that isn't listed somewhere else, including other addons' frames. There's no hover group here.

## In instances

There's one box for each kind of instance: **Show the UI in dungeons**, **Show the UI in raids**, **Show the UI in battlegrounds**, **Show the UI in arenas** and **Show the UI in scenarios**. They're all on to start with, so nothing fades in any instance. Turn one off to let the UI fade there. See [In instances]({{ site.baseurl }}{% link how-it-works.md %}#in-instances).

## Frames by addon

This is where you find frames that don't have a row of their own, grouped by the addon that made them. A few belong to the game itself. Each frame follows its group until you change one of its switches. That switch then belongs to the frame, and the other three keep following the group.

The list fills in as frames appear on screen, so if you haven't seen a frame this session, it isn't here yet. "(not loaded)" next to a name means you've got settings saved for a frame whose addon isn't running right now.

## Resetting

Each section heading shows "(n changed)", which counts the settings in it that differ from the defaults.

- **Reset** in a section heading puts that section back to its defaults. It leaves the frames in Frames by addon alone.
- **Reset** in the Frames by addon heading clears every rule you've given an individual frame, so they all follow their groups again.
- Right-click an element's name to reset just that row, or right-click a slider to reset just that slider.
- **Reset to defaults**, at the bottom of the window, resets everything. `/azf reset` does too. The button asks you first, but the command doesn't.
