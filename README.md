# Heart Screensaver

A native macOS screen saver with a rotating heart and customizable messages.
Supports Apple Silicon and Intel Macs.

![Animated Heart screen saver preview in 1920 × 1080](preview.gif)

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
