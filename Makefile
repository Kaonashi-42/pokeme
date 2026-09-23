APP := PokeMe.app
LINT_PATHS := Package.swift Sources Tests
# Override on release builds, e.g. `make package VERSION=1.2.0`.
VERSION ?= $(shell /usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Info.plist)
ZIP := PokeMe-$(VERSION).zip
# Universal binary so the release runs on both Apple silicon and Intel Macs.
SWIFT_BUILD := swift build -c release --arch arm64 --arch x86_64

.PHONY: all build app package test lint format install clean

all: lint test app

build:
	$(SWIFT_BUILD)

# Assemble a signed .app bundle: EventKit permissions require a bundle with an Info.plist.
app: build
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS
	cp Info.plist $(APP)/Contents/
	/usr/libexec/PlistBuddy \
		-c "Set :CFBundleShortVersionString $(VERSION)" \
		-c "Set :CFBundleVersion $(VERSION)" \
		$(APP)/Contents/Info.plist
	cp "$$($(SWIFT_BUILD) --show-bin-path)/PokeMe" $(APP)/Contents/MacOS/PokeMe
	codesign --force --sign - $(APP)

# Zip the bundle for distribution. ditto keeps the code signature and extended attributes intact.
package: app
	rm -f PokeMe-*.zip PokeMe-*.zip.sha256
	ditto -c -k --keepParent $(APP) $(ZIP)
	shasum -a 256 $(ZIP) > $(ZIP).sha256

test:
	swift test

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
