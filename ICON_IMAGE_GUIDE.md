# 아이콘 이미지 배치 가이드

## 📁 필요한 파일

`android/app/src/main/res/drawable/launch_image.png`

이 파일이 앱 아이콘으로 사용됩니다!

## 🎨 이미지 요구사항

### 크기
- **1024x1024 픽셀** (권장)
- 정사각형

### 배경
- **#fdf6e6 색상 포함** (크림/베이지)
- 또는 투명 배경 + 앱에서 배경색 자동 적용

### 포맷
- PNG 형식
- 24bit 또는 32bit (투명도 포함 가능)

## 📍 파일 위치

```
android/app/src/main/res/
└── drawable/
    └── launch_image.png  ← 여기!
```

## ✅ 현재 설정

```xml
ic_launcher_background.xml
└── launch_image.png 사용

ic_launcher_foreground.xml
└── launch_image.png 사용 (fill로 확대)
```

## 🔧 이미지 만들기

### 방법 1: 디자인 툴 사용
1. Figma/Photoshop/Canva
2. 1024x1024 캔버스
3. 배경색: #fdf6e6
4. HaruFit 로고 배치
5. PNG로 저장

### 방법 2: 온라인 도구
- https://www.canva.com
- https://icon.kitchen
- https://appicon.co

## 💡 중요!

**흰색이 보이지 않으려면:**
- `launch_image.png` 파일에 흰색 배경이 없어야 함
- 대신 #fdf6e6 배경색을 이미지에 직접 포함
- 또는 투명 배경 + 주변을 #fdf6e6로 채움

## 🚀 적용

이미지를 만들어서 여기에 배치:
```
android/app/src/main/res/drawable/launch_image.png
```

그리고 실행:
```bash
flutter clean
flutter run
```

## 🎯 예시 이미지 구성

```
[1024x1024 PNG]
┌─────────────────┐
│  #fdf6e6 배경   │
│                 │
│   [HaruFit]     │  ← 로고/아이콘
│    [Logo]       │
│                 │
└─────────────────┘
```

이미지 파일을 만들어서 `drawable/launch_image.png`에 넣으면 완성!

