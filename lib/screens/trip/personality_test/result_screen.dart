import 'package:flutter/material.dart';

import 'result_data.dart';
import 'score_manager.dart';
import 'personality_test_screen.dart';

import '../../../snob/recommendation_engine.dart';
import '../../../snob/region_vector.dart';
import '../../../services/region_repository.dart';

import 'package:snob/screens/trip/course/course_screen.dart';
import 'package:snob/screens/trip/course/models/course_item.dart';

class ResultScreen extends StatefulWidget {
  final ResultData result;
  final ScoreManager scoreManager;

  const ResultScreen({
    super.key,
    required this.result,
    required this.scoreManager,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  RegionVector? recommend;

  bool loading = true;

  String? errorMessage;

  @override
  void initState() {
    super.initState();

    loadRecommendation();
  }

  // ============================================================
  // 추천 지역 가져오기
  // ============================================================

  Future<void> loadRecommendation() async {
    try {
      final user =
          widget.scoreManager.getUserVector();

      final regions =
          await RegionRepository.getRegions();

      final result =
          RecommendationEngine.recommendRandomRegion(
        user,
        regions,
      );

      if (!mounted) return;

      setState(() {
        recommend = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '나의 여행 유형',
        ),
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              // --------------------------------------------------
              // 여행 유형
              // --------------------------------------------------

              const Text(
                '오늘 당신은 어떤 여행자일까요?',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 30),

              Text(
                widget.result.title,

                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),

                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              Text(
                widget.result.description,

                style: const TextStyle(
                  fontSize: 16,
                ),

                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              const Divider(),

              const SizedBox(height: 30),

              // --------------------------------------------------
              // 추천 지역
              // --------------------------------------------------

              const Text(
                '당신에게 추천하는 여행 지역',

                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // --------------------------------------------------
              // 로딩
              // --------------------------------------------------

              if (loading)
                const Column(
                  children: [
                    CircularProgressIndicator(),

                    SizedBox(height: 15),

                    Text(
                      '당신에게 맞는 여행지를 찾는 중입니다...',
                    ),
                  ],
                )

              // --------------------------------------------------
              // 오류
              // --------------------------------------------------

              else if (errorMessage != null)
                Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 50,
                      color: Colors.redAccent,
                    ),

                    const SizedBox(height: 15),

                    Text(
                      '추천 정보를 가져오는데 실패했습니다.\n'
                      '$errorMessage',

                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: loadRecommendation,

                      child: const Text(
                        '다시 추천받기',
                      ),
                    ),
                  ],
                )

              // --------------------------------------------------
              // 추천 지역
              // --------------------------------------------------

              else if (recommend != null)
                Card(
                  elevation: 4,

                  child: Padding(
                    padding:
                        const EdgeInsets.all(20),

                    child: Column(
                      children: [
                        const Text(
                          '🌿 추천 여행 지역',

                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          recommend!.regionName,

                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight:
                                FontWeight.bold,
                          ),

                          textAlign:
                              TextAlign.center,
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          '이 지역에서 당신에게 맞는\n'
                          '덜 붐비는 관광지를 찾아볼게요.',

                          textAlign:
                              TextAlign.center,

                          style: TextStyle(
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 30),

              // --------------------------------------------------
              // 추천 코스 보기
              // --------------------------------------------------

              if (recommend != null)
                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(
                    onPressed: () {
                      _openCourseScreen();
                    },

                    style:
                        ElevatedButton.styleFrom(
                      minimumSize:
                          const Size(
                        double.infinity,
                        52,
                      ),
                    ),

                    child: const Text(
                      '추천 관광지 보기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 15),

              // --------------------------------------------------
              // 다시 테스트
              // --------------------------------------------------

              OutlinedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,

                    MaterialPageRoute(
                      builder: (_) =>
                          const PersonalityTestScreen(),
                    ),
                  );
                },

                child: const Text(
                  '다시 테스트하기',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 코스 화면 이동
  // ============================================================

  void _openCourseScreen() {
    if (recommend == null) {
      return;
    }

    // 아직 중심 관광지 API 연결 전이므로
    // 임시로 빈 리스트를 전달한다.
    //
    // CourseRecommender가 완성되면
    // 이 부분을 실제 중심 관광지 데이터로 연결한다.

    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (_) => CourseScreen(
          userVector:
              widget.scoreManager.getUserVector(),

          regionName:
              recommend!.regionName,

          centerSpots:
              const <CourseItem>[],
        ),
      ),
    );
  }
}