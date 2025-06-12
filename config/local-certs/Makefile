.PHONY: import-cert clean

all: import-cert server.crt

OS := $(shell uname)
IS_NIXOS := $(shell grep -q NixOS /etc/os-release && echo true)

rootCA.key:
	@echo "==="
	@echo "Enter a passphrase you can remember, like 'salty pickles'"
	@echo "==="
	openssl genrsa \
		-des3 \
		-out $@ \
		2048

rootCA.pem: rootCA.key 
	@echo "==="
	@echo "Enter that same passphrase when prompted (example: 'salty pickles')"
	@echo "==="
	openssl req \
		-x509 \
		-new \
		-nodes \
		-key $< \
		-config rootCA.csr.cnf \
		-sha256 \
		-days 1024 \
		-out $@

ifeq ($(OS), Darwin)
import-cert: rootCA.pem
	@echo "Importing certificate on macOS..."
	security find-certificate -c "identity-pki Development Certificate" >/dev/null 2>/dev/null || \
		(security import $< -t pub -A)
	@echo "NOTE: Please open Keychain Access and set Trust settings to 'Always Trust' for 'identity-pki Development Certificate'"
else ifeq ($(OS), Linux)
ifeq ($(IS_NIXOS), true)
import-cert: rootCA.pem
	@echo "Please add the certificate in your NixOS configuration:"
	@echo "  security.pki.certificates = [ ./rootCA.pem ];"
else
import-cert: rootCA.pem
	@echo "Importing certificate on Linux..."
	@sudo cp -v rootCA.pem /usr/local/share/ca-certificates/identity-pki.pem
	@sudo update-ca-certificates
endif
else
import-cert:
	@echo "Unsupported OS: $(OS)"
endif

server.key: server.csr.cnf
	openssl req \
		-new \
		-sha256 \
		-nodes \
		-out server.csr \
		-newkey rsa:2048 \
		-keyout $@ \
		-config $<

server.crt: server.key
	@echo "==="
	@echo "Enter that same passphrase when prompted (example: 'salty pickles')"
	@echo "==="
	openssl x509 \
		-req \
		-in server.csr \
		-CA rootCA.pem \
		-CAkey rootCA.key \
		-CAcreateserial \
		-out $@ \
		-days 500 \
		-sha256 \
		-extfile v3.ext

rm:
	rm -fv rootCA.key rootCA.key server.key server.crt

ifeq ($(OS), Darwin)
clean: rm
	@echo "NOTE: Please open Keychain Access and manually delete 'identity-pki Development Certificate'"
	# TODO: doesn't seem to remove from the UI when we run this:
	# 	security delete-certificate -t -c "identity-pki Development Certificate"
else ifeq ($(OS), Linux)
ifeq ($(IS_NIXOS), true)
clean: rm
	@echo "NOTE: Please remove the certificate from your NixOS configuration:"
	@echo "  security.pki.certificates = [ ./rootCA.pem ];"
else
clean: rm
	@sudo rm -fv /usr/local/share/ca-certificates/identity-pki.pem
	@sudo update-ca-certificates
endif
endif
