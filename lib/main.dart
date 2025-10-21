import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'providers/user_provider.dart';
import 'providers/meal_provider.dart';
import 'providers/weight_provider.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'models/user_model.dart';
// import 'services/admob_service.dart';
// import 'services/onesignal_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // AdMob 초기화 - 나중에 활성화
  // AdMobService.initialize();
  
  // OneSignal 초기화 - 나중에 활성화
  // await OneSignalService.initialize();

  runApp(const HaruFitApp());
}

class HaruFitApp extends StatelessWidget {
  const HaruFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => MealProvider()),
        ChangeNotifierProvider(create: (_) => WeightProvider()),
      ],
      child: MaterialApp(
        title: 'HaruFit',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE7FBEC),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.notoSansTextTheme(
            ThemeData.light().textTheme.apply(
              bodyColor: const Color(0xFF555555),
              displayColor: const Color(0xFF555555),
            ),
          ),
          primaryTextTheme: GoogleFonts.notoSansTextTheme(
            ThemeData.light().textTheme.apply(
              bodyColor: const Color(0xFF555555),
              displayColor: const Color(0xFF555555),
            ),
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}

// 스플래시 스크린 - 온보딩 완료 여부 확인
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    debugPrint('=== 온보딩 체크 시작 ===');
    
    // 1. 로컬 저장소 확인
    final isComplete = await StorageService.isOnboardingComplete();
    debugPrint('로컬 온보딩 완료 여부: $isComplete');
    
    if (!mounted) return;
    
    if (isComplete) {
      // 로컬에 저장된 사용자 정보 사용
      final user = await StorageService.getUser();
      final supabaseUserId = await StorageService.getSupabaseUserId();
      debugPrint('로컬 저장 사용자: ${user?.name}');
      debugPrint('Supabase User ID: $supabaseUserId');
      
      if (user != null && mounted) {
        Provider.of<UserProvider>(context, listen: false).setUser(user);
      }
      
      // 홈 화면으로 이동
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      // 2. API 서버에서 사용자 확인 (로컬 저장소에 없는 경우)
      debugPrint('로컬 저장소에 없음. API 서버 확인 중...');
      final users = await ApiService.getUsers();
      final apiUser = users.isNotEmpty ? users.first : null;
      
      if (apiUser != null && mounted) {
        debugPrint('API 서버에서 사용자 발견: ${apiUser['nickname']}');
        
        // UserModel 생성 및 로컬 저장
        final user = UserModel(
          id: apiUser['id'],
          name: apiUser['nickname'],
          age: apiUser['age'] ?? 0,
          height: (apiUser['height'] ?? 0).toDouble(),
          currentWeight: (apiUser['currentWeight'] ?? 0).toDouble(),
          targetWeight: (apiUser['targetWeight'] ?? 0).toDouble(),
          dailyCalorieGoal: apiUser['dailyCalorieGoal'] ?? 2000,
          gender: apiUser['gender'] == 'female' ? '여성' : '남성',
          dietMethodName: apiUser['dietMethod']?['name'],
          dietMethodDescription: apiUser['dietMethod']?['description'],
        );
        
        // 로컬 저장
        await StorageService.saveUser(user);
        await StorageService.saveSupabaseUserId(apiUser['id']);
        debugPrint('API 서버 사용자 정보 로컬 저장 완료');
        
        Provider.of<UserProvider>(context, listen: false).setUser(user);
        
        // 홈 화면으로 이동
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
        } else {
          debugPrint('API 서버에도 사용자 없음 -> 온보딩 화면으로 이동');
        // 온보딩 화면으로 이동
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/onboarding');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8FFFE),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF3DDC97),
        ),
      ),
    );
  }
}

