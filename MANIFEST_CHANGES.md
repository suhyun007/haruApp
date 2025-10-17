# AndroidManifest.xml 변경 사항 상세

## 🔄 변경된 항목

### 1. 권한 (Permissions)

#### 추가됨:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```
**목적:** Android 13+ (API 33)에서 푸시 알림을 위해 필요

#### 기존 유지:
- `INTERNET` - API 통신
- `ACCESS_NETWORK_STATE` - 네트워크 상태 확인

---

### 2. 앱 라벨 (Application Label)

#### 변경 전:
```xml
android:label="HaruFit"
```

#### 변경 후:
```xml
android:label="@string/app_name"
```

**이유:**
- 다국어 지원 가능
- strings.xml에서 중앙 관리
- 앱 이름 변경 시 한 곳만 수정

**파일 위치:** `android/app/src/main/res/values/strings.xml`
```xml
<string name="app_name">HaruFit</string>
```

---

### 3. usesCleartextTraffic 제거

#### 변경 전:
```xml
android:usesCleartextTraffic="true"
```

#### 변경 후:
제거됨

**이유:**
- 개발 중에만 필요 (localhost 테스트)
- 프로덕션에서는 HTTPS만 사용
- 보안 강화

---

### 4. AdMob 설정 추가

```xml
<!-- AdMob App ID -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-8911842959624418~7210917048"/>
```

**목적:**
- Google AdMob 광고 SDK 초기화
- 앱 식별자 등록

**필요한 작업:**
- AdMob 계정에서 실제 App ID 발급
- `pubspec.yaml`에 `google_mobile_ads` 패키지 추가
- `lib/services/admob_service.dart`에서 광고 단위 설정

---

### 5. taskAffinity 설정

```xml
android:taskAffinity=""
```

**목적:**
- 앱이 독립적인 태스크로 실행
- 멀티태스킹 시 다른 앱과 분리
- 딥링크/푸시 알림에서 앱 실행 시 새 태스크 생성

---

### 6. OneSignal 푸시 알림

```xml
<!-- OneSignal 설정 -->
<meta-data
    android:name="onesignal_app_id"
    android:value="f4639f32-6c48-4eff-bec8-2f6aca2cb21b" />
<meta-data
    android:name="onesignal_google_project_number"
    android:value="REMOTE" />
```

**목적:**
- OneSignal 푸시 알림 서비스 초기화
- FCM(Firebase Cloud Messaging) 연동

**필요한 작업:**
- OneSignal 계정 생성
- Firebase 프로젝트 설정
- Server Key 등록
- `pubspec.yaml`에 `onesignal_flutter` 패키지 추가

---

### 7. Queries 태그

```xml
<queries>
    <intent>
        <action android:name="android.intent.action.PROCESS_TEXT"/>
        <data android:mimeType="text/plain"/>
    </intent>
</queries>
```

**목적:**
- Android 11+ (API 30) 패키지 가시성
- 텍스트 선택 시 다른 앱과 연동
- Flutter 엔진의 텍스트 처리 플러그인 지원

**사용 예:**
- 텍스트 선택 후 번역 앱으로 전송
- 식사 기록에서 음식 이름 복사/공유

---

## 📱 iOS 변경 사항

### Info.plist 추가:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-8911842959624418~7210917048</string>

<key>NSUserTrackingUsageDescription</key>
<string>맞춤형 광고를 제공하기 위해 추적을 허용해주세요</string>

<key>SKAdNetworkItems</key>
<array>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cstr6suwn9.skadnetwork</string>
    </dict>
</array>
```

---

## 🔐 보안 고려사항

### 1. POST_NOTIFICATIONS 권한
- 런타임 권한 (사용자 동의 필요)
- 적절한 시점에 요청 (첫 실행 후 컨텍스트 제공)

### 2. usesCleartextTraffic 제거
- HTTPS만 사용
- 개발 시 필요하면 디버그 빌드에만 추가

### 3. 광고 추적
- iOS 14.5+ ATT (App Tracking Transparency) 필수
- 사용자 동의 없이 IDFA 수집 불가

---

## 🚀 배포 체크리스트

### Android
- [ ] AdMob App ID 실제 값으로 변경
- [ ] OneSignal App ID 확인
- [ ] POST_NOTIFICATIONS 권한 요청 플로우 구현
- [ ] 프로덕션에서 usesCleartextTraffic 제거됨 확인
- [ ] 광고 테스트 완료

### iOS
- [ ] GADApplicationIdentifier 실제 값으로 변경
- [ ] NSUserTrackingUsageDescription 메시지 수정
- [ ] SKAdNetwork 식별자 추가
- [ ] OneSignal APNs 인증서 설정
- [ ] 푸시 알림 테스트

---

## 📝 버전별 차이

| 항목 | 내가 생성한 기본 버전 | 당신이 제공한 프로덕션 버전 |
|-----|-------------------|---------------------|
| 권한 | INTERNET, NETWORK | **+ POST_NOTIFICATIONS** |
| 라벨 | 하드코딩 | **문자열 리소스** |
| HTTP | 허용 (개발용) | **제거 (보안)** |
| 광고 | ❌ | **✅ AdMob** |
| 푸시 | ❌ | **✅ OneSignal** |
| 텍스트 처리 | ❌ | **✅ Queries** |
| 태스크 관리 | 기본 | **✅ taskAffinity** |

---

## 💡 추가 권장 사항

### 1. Firebase 통합
```bash
# Firebase CLI 설치
npm install -g firebase-tools

# Flutter 프로젝트에 Firebase 추가
flutterfire configure
```

### 2. 앱 서명
- Play Console에서 앱 서명 키 등록
- 릴리즈 빌드 시 서명 자동화

### 3. ProGuard 설정
```gradle
buildTypes {
    release {
        minifyEnabled true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

### 4. 멀티 Dex
```gradle
defaultConfig {
    multiDexEnabled true
}
```

