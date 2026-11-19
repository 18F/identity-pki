Identity-PKI
============

PIV/CAC support for login.gov.

### Purpose and Role of within Login.gob 

### Local development
Identity-pki is a small, focused Rails service that provides PIV/CAC (Personal Identity Verification / Common Access Card) smart-card authentication for identity-idp (the main login.gov IdP). It does not handle any other authentication method. Its entire job is:
1. Accept an mTLS client certificate presented by a user's PIV/CAC card (forwarded by nginx/the load balancer as a header, or available via rack.peer_cert).
2. Validate the certificate's chain of trust, policy OIDs, and revocation status.
3. Package the validation result into a short-lived, encrypted, HMAC-authenticated token.
4. Hand that token back to identity-idp via redirect, where identity-idp calls back into this service (POST /) to decrypt/verify it and learn the outcome.

Because it terminates a user's smart card at the TLS layer, it is one of the few login.gov components that must speak raw X.509 and talk to government PKI infrastructure (OCSP responders, CA repositories, Federal Common Policy CAs, DoD/FICAM root bundles) directly.

#### Dependencies

| Dependency | Version / Notes |
| -------- | -------- |
| Ruby  | 3.4 (pinned in .ruby-version)  |
| OpenSSL  | System library: all cert parsing, OCSP, and CRL verification go through Ruby's openssl bindings, not a pure-Ruby PKI library |
| PostgeSQL | Stores certificate_authorities, certificate_revocations, and piv_cacs tables (see Data Model)  |
| Nginx | Used locally to terminate TLS and forward the client cert header (X-Client-Cert), mimicking how the production load balancer presents the cert to the app. See config/nginx_server.conf.example|
| Redis  | Backs a Bloom filter (nonce_bloom_filter_server) used for replay protection on verification tokens.  |

The project also supports two bootstrap paths baked into bin/setup:
- Homebrew path (default on macOS): installs brew bundle dependencies, bundler, foreman.
- Devenv path (devenv.nix/devenv.yaml/devenv.lock present): if DEVENV_ROOT is set, skips Homebrew and uses the Nix-based devenv toolchain instead. This is the newer, reproducible alternative to Homebrew-based setup.

#### Setting up and running the app

Run the following command to set up your local environment:

```
$ make setup
```

The first time, it will prompt for a passphrase for the root certificate. You can put anything as long as you remember it, it's just for development. You will also want to make sure to [trust the root SSL certificate](#trust-the-root-ssl-certificate)

Run the app server with:

```
$ make run
```

### Running the app locally with the IDP

#### Trust the root SSL certificate

Because identity-idp talks to identity-pki over HTTPS even in development, and the dev cert is self-signed by the locally-generated root CA, your OS/browser will reject it unless you trust that root explicitly:

1. Open the Keychain Access app

2. Within your default keychain, search for the certificate "**identity-pki Development Certificate**"

3. Double-click the certificate to view its details

4. Expand the "Trust" section and select "Always Trust" for the top-level "When using this certificate" dropdown

5. Close the details to save your changes. You'll be prompted to enter your password or PIN to confirm the changes.


#### Cleaning up the root SSL certificate

1. Delete the certificate files:

  ```
  pushd config/local-certs/
  make clean
  popd
  ```

2. Open Keychain Access and delete the certificate named "**identity-pki Development Certificate**"

#### Using Docker Locally

