# AdMob & OneSignal 설정 가이드

## ✅ 적용 완료 항목

### 1. AndroidManifest.xml
- ✅ POST_NOTIFICATIONS 권한 추가
- ✅ AdMob App ID 메타데이터
- ✅ OneSignal 설정
- ✅ taskAffinity="" 설정
- ✅ queries 태그 추가

### 2. iOS Info.plist
- ✅ GADApplicationIdentifier 추가
- ✅ SKAdNetwork 설정
- ✅ NSUserTrackingUsageDescription

### 3. Dependencies
```yaml
google_mobile_ads: ^5.1.0
onesignal_flutter: ^5.0.0
```

### 4. 초기화 코드
- ✅ AdMobService
- ✅ OneSignalService
- ✅ main.dart에서 초기화

## 📱 AdMob 사용법

### 배너 광고
```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';

class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdMobService.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 콘텐츠
        if (_isLoaded && _bannerAd != null)
          SizedBox(
            height: _bannerAd!.size.height.toDouble(),
            width: _bannerAd!.size.width.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}
```

### 전면 광고 (Interstitial)
```dart
InterstitialAd? _interstitialAd;

void _loadInterstitialAd() {
  InterstitialAd.load(
    adUnitId: AdMobService.interstitialAdUnitId,
    request: const AdRequest(),
    adLoadCallback: InterstitialAdLoadCallback(
      onAdLoaded: (ad) {
        _interstitialAd = ad;
        _interstitialAd?.show();
      },
      onAdFailedToLoad: (error) {
        print('Failed to load: $error');
      },
    ),
  );
}
```

## 🔔 OneSignal 사용법

### 사용자 ID 설정
```dart
// 로그인 후
OneSignalService.setExternalUserId('user123');
```

### 태그 설정
```dart
// 사용자 특성 저장
OneSignalService.sendTag('diet_type', 'low_carb');
OneSignalService.sendTag('goal_weight', '65');
```

### 푸시 토큰 가져오기
```dart
String? token = OneSignalService.getPushToken();
print('Push Token: $token');
```

### 푸시 알림 전송 (서버에서)
```bash
curl -X POST https://onesignal.com/api/v1/notifications \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic YOUR_REST_API_KEY" \
  -d '{
    "app_id": "f4639f32-6c48-4eff-bec8-2f6aca2cb21b",
    "include_external_user_ids": ["user123"],
    "contents": {"en": "식사 기록하세요!"},
    "headings": {"en": "HaruFit"}
  }'
```

## ⚙️ AdMob 설정

### 1. AdMob 계정
- https://admob.google.com
- 앱 등록
- 광고 단위 생성
- App ID 교체

### 2. 실제 ID로 변경
`lib/services/admob_service.dart`에서:
```dart
static String get bannerAdUnitId {
  if (Platform.isAndroid) {
    return 'ca-app-pub-YOUR_ACTUAL_ID/banner'; // 실제 ID
  }
  // ...
}
```

### 3. 테스트 디바이스 추가
```dart
MobileAds.instance.updateRequestConfiguration(
  RequestConfiguration(
    testDeviceIds: ['YOUR_DEVICE_ID'],
  ),
);
```

## 🔔 OneSignal 설정

### 1. OneSignal 대시보드
- https://onesignal.com
- App Settings → Keys & IDs
- OneSignal App ID 확인

### 2. FCM 설정 (Android)
- Firebase Console에서 프로젝트 생성
- `google-services.json` 다운로드
- OneSignal에 Server Key 등록

### 3. APNs 설정 (iOS)
- Apple Developer에서 Push Certificate 생성
- OneSignal에 .p12 파일 업로드

## 📊 권한 요청 타이밍

### Android 13+ (POST_NOTIFICATIONS)
```dart
// 적절한 시점에 권한 요청
if (Platform.isAndroid) {
  await OneSignal.Notifications.requestPermission(true);
}
```

### iOS (App Tracking Transparency)
```dart
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

final status = await AppTrackingTransparency.requestTrackingAuthorization();
```

## 🚀 배포 전 체크리스트

- [ ] AdMob App ID를 실제 ID로 변경
- [ ] 테스트 광고 단위 ID를 실제로 변경
- [ ] OneSignal 푸시 인증서 설정 완료
- [ ] 프로덕션에서 usesCleartextTraffic 제거
- [ ] 권한 요청 플로우 테스트
- [ ] 광고 노출 빈도 조절
- [ ] 푸시 알림 테스트

## 💰 수익화 팁

1. **광고 배치**
   - 화면 하단 배너
   - 화면 전환 시 전면 광고
   - 리워드 광고로 프리미엄 기능 제공

2. **사용자 경험**
   - 광고 빈도 조절
   - 스킵 가능한 광고 사용
   - 광고 없는 프리미엄 버전 제공

3. **푸시 알림 전략**
   - 식사 시간 알림
   - 체중 기록 리마인더
   - 목표 달성 축하 메시지

