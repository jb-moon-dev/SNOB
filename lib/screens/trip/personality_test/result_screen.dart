import 'package:flutter/material.dart';

import 'result_data.dart';

import '../../../snob/recommendation_engine.dart';
import '../../../snob/region_vector.dart';
import '../../../snob/user_vector.dart';

import '../../../services/region_repository.dart';

import 'score_manager.dart';



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







  Future<void> loadRecommendation() async {



    try {



      // 현재는 테스트 UserVector
      // 추후 ScoreManager 연결 예정


      final user = widget.scoreManager.getUserVector();



      // 전국 RegionVector 생성

      final regions =

      await RegionRepository.getRegions();








      final result =

      RecommendationEngine.recommendRandomRegion(

        user,

        regions,

      );









      // ⭐ 중요
      // 화면이 사라졌으면 setState 실행 X

      if (!mounted) return;






      setState(() {



        recommend = result;


        loading = false;



      });






    } catch(e) {



      if (!mounted) return;





      setState(() {



        loading = false;


        errorMessage = e.toString();



      });




    }



  }









  @override
  Widget build(BuildContext context) {



    return Scaffold(



      appBar: AppBar(


        title: const Text(

          "나의 여행 유형",

        ),

      ),





      body: Center(



        child: SingleChildScrollView(



          padding:

          const EdgeInsets.all(24),





          child: Column(



            mainAxisAlignment:

            MainAxisAlignment.center,





            children: [





              const Text(


                "오늘 당신은 어떤 여행자일까요?",


                style: TextStyle(

                  fontSize:18,

                ),

              ),






              const SizedBox(height:30),






              Text(


                widget.result.title,


                style:

                const TextStyle(

                  fontSize:28,

                  fontWeight:

                  FontWeight.bold,

                ),


                textAlign:

                TextAlign.center,


              ),






              const SizedBox(height:20),






              Text(


                widget.result.description,


                style:

                const TextStyle(

                  fontSize:16,

                ),


                textAlign:

                TextAlign.center,


              ),






              const SizedBox(height:40),






              const Divider(),






              const SizedBox(height:30),






              const Text(


                "당신에게 추천하는 여행지",


                style:

                TextStyle(

                  fontSize:22,

                  fontWeight:

                  FontWeight.bold,

                ),


              ),






              const SizedBox(height:20),







              if(loading)



                const Column(

                  children: [


                    CircularProgressIndicator(),


                    SizedBox(height:15),


                    Text(

                      "당신에게 맞는 여행지를 찾는 중입니다...",


                    ),


                  ],

                )







              else if(errorMessage != null)



                Text(

                  "추천 정보를 가져오는데 실패했습니다.\n$errorMessage",

                  textAlign:

                  TextAlign.center,

                )







              else



                Card(


                  elevation:4,



                  child: Padding(


                    padding:

                    const EdgeInsets.all(20),




                    child: Column(


                      children: [





                        const Text(


                          "🌿 추천 여행지",


                          style:

                          TextStyle(

                            fontSize:16,

                          ),

                        ),






                        const SizedBox(height:10),






                        Text(


                          recommend!.regionName,


                          style:

                          const TextStyle(

                            fontSize:24,

                            fontWeight:

                            FontWeight.bold,

                          ),


                          textAlign:

                          TextAlign.center,


                        ),



                      ],


                    ),


                  ),


                ),







              const SizedBox(height:40),







              ElevatedButton(



                onPressed: () {


                  Navigator.pop(context);


                },



                child:

                const Text(

                  "다시 테스트하기",

                ),



              ),




            ],


          ),


        ),


      ),


    );


  }



}