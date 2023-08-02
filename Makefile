NAME = plugn
EMAIL = plugn@josediazgonzalez.com
MAINTAINER = dokku
MAINTAINER_NAME = Jose Diaz-Gonzalez
REPOSITORY = plugn
HARDWARE = $(shell uname -m)
SYSTEM_NAME  = $(shell uname -s | tr '[:upper:]' '[:lower:]')
BASE_VERSION ?= 0.12.0
IMAGE_NAME ?= $(MAINTAINER)/$(REPOSITORY)
PACKAGECLOUD_REPOSITORY ?= dokku/dokku-betafish

ifeq ($(CI_BRANCH),release)
	VERSION ?= $(BASE_VERSION)
	DOCKER_IMAGE_VERSION = $(VERSION)
else
	VERSION = $(shell echo "${BASE_VERSION}")build+$(shell git rev-parse --short HEAD)
	DOCKER_IMAGE_VERSION = $(shell echo "${BASE_VERSION}")build-$(shell git rev-parse --short HEAD)
endif

version:
	@echo "$(CI_BRANCH)"
	@echo "$(VERSION)"

define PACKAGE_DESCRIPTION
Hook system that lets users extend your application
with plugins
endef

export PACKAGE_DESCRIPTION

LIST = build release release-packagecloud validate
targets = $(addsuffix -in-docker, $(LIST))

.env.docker:
	@rm -f .env.docker
	@touch .env.docker
	@echo "CI_BRANCH=$(CI_BRANCH)" >> .env.docker
	@echo "GITHUB_ACCESS_TOKEN=$(GITHUB_ACCESS_TOKEN)" >> .env.docker
	@echo "IMAGE_NAME=$(IMAGE_NAME)" >> .env.docker
	@echo "PACKAGECLOUD_REPOSITORY=$(PACKAGECLOUD_REPOSITORY)" >> .env.docker
	@echo "PACKAGECLOUD_TOKEN=$(PACKAGECLOUD_TOKEN)" >> .env.docker
	@echo "VERSION=$(VERSION)" >> .env.docker

build: prebuild
	@$(MAKE) build/darwin/$(NAME)
	@$(MAKE) build/linux/$(NAME)-amd64
	@$(MAKE) build/linux/$(NAME)-arm64
	@$(MAKE) build/linux/$(NAME)-armhf
	@$(MAKE) build/deb/$(NAME)_$(VERSION)_amd64.deb
	@$(MAKE) build/deb/$(NAME)_$(VERSION)_arm64.deb
	@$(MAKE) build/deb/$(NAME)_$(VERSION)_armhf.deb

build-docker-image:
	docker build --rm -q -f Dockerfile.build -t $(IMAGE_NAME):build .

$(targets): %-in-docker: .env.docker
	docker run \
		--env-file .env.docker \
		--rm \
		--volume /var/lib/docker:/var/lib/docker \
		--volume /var/run/docker.sock:/var/run/docker.sock:ro \
		--volume ${PWD}:/src/github.com/$(MAINTAINER)/$(REPOSITORY) \
		--workdir /src/github.com/$(MAINTAINER)/$(REPOSITORY) \
		$(IMAGE_NAME):build make -e $(@:-in-docker=)

build/darwin/$(NAME):
	mkdir -p build/darwin
	CGO_ENABLED=0 GOOS=darwin go build -a -asmflags=-trimpath=/src -gcflags=-trimpath=/src \
										-ldflags "-s -w -X main.Version=$(VERSION)" \
										-o build/darwin/$(NAME)

build/linux/$(NAME)-amd64:
	mkdir -p build/linux
	CGO_ENABLED=0 GOOS=linux go build -a -asmflags=-trimpath=/src -gcflags=-trimpath=/src \
										-ldflags "-s -w -X main.Version=$(VERSION)" \
										-o build/linux/$(NAME)-amd64

build/linux/$(NAME)-arm64:
	mkdir -p build/linux
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -a -asmflags=-trimpath=/src -gcflags=-trimpath=/src \
										-ldflags "-s -w -X main.Version=$(VERSION)" \
										-o build/linux/$(NAME)-arm64

