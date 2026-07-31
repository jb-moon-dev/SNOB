import 'package:flutter/material.dart';
import 'trip/personality_test/personality_test_screen.dart';


class HomeScreen extends StatelessWidget {

  const HomeScreen({super.key});


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text('홈'),
      ),


      body: Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,


          children: [


            const Text(

              '홈 화면',

              style: TextStyle(
                fontSize: 24,
              ),

            ),


            const SizedBox(height:30),



            ElevatedButton(

              onPressed: () {


                Navigator.push(

                  context,

                  MaterialPageRoute(

                    builder: (context) =>
                        const PersonalityTestScreen(),

                  ),

                );


              },


              child: const Text(
                "여행 성향 테스트 시작",
              ),

            ),


          ],

        ),

      ),

    );

  }

}