SCHEME        = RealDeal
PROJECT       = RealDeal.xcodeproj
SIMULATOR     = iPhone 16 Pro
DESTINATION   = platform=iOS Simulator,name=$(SIMULATOR)
APP_BUNDLE_ID = com.kevil.RealDeal
BUILD_DIR     = $(shell xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination "$(DESTINATION)" -showBuildSettings 2>/dev/null | grep " BUILT_PRODUCTS_DIR" | awk '{print $$3}')
APP_PATH      = $(BUILD_DIR)/$(SCHEME).app
RESULT_BUNDLE = /tmp/$(SCHEME).xcresult

.PHONY: build test coverage run install boot clean help

## Build the app for the simulator
build:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination "$(DESTINATION)" \
		-configuration Debug build | xcpretty || xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-destination "$(DESTINATION)" \
		-configuration Debug build 2>&1 | grep -E "error:|warning:|BUILD"

## Run all tests
test:
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) \
		-destination "$(DESTINATION)" \
		2>&1 | grep -E "Test case|passed|failed|BUILD|Executed"

## Run tests with code coverage report
coverage:
	xcodebuild test -project $(PROJECT) -scheme $(SCHEME) \
		-destination "$(DESTINATION)" \
		-enableCodeCoverage YES \
		-resultBundlePath $(RESULT_BUNDLE) \
		2>&1 | grep -E "passed|failed|BUILD" | tail -5
	@echo ""
	@xcrun xccov view --report $(RESULT_BUNDLE) 2>/dev/null | grep -E "\.app|\.swift" | grep -v "Test\|Mock\|xctest"

## Boot simulator, build, install, and launch app
run: boot build install
	xcrun simctl launch "$(SIMULATOR)" $(APP_BUNDLE_ID)
	open -a Simulator

## Boot the simulator
boot:
	xcrun simctl boot "$(SIMULATOR)" 2>/dev/null || true
	open -a Simulator

## Install the built app on the simulator
install:
	xcrun simctl install "$(SIMULATOR)" "$(APP_PATH)"

## Clean build artifacts
clean:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean 2>&1 | tail -3
	rm -rf /tmp/$(SCHEME).xcresult

## Show available targets
help:
	@echo "Available targets:"
	@grep -E '^(##|[a-z]+:)' Makefile | awk '/^## /{desc=substr($$0,4)} /^[a-z]+:/{printf "  make %-12s %s\n", substr($$1,1,length($$1)-1), desc}'
