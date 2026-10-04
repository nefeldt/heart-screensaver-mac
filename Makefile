SDKROOT := $(shell xcrun --show-sdk-path)
SAVER := build/Heart.saver

.PHONY: build install clean
build: $(SAVER)/Contents/MacOS/Heart

$(SAVER)/Contents/MacOS/Heart: Heart.m Info.plist
	mkdir -p $(SAVER)/Contents/MacOS
	cp Info.plist $(SAVER)/Contents/Info.plist
	xcrun clang -fobjc-arc -Wall -Wextra -Wno-unused-parameter -Wno-deprecated-declarations -O2 -isysroot "$(SDKROOT)" -mmacosx-version-min=11.0 -arch arm64 -arch x86_64 -bundle Heart.m -framework ScreenSaver -framework Cocoa -framework OpenGL -o $@
	codesign --force --sign - $(SAVER)

install: build
	mkdir -p "$(HOME)/Library/Screen Savers"
	ditto $(SAVER) "$(HOME)/Library/Screen Savers/Heart.saver"

clean:
	rm -rf build
