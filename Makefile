NAME = plugn
EMAIL = plugn@josediazgonzalez.com
MAINTAINER = josegonzalez
MAINTAINER_NAME = Jose Diaz-Gonzalez
REPOSITORY = plugn
HARDWARE = $(shell uname -m)
BASE_VERSION ?= 0.3.0
IMAGE_NAME ?= $(MAINTAINER)/$(REPOSITORY)
PACKAGECLOUD_REPOSITORY ?= dokku/dokku-betafish

ifeq ($(CIRCLE_BRANCH),release)
	VERSION ?= $(BASE_VERSION)
	DOCKER_VERSION = $(VERSION)
else
	VERSION = $(shell echo "${BASE_VERSION}")build+$(shell git rev-parse --short HEAD)
	DOCKER_VERSION = $(shell echo "${BASE_VERSION}")build-$(shell git rev-parse --short HEAD)
endif

version:
	@echo "$(CIRCLE_BRANCH)"
	@echo "$(VERSION)"

define PACKAGE_DESCRIPTION
Utility that allows users to interact with Procfile files
Procfiles may be specified on stdin or via a flag, but
must always be valid yaml.
endef

export PACKAGE_DESCRIPTION

LIST = build release release-packagecloud validate
targets = $(addsuffix -in-docker, $(LIST))

.env.docker:
	@rm -f .env.docker
	@touch .env.docker
	@echo "CIRCLE_BRANCH=$(CIRCLE_BRANCH)" >> .env.docker
	@echo "GITHUB_ACCESS_TOKEN=$(GITHUB_ACCESS_TOKEN)" >> .env.docker
	@echo "IMAGE_NAME=$(IMAGE_NAME)" >> .env.docker
	@echo "PACKAGECLOUD_REPOSITORY=$(PACKAGECLOUD_REPOSITORY)" >> .env.docker
	@echo "PACKAGECLOUD_TOKEN=$(PACKAGECLOUD_API_TOKEN)" >> .env.docker
	@echo "VERSION=$(VERSION)" >> .env.docker

build:
	@$(MAKE) deps
	@$(MAKE) build/darwin/$(NAME)
	@$(MAKE) build/linux/$(NAME)
	@$(MAKE) build/deb/$(NAME)_$(VERSION)_amd64.deb
	@$(MAKE) build/rpm/$(NAME)-$(VERSION)-1.x86_64.rpm

build-docker-image:
	docker build --rm -q -f Dockerfile.build -t $(IMAGE_NAME):build .

$(targets): %-in-docker: .env.docker
	docker run \
		--env-file .env.docker \
		--rm \
		--volume /var/lib/docker:/var/lib/docker \
		--volume /var/run/docker.sock:/var/run/docker.sock:ro \
		--volume ${PWD}:/go/src/github.com/$(MAINTAINER)/$(REPOSITORY) \
		--workdir /go/src/github.com/$(MAINTAINER)/$(REPOSITORY) \
		$(IMAGE_NAME):build make -e $(@:-in-docker=)

build/darwin/$(NAME):
	mkdir -p build/darwin
	CGO_ENABLED=0 GOOS=darwin go build -a -asmflags=-trimpath=/go/src -gcflags=-trimpath=/go/src \
										-ldflags "-s -w -X main.Version=$(VERSION)" \
										-o build/darwin/$(NAME)

build/linux/$(NAME):
	mkdir -p build/linux
	CGO_ENABLED=0 GOOS=linux go build -a -asmflags=-trimpath=/go/src -gcflags=-trimpath=/go/src \
										-ldflags "-s -w -X main.Version=$(VERSION)" \
										-o build/linux/$(NAME)

build/deb/$(NAME)_$(VERSION)_amd64.deb: build/linux/$(NAME)
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
		build/linux/$(NAME)=/usr/bin/$(NAME) \
		LICENSE=/usr/share/doc/$(NAME)/copyright

