#!/usr/bin/env bash
# gen-certs.sh — local CA + TLS cert for a dev domain, ready for NGINX.
#
#   ./gen-certs.sh app.local            # certs/ca.{key,pem}, certs/app.local.{key,crt}
#   ./gen-certs.sh app.local -o ./tls   # different output dir
#
# The CA is created once and reused, so every cert you make is trusted
# after you trust the CA a single time.
set -euo pipefail

DOMAIN="${1:-}"
OUT="certs"
DAYS=365
CA_NAME="dev-ca"

usage() {
  echo "usage: $0 <domain> [-o out_dir] [-d days] [-n ca_name]" >&2
  exit 1
}

[[ -n "$DOMAIN" ]] || usage
shift
while getopts "o:d:n:" opt; do
  case "$opt" in
    o) OUT="$OPTARG" ;;
    d) DAYS="$OPTARG" ;;
    n) CA_NAME="$OPTARG" ;;
    *) usage ;;
  esac
done

mkdir -p "$OUT"
CA_KEY="$OUT/ca.key"
CA_PEM="$OUT/ca.pem"

# --- CA (once) -------------------------------------------------------------
if [[ ! -f "$CA_KEY" ]]; then
  echo "> creating CA: $CA_PEM"
  openssl genrsa -out "$CA_KEY" 4096 2>/dev/null
  openssl req -x509 -new -nodes -sha256 -days "$((DAYS * 3))" \
    -key "$CA_KEY" -subj "/CN=$CA_NAME" -out "$CA_PEM"
else
  echo "> reusing CA: $CA_PEM"
fi

# --- leaf cert -------------------------------------------------------------
KEY="$OUT/$DOMAIN.key"
CSR="$OUT/$DOMAIN.csr"
CRT="$OUT/$DOMAIN.crt"
EXT="$OUT/$DOMAIN.ext"

# SAN is what browsers check; CN alone is ignored by modern clients.
cat > "$EXT" <<EOF
basicConstraints       = CA:FALSE
authorityKeyIdentifier = keyid,issuer
keyUsage               = digitalSignature, keyEncipherment
extendedKeyUsage       = serverAuth
subjectAltName         = DNS:$DOMAIN, DNS:*.$DOMAIN, IP:127.0.0.1
EOF

echo "> issuing $CRT ($DAYS days)"
openssl genrsa -out "$KEY" 2048 2>/dev/null
openssl req -new -key "$KEY" -subj "/CN=$DOMAIN" -out "$CSR"
openssl x509 -req -in "$CSR" -CA "$CA_PEM" -CAkey "$CA_KEY" -CAcreateserial \
  -out "$CRT" -days "$DAYS" -sha256 -extfile "$EXT" 2>/dev/null
rm -f "$CSR" "$EXT"
chmod 600 "$KEY" "$CA_KEY"

cat <<EOF

done.
  cert: $CRT
  key:  $KEY
  ca:   $CA_PEM   <- trust this once (see README)
EOF
