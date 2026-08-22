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


class PersonalityTestScreen extends StatefulWidget {

  const PersonalityTestScreen({super.key});


  @override
  State<PersonalityTestScreen> createState() =>
      _PersonalityTestScreenState();

}


class _PersonalityTestScreenState
    extends State<PersonalityTestScreen> {


  int currentQuestion = 0;


  final ScoreManager scoreManager =
      ScoreManager();


  late List<Question> shuffledQuestions;


  late List<Answer> shuffledAnswers;


  @override
  void initState() {

    super.initState();


    shuffledQuestions =
        List<Question>.from(questions);


    shuffledAnswers =
        List<Answer>.from(
          shuffledQuestions[currentQuestion].answers,
        )
          ..shuffle(Random());

  }


  void nextQuestion() {

    setState(() {

      currentQuestion++;


      shuffledAnswers =
          List<Answer>.from(
            shuffledQuestions[currentQuestion].answers,
          )
            ..shuffle(Random());

    });

  }


  Future<List<RegionVector>> loadRegions() async {

    final jsonString =
        await rootBundle.loadString(
      'assets/data/region_vectors.json',
    );


    final List<dynamic> jsonData =
        json.decode(jsonString);


    return jsonData
        .map(
          (json) => RegionVector.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();

  }


  Future<void> finishTest() async {

    // =====================================
    // 1. 27개 유형 key 생성
    // =====================================

    final type = TypeMatcher.match(
      city: scoreManager.city,
      nature: scoreManager.nature,
      famous: scoreManager.famous,
      hidden: scoreManager.hidden,
      active: scoreManager.active,
      healing: scoreManager.healing,
    );


    // =====================================
    // 2. 유형 데이터
    // =====================================

    final result =
        ResultRepository.getResult(type);


    // =====================================
    // 3. 사용자 성향 벡터
    // =====================================

    final userVector =
        UserVector.fromScore(
      cityScore: scoreManager.city,
      natureScore: scoreManager.nature,
      famousScore: scoreManager.famous,
      hiddenScore: scoreManager.hidden,
      activeScore: scoreManager.active,
      healingScore: scoreManager.healing,
    );


    // =====================================
    // 4. 저장된 RegionVector 불러오기
    // =====================================

    final regions =
        await loadRegions();


    if (regions.isEmpty) {

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            '추천 가능한 지역 데이터가 없습니다.',
          ),
        ),
      );

      return;

    }


    // =====================================
    // 5. RecommendationEngine
    //    Top 3 중 랜덤 추천
    // =====================================

    final recommendedRegion =
        RecommendationEngine
            .recommendRandomRegion(
      userVector,
      regions,
    );


    // =====================================
    // 6. 결과 화면
    // =====================================

    if (!mounted) {
      return;
    }


    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          personalityType: result.title,
          recommendedRegion:
              recommendedRegion.regionName,
        ),
      ),
    );

  }


  @override
  Widget build(BuildContext context) {

    Question question =
        shuffledQuestions[currentQuestion];


    return Scaffold(

      appBar: AppBar(

        title:
        const Text(
          "여행 성향 테스트",
        ),

      ),


      body: Padding(

        padding:
        const EdgeInsets.all(20),


        child: Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,


          children: [

            Text(

              "${currentQuestion + 1} / ${shuffledQuestions.length}",

              style:
              const TextStyle(

                fontSize: 18,

                fontWeight:
                FontWeight.bold,

              ),

            ),


            const SizedBox(height: 30),


            Text(

              question.question,

              style:
              const TextStyle(

                fontSize: 24,

                fontWeight:
                FontWeight.bold,

              ),

            ),


            const SizedBox(height: 40),


            Column(

              children:

              shuffledAnswers.map((answer) {

                return Padding(

                  padding:
                  const EdgeInsets.only(
                    bottom: 15,
                  ),


                  child: SizedBox(

                    width:
                    double.infinity,


                    child: ElevatedButton(

                      onPressed: () {

                        // 선택한 답변 점수 추가
                        scoreManager.addScore(
                          answer,
                        );


                        if (currentQuestion ==
                            shuffledQuestions.length - 1) {

                          finishTest();

                        } else {

                          nextQuestion();

                        }

                      },


                      child:

                      Text(
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