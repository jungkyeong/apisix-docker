#!/bin/bash

# APISIX 서버 인증서 생성 스크립트
# Root CA로 서명된 APISIX + Dashboard 인증서 생성
# OpenSSL 3.5.4 라이브러리 사용 (RSA)
#
# 사전 조건: generate-rootca.sh 먼저 실행

set -e

# 스크립트 디렉토리 기준 경로 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OPENSSL_DIR="$PROJECT_ROOT/openssl/openssl-3.5.4"
OPENSSL_BIN="$OPENSSL_DIR/apps/openssl"

# 로컬 빌드된 라이브러리 사용
export LD_LIBRARY_PATH="$OPENSSL_DIR:$LD_LIBRARY_PATH"

# 출력 디렉토리
OUTPUT_DIR="$SCRIPT_DIR/data"
mkdir -p "$OUTPUT_DIR"

# 인증서 설정
KEY_SIZE=2048
DAYS_VALID=365
COUNTRY="KR"
STATE="Seoul"
LOCALITY="Seoul"
ORGANIZATION="APISIX"

# Root CA 확인
check_rootca() {
    if [ ! -f "$OUTPUT_DIR/ca.key" ] || [ ! -f "$OUTPUT_DIR/ca.crt" ]; then
        echo "Error: Root CA 파일을 찾을 수 없습니다."
        echo "먼저 generate-rootca.sh를 실행해주세요."
        exit 1
    fi
    echo "Root CA 확인 완료"
    echo ""
}

# OpenSSL 확인
check_openssl() {
    if [ ! -x "$OPENSSL_BIN" ]; then
        echo "Error: OpenSSL 바이너리를 찾을 수 없습니다: $OPENSSL_BIN"
        echo "OpenSSL을 먼저 빌드해주세요."
        exit 1
    fi

    echo "=========================================="
    echo "OpenSSL 버전:"
    "$OPENSSL_BIN" version
    echo "=========================================="
    echo ""
}

# APISIX Gateway 인증서 생성
generate_apisix_cert() {
    echo "[1/4] APISIX Gateway 인증서 생성 중... (RSA ${KEY_SIZE}bit)"

    "$OPENSSL_BIN" genpkey \
        -algorithm RSA \
        -pkeyopt rsa_keygen_bits:$KEY_SIZE \
        -out "$OUTPUT_DIR/apisix.key"

    "$OPENSSL_BIN" req \
        -new \
        -key "$OUTPUT_DIR/apisix.key" \
        -out "$OUTPUT_DIR/apisix.csr" \
        -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=Gateway/CN=localhost"

    cat > "$OUTPUT_DIR/apisix.ext" << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = apisix
DNS.3 = *.apisix.local
IP.1 = 127.0.0.1
IP.2 = 192.168.0.11
EOF

    "$OPENSSL_BIN" x509 \
        -req \
        -in "$OUTPUT_DIR/apisix.csr" \
        -CA "$OUTPUT_DIR/ca.crt" \
        -CAkey "$OUTPUT_DIR/ca.key" \
        -CAcreateserial \
        -out "$OUTPUT_DIR/apisix.crt" \
        -days $DAYS_VALID \
        -sha256 \
        -extfile "$OUTPUT_DIR/apisix.ext"

    echo "  완료: apisix.key, apisix.crt"
    echo ""
}

# Dashboard 인증서 생성
generate_dashboard_cert() {
    echo "[2/4] Dashboard 인증서 생성 중... (RSA ${KEY_SIZE}bit)"

    "$OPENSSL_BIN" genpkey \
        -algorithm RSA \
        -pkeyopt rsa_keygen_bits:$KEY_SIZE \
        -out "$OUTPUT_DIR/dashboard.key"

    "$OPENSSL_BIN" req \
        -new \
        -key "$OUTPUT_DIR/dashboard.key" \
        -out "$OUTPUT_DIR/dashboard.csr" \
        -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=Dashboard/CN=localhost"

    cat > "$OUTPUT_DIR/dashboard.ext" << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = apisix-dashboard
DNS.3 = *.apisix.local
IP.1 = 127.0.0.1
IP.2 = 192.168.0.11
EOF

    "$OPENSSL_BIN" x509 \
        -req \
        -in "$OUTPUT_DIR/dashboard.csr" \
        -CA "$OUTPUT_DIR/ca.crt" \
        -CAkey "$OUTPUT_DIR/ca.key" \
        -CAcreateserial \
        -out "$OUTPUT_DIR/dashboard.crt" \
        -days $DAYS_VALID \
        -sha256 \
        -extfile "$OUTPUT_DIR/dashboard.ext"

    echo "  완료: dashboard.key, dashboard.crt"
    echo ""
}

# 파일 권한 설정 (Docker 컨테이너에서 읽을 수 있도록)
set_permissions() {
    echo "[3/4] 파일 권한 설정 중..."
    chmod 644 "$OUTPUT_DIR/apisix.key"
    chmod 644 "$OUTPUT_DIR/apisix.crt"
    chmod 644 "$OUTPUT_DIR/dashboard.key"
    chmod 644 "$OUTPUT_DIR/dashboard.crt"
    echo "  완료: 권한 644 적용"
    echo ""
}

# 임시 파일 정리
cleanup() {
    echo "[4/4] 임시 파일 정리 중..."
    rm -f "$OUTPUT_DIR"/*.csr "$OUTPUT_DIR"/*.ext "$OUTPUT_DIR"/*.srl
    echo ""
}

# 인증서 정보 출력
show_cert_info() {
    echo "=========================================="
    echo "생성된 인증서 정보:"
    echo "=========================================="

    echo ""
    echo "[APISIX 인증서]"
    "$OPENSSL_BIN" x509 -in "$OUTPUT_DIR/apisix.crt" -noout -subject -issuer -dates

    echo ""
    echo "[Dashboard 인증서]"
    "$OPENSSL_BIN" x509 -in "$OUTPUT_DIR/dashboard.crt" -noout -subject -issuer -dates
}

# 인증서 검증
verify_certs() {
    echo ""
    echo "=========================================="
    echo "인증서 체인 검증:"
    echo "=========================================="
    "$OPENSSL_BIN" verify -CAfile "$OUTPUT_DIR/ca.crt" "$OUTPUT_DIR/apisix.crt"
    "$OPENSSL_BIN" verify -CAfile "$OUTPUT_DIR/ca.crt" "$OUTPUT_DIR/dashboard.crt"
}

# 메인 실행
main() {
    echo "=========================================="
    echo "APISIX 서버 인증서 생성 (Root CA 서명)"
    echo "=========================================="
    echo ""

    check_openssl
    check_rootca
    generate_apisix_cert
    generate_dashboard_cert
    set_permissions
    cleanup
    show_cert_info
    verify_certs

    echo ""
    echo "=========================================="
    echo "생성 완료!"
    echo "=========================================="
    echo "data/ 폴더:"
    echo "  - apisix.key, apisix.crt       (APISIX Gateway)"
    echo "  - dashboard.key, dashboard.crt (Dashboard)"
    echo ""
    echo "인증서 체인:"
    echo "  ca.crt -> apisix.crt"
    echo "  ca.crt -> dashboard.crt"
    echo "=========================================="
}

main
