## 사용법

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
