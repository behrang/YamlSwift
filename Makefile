module-name = Yaml
sources = Tokenizer.swift Parser.swift Regex.swift Yaml.swift
sdk = $$(xcrun --show-sdk-path --sdk macosx)

all: build/libyaml.dylib build/Yaml.swiftmodule

build/libyaml.dylib: $(sources) | build
	@echo Build lib...
	@xcrun swiftc \
		-emit-library \
		-module-name $(module-name) \
		-sdk $(sdk) \
		-O \
		-o $@ \
		$^

build/Yaml.swiftmodule: build/libyaml.dylib
	@echo Build swiftmodule...
	@xcrun swiftc \
		-emit-module \
		-module-name $(module-name) \
		-sdk $(sdk) \
		-o $@ \
		$(sources)

build/test: Test.swift $(sources) | build
	@echo Build test...
	@cp $< build/main.swift
	@xcrun swiftc \
		-emit-executable \
		-sdk $(sdk) \
		-o $@ \
		build/main.swift $(sources)
	@rm build/main.swift

build:
	@mkdir -p $@

test: build/test
	@echo Testing...
	@build/test

clean:
	@rm -rf build

.PHONY: clean test
