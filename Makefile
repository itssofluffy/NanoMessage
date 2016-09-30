#NN_CONFIG_OPT = -Xlinker=-L/usr/local/lib/x86_64-linux-gnu
all: build

gyb:
	gyb-source

build: gyb
	swift build $(NN_CONFIG_OPT)

test: gyb
	swift test $(NN_CONFIG_OPT)

runtest:
	swift test --skip-build

docs:
	swift package generate-xcodeproj

clean:
	swift build --clean

.PHONY: gyb build test runtest docs clean
