# TLS Security: Auditing & Downgrade Analysis

A **local-only**, two-server HTTPS laboratory for a university Secure Communications Systems project. It supports Meeting #2's **Testbed Setup (Implementation)** and **Experiments (Validation)**.

## Architecture

| Service | Docker DNS address | Windows host address | Security difference |
|---|---|---|---|
| `baseline` | `https://baseline:443/` | `https://localhost:8443/` | TLS 1.2 and 1.3; includes a legacy TLS 1.2 CBC suite; **no HSTS** |
| `hardened` | `https://hardened:443/` | `https://localhost:9443/` | TLS 1.3 only; HSTS present; session tickets disabled |

Both use disposable certificates signed by the same **locally generated test CA**. This isolates certificate differences from protocol/HSTS differences. The certificates are deliberately **not trusted** by your operating system or by ordinary scanner trust stores. For a positive trust test, explicitly supply `certs/ca.crt` to OpenSSL.

**Never deploy the baseline configuration to a public server. Never install `ca.crt` as a globally trusted OS/browser root, and never commit CA/private keys.**

## Requirements

- Windows 11 + Docker Desktop (Linux containers), or Docker Engine + Compose on Linux.
- PowerShell or a POSIX shell; `curl.exe` is included in Windows 11.
- No local Python/SSLyze installation required.
- No external domain, cloud VM, or extra hardware needed.

## Quick start on Windows PowerShell

Open PowerShell in this repository directory:

```powershell
.\scripts\start.ps1
.\scripts\smoke-test.ps1
```

Equivalent manual commands (PowerShell, CMD, Linux shell):

```shell
docker compose config --quiet
docker compose build certgen
docker compose run --rm certgen
docker compose up -d baseline hardened
docker compose ps
```

The certificate generator is **idempotent**: if all six key/cert files are already present, it preserves them. If generation was interrupted, back up and clear generated certificate files before retrying.

### Quick checks

```powershell
curl.exe -k -I https://localhost:8443/
curl.exe -k -I https://localhost:9443/
docker compose exec -T baseline nginx -t
docker compose exec -T hardened nginx -t
```

`-k` deliberately ignores the test CA's lack of public trust. It is **only for this local test lab**; it must not be used as evidence that certificates are valid/trusted.

Expected: HTTP 200 for both endpoints; `Strict-Transport-Security: max-age=300` appears **only** on the hardened endpoint.

### Stop the lab

```powershell
docker compose down
```

To completely regenerate the CA and server certificates, first stop the lab and delete the generated files in `certs/` (keep `.gitkeep`), then rerun `start.ps1`. Previously saved scans are not directly comparable if you rotate certificates.

## Scanning from Docker containers

Both servers are accessible by their service names inside `tlslab_network` (the explicitly named Docker network):

```powershell
docker run --rm --network tlslab_network nablac0d3/sslyze:latest baseline:443
docker run --rm --network tlslab_network nablac0d3/sslyze:latest hardened:443

docker run --rm --network tlslab_network ghcr.io/testssl/testssl.sh baseline:443
docker run --rm --network tlslab_network ghcr.io/testssl/testssl.sh hardened:443
```

The external scanner containers must join the network. Using `localhost:8443` **inside a scanner container** would target that scanner container itself, not the Windows host.

For HTTPS response headers from the Windows host, use `curl.exe -k -I` as shown above. For OpenSSL tests, see [docs/person3.md](docs/person3.md).

## Repository map

```text
compose.yaml                  two HTTPS endpoints + certificate/tool containers
nginx/baseline/nginx.conf     baseline TLS settings
nginx/hardened/nginx.conf     hardened TLS settings
scripts/generate-certs.sh     disposable CA + leaf cert generator
scripts/start.ps1             one-command setup on Windows
scripts/smoke-test.ps1        basic readiness tests on Windows
tools/Dockerfile              OpenSSL container (no host install needed)
certs/                        generated secrets (ignored by Git)
results/                      temporary scans/screenshots (ignored by Git)
docs/person2.md               handoff for auditing/certificate work
docs/person3.md               handoff for downgrade/mitmproxy work
docs/meeting2.md              report outline & evidence checklist
docs/github-setup.md           publish to GitHub, invite team
docs/validation-notes.md       initial validation & remaining runtime checks
```

