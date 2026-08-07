import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import 'screens/onboarding_screen.dart';
import 'widgets/bottom_navigation.dart';
import 'services/kakao_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 카카오 로그인
  KakaoSdk.init(
    nativeAppKey: 'f5c2a76b9629d32baa7816b9320e1453',
  );


  // 카카오맵
  AuthRepository.initialize(
    appKey: '62411923f1777b7b6b056bde95e80685',
  );


  runApp(const SNOBApp());
}


class SNOBApp extends StatelessWidget {
  const SNOBApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "SNOB",
      home: const StartScreen(),
    );
  }
}



class StartScreen extends StatefulWidget {

  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();

}



class _StartScreenState extends State<StartScreen> {


  @override
  void initState() {
    super.initState();
    checkLogin();
  }


  Future<void> checkLogin() async {

    await Future.delayed(
      const Duration(milliseconds:300)
    );


    bool hasToken =
        await KakaoAuthService.checkToken();


    print("로그인 상태 : $hasToken");


    if(!mounted) return;


    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
        hasToken
        ? const BottomNavigation()
        : const OnboardingScreen(),
      ),
    );

  }



  @override
  Widget build(BuildContext context){

    return const Scaffold(
      body: Center(
        child:CircularProgressIndicator(),
      ),
    );

  }

}