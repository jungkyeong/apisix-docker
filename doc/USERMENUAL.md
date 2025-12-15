## 사용법

### 볼륨 폴더 생성
1. docker compose 파일 위치에 data라는 폴더 생성

### 인증서 생성 스크립트 사용
- Ubuntu 서버 혹은 WSL에서
- cd certs
- bash generate-certs.sh

### Docker 실행
1. 빌드 및 실행
- sudo docker compose up -d --build
2. 실행
- sudo docker compose up -d
3. 중지
- docker-compose down
4. 삭제
- docker-compose down -v
5. 로그 조회
- docker-compose logs -f
- sudo docker logs -f apisix-service

### etcd에 인증서 등록
- 컨테이너 초기 시작 시 SSL 인증서 etcd에 admin api를 통해 등록
- sudo docker exec apisix curl -k https://127.0.0.1:9180/apisix/admin/ssls/1 \
  -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" \
  -X PUT \
  -d '{
    "cert": "'"$(sudo docker exec apisix cat /etc/apisix/ssl/apisix.crt)"'",
    "key": "'"$(sudo docker exec apisix cat /etc/apisix/ssl/apisix.key)"'",
    "snis": ["192.168.0.11", "localhost", "apisix"]
  }'

### 확인
1. curl -k "https://192.168.0.11:9443" --head | grep Server
2. curl -k "https://192.168.0.11:9444" --head | grep Server

## APISIX upstream, route 생성
### Upstream 생성 (단일 테스트)
  1. Keycloak upstream 생성
  - name: keycloak-upstream
  - host: 192.168.0.11
  - port: 8743
  - Algorithm: Round Robin
  - Upstream Type: Node
  - Scheme: HTTPS

  2. Client app upstream 1 생성
  - name: keycloak-upstream
  - host: 192.168.0.11
  - port: 8543
  - Algorithm: Round Robin
  - Upstream Type: Node
  - Scheme: HTTPS

  3. Client app upstream 2 생성
  - name: keycloak-upstream
  - host: 192.168.0.11
  - port: 8643
  - Algorithm: Round Robin
  - Upstream Type: Node
  - Scheme: HTTPS

2. Route 생성
  1. keycloak route 생성
  - name: keycloack-route
  - priority: 10
  - path: /realms/* (아니면 특정 realm만 하려면 /realms/myrealm/*으로 설정)

  2. client route 생성
  - name: client-app-route
  - priority: 0
  - path: /*

  3. redirect 리소스용 route 생성
  - name: keycloak-resources-route
  - priority: 10
  - path: /resources/*

3.  keycloak client 설정
  - Valid redirect URls: https://192.168.0.11:9443/*
  - Valid post logout redirect URls: https://192.168.0.11:9443/*

4. client app 설정
  - 서버 url: https://192.168.0.11:9443
  - redirect url: https://192.168.0.11:9443/callback


### Upstream 생성 (다중 관리 테스트)
1. upstream 생성
  - keycloak-upstream : 192.168.0.11:8743
  - client1-upstream : 192.168.0.11:8543
  - client2-upstream : 192.168.0.11:8643

2. route 생성
  1. 연결 정보
  - keycloak-route : /realms/*, Priority: 10, keycloak-upstream
  - keycloak-resources-route: /resources/*, Priority: 10, keycloak-upstream
  - client1-route: /realm1/* , Priority: 5, client1-upstream
  - client2-route: /realm2/* , Priority: 5, client2-upstream
  
  2. proxy-rewrite 활성화(로그인 후 콜백 설정용)
  - route 생성 후 우측의 흰색 버튼 -> view 클릭 -> Raw Data Editor에 플러그인 추가 후 Submit
  - 플러그인 적용 예시
  '''
  "plugins": {
    "proxy-rewrite": {
      "regex_uri": [
        "^/pqc-area/(.*)",
        "/$1"
      ]
    }
  },
  '''

  - 전체 적용 예시
  '''
{
  "uri": "/pqc-area/*",
  "name": "pqc-area-route",
  "methods": [
    "GET",
    "POST",
    "PUT",
    "DELETE",
    "PATCH",
    "HEAD",
    "OPTIONS",
    "CONNECT",
    "TRACE",
    "PURGE"
  ],
  "plugins": {
    "proxy-rewrite": {
      "regex_uri": [
        "^/pqc-area/(.*)",
        "/$1"
      ]
    }
  },
  "upstream_id": "597254567796671170",
  "status": 1
}

  '''

3. Cleint app 설정 필요 (앱은 keycloak-client 참고)
  1. client 1
  - server-url: https://192.168.0.11:9443
  - redirect-uri: https://192.168.0.11:9443/pqc-area/callback
  2. client 2
  - server-url: https://192.168.0.11:9443
  - redirect-uri: https://192.168.0.11:9443/no-pqc-area/callback

4. keycloak
  1. pqc-area용 realm의 client:
  - Valid redirect URIs: https://192.168.0.11:9443/pqc-area/*
  - Valid post logout redirect URIs: https://192.168.0.11:9443/pqc-area/*
  - Web origins: https://192.168.0.11:9443
  2. no-pqc-area용 realm의 client:
  - Valid redirect URIs: https://192.168.0.11:9443/no-pqc-area/*
  - Valid post logout redirect URIs: https://192.168.0.11:9443/no-pqc-area/*
  - Web origins: https://192.168.0.11:9443




