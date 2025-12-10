#!/bin/bash

# Self-signed SSL 인증서 생성 스크립트

SCRIPT_DIR="$(dirname "$0")"
DATA_DIR="$SCRIPT_DIR/data"

# data 폴더 생성
mkdir -p "$DATA_DIR"
cd "$DATA_DIR"

# CA 인증서 생성
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 \
    -out ca.crt \
    -subj "/C=KR/ST=Seoul/L=Seoul/O=APISIX/OU=Dev/CN=APISIX-CA"

# APISIX Gateway 인증서 생성
openssl genrsa -out apisix.key 2048
openssl req -new -key apisix.key \
    -out apisix.csr \
    -subj "/C=KR/ST=Seoul/L=Seoul/O=APISIX/OU=Gateway/CN=localhost"

cat > apisix.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = apisix
DNS.3 = *.apisix.local
IP.1 = 127.0.0.1
EOF

openssl x509 -req -in apisix.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out apisix.crt -days 3650 -sha256 -extfile apisix.ext

# Dashboard 인증서 생성
openssl genrsa -out dashboard.key 2048
openssl req -new -key dashboard.key \
    -out dashboard.csr \
    -subj "/C=KR/ST=Seoul/L=Seoul/O=APISIX/OU=Dashboard/CN=localhost"

cat > dashboard.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names] 
DNS.1 = localhost
DNS.2 = apisix-dashboard
DNS.3 = *.apisix.local
IP.1 = 127.0.0.1
EOF

openssl x509 -req -in dashboard.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out dashboard.crt -days 3650 -sha256 -extfile dashboard.ext

# 권한 설정
chmod 644 *.crt *.key

# 정리
rm -f *.csr *.ext *.srl

echo "SSL 인증서 생성 완료!"
echo "생성된 파일:"
ls -la *.crt *.key
