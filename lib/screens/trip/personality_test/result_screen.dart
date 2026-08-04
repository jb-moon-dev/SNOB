import 'package:flutter/material.dart';

import 'result_data.dart';

import '../../../snob/recommendation_engine.dart';
import '../../../snob/region_vector.dart';
import '../../../snob/user_vector.dart';

import '../../../services/region_repository.dart';



class ResultScreen extends StatefulWidget {


  final ResultData result;



  const ResultScreen({

    super.key,

    required this.result,

  });




  @override
  State<ResultScreen> createState() => _ResultScreenState();

}





class _ResultScreenState extends State<ResultScreen> {



  RegionVector? recommend;



  bool loading = true;





  @override
  void initState(){


    super.initState();


    loadRecommendation();


  }






  // ================================
  // 전국 데이터 기반 추천
  // ================================


  Future<void> loadRecommendation() async {



    final user = UserVector.fromScore(


      cityScore: 2,

      natureScore: 8,


      famousScore: 3,

      hiddenScore: 7,


      activeScore: 2,

      healingScore: 8,


    );






    final regions =

    await RegionRepository.getRegions();






    final result =

    RecommendationEngine.recommendRandomRegion(

      user,

      regions,

    );







    setState(() {


      recommend = result;


      loading = false;


    });



  }







  @override
  Widget build(BuildContext context){



    return Scaffold(


      appBar: AppBar(

        title: const Text(

          "나의 여행 유형",

        ),

      ),





      body: Center(


        child: SingleChildScrollView(



          padding: const EdgeInsets.all(24),




          child: Column(



            mainAxisAlignment:

            MainAxisAlignment.center,





            children: [






              const Text(

                "오늘 당신은 어떤 여행자일까요?",

                style: TextStyle(

                  fontSize: 18,

                ),

              ),






              const SizedBox(height:30),






              Text(

                widget.result.title,

                style: const TextStyle(

                  fontSize:28,

                  fontWeight:FontWeight.bold,

                ),

                textAlign:

                TextAlign.center,

              ),






              const SizedBox(height:20),






              Text(

                widget.result.description,

                style: const TextStyle(

                  fontSize:16,

                ),

                textAlign:

                TextAlign.center,

              ),






              const SizedBox(height:20),







              const Divider(),






              const SizedBox(height:20),







              const Text(

                "당신에게 추천하는 여행지",

                style: TextStyle(

                  fontSize:22,

                  fontWeight:FontWeight.bold,

                ),

              ),







              const SizedBox(height:20),







              if(loading)


                const CircularProgressIndicator()




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


                onPressed: (){


                  Navigator.pop(context);


                },


                child:

                const Text(

                  "다시 테스트하기",

                ),

              )




            ],


          ),


        ),


      ),


    );


  }



}