1. Download, install, and launch [Docker](https://www.docker.com/products/docker-desktop).

1. Build the Docker containers: `docker-compose build`

1. Run `make docker_setup` to copy configuration files and bootstrap the database.

1. Start the Docker containers `docker-compose up` and `open https://localhost:8443` (If you see an SSL error, check [Trust the root SSL certificate](#trust-the-root-ssl-certificate) instructions)

`docker-compose.yml` defines three services:
- `web`: builds from the root Dockerfile, mounts the whole repo as a volume (.:/pivcac) for live-reload style development, and exposes 8443 externally.
- `db`: vanilla postgres image with a bind-mounted ./postgres-data volume for persistence across container restarts.
- `redis`: backs the nonce bloom filter (see §6).

Key environment variables injected into the web container (beyond what's in application.yml):
- `DATABASE_URL=postgres://postgres@db` Overrides `config/database.yml`'s host resolution to point at the db service by Docker Compose network name.
- `DATABASE_CLEANER_ALLOW_REMOTE_DATABASE_URL=true` Needed because DatabaseCleaner's RSpec setup normally refuses to run against anything that doesn't look like localhost.
- `nonce_bloom_filter_server=redis://redis:6379` Points the bloom filter at the Compose-networked Redis instance rather than localhost.
- Statement/transaction timeouts are both bumped to 30s (vs. the default 2.5s/5s in `application.yml.default`) to tolerate slower containerized I/O.

`make docker_setup` → `bin/docker_setup` copies configuration files into place and bootstraps the DB inside the container context. This is effectively the Docker-equivalent of bin/setup's DB-prep steps, but it skips the Keychain/Homebrew-specific host steps since those don't apply inside a container.

The three separate Dockerfiles in the repo root serve different purposes:
- `Dockerfile`: local dev container (used by docker-compose).
- `k8.Dockerfile`: production Kubernetes deployment image.
- `nginx.Dockerfile`: a dedicated nginx sidecar/front image, consistent with the TLS-termination role nginx plays even in prod.
- `prod.Dockerfile`: a non-k8s production build variant.


### Certificate Authority Management

The PIV/CAC service relies on having all of the certificate authorities (issuing
certificates). If a certificate authority is missing, then any client certificates
signed by that authority will not be recognized as valid.

All certificates have to link back to a trusted root. Trusted roots are implicitly
trusted as long as they aren't expired. Any certificate authority that can't be
traced back to a trusted root will be ignored.

Certificate authorities are made trusted roots by listing their key id in the
`config/application.yml`. The `trusted_ca_root_identifiers` configuration attribute
is a comma-delimited list of key ids.

#### The Trust Model

Every certificate presented by a user's PIV/CAC must trace, through zero or more intermediate CAs, back to an entry in `trusted_ca_root_identifiers` (config/application.yml, keyed by SHA1 key-id fingerprint, comma-delimited). This list is deliberately narrow in production and the default/dev config trusts only the `Federal Common Policy G2 root (F4:27:5C:A9:C3:7C:47:F4:FA:A6:A7:B0:59:97:AA:DD:35:26:17:E3)`:
- All known certs are loaded from config/certs/*.pem (recursively) at boot via `load_certs!`, plus a bundled FICAM cert bundle (config/cert_bundles/ficam_bundle.pem) that supplies intermediate/root certs (including cross-signed roots) without requiring every one to be committed individually.
- Certificates and their signer relationships are modeled as a directed graph (`RGL::DirectedAdjacencyGraph`), where `add_link(child_key_id, signer_key_id)` wires up each cert to its issuer.
- `x509_certificate_chain_to_root` uses Dijkstra's shortest path (rgl/dijkstra) over that graph to walk from a cert's signer up to a given trusted root. This is a somewhat unusual but effective way to model "is there a signing path from A to a trusted root."
- `remove_untrusted_certificates` recomputes the full transitively-trusted set starting from the roots and prunes anything not reachable. i.e., trust is additive from the roots down, not "everything not explicitly rejected."
- Every certificate added to the store is also persisted as a CertificateAuthority DB row (`find_or_create_for_certificate`), which is what CRL/OCSP revocation tracking hangs off of.

#### Dynamically Fetching Missing CA Certificates

When a client cert's issuer isn't already in the local store, `IssuingCaService` and `CertificateChainService` can fetch intermediate/issuing certificates live over HTTP using the Authority Information Access (AIA) "CA Issuers" extension in the certificate, PKCS7-decoding the response.

Critical safety control: `IssuingCaService.allowed_host?` checks the target host against `ca_issuer_host_allow_list` (a comma-delimited allowlist in application.yml, e.g. aia.certipath.com, crl.disa.mil, pki.treasury.gov, etc.) before making any outbound request. This is an explicit SSRF guardrail so the app can't be tricked into fetching from an arbitrary attacker-controlled URL embedded in a malicious certificate's AIA extension. Responses are cached in-memory (MiniCache::Store, 60-minute TTL) to avoid hammering government CA repositories on every request.

#### Operational Rake Tasks for CA Management

- `rake ca:dump` : prints every cert currently in the CertificateStore as PEM, useful for inspecting what's trusted at runtime.
- `rake ca:graph` : emits a PlantUML diagram of signer → signee relationships across the whole CertificateStore, which is genuinely useful for visualizing the federal PKI trust tree your instance currently has loaded.
- `rake certs:remove_invalid` (optionally EXPIRING=true) : deletes .pem files from config/certs/ for certs that are already invalid, or (with the flag) expiring within 30 days.
- `rake certs:list_ficam_certs` : enumerates everything in the bundled FICAM cert bundle with expiration/self-signed/OCSP metadata.
- `rake certs:print_expiring[deadline_days]` : CI/ops-friendly check; exits 1 if any cert in the store expires before the deadline, making it suitable as a scheduled monitoring job.
- `rake certs:find_replacement[key_id]` : an interactive tool: given an expiring cert's key id, it fetches its issuer's CA Repository (SIA extension), fuzzy-matches candidate replacement certs by subject similarity (Jaro-Winkler distance > 0.95), and lets an operator interactively select and download replacements into config/certs/.
- `rake certs:find_new` : walks each trusted root's CA Repository and surfaces any certs issued by it that aren't yet in the store, for manual review/approval.
- `rake certs:find_missing_intermediate_certs[cert_path]` : given a leaf cert from a user who's reporting a PIV/CAC error (per the troubleshooting runbook linked in the code comment), walks the chain and tries to auto-fetch any missing intermediates.
- `rake certs:generate_certificate_bundles` : regenerates the FICAM bundle from idmanagement.gov's published PKCS7 bundle, with a specific carve-out: it strips the Federal Bridge CA G4 cert unless its signer is itself a trusted root, to avoid a circular cross-signing loop. There's a code comment flagging this as something to monitor given that cert's 2029 expiration.
- `rake certs:check_certificate_bundle` : CI-style sanity check that the FICAM bundle file exists, parses, and isn't empty; exits 1 with remediation instructions otherwise.
- `rake certs:validate_client_cert[cert_path]` : ad hoc single-certificate validation against the current store, useful for debugging a specific user-submitted cert outside of the full HTTP flow.


#### Managing OCSP

OCSP is a real-time revocation status protocol for certificates. We contact the OCSP
server when we check the validity of a certificate rather than relying on a periodic
refresh of CRLs. CRLs become a fall-back if we aren't able to contact the OCSP server.

If we have a OCSP URL on record for an issuing certificate, we use that. Otherwise, we
find the OCSP URL in the certificate we're verifying. If we are not able to get a
response from the OCSP server, we fall back to the CRL information we've cached.

If we get a "revoked" status from the OCSP server, we record that for future checks so
we don't have to go back to the OCSP server.

Once a certificate is marked as revoked, we don't "unrevoke." We will always refuse to
accept the certificate as valid unless the revocation status is removed from the
database.

### Managing Certificate Revocation Lists (CRLs)

The application does not download CRLs. Instead, it expects revoked serial numbers to
be listed in the `certificate_revocations` table.

OCSP (Online Certificate Status Protocol) is the primary, real-time revocation check. CRLs are a fallback only. The flow in OcspService:
1. On initialization, it looks up the CertificateAuthority row matching the subject cert's signer (CertificateAuthority.find_by(key: subject.signing_key_id)).
1. If the authority and its certificate are known, it builds an OpenSSL::OCSP::Request with a CertificateId (subject serial + issuer, SHA1 digest) and a fresh nonce (add_nonce) to prevent replay of a stale cached OCSP response.
1. It resolves the OCSP responder URL in this preference order: the CertificateAuthority's cached ocsp_http_url (populated once and persisted) → else the subject cert's own OCSP AIA URL (fetched and cached back onto the CertificateAuthority row for next time).
1. The HTTP POST to the OCSP responder (content-type: application/ocsp-request) has configurable open/read timeouts (http_open_timeout/http_read_timeout, default 5s each) and a manual retry on ECONNRESET/timeout (one retry, 1-second backoff).
1. Responses are cached in-process for 5 minutes (OCSP_RESPONSE_CACHE_EXPIRATION), keyed by issuer+subject+serial+URL, to avoid re-querying the same OCSP responder repeatedly for the same cert in a short window.
1. If there's no issuer cert available or the request can't be built at all, it falls back directly to the local revocation table (CertificateAuthority.revoked?) rather than failing closed or open. Absence of an OCSP channel doesn't block the user, but does fall back to whatever's cached locally from CRL ingestion.
1. Revocation is sticky: once a cert is recorded as revoked (via either OCSP or CRL), nothing in the codebase "un-revokes" it. The only way to clear that state is a direct operator action removing the row from the certificate_revocations table. This is an intentional fail-safe against a transient bad OCSP/CRL response un-revoking a genuinely compromised certificate.
1. All network/parsing errors during OCSP are swallowed into a warn-level log line (log_ocsp_error) with structured context (error type, URL, key id) rather than raised. OCSP infrastructure being flaky shouldn't crash the request handling path.


##### Loading CRL Metadata

Use the `rake crls:load` command to load a CSV of CRL metadata into the database. This
command takes an optional filename argument if you aren't providing the CSV on STDIN.

The CSV has the following columns:
1. certificate authority key id
2. valid not before date/time
3. valid not after date/time
4. certificate authority subject
5. CRL HTTP URL

##### Dumping CRL Metadata

Use the `rake crls:dump` command to dump a CSV of CRL metadata from the database. This
command takes an optional filename argument if you aren't wanting the CSV on STDOUT.

The CSV has the same columns as for `crls:load`.

##### Updating CRLs

Unlike OCSP, the app never autonomously downloads a CRL out of a certificate's CRL Distribution Points extension. CRL URLs are centrally curated and stored per-CertificateAuthority row (crl_http_url column), and revoked serials are pre-loaded into the certificate_revocations table. This is a deliberate design choice: it avoids trusting arbitrary CRL URLs embedded in certificates (another SSRF-style guardrail) and gives operators a controlled ingestion pipeline.

##### CSV-Based CRL Metadata Pipeline
- `rake crls:load[file]` : reads a CSV (from STDIN if no file given) with columns [key_id, valid_not_before, valid_not_after, dn, crl_http_url] and upserts CertificateAuthority rows (find_or_create_by(key:, dn:)), updating crl_http_url if the incoming value differs from what's stored.
- `rake crls:dump[file]` : the inverse: dumps every CertificateAuthority row's same five columns to CSV (STDOUT if no file given), making a full round-trip export/import workflow for managing CA + CRL-URL metadata outside the app (e.g. in a spreadsheet or another system of record).
- `rake crls:update` : the actual fetch job: iterates every CertificateAuthority that has a crl_http_url set (with_crl_http_url scope), fetches the CRL, and calls update_revocations on each. Because of the CRL security model, the command will not fetch or update CRLs for
certificate authorities that aren't linked to a trusted root. Make sure your trusted roots
are configured if you aren't seeing CRLs fetched as you expect.

##### CRL Fetch and Verification Details (CertificateRevocationListService / CertificateAuthority#update_revocations)

1. retrieve_serials_from_url does a plain HTTP GET of the CRL URL, parses the DER response into an OpenSSL::X509::CRL.
1. valid_crl? enforces two checks before trusting any revoked-serial data from the CRL: the CRL's issuer must match the stored authority's cert subject, and the CRL's signature must verify (crl_store.verify(certificate.public_key)) against that authority's public key — an unsigned or wrongly-signed CRL is discarded entirely (returns []), rather than partially trusted.
1. New serials (those not already present) are bulk-inserted via CertificateRevocation.import with validate: false and on_duplicate_key: :ignore in batches of 5000. This is optimized for CRLs that can contain large numbers of entries, at the cost of skipping ActiveRecord validations on insert (acceptable here since the data is already shape-validated by the CRL parser).
1. Before the bulk run, rake crls:update bumps the Postgres statement_timeout to a very high value (1,000,000ms) specifically because these bulk imports can legitimately take a long time and shouldn't be killed by the default 2.5s statement timeout configured for normal request traffic.
1. Per-authority failures are caught and logged as warnings (rescue StandardError) so one CA's broken/unreachable CRL doesn't abort the batch job for all the others.
1. A CA with a crl_http_url set but no linked trusted root will silently not have its CRL fetched (with_crl_http_url doesn't filter on trust, but nothing downstream will act on an untrusted CA's data). It will always verify trusted_ca_root_identifiers first when CRLs "aren't updating as expected."

### Request/Response Flow

#### GET / → IdentifyController#create (the "identify" leg)
1. identity-idp redirects the user's browser to this app with a nonce query param (required and raises/renders 400 if missing) and an optional redirect_uri.
1. nginx/the load balancer performs the mTLS handshake and forwards the client cert as either the X-Client-Cert header or via rack.peer_cert; the value is URL-escaped or tab-stripped depending on client_cert_escaped config (platform-dependent quirk).
1. The referrer, where to redirect back to, is validated against identity_idp_host from config; if the host doesn't match, the request is rejected as a bad referrer. This is the app's CSRF/open-redirect guard, since redirect_to ... allow_other_host: true is otherwise permissive by design (it needs to redirect to an external host, identity-idp, hence it being explicitly allowed only after host validation).
1. If no cert was presented at all, it still redirects back to identity-idp but with a token encoding error: 'certificate.none'. The "no cert" case is itself encoded into a valid, verifiable token, not a bare HTTP error, so identity-idp has a consistent single decode path.
1. If a cert was presented, it's parsed, validated (cert.validate_cert(is_leaf: true)), and a structured JSON log line is emitted (log_certificate) capturing issuer, OCSP URL, matched/mapped policy OIDs, and validity. This is the primary observability hook for understanding PIV/CAC authentication outcomes in production logs.
1. Either way, the result is boxed via TokenService.box and appended to the redirect URL as a token query param (CGI.escaped).

#### POST / → VerifyController#open (the "verify" leg)

identity-idp calls back with the token it received, plus an Authentication header carrying an HMAC (hmac <user>:<nonce>:<digest>). This endpoint explicitly skips Rails' CSRF protection (skip_before_action :verify_authenticity_token) since it's a server-to-server call, not a browser form post. `TokenService.open` decrypts/verifies and returns the underlying claims as JSON or {"error": "token.missing"} if the param is absent.


### Token Service: Encryption, Authentication, and Replay Protection

TokenService is the trust boundary between the two legs above, and does three independent things:

1. Confidentiality/integrity: uses Rails' ActiveSupport::MessageEncryptor with AES-256-GCM, keyed via ActiveSupport::KeyGenerator from a salt/pepper pair in config, truncated to 32 bytes (a legacy compatibility note in the code explains this was needed once newer Ruby OpenSSL started rejecting 64-byte keys that older Ruby silently truncated). Key rotation is supported. If _old salt/pepper values are configured, the encryptor is initialized with rotation support (encryptor.rotate prior_key) so tokens signed with the previous key pair during a rotation window still decrypt.
1. Entropy padding: since the payload itself may be small (e.g. just an error code and a nonce), two random base64 fields (r1/r2) are injected before/after the real data specifically to avoid the ciphertext being too predictable/short. This is a deliberate mitigation against certain cryptanalysis risks on short, low-entropy plaintexts.
1. Sender authenticity + replay protection (authentic?): separate from the encryption, there's an HMAC-SHA256 check using a distinct shared secret (piv_cac_verify_token_secret), computed over token + nonce. The nonce is also checked against a Redis-backed counting Bloom filter (nonce_bloom_filter_* config).  If a nonce has been seen before, the token is rejected as a replay, even if the encryption/HMAC are otherwise valid. There's a # TODO comment noting the secret isn't yet mandatory everywhere (secret.blank? short-circuits to trusted). This is worth being aware of as a known interim state, not a bug.
1. Tokens expire after 5 minutes (TOKEN_LIFESPAN), enforced by MessageEncryptor's own expires_in.

### Data Model

Three core ActiveRecord models:

- `CertificateAuthority` : one row per known CA key id (validated as a colon-delimited hex string, e.g. F4:27:...). Holds dn, validity window, optional crl_http_url/ocsp_http_url, and has_many :certificate_revocations. revoked? is both an instance method (checked against its own revocation list) and a class method shortcut (CertificateAuthority.revoked?(subject_cert) looks up the authority by the subject's signer key first).
- `CertificateRevocation` : individual revoked serial numbers scoped to a CertificateAuthority; bulk-imported via activerecord-import.
- `PivCac` : represents a known PIV/CAC identity. Notably, it never stores the raw Distinguished Name (DN) : only a SHA-512 hash of it (dn_signature), assigned via a custom dn= setter that immediately hashes the input. This is a privacy-by-design choice: DNs can contain PII (name, sometimes SSN-derived identifiers on some card types), so the DB only ever holds a one-way hash plus a generated UUID, never the plaintext DN.
