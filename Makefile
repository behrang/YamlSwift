# Usage: make [CONFIG=debug|release]
# Make file is based on:
#   http://owensd.io/2015/01/14/compiling-swift-without-xcode.html

MODULE_NAME   = Yaml
SDK           = macosx

CONFIG       ?= debug

ROOT_DIR      = $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
BUILD_DIR    = $(ROOT_DIR)/build
TARGET_DIR    = $(BUILD_DIR)/$(SDK)/$(CONFIG)
FRAMEWORK_DIR = $(TARGET_DIR)/$(MODULE_NAME).framework
SRC_DIR       = $(ROOT_DIR)

ifeq ($(CONFIG), debug)
	CFLAGS=-Onone -g
else
	CFLAGS=-O -whole-module-optimization
endif

SWIFTC      = $(shell xcrun -f swiftc)
SDK_PATH    = $(shell xcrun --show-sdk-path --sdk $(SDK))
SWIFT_FILES = $(shell find $(SRC_DIR) -name '*.swift' -not -name 'Test.swift' -type f)

all: $(FRAMEWORK_DIR)

$(FRAMEWORK_DIR): $(SWIFT_FILES)
	@echo Build framework...
	@rm -rf $(FRAMEWORK_DIR)
	@mkdir -p $(FRAMEWORK_DIR)
	@$(SWIFTC) $(SWIFT_FILES) \
		$(CFLAGS) \
		-sdk $(SDK_PATH) \
		-module-name $(MODULE_NAME) \
		-emit-module \
		-emit-module-path $(FRAMEWORK_DIR)/$(MODULE_NAME).swiftmodule \
		-emit-library \
		-o $(FRAMEWORK_DIR)/$(MODULE_NAME)

$(BUILD_DIR)/test: Test.swift $(FRAMEWORK_DIR)
	@echo Build test...
	@$(SWIFTC) Test.swift \
		-sdk $(SDK_PATH) \
		-emit-executable \
		-I $(FRAMEWORK_DIR) \
		-F $(TARGET_DIR) \
		-framework $(MODULE_NAME) \
		-o $@

test: $(BUILD_DIR)/test
	@echo Testing...
	@$(BUILD_DIR)/test

clean:
	@rm -rf $(BUILD_DIR)

.PHONY: all test clean
