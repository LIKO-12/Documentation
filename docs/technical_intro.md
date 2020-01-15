---
id: technical_intro
title: Technical Intro
sidebar_label: Technical Intro
---

LIKO-12 is a fantasy computer, which is made of multiple components.

Each component provides this fantasy computer with a specific set of functionalities, for example:

- The GPU allows the computer to have a graphical display, and do drawing operations.
- The Keyboard allows to accept some text input from the user.
- The WEB peripheral allows the computer to access the internet.

Those components in LIKO-12's universe are called: _Peripherals_.

It's a _fantasy_ computer because none of those peripherals are real, but instead they're emulated under the _host_ device (the real computer running LIKO-12), and LIKO-12 itself is just an application.

When LIKO-12 is started, some actions happen just as in real-life computers:

The BIOS initializes the whole computer, it's the first thing loaded from the whole LIKO-12 system.

By it's turn, it loads the rest of peripherals:

The BIOS by then shows that POST screen, displaying some of the fantasy specifications of the system, like the screen resolution, and the disk drives storage.

After that the BIOS checks for the file `boot.lua` in the `C` drive