#!/bin/bash

# SSL 인증서를 APISIX Admin API에 등록 (powershell용)
# IP 및 API key를 APISIX 환경 설정에 맞게 설정 후 사용

CERT=$(cat /etc/apisix/ssl/apisix.crt | awk '{printf "%s\\n", $0}')
KEY=$(cat /etc/apisix/ssl/apisix.key | awk '{printf "%s\\n", $0}')

curl -k -X PUT https://127.0.0.1:9203/apisix/admin/ssls/1 \
  -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" \
  -H "Content-Type: application/json" \
  -d "{\"cert\": \"${CERT}\", \"key\": \"${KEY}\", \"snis\": [\"localhost\", \"apisix\", \"192.168.0.11\"]}"
