# 앱 아이콘 설정 가이드

## 📱 Android 아이콘 위치

### 수동 배치
각 해상도별로 `ic_launcher.png` 파일 배치:

```
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png      (48x48)
├── mipmap-hdpi/ic_launcher.png      (72x72)
├── mipmap-xhdpi/ic_launcher.png     (96x96)
├── mipmap-xxhdpi/ic_launcher.png    (144x144)
└── mipmap-xxxhdpi/ic_launcher.png   (192x192)
```

## 🍎 iOS 아이콘 위치

```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

Xcode에서 자동으로 관리됩니다.

## ⚡ 자동 생성 (권장)

### 1단계: 아이콘 이미지 준비
- **크기:** 1024x1024 픽셀
- **형식:** PNG (투명 배경 가능)
- **위치:** `assets/icon/icon.png`

### 2단계: 의존성 설치
```bash
cd haruApp
flutter pub get
```

### 3단계: 아이콘 생성
```bash
flutter pub run flutter_launcher_icons
```

이 명령어가 자동으로:
- Android의 모든 해상도 아이콘 생성
- iOS의 모든 해상도 아이콘 생성
- Adaptive Icon (Android) 생성

## 🎨 Adaptive Icon (Android 8.0+)

`pubspec.yaml` 설정:
```yaml
flutter_launcher_icons:
  adaptive_icon_background: "#E6C767"  # HaruFit 브랜드 컬러
  adaptive_icon_foreground: "assets/icon/icon.png"
```

## ✅ 확인 방법

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios
```

앱 설치 후 홈 화면에서 아이콘 확인

## 💡 팁

1. **고해상도 준비:** 1024x1024 PNG로 시작
2. **단순한 디자인:** 작은 크기에서도 인식 가능하게
3. **Safe Zone:** 중요한 요소는 중앙에 배치
4. **테스트:** 다양한 배경색에서 테스트

