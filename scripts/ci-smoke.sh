#!/bin/sh
# Automated smoke tests for GitHub Actions. This does not replace the full experiments.
set -eu

docker compose exec -T baseline nginx -t
docker compose exec -T hardened nginx -t

curl -fkSsI --max-time 10 https://127.0.0.1:8443/ >/tmp/tls-baseline-headers
curl -fkSsI --max-time 10 https://127.0.0.1:9443/ >/tmp/tls-hardened-headers

if grep -qi '^Strict-Transport-Security:' /tmp/tls-baseline-headers; then
    echo 'FAIL: baseline unexpectedly has HSTS' >&2
    exit 1
fi
if ! grep -qi '^Strict-Transport-Security: max-age=300' /tmp/tls-hardened-headers; then
    echo 'FAIL: hardened is missing HSTS' >&2
    exit 1
fi

# Check normal TLS 1.2, forced legacy CBC and inappropriate fallback.
docker compose run --rm -T tls-client s_client -connect baseline:443 -servername baseline -tls1_2 -CAfile /certs/ca.crt -verify_hostname baseline -verify_return_error -brief </dev/null >/tmp/tls12.log 2>&1
grep -q 'CONNECTION ESTABLISHED' /tmp/tls12.log

docker compose run --rm -T tls-client s_client -connect baseline:443 -servername baseline -tls1_2 -cipher ECDHE-RSA-AES128-SHA -CAfile /certs/ca.crt -verify_hostname baseline -verify_return_error -brief </dev/null >/tmp/tls-cbc.log 2>&1
grep -q 'CONNECTION ESTABLISHED' /tmp/tls-cbc.log

if docker compose run --rm -T tls-client s_client -connect baseline:443 -servername baseline -tls1_2 -fallback_scsv -brief </dev/null >/tmp/tls-fallback.log 2>&1; then
    echo 'FAIL: fallback handshake unexpectedly succeeded' >&2
    exit 1
fi
grep -qi 'inappropriate fallback' /tmp/tls-fallback.log

if docker compose run --rm -T tls-client s_client -connect hardened:443 -servername hardened -tls1_2 -brief </dev/null >/tmp/hardened-tls12.log 2>&1; then
    echo 'FAIL: hardened accepted TLS 1.2' >&2
    exit 1
fi

docker compose run --rm -T tls-client s_client -connect hardened:443 -servername hardened -tls1_3 -CAfile /certs/ca.crt -verify_hostname hardened -verify_return_error -brief </dev/null >/tmp/hardened-tls13.log 2>&1
grep -q 'CONNECTION ESTABLISHED' /tmp/hardened-tls13.log

echo 'PASS: HTTPS, HSTS, TLS 1.2/CBC, fallback rejection, and TLS 1.3 behavior.'
