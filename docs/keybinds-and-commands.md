---
title: Keybinds and commands
nav_order: 5
---

# Keybinds and commands

## Keys

The addon doesn't bind keys for you, so it can't clash with any you already use.

To set them up, open the settings window (`/azf menu`), go to **Keys** and select **Open key bindings**. Find the Alt+Z Forever section in Blizzard's panel and bind the ones you want. Back in the settings window, **Keys** shows what each one's set to.

Each key has one name in Blizzard's panel and a longer one in the settings window:

| In the key bindings panel | In the settings window | What it does |
|---|---|---|
| **Toggle fade mode** | **Turn fading on and off** | Switches fade mode off and on. Same as `/azf toggle`. |
| **Toggle element fade** | **Point at an element: toggle its fading** | Switches fading on or off for the element under your mouse. |
| **Element fade settings** | **Point at an element: open its settings** | Opens a small card with the settings for the element under your mouse. |
| **Hide everything / restore** | **Hide everything, press again to restore** | Hides your whole UI. Press it again to bring it back. Same as `/azf hideall`. |

### The pointing keys

**Toggle element fade** and **Element fade settings** work on whatever's under your mouse, even when it's faded out. Aim at the empty spot where a bar normally sits and they still find it.

**Toggle element fade** flashes the element it found and tells you in chat what it is and how it's set now: "always shown" or "fades". Picked the wrong thing? Press it again to undo. If there's nothing with settings under your mouse, it tells you that instead.

**Element fade settings** opens a small card beside your mouse. It has the element's four switches, labelled **Always shown**, **Shows in combat**, **Shows when standing still** and **Shows while moving**, plus a **Reset** button. Press the key again on the same element to close the card, or on a different element to move it there. **Esc** closes it too.

With fade mode off, both keys still save your changes. Nothing fades until you turn fade mode back on, and both keys remind you about that.

These two are meant to share a key: put **Toggle element fade** on a key, and **Element fade settings** on Shift plus the same key.

![The element card, opened over the minimap]({{ '/assets/element-card.png' | relative_url }})

## Commands

Type `/azf help` in game to see this list.

| Command | What it does |
|---|---|
| `/azf` | Opens or closes the settings window. `/azf menu` does the same. |
| `/azf toggle` | Switches fade mode off and on. `/azf on` and `/azf off` work too. |
| `/azf hideall` | Hides everything. Run it again to come back. |
| `/azf reset` | Resets every setting to its default, without asking first. |
| `/azf debug` | Shows the addon's status and any frames it couldn't find. |
| `/azf debug <FrameName>` | Shows why one frame is or isn't fading. `/fstack` gives you frame names. |
| `/azf under` | Point at a frame that fades wrongly and press Enter. The bug report picks it up. |
| `/azf point` | Shows what the pointing keys act on, and how they found it. |
| `/azf report` | Opens a window with a link to the issue page and a report to paste. |
| `/azf welcome` | Opens the welcome window again, with your keys and how to use them. |
| `/azf help` | Lists these commands. |
