module-name = Yaml
sources = Tokenizer.swift Parser.swift Regex.swift Yaml.swift
objects := $(patsubst %.swift,build/%.o,$(sources))
sdk = $$(xcrun --show-sdk-path --sdk macosx)

build/libyaml.a: $(sources) | build
	@echo Build module...

	@cd build && xcrun swiftc \
		-emit-object \
		-module-name $(module-name) \
		-sdk $(sdk) \
		$(patsubst %,../%,$^)

	@xcrun swiftc \
		-emit-module \
		-module-name $(module-name) \
		-sdk $(sdk) \
		-o build/Yaml.swiftmodule \
		$^

	@xcrun swiftc \
		-emit-library \
		-module-name $(module-name) \
		-o $@ \
		$(objects)

build/test: Test.swift build/libyaml.a | build
	@echo Build test...
	@xcrun swiftc \
		-emit-executable \
		-sdk $(sdk) \
		-I build \
		-L build \
		-lyaml \
		-o $@ \
		-O \
		$<

build:
	@mkdir -p $@

test: build/test
	@echo Testing...
	@build/test

clean:
	@rm -rf build

.PHONY: clean test
