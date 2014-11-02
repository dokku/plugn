NAME=plugn
HARDWARE=$(shell uname -m)
VERSION=0.1.0

build: bashenv
	go get || true && go build

bashenv:
	mkdir -p bashenv/compiled
	cat bashenv/*.bash > bashenv/compiled/bashenv
	go-bindata -prefix="bashenv/compiled" -o="./bashenv.go" bashenv/compiled
	rm -rf bashenv/compiled

release:
	rm -rf release
	mkdir release
	GOOS=linux go build -o release/$(NAME)
	cd release && tar -zcf $(NAME)_$(VERSION)_linux_$(HARDWARE).tgz $(NAME)
	GOOS=darwin go build -o release/$(NAME)
	cd release && tar -zcf $(NAME)_$(VERSION)_darwin_$(HARDWARE).tgz $(NAME)
	rm release/$(NAME)
	echo "$(VERSION)" > release/version
	echo "progrium/$(NAME)" > release/repo
	gh-release # https://github.com/progrium/gh-release


.PHONY: bashenv release