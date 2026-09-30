---
title: Troubleshooting
nav_order: 6
---

# Troubleshooting

## Something won't fade

A few things can keep an element up. Work down this list:

- Check that fade mode is on. Typing `/azf on` makes sure.
- Check where you are. Nothing fades in dungeons, raids, battlegrounds, arenas or scenarios unless you've turned that kind off in the **In instances** section. See [In instances]({{ site.baseurl }}{% link how-it-works.md %}#in-instances).
- Open the element's section in the settings window. If **Always shown** is on, it never fades.
- Look at its other switches. **In combat**, **Standing still** and **Moving** keep it up in those situations. See [the four switches]({{ site.baseurl }}{% link settings.md %}#the-four-switches).
- If it belongs to another addon, look for it under **Frames by addon**. If it isn't there, it follows **Other frames** in the Everything else section.
- Tooltips, popups, open windows and waypoint arrows never fade. That's on purpose.
- If it's in a hover group, your mouse might be resting on another element in that group.

## Something never comes back

- Hover over the spot where it should be.
- Make sure hide-all isn't on. Press its key or type `/azf hideall` to come back.
- AFK fade might have kicked in. Hovering and tooltips don't work until you move the mouse, cast or enter combat. See [AFK fade]({{ site.baseurl }}{% link how-it-works.md %}#afk-fade).
- Check its switches. If **In combat**, **Standing still** and **Moving** are all off, only hovering brings it back.

## The pointing key does nothing

Either the key isn't bound, or there's nothing with settings under your mouse. If it isn't bound, the Keys section of the settings window shows "not set". If there's nothing under the mouse, the key tells you so in chat.

With fade mode off, the key still works. It just reminds you that nothing fades until you turn fade mode back on.

## My settings didn't save

WoW only writes settings to disk when you log out or `/reload`. If the game crashes first, you lose whatever you've changed since the last save. After a big round of changes, a quick `/reload` keeps them safe.

Fade mode and hide-all aren't settings, so they never save. Fade mode is on and hide-all is off every time you log in.

## Which frame is this?

- `/azf point` names what the pointing keys act on, and how they found it.
- `/azf under` lists the frame under your mouse and the frames it sits inside. Point at the frame, type the command and press Enter.
- `/fstack` is Blizzard's own tool. It lists every frame under the mouse.

## What does /azf debug show?

`/azf debug` prints a status report in chat. It tells you whether fade mode, hide-all and AFK fade are on, what kind of instance you're in and whether fading is off there, which keys you've bound, and any frames the addon couldn't find on this client. The rest is timing detail that helps me track down bugs.

`/azf debug <FrameName>` tells you why one frame is or isn't fading. Frame names are case-sensitive.

## Reporting a bug

If something isn't working right, I'd like to hear about it. Here's how to send me a report:

1. Type `/azf report`, or select **Report a bug** in the settings window.
2. Use **Select link** to highlight the link, press Ctrl+C and paste it into your browser. You need a free GitHub account.
3. Tell me what happened in the form.
4. Back in the game, use **Select report**, press Ctrl+C and paste the report into the form's Report box. It has your settings and addon list, but no account or character names.

If a frame fades when it shouldn't, or stays up when it should fade, point at it and type `/azf under` first. Then select **Refresh** in the report window before you copy the report, so it includes that frame.
