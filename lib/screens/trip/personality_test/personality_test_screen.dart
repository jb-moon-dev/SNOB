import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'questions.dart';
import 'question_model.dart';
import 'score_manager.dart';

import 'type_matcher.dart';
import 'result_data.dart';
import 'result_screen.dart';

import 'package:snob/snob/user_vector.dart';
import 'package:snob/snob/recommendation_engine.dart';
import 'package:snob/snob/region_vector.dart';

// 현재 여행 성향 저장
import '../../../services/personality_storage.dart';

class PersonalityTestScreen extends StatefulWidget {
  const PersonalityTestScreen({super.key});

  @override
  State<PersonalityTestScreen> createState() =>
      _PersonalityTestScreenState();
}

class _PersonalityTestScreenState
    extends State<PersonalityTestScreen> {
  int currentQuestion = 0;

  final ScoreManager scoreManager = ScoreManager();

  late List<Question> shuffledQuestions;

  late List<Answer> shuffledAnswers;

  @override
  void initState() {
    super.initState();

    // ============================================================
    // 질문 준비
    // ============================================================

    shuffledQuestions = List<Question>.from(questions);

    // ============================================================
    // 첫 번째 질문의 답변 랜덤 섞기
    // ============================================================

    shuffledAnswers = List<Answer>.from(
      shuffledQuestions[currentQuestion].answers,
    )..shuffle(Random());
  }

  // ============================================================
  // 다음 질문
  // ============================================================

  void nextQuestion() {
    setState(() {
      currentQuestion++;

      shuffledAnswers = List<Answer>.from(
        shuffledQuestions[currentQuestion].answers,
      )..shuffle(Random());
    });
  }

  // ============================================================
  // 지역 데이터 불러오기
  // ============================================================

  Future<List<RegionVector>> loadRegions() async {
    final jsonString = await rootBundle.loadString(
      'assets/data/region_vectors.json',
    );

    final List<dynamic> jsonData = json.decode(jsonString);

    return jsonData
        .map(
          (json) => RegionVector.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // ============================================================
  // 테스트 완료
  // ============================================================

  Future<void> finishTest() async {
    // ============================================================
    // 1. 27개 유형 key 생성
    // ============================================================

    final type = TypeMatcher.match(
      city: scoreManager.city,
      nature: scoreManager.nature,
      famous: scoreManager.famous,
      hidden: scoreManager.hidden,
      active: scoreManager.active,
      healing: scoreManager.healing,
    );

    // ============================================================
    // 2. 유형 데이터
    // ============================================================

    final result = ResultRepository.getResult(type);

    // ============================================================
    // 3. 사용자 성향 벡터 생성
    // ============================================================

    final userVector = UserVector.fromScore(
      cityScore: scoreManager.city,
      natureScore: scoreManager.nature,
      famousScore: scoreManager.famous,
      hiddenScore: scoreManager.hidden,
      activeScore: scoreManager.active,
      healingScore: scoreManager.healing,
    );

    // ============================================================
    // 4. 지역 데이터 불러오기
    // ============================================================

    final regions = await loadRegions();

    if (regions.isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '추천 가능한 지역 데이터가 없습니다.',
          ),
        ),
      );

      return;
    }

    // ============================================================
    // 5. 추천 지역 계산
    //    Top 3 중 랜덤 추천
    // ============================================================

    final recommendedRegion =
        RecommendationEngine.recommendRandomRegion(
      userVector,
      regions,
    );

    // ============================================================
    // 6. 현재 여행 성향 저장
    //
    // 테스트 결과를 SharedPreferences에 저장한다.
    //
    // 예:
    // personalityType    → 보물 수집가
    // recommendedRegion  → 경주
    //
    // 마이페이지에서는 이 데이터를 불러와서
    // 현재 여행 성향으로 보여준다.
    // ============================================================

    await PersonalityStorage.savePersonality(
      personalityType: result.title,
      recommendedRegion: recommendedRegion.regionName,
    );

    // ============================================================
    // 7. 결과 화면으로 이동
    // ============================================================

    if (!mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          personalityType: result.title,
          recommendedRegion: recommendedRegion.regionName,
        ),
      ),
    );
  }

  // ============================================================
  // 화면
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final Question question =
        shuffledQuestions[currentQuestion];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '여행 성향 테스트',
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======================================================
            // 진행도
            // ======================================================

            Text(
              '${currentQuestion + 1} / ${shuffledQuestions.length}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            // ======================================================
            // 질문
            // ======================================================

            Text(
              question.question,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            // ======================================================
            // 답변
            // ======================================================

            Column(
              children: shuffledAnswers.map((answer) {
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 15,
                  ),

                  child: SizedBox(
                    width: double.infinity,

                    child: ElevatedButton(
                      onPressed: () {
                        // ------------------------------------------
                        // 선택한 답변 점수 추가
                        // ------------------------------------------

                        scoreManager.addScore(
                          answer,
                        );

                        // ------------------------------------------
                        // 마지막 질문인지 확인
                        // ------------------------------------------

                        if (currentQuestion ==
                            shuffledQuestions.length - 1) {
                          // 마지막 질문이면 결과 계산
                          finishTest();
                        } else {
                          // 다음 질문
                          nextQuestion();
                        }
                      },

                      child: Text(
                        answer.text,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}