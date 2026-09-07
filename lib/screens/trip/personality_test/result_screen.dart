import 'package:flutter/material.dart';
import '../course/result_screen.dart';
import 'personality_test_screen.dart';

class ResultScreen extends StatelessWidget {
  // ============================================================
  // 심리테스트 결과 유형
  // ============================================================

  final String personalityType;

  // ============================================================
  // 추천 지역
  //
  // 중요:
  // 이 값은 RecommendationEngine에서 이미
  // canonical 210개 중 하나로 확정된 값이다.
  //
  // ResultScreen에서는 지역명을 다시 변환하지 않는다.
  // ============================================================

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
    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const PersonalityTestScreen(),
      ),
    );
  }

  // ============================================================
  // 코스 추천
  // ============================================================

  void _goToCourseRecommendation(
    BuildContext context,
  ) {
    final region =
        recommendedRegion.trim();

    if (region.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '추천 지역을 확인할 수 없습니다.',
          ),
        ),
      );

      return;
    }

    // ------------------------------------------------------------
    // 중요
    //
    // 여기서는 지역명을 변환하지 않는다.
    //
    // RecommendationEngine
    //       ↓
    // canonical 210개 지역
    //       ↓
    // recommendedRegion
    //       ↓
    // Center50
    //
    // 같은 문자열을 그대로 전달한다.
    // ------------------------------------------------------------

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseResultScreen(
          regionName: region,
        ),
      ),
    );
  }

  // ============================================================
  // build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (
        didPop,
        result,
      ) {
        if (didPop) return;

        _goHome(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            '여행 성향 결과',
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
            ),
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

                // ==================================================
                // 제목
                // ==================================================

                const Text(
                  '✨ 당신의 여행 성향',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                // ==================================================
                // 여행 유형
                // ==================================================

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(24),
                  decoration:
                      BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(20),
                    color:
                        Colors.grey.shade100,
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

                      const SizedBox(
                        height: 12,
                      ),

                      Text(
                        personalityType,
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          fontSize: 26,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ==================================================
                // 추천 지역
                // ==================================================

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(24),
                  decoration:
                      BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          Colors.grey.shade300,
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

                      const SizedBox(
                        height: 12,
                      ),

                      Text(
                        recommendedRegion,
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          fontSize: 24,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      const Text(
                        '당신의 여행 성향과 가장 잘 맞는 지역이에요.',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ==================================================
                // 다시 하기
                // ==================================================

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
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ==================================================
                // 코스 추천
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        recommendedRegion
                                .trim()
                                .isEmpty
                            ? null
                            : () {
                                _goToCourseRecommendation(
                                  context,
                                );
                              },
                    child: const Text(
                      '코스 추천 넘어가기 →',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
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

