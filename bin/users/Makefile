test: mocks/mock_client.go
	go fmt
	go test

mocks/mock_client.go: client.go
	mockgen -source=client.go -destination=mocks/mock_client.go -package=mocks

build:
	go build -mod vendor .

# this updates the vendored code
vendor:
	go mod tidy
	go mod vendor
