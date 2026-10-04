# Heart Screensaver

A native macOS screen saver with a rotating heart and customizable messages.
Supports Apple Silicon and Intel Macs.

## Install

Install Apple's command line tools if needed:

```sh
xcode-select --install
```

Clone the repository, build, and install:

```sh
git clone https://github.com/nefeldt/heart-screensaver-mac.git
cd heart-screensaver-mac
make install
```

This installs `Heart.saver` into `~/Library/Screen Savers/`.
Open System Settings, find the screen saver selection, and select **Heart**.
On newer macOS versions, the screen saver selection is under **Wallpaper**.

## Messages

Select **Heart** and open **Options…**. Enter one message per line, choose how
often messages change, and click **Save**. The default interval is 10 seconds.

If the options do not appear after an update, quit System Settings and reopen
it. A logout and login may be needed if macOS still has the previous version loaded.

## Start delay

Choose the delay in System Settings. To request a 30-second idle delay:

```sh
defaults -currentHost write com.apple.screensaver idleTime -int 30
```

macOS may reset this value when you change the delay in System Settings.

## Build only

```sh
make
```

The bundle is created at `build/Heart.saver`.

## Uninstall

Select another screen saver, then remove `Heart.saver` from
`~/Library/Screen Savers/`.
