import 'package:flutter/material.dart';
import '../services/kakao_auth_service.dart';
import '../widgets/bottom_navigation.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool isLoading = false;

  Future<void> kakaoLogin() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    print("카카오 버튼 클릭");

    final user = await KakaoAuthService.login();

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (user != null) {
      print("카카오 로그인 성공 (사용자 ID: ${user.id})");

      // 로그인 성공 시 메인 화면(BottomNavigation)으로 바로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const BottomNavigation(),
        ),
      );
    } else {
      print("카카오 로그인 실패");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("카카오 로그인에 실패했습니다."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 180),
              const Text(
                "SNOB",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "모두의 여행에서,\n오직 나만의 여행으로",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: 280,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : kakaoLogin,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("카카오로 시작하기"),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: 280,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    print("Apple 로그인 준비");
                  },
                  child: const Text("Apple로 시작하기"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}