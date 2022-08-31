users: *.go
	go build -mod vendor .

.PHONY: test
test: mocks/mock_client.go
	go test

mocks/mock_client.go: client.go
	mockgen -source=client.go -destination=mocks/mock_client.go -package=mocks

# this updates the vendored code
.PHONY: vendor
vendor:
	go mod tidy
	go mod vendor

.PHONY: validate
validate:
	go run . --validate --file=../../terraform/master/global/users.yaml
