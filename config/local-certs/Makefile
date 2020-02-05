.PHONY: keychain-import clean

all: keychain-import server.crt

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

keychain-import: rootCA.pem
	security find-certificate -c "identity-pki Development Certificate" >/dev/null 2>/dev/null || \
		(security import $< -t pub -A)
	@echo "NOTE: please open Keychain Access and set Trust settings to 'Always Trust' for 'identity-pki Development Certificate'"

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

clean:
	rm -f rootCA.key rootCA.key server.key server.crt
	@echo "NOTE: Please open Keychain Access and manually delete 'identity-pki Development Certificate'"
	# TODO: doesn't seem to remove from the UI when we run this:
	# 	security delete-certificate -t -c "identity-pki Development Certificate"
