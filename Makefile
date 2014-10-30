
build: bashenv
	go get || true && go build

bashenv:
	mkdir -p bashenv/compiled
	cat bashenv/*.bash > bashenv/compiled/bashenv
	go-bindata -prefix="bashenv/compiled" -o="./bashenv.go" bashenv/compiled
	rm -rf bashenv/compiled

.PHONY: bashenv