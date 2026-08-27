import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import 'screens/onboarding_screen.dart';
import 'widgets/bottom_navigation.dart';
import 'services/kakao_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // Kakao SDK 초기화
  // ============================================================

  await KakaoSdk.init(
    nativeAppKey: 'f5c2a76b9629d32baa7816b9320e1453',
  );

  print('카카오 SDK 초기화 완료');

  // ============================================================
  // Kakao Map 초기화
  // ============================================================

  AuthRepository.initialize(
    appKey: '62411923f1777b7b6b056bde95e80685',
  );

  print('카카오맵 SDK 초기화 완료');

  // ============================================================
  // 앱 실행
  // ============================================================

  runApp(const SNOBApp());
}

// ============================================================
// SNOB App
// ============================================================

class SNOBApp extends StatelessWidget {
  const SNOBApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SNOB',
      home: const StartScreen(),
    );
  }
}

// ============================================================
// 시작 화면
// ============================================================

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

// ============================================================
// StartScreen State
// ============================================================

class _StartScreenState extends State<StartScreen> {
  @override
  void initState() {
    super.initState();

    checkLogin();
  }

  // ============================================================
  // 로그인 상태 확인
  // ============================================================

  Future<void> checkLogin() async {
    print('로그인 상태 확인 시작');

    await Future.delayed(
      const Duration(milliseconds: 300),
    );

    final bool hasToken =
        await KakaoAuthService.checkToken();

    print('로그인 상태 : $hasToken');

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) {
          if (hasToken) {
            print('BottomNavigation으로 이동');

            return const BottomNavigation();
          }

          print('OnboardingScreen으로 이동');

          return const OnboardingScreen();
        },
      ),
    );
  }

  // ============================================================
  // 화면
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}