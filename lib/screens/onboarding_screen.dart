import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';
import '../services/kakao_auth_service.dart';


class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: SafeArea(

        child: Center(

          child: Column(

            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              // 이미지 들어갈 자리 (나중에 교체)
              const SizedBox(
                height: 180,
              ),


              const Text(
                "SNOB",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),


              const SizedBox(height: 20),


              const Text(
                "모두의 여행에서,\n오직 나만의 여행으로",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  height: 1.5,
                ),
              ),


              const SizedBox(height: 60),


              SizedBox(

                width: 280,

                height: 50,

                child: ElevatedButton(

                  onPressed: () async {
                      final user = await KakaoAuthService.login();
                        if (user != null) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const BottomNavigation(),
                              ),
                              );
                              }
                              },

                  child: const Text(
                    "카카오로 시작하기",
                    style: TextStyle(                
                      fontSize: 16,
                    ),
                  ),

                ),

              ),


              const SizedBox(height: 15),


              SizedBox(

                width: 280,

                height: 50,

                child: ElevatedButton(

                  onPressed: () {

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const BottomNavigation(),
                      ),
                    );

                  },

                  child: const Text(
                    "Apple로 시작하기",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),

                ),

              ),

            ],
          ),

        ),

      ),

    );
  }
}