import 'dart:math';

import 'package:flutter/material.dart';

import 'questions.dart';
import 'question_model.dart';
import 'score_manager.dart';

import 'type_matcher.dart';
import 'result_data.dart';
import 'result_screen.dart';



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


    shuffledQuestions = List<Question>.from(questions);


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







  void finishTest() {



    // 점수를 기반으로 27개 유형 key 생성

    final type =
        TypeMatcher.match(


          city: scoreManager.city,

          nature: scoreManager.nature,



          famous: scoreManager.famous,

          hidden: scoreManager.hidden,



          active: scoreManager.active,

          healing: scoreManager.healing,



        );







    // 유형 데이터 가져오기

    final result =
        ResultRepository.getResult(type);








    Navigator.push(


      context,


      MaterialPageRoute(



        builder: (context) =>

            ResultScreen(



              result: result,



              // ⭐ 추가
              // 심리테스트 결과 점수 전달

              scoreManager: scoreManager,



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


                fontSize:18,


                fontWeight:

                FontWeight.bold,


              ),



            ),







            const SizedBox(height:30),







            Text(


              question.question,


              style:

              const TextStyle(


                fontSize:24,


                fontWeight:

                FontWeight.bold,


              ),



            ),







            const SizedBox(height:40),







            Column(



              children:



              shuffledAnswers.map((answer){





                return Padding(





                  padding:

                  const EdgeInsets.only(

                    bottom:15,

                  ),







                  child:

                  SizedBox(



                    width:

                    double.infinity,







                    child:

                    ElevatedButton(





                      onPressed:(){






                        // 선택한 답변 점수 추가

                        scoreManager.addScore(answer);








                        if(currentQuestion ==

                            shuffledQuestions.length - 1){






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