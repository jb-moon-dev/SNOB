import 'package:flutter/material.dart';
import 'result_data.dart';


class ResultScreen extends StatelessWidget {

  final String resultType;


  const ResultScreen({
    super.key,
    required this.resultType,
  });


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("여행 성향 결과"),
      ),


      body: Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [


            const Text(
              "당신의 여행 유형은",
              style: TextStyle(
                fontSize: 22,
              ),
            ),


            const SizedBox(height:20),


            Text(
              ResultData.results[resultType]!["title"]!,
              style: const TextStyle(
                fontSize:32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height:20),
            Text(
              ResultData.results[resultType]!["description"]!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18,),),
            
            const SizedBox(height:20),
            Text(
              "추천 여행 키워드",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),
            Text(
              ResultData.results[resultType]!["keyword"]!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16,),),

          ],

        ),

      ),

    );

  }

}