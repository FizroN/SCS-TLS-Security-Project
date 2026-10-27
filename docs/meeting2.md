# Meeting #2 — implementation and validation handoff

The lecturer expects **the practical part completed**, specifically:

- **Section 3 — Testbed Setup (Implementation):** reproducible Docker setup, security design, certificate generation and system configuration.
- **Section 4 — Experiments (Validation):** executed tests, real observations, evidence, comparisons, and limitations.

Live demos are not mandatory. Screenshots, configuration fragments, outputs, figures, and tables are acceptable.

## Section 3: Testbed Setup

Describe the host OS, Docker Desktop/Engine and Compose versions, image tags and digest (if possible), Docker network (`tlslab_network`), two endpoints and port mappings, certificate SAN and trust model, and the baseline/hardened Nginx configuration differences.

| Property | Baseline | Hardened |
|---|---|---|
| Container address | `baseline:443` | `hardened:443` |
| Windows host address | `localhost:8443` | `localhost:9443` |
| TLS versions | TLS 1.2 + TLS 1.3 | TLS 1.3 only |
| TLS 1.2 ciphers | ECDHE-RSA-AES128-SHA (CBC), ECDHE-RSA-AES128-GCM-SHA256 | Not applicable |
| HSTS | Absent | `max-age=300` |
| Certificate issuer | Private test CA | Same private test CA |
| Server certificate | `baseline.crt` | `hardened.crt` |

**Note:** The project uses **two intentionally different configurations**, not a genuine historical snapshot of a production service. Treat comparisons as controlled experiments, not proof that every vulnerability is exploitable. TLS 1.2 itself remains broadly usable when configured with modern suites; the baseline additionally retains an older CBC suite.

## Section 4: Experiment matrix

| Experiment | Test | Minimum evidence | Owner |
|---|---|---|---|
| 1 Protocol/ciphers | SSLyze + testssl.sh scans of both endpoints | Four reports and summary table | Person 2 |
| 2 Downgrade | Standard 1.2, fallback 1.2, forced 1.2 against TLS 1.3-only server | Handshake output and meaning | Person 3 |
| 3 Certificates & HSTS | Trust, mismatch, missing trust; header presence | Three cert outcomes + headers | Person 2 |
| 4 Hardening | Compare endpoints side-by-side | Config diff + synthesis table | Person 1 with all teammates |
| Supplement | mitmproxy inspection of explicitly proxied HTTPS | One captured request/response + trust explanation | Person 3 |

## Person 1 acceptance checklist

- [ ] `docker compose config --quiet` passes
- [ ] `scripts/start.ps1` completes on Windows Docker Desktop
- [ ] Both containers are healthy and responding (`docker compose ps`)
- [ ] `nginx -t` passes for both
- [ ] `curl.exe -k -I https://localhost:8443/` responds HTTP 200 with **no HSTS**
- [ ] `curl.exe -k -I https://localhost:9443/` responds HTTP 200 with **HSTS**
- [ ] Baseline allows TLS 1.2; hardened rejects TLS 1.2 and accepts TLS 1.3
- [ ] Other teammates can run scanners using `--network tlslab_network`
- [ ] Save tool version commands and configuration snippets
- [ ] Save useful screenshots and include analysis in report

## Record reproducibility metadata

```powershell
docker version
docker compose version
docker compose images
docker compose ps
docker compose exec -T baseline nginx -V
docker compose exec -T hardened nginx -V
```

Do not record or submit `ca.key`, `baseline.key`, `hardened.key`; do not install lab CA globally.

## Issues to watch

- Public scanners using default CA stores will mark locally generated certs as **untrusted**. This is expected and is not a difference between the two endpoints.
- OpenSSL in modern containers may restrict obsolete TLS 1.0/3DES; experiments do not require forcing them.
- `TLS_FALLBACK_SCSV` detects certain inappropriate version fallback cases; it is not general protection against all downgrades.
- HSTS is tested via HTTP response headers; browsers and clients may handle `.localhost` specially.
- testssl.sh may detect more than SSLyze. Different tests and false positives need interpretation.
- Results should be labelled by date, scanner version, server config and environment.
