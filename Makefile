
build: bashenv
	go get || true && go build

bashenv:
	cat bashenv/* | go-bindata -func bashenv > bashenv.go

.PHONY: bashenv