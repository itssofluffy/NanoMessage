#NN_CONFIG_OPTS = -Xlinker=-L/usr/local/lib/x86_64-linux-gnu
all: build

build:
	swift build $(NN_CONFIG_OPTS)

release:
	swift build --configuration release $(NN_CONFIG_OPTS)

test:
	swift test $(NN_CONFIG_OPTS)

runtest:
	swift test --skip-build

docs:
	swift package generate-xcodeproj

clean:
	swift package clean

build-docker-image:
	docker build --tag itssofluffy/nanomsg.swift .ci

publish-docker-image:
	docker push itssofluffy/nanomsg.swift

.PHONY: build release test runtest docs clean build-docker-image publish-docker-image
