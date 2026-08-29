import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ZeroLinkApp());
}

class ZeroLinkApp extends StatefulWidget {
  const ZeroLinkApp({super.key});

  @override
  State<ZeroLinkApp> createState() => _ZeroLinkAppState();
}

class _ZeroLinkAppState extends State<ZeroLinkApp> with WidgetsBindingObserver {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Keep presence accurate as the app backgrounds/foregrounds.
    if (state == AppLifecycleState.resumed) {
      _authService.setOnlineStatus(true);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _authService.setOnlineStatus(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZeroLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