build/rpm/$(NAME)-$(VERSION)-1.x86_64.rpm: build/linux/$(NAME)
	export SOURCE_DATE_EPOCH=$(shell git log -1 --format=%ct) \
		&& mkdir -p build/rpm \
		&& fpm \
		--architecture x86_64 \
		--category utils \
		--description "$$PACKAGE_DESCRIPTION" \
		--input-type dir \
		--license 'MIT License' \
		--maintainer "$(MAINTAINER_NAME) <$(EMAIL)>" \
		--name $(NAME) \
		--output-type rpm \
		--package build/rpm/$(NAME)-$(VERSION)-1.x86_64.rpm \
		--rpm-os linux \
		--url "https://github.com/$(MAINTAINER)/$(REPOSITORY)" \
		--vendor "" \
		--version $(VERSION) \
		--verbose \
		build/linux/$(NAME)=/usr/bin/$(NAME) \
		LICENSE=/usr/share/doc/$(NAME)/copyright

clean:
	rm -rf build release validation

circleci:
	docker version
	rm -f ~/.gitconfig

deps:
	go get -u github.com/jteeuwen/go-bindata/...
	dep ensure -vendor-only
	go-bindata bashenv

docker-image:
	docker build --rm -q -f Dockerfile.hub -t $(IMAGE_NAME):$(DOCKER_VERSION) .

release: build
	go get -u github.com/progrium/gh-release/...
	rm -rf release && mkdir release
	tar -zcf release/$(NAME)_$(VERSION)_linux_$(HARDWARE).tgz -C build/linux $(NAME)
	tar -zcf release/$(NAME)_$(VERSION)_darwin_$(HARDWARE).tgz -C build/darwin $(NAME)
	cp build/deb/$(NAME)_$(VERSION)_amd64.deb release/$(NAME)_$(VERSION)_amd64.deb
	cp build/rpm/$(NAME)-$(VERSION)-1.x86_64.rpm release/$(NAME)-$(VERSION)-1.x86_64.rpm
	gh-release create $(MAINTAINER)/$(REPOSITORY) $(VERSION) $(shell git rev-parse --abbrev-ref HEAD)

release-packagecloud:
	@$(MAKE) release-packagecloud-deb
	@$(MAKE) release-packagecloud-rpm

release-packagecloud-deb: build/deb/$(NAME)_$(VERSION)_amd64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/ubuntu/trusty  build/deb/$(NAME)_$(VERSION)_amd64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/ubuntu/utopic  build/deb/$(NAME)_$(VERSION)_amd64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/ubuntu/vivid   build/deb/$(NAME)_$(VERSION)_amd64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/ubuntu/wily    build/deb/$(NAME)_$(VERSION)_amd64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/ubuntu/xenial  build/deb/$(NAME)_$(VERSION)_amd64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/ubuntu/yakkety build/deb/$(NAME)_$(VERSION)_amd64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/ubuntu/zesty   build/deb/$(NAME)_$(VERSION)_amd64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/ubuntu/artful  build/deb/$(NAME)_$(VERSION)_amd64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/ubuntu/bionic  build/deb/$(NAME)_$(VERSION)_amd64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/debian/wheezy  build/deb/$(NAME)_$(VERSION)_amd64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/debian/jessie  build/deb/$(NAME)_$(VERSION)_amd64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/debian/stretch build/deb/$(NAME)_$(VERSION)_amd64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/debian/buster  build/deb/$(NAME)_$(VERSION)_amd64.deb

release-packagecloud-rpm: build/rpm/$(NAME)-$(VERSION)-1.x86_64.rpm
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/el/7           build/rpm/$(NAME)-$(VERSION)-1.x86_64.rpm

store-artifacts: build
	mkdir -p /tmp/artifacts
	cp -r build/* /tmp/artifacts

validate:
	mkdir -p validation
	lintian build/deb/$(NAME)_$(VERSION)_amd64.deb || true
	dpkg-deb --info build/deb/$(NAME)_$(VERSION)_amd64.deb
	dpkg -c build/deb/$(NAME)_$(VERSION)_amd64.deb
	cd validation && ar -x ../build/deb/$(NAME)_$(VERSION)_amd64.deb
	cd validation && rpm2cpio ../build/rpm/$(NAME)-$(VERSION)-1.x86_64.rpm > $(NAME)-$(VERSION)-1.x86_64.cpio
	ls -lah build/deb build/rpm validation
	sha1sum build/deb/$(NAME)_$(VERSION)_amd64.deb
	sha1sum build/rpm/$(NAME)-$(VERSION)-1.x86_64.rpm

test:
	docker build --rm -q -f Dockerfile.dev -t plugn:dev .
	go get -u github.com/progrium/basht/...
	basht tests/*/tests.sh