build/linux/$(NAME)-armhf:
	mkdir -p build/linux
	CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=5 go build -a -asmflags=-trimpath=/src -gcflags=-trimpath=/src \
										-ldflags "-s -w -X main.Version=$(VERSION)" \
										-o build/linux/$(NAME)-armhf

build/deb/$(NAME)_$(VERSION)_amd64.deb: build/linux/$(NAME)-amd64
	export SOURCE_DATE_EPOCH=$(shell git log -1 --format=%ct) \
		&& mkdir -p build/deb \
		&& fpm \
		--architecture amd64 \
		--category utils \
		--description "$$PACKAGE_DESCRIPTION" \
		--input-type dir \
		--license 'MIT License' \
		--maintainer "$(MAINTAINER_NAME) <$(EMAIL)>" \
		--name $(NAME) \
		--output-type deb \
		--package build/deb/$(NAME)_$(VERSION)_amd64.deb \
		--url "https://github.com/$(MAINTAINER)/$(REPOSITORY)" \
		--vendor "" \
		--version $(VERSION) \
		--verbose \
		build/linux/$(NAME)-amd64=/usr/bin/$(NAME) \
		LICENSE=/usr/share/doc/$(NAME)/copyright

build/deb/$(NAME)_$(VERSION)_arm64.deb: build/linux/$(NAME)-arm64
	export SOURCE_DATE_EPOCH=$(shell git log -1 --format=%ct) \
		&& mkdir -p build/deb \
		&& fpm \
		--architecture arm64 \
		--category utils \
		--description "$$PACKAGE_DESCRIPTION" \
		--input-type dir \
		--license 'MIT License' \
		--maintainer "$(MAINTAINER_NAME) <$(EMAIL)>" \
		--name $(NAME) \
		--output-type deb \
		--package build/deb/$(NAME)_$(VERSION)_arm64.deb \
		--url "https://github.com/$(MAINTAINER)/$(REPOSITORY)" \
		--vendor "" \
		--version $(VERSION) \
		--verbose \
		build/linux/$(NAME)-arm64=/usr/bin/$(NAME) \
		LICENSE=/usr/share/doc/$(NAME)/copyright

build/deb/$(NAME)_$(VERSION)_armhf.deb: build/linux/$(NAME)-armhf
	export SOURCE_DATE_EPOCH=$(shell git log -1 --format=%ct) \
		&& mkdir -p build/deb \
		&& fpm \
		--architecture armhf \
		--category utils \
		--description "$$PACKAGE_DESCRIPTION" \
		--input-type dir \
		--license 'MIT License' \
		--maintainer "$(MAINTAINER_NAME) <$(EMAIL)>" \
		--name $(NAME) \
		--output-type deb \
		--package build/deb/$(NAME)_$(VERSION)_armhf.deb \
		--url "https://github.com/$(MAINTAINER)/$(REPOSITORY)" \
		--vendor "" \
		--version $(VERSION) \
		--verbose \
		build/linux/$(NAME)-armhf=/usr/bin/$(NAME) \
		LICENSE=/usr/share/doc/$(NAME)/copyright

clean:
	rm -rf build release validation

ci-report:
	docker version
	rm -f ~/.gitconfig

docker-image:
	docker build --rm -q -f Dockerfile.hub -t $(IMAGE_NAME):$(DOCKER_IMAGE_VERSION) .
	docker tag $(IMAGE_NAME):$(DOCKER_IMAGE_VERSION) $(IMAGE_NAME):hub

bin/gh-release:
	mkdir -p bin
	curl -o bin/gh-release.tgz -sL https://github.com/progrium/gh-release/releases/download/v2.3.3/gh-release_2.3.3_$(SYSTEM_NAME)_$(HARDWARE).tgz
	tar xf bin/gh-release.tgz -C bin
	chmod +x bin/gh-release

bin/gh-release-body:
	mkdir -p bin
	curl -o bin/gh-release-body "https://raw.githubusercontent.com/dokku/gh-release-body/master/gh-release-body"
	chmod +x bin/gh-release-body

