import 'dart:math';

import 'package:flutter/material.dart';

import 'questions.dart';
import 'question_model.dart';


class PersonalityTestScreen extends StatefulWidget {

  const PersonalityTestScreen({super.key});


  @override
  State<PersonalityTestScreen> createState() =>
      _PersonalityTestScreenState();

}


class _PersonalityTestScreenState
    extends State<PersonalityTestScreen> {


  int currentQuestion = 0;


  late List<Question> shuffledQuestions;


  late List<Answer> shuffledAnswers;



  @override
  void initState() {

    super.initState();

    shuffledQuestions = List<Question>.from(questions)
      ..shuffle(Random());


    shuffledAnswers =
        List<Answer>.from(
          shuffledQuestions[currentQuestion].answers,
        )
        ..shuffle(Random());

  }




  void nextQuestion(){


    if(currentQuestion ==
        shuffledQuestions.length - 1){

      return;

    }


    setState(() {


      currentQuestion++;


      shuffledAnswers =
          List.from(
            shuffledQuestions[currentQuestion].answers,
          );


      shuffledAnswers.shuffle(Random());


    });


  }





  @override
  Widget build(BuildContext context) {


    Question question =
        shuffledQuestions[currentQuestion];



    return Scaffold(


      appBar: AppBar(

        title:
        const Text("여행 성향 테스트"),

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
                      bottom:15
                  ),



                  child:SizedBox(


                    width:
                    double.infinity,



                    child:
                    ElevatedButton(


                      onPressed:(){

                        nextQuestion();

                      },



                      child:
                      Text(answer.text),


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