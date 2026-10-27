#!/bin/sh
# Generate disposable lab-only CA and two server certificates.
set -eu
umask 077

mkdir -p /certs
if [ -e /certs/ca.key ] || [ -e /certs/ca.crt ] || [ -e /certs/baseline.key ] || [ -e /certs/hardened.key ]; then
    if [ -s /certs/ca.crt ] && [ -s /certs/ca.key ] && \
       [ -s /certs/baseline.crt ] && [ -s /certs/baseline.key ] && \
       [ -s /certs/hardened.crt ] && [ -s /certs/hardened.key ]; then
        echo 'Lab certificates already exist; keeping them unchanged.'
        exit 0
    fi
    echo 'Certificate directory contains incomplete files. Back it up, then clear generated files before retrying.' >&2
    exit 1
fi

openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 -out /certs/ca.key >/dev/null 2>&1
openssl req -new -x509 -sha256 -days 365 \
    -key /certs/ca.key -out /certs/ca.crt \
    -subj '/CN=TLS Laboratory Root CA' \
    -addext 'basicConstraints=critical,CA:TRUE' \
    -addext 'keyUsage=critical,keyCertSign,cRLSign' >/dev/null 2>&1

for name in baseline hardened; do
    openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 \
        -out "/certs/${name}.key" >/dev/null 2>&1
    openssl req -new -sha256 -key "/certs/${name}.key" \
        -out "/certs/${name}.csr" -subj "/CN=${name}.localhost" >/dev/null 2>&1

    cat > "/certs/${name}.ext" <<EXT
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:${name},DNS:${name}.localhost,DNS:localhost,IP:127.0.0.1
EXT

    openssl x509 -req -in "/certs/${name}.csr" \
        -CA /certs/ca.crt -CAkey /certs/ca.key -CAcreateserial \
        -out "/certs/${name}.crt" -days 90 -sha256 \
        -extfile "/certs/${name}.ext" >/dev/null 2>&1
    rm "/certs/${name}.csr" "/certs/${name}.ext"
done

chmod 644 /certs/*.crt
chmod 600 /certs/*.key
printf 'Generated disposable local CA + baseline and hardened HTTPS certificates.\n'
printf 'Do NOT import the CA into the operating-system/browser trust store.\n'
