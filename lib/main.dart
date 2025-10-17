import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'providers/user_provider.dart';
import 'providers/meal_provider.dart';
import 'providers/weight_provider.dart';
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
            seedColor: const Color(0xFFE6C767),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.ralewayTextTheme(),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

