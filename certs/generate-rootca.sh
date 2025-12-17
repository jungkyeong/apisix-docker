#!/bin/bash

# APISIX Root CA 인증서 생성 스크립트
# Root CA만 단독 생성
# OpenSSL 3.5.4 라이브러리 사용 (RSA)

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
KEY_SIZE=4096
DAYS_VALID=3650
COUNTRY="KR"
STATE="Seoul"
LOCALITY="Seoul"
ORGANIZATION="APISIX"

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

# Root CA 개인키 생성
generate_rootca_key() {
    echo "[1/3] Root CA 개인키 생성 중... (RSA ${KEY_SIZE}bit)"
    "$OPENSSL_BIN" genpkey \
        -algorithm RSA \
        -pkeyopt rsa_keygen_bits:$KEY_SIZE \
        -out "$OUTPUT_DIR/ca.key"
    echo "  완료: ca.key"
    echo ""
}

# Root CA 인증서 생성 (자체 서명)
generate_rootca_cert() {
    echo "[2/3] Root CA 인증서 생성 중... (자체 서명)"
    "$OPENSSL_BIN" req \
        -new \
        -x509 \
        -key "$OUTPUT_DIR/ca.key" \
        -sha256 \
        -days $DAYS_VALID \
        -out "$OUTPUT_DIR/ca.crt" \
        -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=Dev/CN=APISIX-CA"
    echo "  완료: ca.crt"
    echo ""
}

# 파일 권한 설정 (Docker 컨테이너에서 읽을 수 있도록)
set_permissions() {
    echo "[3/3] 파일 권한 설정 중..."
    chmod 644 "$OUTPUT_DIR/ca.key"
    chmod 644 "$OUTPUT_DIR/ca.crt"
    echo "  완료: 권한 644 적용"
    echo ""
}

# 인증서 정보 출력
show_cert_info() {
    echo "=========================================="
    echo "Root CA 인증서 정보:"
    echo "=========================================="
    "$OPENSSL_BIN" x509 -in "$OUTPUT_DIR/ca.crt" -noout -subject -issuer -dates
}

# 메인 실행
main() {
    echo "=========================================="
    echo "APISIX Root CA 인증서 생성 (RSA)"
    echo "=========================================="
    echo ""

    check_openssl
    generate_rootca_key
    generate_rootca_cert
    set_permissions
    show_cert_info

    echo ""
    echo "=========================================="
    echo "생성 완료!"
    echo "=========================================="
    echo "data/ 폴더:"
    echo "  - ca.key (Root CA 개인키)"
    echo "  - ca.crt (Root CA 인증서)"
    echo ""
    echo "서버 인증서 생성:"
    echo "  ./generate-server.sh"
    echo "=========================================="
}

main
