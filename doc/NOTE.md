### certs
1. Self-Sign 인증서 생성
- CA, apisix gateway, 대시보드용 키 제공

### apisix
1. control API
- APISIX가 실행 중인 노드의 상태 정보(ex 메모리, CPU, 버전, 플러그인 상태 등)을 조회할 수 있게 하는 내부 관리용 API

2. admin API
- 라우팅 관리, 백앤드 서비스 관리, 플러그인 구성, 보안, 인증 관리 등의 실질적인 게이트웨이의 네트워크 제어 수행용 API

3. 인증키
- API 요청 시, HTTP 요청 헤더에 포함되어 사용됨 (관리 작업 수행 확인용)

4. etcd
- 분산형 키-값 저장소
- 분산 시스템의 각 서비스 간 설정 저장소 역할
- APISIX - 대시보드 간 etcd 공유 

5. 플러그인

### dashboard
1. conf
- 대시보드 서버 listen
- etcd
    - 분산형 키-값 저장소로써 APISIX - 대시보드 간 etcd 공유
- log
    - error_log: 오류 로그를 해당 파일 경로에 기록
    - access_log: 요청 및 응답 등 접근 로그를 해당 파일 경로에 기록
- security
    - content_security_policy: 보안정책 설정
- ssl
    - https 접속 설정

2. authentication
- secret: JWT 토큰 서명에 사용되는 비밀 키
- expire_time: 로그인 후 세션 유지 시간(초 단위)
- users: 초기 접속 계정 정보

3. 플러그인

### 저장되는 볼륨의 내용
- data/etcd: etcd 데이터: Routes, Upstreams, Services, SSL 인증서, Plugins 등 APISIX 설정 데이터
