# Person 3 — TLS downgrade analysis and mitmproxy

## TLS downgrade objective

Explain that **TLS 1.2 negotiation is not automatically a downgrade vulnerability**. A client intentionally offering TLS 1.2 can negotiate that version normally. `TLS_FALLBACK_SCSV` allows a client *retrying below its supported version* to signal that condition; a server supporting a higher version should return an `inappropriate_fallback` alert. This feature is documented in [RFC 7507](https://www.rfc-editor.org/rfc/rfc7507).

## Lab experiments using the OpenSSL container

The `tls-client` service contains the OpenSSL CLI, is connected to the same Docker network, and has the lab CA mounted read-only. Run these commands from the repository root (PowerShell):

**A. Normal TLS 1.2 to baseline (should succeed)**

```powershell
docker compose run --rm tls-client s_client -connect baseline:443 -servername baseline -tls1_2 -CAfile /certs/ca.crt -verify_hostname baseline -verify_return_error -brief
```

**B. TLS 1.2 with fallback indication to baseline (should fail)**

```powershell
docker compose run --rm tls-client s_client -connect baseline:443 -servername baseline -tls1_2 -fallback_scsv -CAfile /certs/ca.crt -verify_hostname baseline -brief
```

Look for `inappropriate fallback` or a handshake error. A nonzero exit status is expected in the failure case. Unlike a certificate failure, it should fail specifically because of the fallback signal.

**C. Forced TLS 1.2 to hardened (should fail: hardened supports TLS 1.3 only)**

```powershell
docker compose run --rm tls-client s_client -connect hardened:443 -servername hardened -tls1_2 -brief
```

**D. TLS 1.3 to hardened (should succeed)**

```powershell
docker compose run --rm tls-client s_client -connect hardened:443 -servername hardened -tls1_3 -CAfile /certs/ca.crt -verify_hostname hardened -verify_return_error -brief
```

When using `s_client` interactively, type `Q` and Enter to exit. Record both success and failure outcomes, with the reason for each.

## mitmproxy: small additional demonstration (do not confuse with a downgrade exploit)

The lecturers mentioned the third linked tool. mitmproxy is a supplementary HTTPS proxy/interception demo, *not* a TLS version scanner and *not* proof of a real-world MITM vulnerability.

Suggested controlled flow:

1. Start mitmweb locally (host or its official Docker image), following [official setup instructions](https://docs.mitmproxy.org/stable/overview/getting-started/).
2. Configure one test `curl` or browser client explicitly to use the proxy.
3. Use your own `baseline` HTTPS service as the upstream destination; from a host client it is `https://localhost:8443`.
4. Observe that the proxy presents its own certificate to the client. Only with deliberate trust of mitmproxy's local test CA can strict client verification succeed.
5. Capture one proxied request/response and explain the two separate TLS connections.

If mitmproxy refuses to verify the upstream **private-lab CA**, you must explicitly configure upstream trust for the lab CA or run the proxy with upstream certificate verification disabled **only for a clearly labelled disposable test**, not production. Never install mitmproxy's CA system-wide on your personal machine just to finish the assignment.

## Deliverables

- Four OpenSSL handshake outcomes (normal and fallback; TLS 1.2 vs TLS 1.3).
- Explanation of downgrade protection versus an ordinary lower-version handshake.
- One mitmproxy screenshot and a description of explicit proxy trust.
- Command/tool versions and any limitations observed.