release: build bin/gh-release bin/gh-release-body
	rm -rf release && mkdir release
	tar -zcf release/$(NAME)_$(VERSION)_linux_amd64.tgz -C build/linux $(NAME)-amd64
	tar -zcf release/$(NAME)_$(VERSION)_linux_arm64.tgz -C build/linux $(NAME)-arm64
	tar -zcf release/$(NAME)_$(VERSION)_linux_armhf.tgz -C build/linux $(NAME)-armhf
	tar -zcf release/$(NAME)_$(VERSION)_darwin_$(HARDWARE).tgz -C build/darwin $(NAME)
	cp build/deb/$(NAME)_$(VERSION)_amd64.deb release/$(NAME)_$(VERSION)_amd64.deb
	cp build/deb/$(NAME)_$(VERSION)_arm64.deb release/$(NAME)_$(VERSION)_arm64.deb
	cp build/deb/$(NAME)_$(VERSION)_armhf.deb release/$(NAME)_$(VERSION)_armhf.deb
	bin/gh-release create $(MAINTAINER)/$(REPOSITORY) $(VERSION) $(shell git rev-parse --abbrev-ref HEAD)
	bin/gh-release-body $(MAINTAINER)/$(REPOSITORY) v$(VERSION)

release-packagecloud:
	@$(MAKE) release-packagecloud-deb

release-packagecloud-deb: build/deb/$(NAME)_$(VERSION)_amd64.deb build/deb/$(NAME)_$(VERSION)_arm64.deb build/deb/$(NAME)_$(VERSION)_armhf.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/ubuntu/bionic  build/deb/$(NAME)_$(VERSION)_amd64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/ubuntu/focal   build/deb/$(NAME)_$(VERSION)_amd64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/ubuntu/jammy   build/deb/$(NAME)_$(VERSION)_amd64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/debian/buster  build/deb/$(NAME)_$(VERSION)_amd64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/debian/bullseye build/deb/$(NAME)_$(VERSION)_amd64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/debian/bookworm build/deb/$(NAME)_$(VERSION)_amd64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/ubuntu/focal    build/deb/$(NAME)_$(VERSION)_arm64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/ubuntu/jammy    build/deb/$(NAME)_$(VERSION)_arm64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/debian/bullseye build/deb/$(NAME)_$(VERSION)_arm64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/debian/bookworm build/deb/$(NAME)_$(VERSION)_arm64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/ubuntu/focal    build/deb/$(NAME)_$(VERSION)_armhf.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/ubuntu/jammy    build/deb/$(NAME)_$(VERSION)_armhf.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/raspbian/buster build/deb/$(NAME)_$(VERSION)_armhf.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/raspbian/bullseye build/deb/$(NAME)_$(VERSION)_armhf.deb

validate: test
	mkdir -p validation
	lintian build/deb/$(NAME)_$(VERSION)_amd64.deb || true
	lintian build/deb/$(NAME)_$(VERSION)_arm64.deb || true
	lintian build/deb/$(NAME)_$(VERSION)_armhf.deb || true
	dpkg-deb --info build/deb/$(NAME)_$(VERSION)_amd64.deb
	dpkg-deb --info build/deb/$(NAME)_$(VERSION)_arm64.deb
	dpkg-deb --info build/deb/$(NAME)_$(VERSION)_armhf.deb
	dpkg -c build/deb/$(NAME)_$(VERSION)_amd64.deb
	dpkg -c build/deb/$(NAME)_$(VERSION)_arm64.deb
	dpkg -c build/deb/$(NAME)_$(VERSION)_armhf.deb
	cd validation && ar -x ../build/deb/$(NAME)_$(VERSION)_amd64.deb
	cd validation && ar -x ../build/deb/$(NAME)_$(VERSION)_arm64.deb
	cd validation && ar -x ../build/deb/$(NAME)_$(VERSION)_armhf.deb
	ls -lah build/deb validation
	sha1sum build/deb/$(NAME)_$(VERSION)_amd64.deb
	sha1sum build/deb/$(NAME)_$(VERSION)_arm64.deb
	sha1sum build/deb/$(NAME)_$(VERSION)_armhf.deb

prebuild:
	git config --global --add safe.directory $(shell pwd)
	git status
	cd / && go install github.com/go-bindata/go-bindata/...@latest
	cd / && go install github.com/progrium/basht/...@latest

test: prebuild docker-image
	basht tests/*/tests.sh
