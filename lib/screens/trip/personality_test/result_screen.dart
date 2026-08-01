import 'package:flutter/material.dart';
import 'result_data.dart';


class ResultScreen extends StatelessWidget {

  final ResultData result;

  const ResultScreen({
    super.key,
    required this.result,
  });


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("나의 여행 유형"),
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              const Text(
                "오늘 당신은 어떤 여행자일까요?",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),


              const SizedBox(height: 30),


              Text(
                result.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),


              const SizedBox(height: 20),


              Text(
                result.description,
                style: const TextStyle(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),


              const SizedBox(height: 30),


              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),

                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Text(
                  result.keyword,
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),


              const SizedBox(height: 40),


              ElevatedButton(
                onPressed: () {

                  Navigator.pop(context);

                },

                child: const Text(
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