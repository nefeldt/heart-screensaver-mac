SDKROOT := $(shell xcrun --show-sdk-path)
SAVER := build/Heart.saver
VERSION := $(shell /usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Info.plist)
DMG := build/Heart-$(VERSION).dmg
SIGN_IDENTITY ?=
NOTARY_PROFILE ?=

.PHONY: build install release clean
build: $(SAVER)/Contents/MacOS/Heart

$(SAVER)/Contents/MacOS/Heart: Heart.m Info.plist
	mkdir -p $(SAVER)/Contents/MacOS
	cp Info.plist $(SAVER)/Contents/Info.plist
	xcrun clang -fobjc-arc -Wall -Wextra -Wno-unused-parameter -Wno-deprecated-declarations -O2 -isysroot "$(SDKROOT)" -mmacosx-version-min=11.0 -arch arm64 -arch x86_64 -bundle Heart.m -framework ScreenSaver -framework Cocoa -framework OpenGL -o $@
	codesign --force --sign - $(SAVER)

install: build
	mkdir -p "$(HOME)/Library/Screen Savers"
	ditto $(SAVER) "$(HOME)/Library/Screen Savers/Heart.saver"

release: build
	@test -n "$(SIGN_IDENTITY)" || { echo 'Set SIGN_IDENTITY to your Developer ID Application identity'; exit 1; }
	@case "$(SIGN_IDENTITY)" in "Developer ID Application: "*) ;; *) echo 'A Developer ID Application certificate is required'; exit 1 ;; esac
	@test -n "$(NOTARY_PROFILE)" || { echo 'Set NOTARY_PROFILE to your notarytool keychain profile'; exit 1; }
	codesign --force --sign "$(SIGN_IDENTITY)" --timestamp --options runtime $(SAVER)
	codesign --verify --strict $(SAVER)
	rm -rf build/release
	mkdir -p build/release
	ditto $(SAVER) build/release/Heart.saver
	hdiutil create -ov -format UDZO -volname Heart -srcfolder build/release "$(DMG)"
	codesign --sign "$(SIGN_IDENTITY)" --timestamp "$(DMG)"
	xcrun notarytool submit "$(DMG)" --keychain-profile "$(NOTARY_PROFILE)" --wait
	xcrun stapler staple "$(DMG)"
	xcrun stapler validate "$(DMG)"
	spctl --assess --type open --context context:primary-signature --verbose "$(DMG)"
	shasum -a 256 "$(DMG)" > "$(DMG).sha256"

clean:
	rm -rf build
