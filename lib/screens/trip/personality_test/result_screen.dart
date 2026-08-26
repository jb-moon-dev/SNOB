import 'package:flutter/material.dart';

import '../course/center50.dart';
import 'personality_test_screen.dart';

class ResultScreen extends StatelessWidget {
  // 심리테스트 결과 유형
  final String personalityType;

  // 추천 지역
  final String recommendedRegion;

  const ResultScreen({
    super.key,
    required this.personalityType,
    required this.recommendedRegion,
  });

  // ============================================================
  // 홈으로 이동
  // ============================================================

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );
  }

  // ============================================================
  // 성향 테스트 다시 하기
  // ============================================================

  void _restartTest(BuildContext context) {
    // 현재 결과 화면과 기존 테스트 화면을 모두 정리해서
    // 홈 화면으로 돌아간다.
    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );

    // 새로운 PersonalityTestScreen을 시작한다.
    // 새로운 화면이 생성되므로 ScoreManager도 새로 만들어진다.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PersonalityTestScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 시스템 뒤로가기 버튼을 눌렀을 때
      // 기본 pop 대신 홈으로 이동
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        _goHome(context);
      },

      child: Scaffold(
        appBar: AppBar(
          title: const Text('여행 성향 결과'),
          centerTitle: true,

          // 앱바의 뒤로가기 버튼도 홈으로 이동
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _goHome(context);
            },
          ),
        ),

        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 30),

                // -----------------------------
                // 제목
                // -----------------------------
                const Text(
                  '✨ 당신의 여행 성향',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                // -----------------------------
                // 여행 유형
                // -----------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey.shade100,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '당신의 여행 유형',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        personalityType,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // -----------------------------
                // 추천 지역
                // -----------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '📍 추천 여행 지역',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        recommendedRegion,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        '당신의 여행 성향과 가장 잘 맞는 지역이에요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // -----------------------------
                // 다시 하기
                // -----------------------------
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      _restartTest(context);
                    },
                    child: const Text(
                      '다시 하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // -----------------------------
                // 코스 추천으로 이동
                // -----------------------------
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Center50Screen(
                            regionName: recommendedRegion,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      '코스 추천 넘어가기 →',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}