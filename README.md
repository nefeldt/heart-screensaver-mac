# Heart Screensaver

A native macOS screen saver with a rotating heart and customizable messages.
Supports Apple Silicon and Intel Macs.

![Heart screen saver with the message I love my job](preview.png)

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

## Signed release

You need a **Developer ID Application** certificate with its private key in your
login keychain. Create it in Xcode's account settings under **Manage Certificates**
or through your Apple Developer account. Apple Development and iPhone Distribution
certificates cannot be used for this release.

Store notarization credentials using the interactive Keychain prompt:

```sh
xcrun notarytool store-credentials heart-notary
```

Build, sign, notarize, and validate the disk image:

```sh
make release \
  SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
  NOTARY_PROFILE=heart-notary
```

The version comes from `Info.plist`. After this command succeeds,
`build/Heart-1.0.dmg` and its `.sha256` file can be attached to a GitHub release.
Nothing is published automatically. Open the disk image and double-click
`Heart.saver` to install it.

See Apple's [notarization documentation](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
for details.
