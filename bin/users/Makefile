users: sync.go client.go
	go build -mod vendor .

.PHONY: test
test: mocks/mock_client.go
	go fmt
	go test

mocks/mock_client.go: client.go
	mockgen -source=client.go -destination=mocks/mock_client.go -package=mocks

# this updates the vendored code
.PHONY: vendor
vendor:
	go mod tidy
	go mod vendor
