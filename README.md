### 개요
1. APISIX docker compose 버전
2. APISIX와 대시보드가 etcd라는 설정 저장소를 통해 설정을 공유하는 형태

### 접속 정보 (192.168.0.11)
1. Dashboard (HTTP):
- http://192.168.0.11:9200
- 로그인: admin / admin
2. Dashboard (HTTPS):
- https://192.168.0.11:9201
3. APISIX Gateway:
- HTTP: http://192.168.0.11:9202
- HTTPS: https://192.168.0.11:9204
4. Admin API (HTTPS):
- https://192.168.0.11:9203
5. Prometheus metrics:
- http://192.168.0.11:9205
6. Control API:
- http://192.168.0.11:9206
7. etcd (내부용):
- http://apisix-etcd-2:9207


### step test
1. Docker Desktop, Linux Server 환경에서 구동 확인

### Client 설정
- 서버 url: https://192.168.0.11:9204
- realm: apisix-test
- client: kyber-client
- tkXxFNRAFdqV0AjoaW3ywA4eh7umjpBB
- redirect url: https://192.168.0.11:9204/kyber-area/callback

- Keyclaok 클라이언트
- Valid redirect URIs: https://192.168.0.11:9204/kyber-area/*
- Valid post logout redirect URIs: https://192.168.0.11:9204/kyber-area/*
- web origin: https://192.168.0.11:9204
