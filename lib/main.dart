import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import semua halaman lo
import 'package:artheca/Layout/AuthPage.dart';
import 'package:artheca/Layout/OnBoarding.dart';
import 'package:artheca/Layout/SplashScreen.dart';
import 'package:artheca/MainNavigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://acngaavsrhiczjqkpuhc.supabase.co',
    anonKey: 'sb_publishable_LNyeq9ThtfHDvLVHT-RUIQ_rovuf4zm',
  );

  final session = Supabase.instance.client.auth.currentSession;

  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  String initialRoute;
  if (session != null) {
    initialRoute = '/home';
  } else if (!hasSeenOnboarding) {
    initialRoute = '/onboarding';
  } else {
    initialRoute = '/login';
  }

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Artheca',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color(0xFFAC9362),
        fontFamily: 'Poppins',
      ),
      // Pake initialRoute yang udah kita tentuin di atas tadi
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const MainNavigation(),
      },
    );
  }
}