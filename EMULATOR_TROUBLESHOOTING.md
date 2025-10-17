# Android 에뮬레이터 문제 해결

## ❌ INSTALL_FAILED_INSUFFICIENT_STORAGE 오류

### 빠른 해결법

```bash
# 1. 캐시 정리
adb shell pm trim-caches 500M

# 2. 이전 앱 제거
adb shell pm uninstall com.harufit.app

# 3. 프로젝트 클린
cd haruApp
flutter clean

# 4. 앱 실행
flutter run -d emulator-5554
```

### 에뮬레이터 저장공간 늘리기

#### Android Studio에서 설정:

1. **Tools → Device Manager** 열기
2. 에뮬레이터 옆 **⋮** (점 세개) → **Edit** 클릭
3. **Show Advanced Settings** 클릭
4. **Internal Storage** 증가 (예: 2048 MB → 4096 MB)
5. **Finish** 클릭

#### 터미널에서 새 에뮬레이터 생성:

```bash
# 사용 가능한 시스템 이미지 확인
sdkmanager --list | grep system-images

# 시스템 이미지 설치 (없으면)
sdkmanager "system-images;android-34;google_apis;arm64-v8a"

# 새 에뮬레이터 생성 (4GB 저장공간)
avdmanager create avd -n HaruFit_Emulator \
  -k "system-images;android-34;google_apis;arm64-v8a" \
  -d "pixel_5" \
  -b arm64-v8a \
  --sdcard 4096M

# 에뮬레이터 실행
emulator -avd HaruFit_Emulator
```

## 📱 여러 디바이스 연결 시

```bash
# 연결된 디바이스 확인
flutter devices

# 특정 디바이스에 실행
flutter run -d emulator-5554        # Android 에뮬레이터
flutter run -d 00008110-000C        # 실제 iOS 기기
flutter run -d 6CD91A94-62BF        # iOS 시뮬레이터

# 모든 디바이스에 실행
flutter run -d all
```

## 🔧 에뮬레이터 공간 확보

```bash
# 에뮬레이터 접속
adb shell

# 저장공간 확인
df -h

# 앱 목록 확인
pm list packages

# 불필요한 앱 제거
pm uninstall <package_name>

# 전체 데이터 초기화 (주의!)
adb shell rm -rf /data/data/*
```

## 💡 권장 에뮬레이터 설정

- **Internal Storage:** 4096 MB 이상
- **SD Card:** 2048 MB 이상
- **RAM:** 2048 MB 이상
- **Android API:** API 30 (Android 11) 이상

## 🚀 실제 기기 사용 (권장)

에뮬레이터 문제를 피하려면 실제 Android 기기를 사용하세요:

1. USB 디버깅 활성화
2. USB로 컴퓨터 연결
3. `flutter devices` 확인
4. `flutter run` 실행

훨씬 빠르고 안정적입니다!

