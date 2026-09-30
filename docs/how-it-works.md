---
title: How it works
nav_order: 3
---

# How it works

## Fade mode

Fade mode is the master switch. While it's on, elements fade when you aren't using them. While it's off, nothing fades and your interface looks the way WoW normally draws it, though hide-all and AFK fade still work. Either way, your settings stay put.

Fade mode doesn't save. It's on every time you log in or reload.

Switch it off and on with your **Toggle fade mode** key or `/azf toggle`. `/azf on` and `/azf off` work too.

Faded elements drop to the **Faded opacity** you set in General. It starts at 0, which hides them completely. If you'd like to keep a faint trace of your UI, raise it.

## What brings an element back

Every element has its own rules, and you can change them all in [Settings]({{ site.baseurl }}{% link settings.md %}). Here's what happens with the defaults.

Hover over a faded element and it's back instantly. Elements come in groups, so its neighbours come back with it. See [Hover groups](#hover-groups).

Combat brings back most elements. The quest tracker and RestedXP Guides stay faded, since you rarely need them mid-fight.

When you stop moving, the minimap, quest tracker, chat, party frames and RestedXP Guides fade back in. Everything else waits until something brings it back. Moving on its own doesn't show anything. You can change both for each element with the **Standing still** and **Moving** switches.

While you have a target, your target and player frames stay up. Picking a target also shows them for 7 seconds, even while you're moving. If you'd rather have just the 7 seconds, turn off **Show while you have a target** in the Unit frames section.

Casting a spell brings your action bars back for 3 seconds and shows your target and player frames for 7. A failed cast or a button press does the same.

When you gain a buff, the buff frame shows for the **Keep showing after hover** time in the Minimap, quests and buffs section. That's 3 seconds by default. To stop it, turn off **Show buffs when a new buff arrives** in the same section.

A whisper, including a Battle.net whisper, shows chat for 10 seconds. The exception is [hide-all](#hide-all) and [AFK fade](#afk-fade). During those, chat waits and comes back with everything else.

Chat also stays up while you type. After you send a message, close the chat box or move the mouse off chat, it stays for another 3 seconds.

If you'd like a pause before anything fades, set **Wait before fading** in General. It keeps elements up for a while after combat ends or you start moving. It's 0 seconds by default.

## Hover groups

When you hover one element, its whole group comes back with it. There are four groups:

- Action bars: any bar brings back all of them, plus the micro menu, bags and XP bar.
- Unit frames: the player, pet, target or focus frame brings back all of them.
- Party and raid: the party frames and the raid panel come back together.
- Minimap, quests and buffs: the minimap, quest tracker, buffs and debuffs come back together.

Everything else doesn't get a group, because one hover there would bring back the whole screen.

To make every element in a section come back on its own, turn off that section's **Hover one, show all**.

### Staying up after a hover

**Keep showing after hover** sets how long a group stays up once the mouse leaves. Most groups start at 0, so they fade as soon as you move away. The minimap group stays for 3 seconds and then disappears without a fade, because **Then hide at once** is on for that section.

## Auras that stay visible

Any buff or debuff at 2 or more stacks stays visible while the rest of the buff frame fades, so you can keep an eye on it. Turn that off with **Always show auras at 2+ stacks** in the Minimap, quests and buffs section.

## Tooltips

Tooltips that usually sit in the bottom-right corner, for units and world objects, show up at your cursor instead. Action button and bag tooltips stay where they always are. If you prefer the corner, turn off **Tooltips follow the mouse** in General.

## Other addons' frames

Other addons' frames fade along with everything else. By default they follow the **Other frames** row in the Everything else section, and you can give any of them its own rules under **Frames by addon**.

Tooltips, popups, windows you've opened and waypoint arrows never fade.

## In instances

Inside dungeons, raids, battlegrounds, arenas and scenarios, nothing fades by default. Your UI looks the way it normally does there. Hide-all and AFK fade still work.

To let the UI fade in one kind of instance, turn off its box in the **In instances** section of the settings window, for example **Show the UI in raids**.

## Hide-all

Hide-all hides everything, even elements set to **Always shown**, the minimap included. It works with fade mode off too, and it's always off when you log in.

Press your **Hide everything / restore** key or type `/azf hideall`, then do it again to come back. Hide-all never touches your settings, so you're back exactly where you left off.

Hovering still works while hide-all is on. Targeting something, or selecting a unit with the mouse, flashes your target and player frames for 5 seconds. Casting and whispers don't bring anything back.

## AFK fade

After 30 seconds without any input, AFK fade hides your UI the way hide-all does. The difference is that it leaves anything set to **Always shown** where it is. It's on by default, it never starts in combat, and it works even with fade mode off or inside an instance. In General, **Fade when you're away (AFK)** turns it on and off, and **AFK fade after** sets the wait, anywhere from 15 to 300 seconds.

Your UI comes back as soon as you move the mouse, select a unit, press an action button, cast, target something, enter combat or move your character.

While AFK fade is on, hovering doesn't bring anything back and tooltips don't appear. Whispers wait too, and chat returns with everything else.
