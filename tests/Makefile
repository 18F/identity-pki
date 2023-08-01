build:
	go build -mod vendor .

# this updates the vendored code
.PHONY: update-go-deps
update-go-deps:
	go get -t -u ./...
	go mod tidy
ifneq (,$(wildcard vendor))
	go mod vendor
endif

