# Initial scaffold validation (performed during project preparation)

## What was checked

The configurations and scripts were examined and tested using native Linux tools in an isolated temporary directory. This was **not** a Docker Desktop/Compose run, so the final check must be repeated by Person 1 on Windows and later by the GitHub Actions workflow.

Test platform used during preparation: Nginx 1.26.3, OpenSSL 3.5.5 (running library). Certificate creation was tested using the `generate-certs.sh` script with temporary-directory paths.

| Check | Result |
|---|---|
| `compose.yaml` parses as YAML | PASS (static only) |
| Docker Compose validation against Docker engine | NOT RUN in this environment |
| Local certificate generation | PASS |
| Certificate generator idempotence | PASS |
| Both leaf certificates verify against the test CA | PASS |
| Both Nginx configurations pass `nginx -t` | PASS (with local temporary paths/ports) |
| Both respond HTTP 200 on HTTPS | PASS (native Nginx runtime) |
| Baseline has no HSTS; hardened has HSTS | PASS |
| Baseline accepts TLS 1.2 | PASS |
| Baseline accepts specified TLS 1.2 CBC suite | PASS |
| Baseline rejects a TLS 1.2 inappropriate fallback signal | PASS (`inappropriate fallback` TLS alert) |
| Hardened rejects TLS 1.2 | PASS |
| Hardened accepts TLS 1.3 | PASS |
| Docker Desktop environment with published ports | PENDING on user machine |
| Actual container scanner compatibility | PENDING on user machine |
| GitHub Actions Docker test | PENDING after repository published |

## Why this matters

The native tests establish that the intended TLS behavior is achievable with current Nginx/OpenSSL implementations. They are not a substitute for actually starting the supplied Compose configuration on Docker Desktop. Once the local Docker deployment is run, capture the Windows test output, the GitHub CI status, and scanner output as Meeting #2 evidence.
