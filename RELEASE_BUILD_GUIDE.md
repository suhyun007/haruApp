# Google Play 배포 가이드

## 1️⃣ Keystore 생성

### 터미널에서 실행:
```bash
cd /Users/admin/Projects/HaruFit/haruApp

keytool -genkey -v -keystore android/app/harufit-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias harufit
```

### 입력할 정보:
```
키 저장소 비밀번호: [6자 이상 입력, 기억하세요!]
비밀번호 재입력: [동일하게]
이름과 성: HaruFit
조직 단위: Development
조직: HaruFit
구/군/시: Seoul
시/도: Seoul
국가 코드: KR
확인: yes
키 비밀번호: [Enter - 저장소 비밀번호와 동일]
```

**중요: 비밀번호를 안전하게 보관하세요!**

## 2️⃣ key.properties 파일 생성

`android/key.properties` 파일 생성 (이미 생성됨):
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=harufit
storeFile=harufit-release-key.jks
```

**YOUR_STORE_PASSWORD와 YOUR_KEY_PASSWORD를 실제 비밀번호로 변경!**

## 3️⃣ build.gradle 설정

`android/app/build.gradle`에 서명 설정 추가 (이미 추가됨)

## 4️⃣ Release 빌드

### AAB (Google Play용):
```bash
cd /Users/admin/Projects/HaruFit/haruApp
flutter clean
flutter pub get
flutter build appbundle --release
```

생성 위치: `build/app/outputs/bundle/release/app-release.aab`

### APK (직접 설치용):
```bash
flutter build apk --release
```

생성 위치: `build/app/outputs/flutter-apk/app-release.apk`

## 5️⃣ Google Play 업로드

1. Google Play Console 접속
2. 앱 선택 → 출시 → 테스트 → 내부 테스트
3. 새 버전 만들기
4. `app-release.aab` 업로드
5. 버전 정보 입력
6. 검토 후 출시

## ⚠️ 중요 파일 보안

`.gitignore`에 추가 (이미 추가됨):
```
*.jks
key.properties
```

**절대 GitHub에 올리지 마세요!**

## 🔐 비밀번호 분실 시

Keystore 비밀번호를 잊어버리면:
- 새로운 keystore 생성 필요
- 기존 앱 업데이트 불가능 (새 앱으로 재등록)
- **비밀번호를 안전하게 보관하세요!**

## 📱 버전 관리

`pubspec.yaml`:
```yaml
version: 1.0.0+1  # 1.0.0 = 버전 이름, +1 = 버전 코드
```

업데이트 시:
```yaml
version: 1.0.1+2  # 버전 코드를 증가
```

## ✅ 체크리스트

배포 전 확인:
- [ ] Keystore 생성 완료
- [ ] key.properties 설정 완료
- [ ] 비밀번호 안전하게 저장
- [ ] AdMob ID를 실제 ID로 변경
- [ ] 앱 아이콘 설정 완료
- [ ] 테스트 완료
- [ ] AAB 빌드 성공
- [ ] 버전 정보 업데이트

