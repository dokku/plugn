NAME=plugn
HARDWARE=$(shell uname -m)
VERSION=0.2.0

build:
	go-bindata bashenv
	mkdir -p build/linux  && GOOS=linux  go build -ldflags "-X main.Version $(VERSION)" -o build/linux/$(NAME)
	mkdir -p build/darwin && GOOS=darwin go build -ldflags "-X main.Version $(VERSION)" -o build/darwin/$(NAME)

deps:
	go get -u github.com/jteeuwen/go-bindata/...
	go get -u github.com/progrium/gh-release/...
	go get || true

release: build
	rm -rf release && mkdir release
	tar -zcf release/$(NAME)_$(VERSION)_linux_$(HARDWARE).tgz -C build/linux $(NAME)
	tar -zcf release/$(NAME)_$(VERSION)_darwin_$(HARDWARE).tgz -C build/darwin $(NAME)
	gh-release create progrium/$(NAME) $(VERSION) $(shell git rev-parse --abbrev-ref HEAD)

.PHONY: build release deps
