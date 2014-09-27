module-name = Yaml

build/libyaml.a: build/yaml.o build/yaml.swiftmodule
	@xcrun swiftc \
		-emit-library \
		-module-name $(module-name) \
		-o $@ \
		$^

build/yaml.swiftmodule: yaml.swift | build
	@xcrun swiftc \
		-emit-module \
		-module-name $(module-name) \
		-o $@ \
		$^

build/yaml.o: yaml.swift | build
	@xcrun swiftc \
		-emit-library \
		-emit-object \
		-module-name $(module-name) \
		-o $@ \
		$^

build/test: test.swift build/libyaml.a | build
	@xcrun swiftc \
		-emit-executable \
		-I build \
		-L build \
		-lyaml \
		-o build/test \
		test.swift

build:
	@mkdir -p $@

test: build/test
	@build/test

clean:
	@rm -rf build

.PHONY: clean test
