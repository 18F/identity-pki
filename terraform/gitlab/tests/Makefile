# This will update the vendored code here.
.PHONY: update-go-deps
update-go-deps:
	go get -t -u ./...
	go mod tidy
ifneq (,$(wildcard vendor))
	go mod vendor
endif

