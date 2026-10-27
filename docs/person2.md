# Person 2 — TLS security auditing, certificates and HSTS

## Your inputs

Person 1 provides `compose.yaml`, both running HTTPS services, and a local CA public certificate in `certs/ca.crt`. Use **Docker containers** for SSLyze and testssl.sh; do not need Windows-native nassl.

## What to do

1. Run a complete SSLyze scan against `baseline:443` and `hardened:443` on network `tlslab_network`.
2. Run complete testssl.sh scans against the same endpoints.
3. Document accepted TLS versions and suites, clearly separating **supported** from **actually selected by ordinary clients**.
4. Check certificate chain, validity period, SAN/hostname, and explicit CA trust.
5. Compare HTTP `Strict-Transport-Security` headers (`curl.exe -k -I` on host).
6. Distinguish **scanner warnings** from **proven exploitability**; our lab is about configuration audit, not attacks against a third-party host.

## Commands (PowerShell from repository root)

```powershell
docker run --rm --network tlslab_network nablac0d3/sslyze:latest baseline:443
docker run --rm --network tlslab_network nablac0d3/sslyze:latest hardened:443

docker run --rm --network tlslab_network ghcr.io/testssl/testssl.sh baseline:443
docker run --rm --network tlslab_network ghcr.io/testssl/testssl.sh hardened:443

curl.exe -k -I https://localhost:8443/
curl.exe -k -I https://localhost:9443/
```

For the **trusted certificate check**, use the OpenSSL tool service (expected `Verification: OK`):

```powershell
docker compose run --rm tls-client s_client -connect baseline:443 -servername baseline -tls1_2 -verify_hostname baseline -CAfile /certs/ca.crt -verify_return_error -brief
```

For **negative tests**, rerun *without* `-CAfile` (untrusted test CA), or use `-verify_hostname wrong.localhost` with the CA file (hostname mismatch). In an interactive terminal, type `Q` followed by Enter to end the `s_client` session. Use `-brief` to reduce output.

**Important:** HSTS is an **HTTP response header**, not part of the TLS handshake. SSLyze's default report does not replace an HTTP header check. Also, the short 300-second HSTS test policy is appropriate for this disposable lab but is not a production recommendation.

## Deliverables

- Four scanner reports: 2 scanners x 2 servers.
- Certificate trust positive and negative result, plus hostname mismatch result.
- Screenshot/command output proving baseline HSTS is absent and hardened HSTS is present.
- One table summarizing differences, interpretations, and evidence filenames.

Do not submit generated private keys or commit raw results with system-identifying details accidentally. Put temporary outputs in `results/` and share chosen evidence in the report.