## Experiment mapping

| Experiment | Implemented in this repository | Next owner |
|---|---|---|
| 1 — TLS protocols & cipher suites | Two intentionally contrasting Nginx configurations | Person 2 performs scans and interprets results |
| 2 — Downgrade analysis | Baseline supports TLS 1.2 + TLS 1.3; hardened TLS 1.3 only | Person 3 runs fallback tests |
| 3 — Certificates & HSTS | Local CA, server certificates with SAN, baseline no HSTS vs hardened HSTS | Person 2 tests trust/mismatch and headers |
| 4 — Before/after hardening | Two parallel configurations with stable endpoints | All three combine findings |

The goal is **reproducible configuration comparisons**, not a real-world exploit. TLS 1.2 support by itself is not a flaw; the baseline's combination of TLS 1.2 plus weaker CBC choices and absent HSTS provides contrast. Current OpenSSL versions may refuse ancient TLS 1.0 or 3DES suites; those are intentionally *not* necessary for the lab.

## What counts as Person 1 complete?

- `docker compose config --quiet` succeeds.
- Both Nginx services launch; `nginx -t` succeeds for both.
- Both return HTTP 200 at host ports 8443 and 9443.
- Baseline has **no** HSTS header; hardened **does**.
- Baseline accepts TLS 1.2, hardened rejects it; hardened accepts TLS 1.3 (verify with OpenSSL tests).
- Person 2/3 can scan services on the `tlslab_network` network.
- Document actual Docker/NGINX/OpenSSL versions and screenshots for Meeting #2.

See [docs/meeting2.md](docs/meeting2.md) for a complete evidence checklist.

## Troubleshooting

- **Nginx complains about missing certificates:** Run `docker compose run --rm certgen` *before* `docker compose up -d`.
- **Docker unavailable:** Start Docker Desktop and confirm Linux containers mode; run `docker info`.
- **Port taken:** Change the *host* port in `compose.yaml` (left side of `8443:443`, `9443:443`). Leave container port 443 unchanged.
- **Certificate not trusted:** Expected. Supply `/certs/ca.crt` explicitly to OpenSSL for a *positive* verification test.
- **Scanners cannot resolve `baseline`:** Check `docker network inspect tlslab_network` and pass `--network tlslab_network`.
- **You expected TLS 1.0:** Deliberately not enabled. Supporting an obsolete protocol in 2026 requires special legacy configuration that would complicate this project.
- **Windows Smart App Control blocks `nassl`:** Use the SSLyze Docker image rather than a native Python extension, as in the commands above.

## References

- [Nginx SSL module](https://nginx.org/en/docs/http/ngx_http_ssl_module.html)
- [Docker Compose networking](https://docs.docker.com/compose/how-tos/networking/)
- [OpenSSL s_client](https://docs.openssl.org/master/man1/openssl-s_client/)
- [SSLyze](https://github.com/nabla-c0d3/sslyze)
- [testssl.sh](https://github.com/testssl/testssl.sh)

## Status

The repository contains ready-to-run configuration and verification scripts. See [initial validation notes](docs/validation-notes.md) for tested Nginx/OpenSSL behavior and remaining container tests. **The maintainers must run and capture the Docker tests on their own machine** before calling the environment operational. This code is intended for an educational, local-only security lab.

## GitHub and continuous integration

See [docs/github-setup.md](docs/github-setup.md) for creating a GitHub repository and inviting teammates. A [GitHub Actions workflow](.github/workflows/testbed.yml) performs automated smoke tests on pushes and pull requests. This workflow has **not been run yet**; check its result after publishing.
