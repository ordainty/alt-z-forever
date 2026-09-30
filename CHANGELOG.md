# Changelog

## 0.1.0

First release.

### Fading
- Fades action bars, unit frames, party and raid frames, the minimap, quest tracker, buffs, chat and other addons' frames when you aren't using them.
- Brings elements back on hover, in combat, when you pick a target, cast a spell, gain a buff or get a whisper.
- Hovering one element brings back its whole group, such as all your action bars at once.
- Buffs and debuffs at 2 or more stacks stay visible while the rest of the buff frame fades.
- Nothing fades inside dungeons, raids, battlegrounds, arenas or scenarios unless you turn that on.

### Settings
- A settings window (`/azf menu`) with four switches for every element: **Always shown**, **In combat**, **Standing still** and **Moving**.
- Separate rules for individual frames from other addons, under **Frames by addon**.
- Sliders for faded opacity, fade-in and fade-out time, and how long elements stay up.
- Reset a single row, a section, or everything.
- A minimap button opens the settings window. Turn it off under **General** if you don't want it.

### Keys and commands
- **Toggle fade mode**: switches fading off and on.
- **Hide everything / restore**: hides the whole UI, the minimap included, until you press it again.
- **Toggle element fade** and **Element fade settings**: point at any element, even a faded one, to toggle its fading or open its settings card.
- The addon doesn't bind any keys for you, so it can't clash with yours.

### Extras
- A welcome window on your first login shows the keys and how to use them. `/azf welcome` brings it back.
- AFK fade: the UI fades after 30 seconds without input and comes back when you move.
- Tooltips for units and world objects show at your cursor instead of the corner.
- `/azf report` builds a bug report for you to paste.

Based on Conceal by Keirmot (Joao Pires), GPLv3.
