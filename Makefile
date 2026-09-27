ifeq (,$(DEVELOPER_DIR))
ifneq (,$(wildcard /Applications/Xcode.app/Contents/Developer))
export DEVELOPER_DIR := /Applications/Xcode.app/Contents/Developer
endif
endif

PROJECT := Codenotch.xcodeproj
SCHEME  := Codenotch
APP_NAME := Codenotch
ARCH    ?= $(shell uname -m)
DEST    ?= platform=macOS,arch=$(ARCH)
DERIVED := build/DerivedData
APP_DEBUG   := $(DERIVED)/Build/Products/Debug/$(APP_NAME).app
APP_RELEASE := $(DERIVED)/Build/Products/Release/$(APP_NAME).app
XCB := xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DEST)' -derivedDataPath $(DERIVED)

.PHONY: gen build test run release verify clean

gen:
	xcodegen generate

build: gen
	$(XCB) -configuration Debug build

test: gen
	$(XCB) -configuration Debug test

run: build
	pkill -x $(APP_NAME) 2>/dev/null || true
	open "$(APP_DEBUG)"

release: gen
	$(XCB) -configuration Release build
	@echo "$(APP_RELEASE)"

# The shipped bundle must stay sandboxed, without network entitlements and
# without embedded frameworks.
verify:
	@APP="$(APP_RELEASE)"; test -d "$$APP" || APP="$(APP_DEBUG)"; \
	echo "Checking $$APP"; \
	codesign -d --entitlements - --xml "$$APP" 2>/dev/null | plutil -p - ; \
	codesign -d --entitlements - --xml "$$APP" 2>/dev/null | grep -q 'com.apple.security.app-sandbox' \
		|| { echo "FAIL: sandbox is off"; exit 1; }; \
	! codesign -d --entitlements - --xml "$$APP" 2>/dev/null | grep -Eq 'network|files\.|temporary-exception|get-task-allow' \
		|| { echo "FAIL: unexpected entitlement"; exit 1; }; \
	test ! -d "$$APP/Contents/Frameworks" || { echo "FAIL: embedded frameworks"; ls "$$APP/Contents/Frameworks"; exit 1; }; \
	echo "OK"

clean:
	rm -rf build $(PROJECT)
