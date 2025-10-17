// OneSignal 사용 시 주석 해제
// import 'package:onesignal_flutter/onesignal_flutter.dart';
//
// class OneSignalService {
//   static const String appId = 'f4639f32-6c48-4eff-bec8-2f6aca2cb21b';
//
//   static Future<void> initialize() async {
//     // OneSignal 초기화
//     OneSignal.initialize(appId);
//
//     // 푸시 알림 권한 요청
//     await OneSignal.Notifications.requestPermission(true);
//
//     // 알림 수신 리스너
//     OneSignal.Notifications.addClickListener((event) {
//       print('Notification clicked: ${event.notification.title}');
//     });
//
//     // 포그라운드 알림 표시 설정
//     OneSignal.Notifications.addForegroundWillDisplayListener((event) {
//       print('Foreground notification: ${event.notification.title}');
//       event.preventDefault();
//       event.notification.display();
//     });
//   }
//
//   // 사용자 ID 설정
//   static void setExternalUserId(String userId) {
//     OneSignal.login(userId);
//   }
//
//   // 태그 설정
//   static void sendTag(String key, String value) {
//     OneSignal.User.addTagWithKey(key, value);
//   }
//
//   // 푸시 토큰 가져오기
//   static String? getPushToken() {
//     return OneSignal.User.pushSubscription.token;
//   }
// }
