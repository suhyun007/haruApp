# 아이콘 흰색 배경 제거 방법

## 문제
앱 아이콘에 흰색 레이어가 보임:
- 네모 배경
- **흰색 (제거하고 싶음)**
- #fdf6e6 색상

## 원인
`assets/icon/icon.png` 파일 자체에 흰색 배경이 있음

## 해결 방법

### 방법 1: 투명 배경 아이콘 사용 (권장)

1. **포토샵/피그마 등에서:**
   - 1024x1024 PNG
   - **투명 배경** (흰색 배경 제거)
   - 아이콘만 남김
   - `assets/icon/icon.png`로 저장

2. **아이콘 재생성:**
```bash
cd haruApp
flutter pub run flutter_launcher_icons
flutter clean
flutter run
```

### 방법 2: 배경색과 아이콘 색상 통일

`pubspec.yaml`:
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/icon.png"  # 투명 배경 아이콘
  adaptive_icon_background: "#fdf6e6"  # 배경색
  adaptive_icon_foreground: "assets/icon/icon.png"  # 전경 아이콘
```

### 방법 3: Adaptive Icon 비활성화 (간단)

`pubspec.yaml`:
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/icon.png"  # 직접 배경색 포함된 아이콘 사용
  # adaptive_icon 설정 제거
```

이 경우 `icon.png`에 직접 #fdf6e6 배경색을 넣어야 함

## 추천 아이콘 구성

### 투명 배경 아이콘 (icon.png)
```
크기: 1024x1024
배경: 투명
내용: HaruFit 로고만
형식: PNG (24bit with alpha)
```

### 배경색
```
#fdf6e6 (크림/베이지)
```

## 테스트

```bash
cd haruApp
flutter pub run flutter_launcher_icons
flutter clean
flutter run -d emulator-5554
```

홈 화면에서 아이콘 확인!

## 온라인 도구

투명 배경 만들기:
- https://www.remove.bg (배경 제거)
- https://www.canva.com (디자인)
- https://icon.kitchen (Android 아이콘 생성)

## 빠른 해결 (임시)

흰색이 보기 싫다면 배경색을 흰색으로 변경:
```yaml
adaptive_icon_background: "#FFFFFF"
```

하지만 투명 배경 아이콘을 만드는 것이 정석입니다!

