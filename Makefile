APP := PokeMe.app
LINT_PATHS := Package.swift Sources Tests scripts
# Override on release builds, e.g. `make package VERSION=1.2.0`.
VERSION ?= $(shell /usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Info.plist)
ZIP := PokeMe-$(VERSION).zip
# Universal binary so the release runs on both Apple silicon and Intel Macs.
SWIFT_BUILD := swift build -c release --arch arm64 --arch x86_64

.PHONY: all build app icon screenshot package test coverage lint format install clean

all: lint test app

build:
	$(SWIFT_BUILD)

# Assemble a signed .app bundle: EventKit permissions require a bundle with an Info.plist.
app: build
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	cp Info.plist $(APP)/Contents/
	cp Resources/AppIcon.icns $(APP)/Contents/Resources/
	/usr/libexec/PlistBuddy \
		-c "Set :CFBundleShortVersionString $(VERSION)" \
		-c "Set :CFBundleVersion $(VERSION)" \
		$(APP)/Contents/Info.plist
	cp "$$($(SWIFT_BUILD) --show-bin-path)/PokeMe" $(APP)/Contents/MacOS/PokeMe
	codesign --force --options runtime --entitlements PokeMe.entitlements --sign - $(APP)

# Regenerate Resources/AppIcon.icns from scripts/make-icon.swift (the .icns is committed, so builds don't need this).
icon:
	rm -rf .build/AppIcon.iconset
	swift scripts/make-icon.swift .build/AppIcon.iconset
	mkdir -p Resources
	iconutil --convert icns --output Resources/AppIcon.icns .build/AppIcon.iconset
	cp .build/AppIcon.iconset/icon_128x128@2x.png docs/icon.png

# Render the overlay with the sample meeting for the README. Uses the unsandboxed debug build so it can write to docs/.
screenshot:
	swift run PokeMe --render-preview docs/overlay.png

# Zip the bundle for distribution. ditto keeps the code signature and extended attributes intact.
package: app
	rm -f PokeMe-*.zip PokeMe-*.zip.sha256
	ditto -c -k --keepParent $(APP) $(ZIP)
	shasum -a 256 $(ZIP) > $(ZIP).sha256

test:
	swift test

# Tests plus line coverage of PokeMeCore (the app target is thin platform glue with no unit tests).
coverage:
	swift test --enable-code-coverage
	python3 scripts/coverage.py "$$(swift test --show-codecov-path)" Sources/PokeMeCore $(if $(BADGE),--badge $(BADGE))

lint:
	swift format lint --strict --recursive --parallel $(LINT_PATHS)

format:
	swift format format --in-place --recursive --parallel $(LINT_PATHS)

install: app
	-pkill -x PokeMe && sleep 1
	rm -rf /Applications/$(APP)
	cp -R $(APP) /Applications/
	open /Applications/$(APP)

clean:
	rm -rf .build $(APP) PokeMe-*.zip PokeMe-*.zip.sha256
