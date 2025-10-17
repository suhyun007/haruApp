# Android Adaptive Icon XML 방식

## ✅ 생성된 파일 구조

```
android/app/src/main/res/
├── drawable/
│   ├── ic_launcher_background.xml    # 배경 (#fdf6e6)
│   └── ic_launcher_foreground.xml    # 전경 (아이콘)
├── mipmap-anydpi-v26/
│   ├── ic_launcher.xml               # Adaptive Icon 정의
│   └── ic_launcher_round.xml         # 라운드 아이콘
└── mipmap-*/
    └── ic_launcher.png               # 구버전 폴백용
```

## 📝 파일 설명

### 1. ic_launcher_background.xml
- **배경색:** #fdf6e6 (크림색)
- **형식:** Vector Drawable (확대/축소 품질 유지)
- **크기:** 108x108dp

### 2. ic_launcher_foreground.xml
- **현재:** 간단한 예시 아이콘 (흰색 H)
- **수정 필요:** 실제 HaruFit 로고로 교체
- **형식:** Vector Drawable (SVG 변환)

### 3. mipmap-anydpi-v26/ic_launcher.xml
- Android 8.0+ (API 26) Adaptive Icon 정의
- background + foreground 조합

## 🎨 ic_launcher_foreground.xml 커스터마이징

### 방법 1: SVG를 Vector Drawable로 변환

1. **SVG 파일 준비**
   - HaruFit 로고 SVG

2. **Android Studio에서 변환**
   - 우클릭 → New → Vector Asset
   - Local file (SVG, PSD) 선택
   - SVG 파일 선택
   - Next → Finish

3. **생성된 XML 코드 복사**
   - `ic_launcher_foreground.xml`에 붙여넣기

### 방법 2: 온라인 변환

https://svg2vector.com/ 에서 SVG → Vector Drawable 변환

### 방법 3: 직접 작성 (간단한 도형)

```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    
    <!-- 중앙 정렬 그룹 -->
    <group
        android:scaleX="0.6"
        android:scaleY="0.6"
        android:translateX="54"
        android:translateY="54">
        
        <!-- 여기에 로고 Path 추가 -->
        <path
            android:fillColor="#E6C767"
            android:pathData="M ... (SVG path data)" />
    </group>
</vector>
```

## 🔧 색상 변경

### 배경색 변경
`ic_launcher_background.xml`:
```xml
<path
    android:fillColor="#YOUR_COLOR"
    android:pathData="M0,0h108v108h-108z" />
```

### 아이콘 색상 변경
`ic_launcher_foreground.xml`:
```xml
<path
    android:fillColor="#YOUR_COLOR"
    android:pathData="..." />
```

## ✅ 장점

1. **해상도 독립적** - Vector 방식이라 어떤 크기에도 선명
2. **파일 크기 작음** - PNG보다 훨씬 작음
3. **쉬운 수정** - 색상/크기 XML만 수정
4. **흰색 배경 없음** - background와 foreground 완전 분리

## 🚀 적용 방법

```bash
cd haruApp
flutter clean
flutter run
```

XML 파일은 자동으로 인식됩니다!

## 💡 현재 상태

- ✅ 배경: #fdf6e6 크림색
- ⚠️ 전경: 임시 예시 아이콘 (H 모양)
- 🔄 **다음 단계:** 실제 HaruFit 로고를 `ic_launcher_foreground.xml`에 넣기

## 📱 테스트

```bash
flutter run -d emulator-5554
```

홈 화면에서 아이콘 확인!

## 🎯 추천 도구

- **Figma/Sketch** → Export as SVG
- **svg2vector.com** → SVG to Android Vector
- **Android Studio** → Vector Asset Studio
- **shapeshifter.design** → Path 애니메이션 편집

