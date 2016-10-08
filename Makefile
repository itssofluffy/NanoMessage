#NN_CONFIG_OPTS = -Xlinker=-L/usr/local/lib/x86_64-linux-gnu
all: build

build:
	swift build $(NN_CONFIG_OPTS)

buildrelease:
	swift build --configuration release $(NN_CONFIG_OPTS)

test:
	swift test $(NN_CONFIG_OPTS)

runtest:
	swift test --skip-build

docs:
	swift package generate-xcodeproj

clean:
	swift build --clean

.PHONY: build test runtest docs clean
