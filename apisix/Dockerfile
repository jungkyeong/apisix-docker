FROM apache/apisix:3.8.0-debian

USER root

# 빌드 도구 설치
RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    perl \
    && rm -rf /var/lib/apt/lists/*

# OpenSSL 소스 복사 (빌드된 폴더 또는 tar.gz)
# COPY openssl/openssl-3.5.4/ /tmp/openssl-3.5.4/
COPY openssl/openssl-3.5.4.tar.gz /tmp/

# OpenSSL 3.5.4 빌드 (이미 빌드된 경우 스킵)
RUN if [ -f /tmp/openssl-3.5.4/libcrypto.so.3 ]; then \
        echo "Using pre-built OpenSSL 3.5.4..." && \
        mkdir -p /usr/local/openssl-3.5.4/lib64 && \
        mkdir -p /usr/local/openssl-3.5.4/bin && \
        mkdir -p /usr/local/openssl-3.5.4/include && \
        cp -r /tmp/openssl-3.5.4/include/openssl /usr/local/openssl-3.5.4/include/ && \
        cp /tmp/openssl-3.5.4/*.so* /usr/local/openssl-3.5.4/lib64/ && \
        cp /tmp/openssl-3.5.4/apps/openssl /usr/local/openssl-3.5.4/bin/; \
    else \
        echo "Building OpenSSL 3.5.4 from source..." && \
        cd /tmp && \
        tar -xzf openssl-3.5.4.tar.gz && \
        cd openssl-3.5.4 && \
        ./Configure --prefix=/usr/local/openssl-3.5.4 --openssldir=/usr/local/openssl-3.5.4/ssl \
            shared \
            linux-x86_64 && \
        make -j$(nproc) && \
        make install; \
    fi && \
    rm -rf /tmp/openssl-3.5.4 /tmp/openssl-3.5.4.tar.gz

# 수정된 EYL 라이브러리 덮어쓰기
# COPY openssl/eyl/realize/ /tmp/eyl/
# RUN cp /tmp/eyl/libcrypto.so.3 /usr/local/openssl-3.5.4/lib64/ && \
#     cp /tmp/eyl/libssl.so.3 /usr/local/openssl-3.5.4/lib64/ && \
#     cp /tmp/eyl/openssl /usr/local/openssl-3.5.4/bin/ && \
#     rm -rf /tmp/eyl

# 시스템 라이브러리 경로에 OpenSSL 3.5.4 추가
RUN echo "/usr/local/openssl-3.5.4/lib64" > /etc/ld.so.conf.d/openssl-3.5.4.conf && \
    ldconfig

# OpenSSL 3.5.4를 기본으로 사용하도록 환경변수 설정
ENV PATH="/usr/local/openssl-3.5.4/bin:$PATH"
ENV LD_LIBRARY_PATH="/usr/local/openssl-3.5.4/lib64:$LD_LIBRARY_PATH"

USER apisix
