import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';
import '../services/kakao_auth_service.dart';



class OnboardingScreen extends StatelessWidget {


  const OnboardingScreen({super.key});



  @override
  Widget build(BuildContext context) {


    return Scaffold(


      body: SafeArea(


        child: Center(


          child: Column(


            mainAxisAlignment: MainAxisAlignment.center,


            children: [



              const SizedBox(
                height: 180,
              ),



              const Text(
                "SNOB",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),



              const SizedBox(
                height: 20,
              ),



              const Text(
                "모두의 여행에서,\n오직 나만의 여행으로",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                ),
              ),



              const SizedBox(
                height: 60,
              ),




              SizedBox(


                width: 280,


                height: 50,


                child: ElevatedButton(


                  onPressed: () async {


                    print("카카오 버튼 클릭");



                    final user =
                        await KakaoAuthService.login();



                    print(
                      "user 결과: $user"
                    );



                    if(user != null){



                      print(
                        "홈 이동 시작"
                      );



                      Navigator.pushReplacement(


                        context,


                        MaterialPageRoute(


                          builder: (context)=>


                              const BottomNavigation(),


                        ),


                      );


                    }



                  },



                  child: const Text(
                    "카카오로 시작하기",
                  ),


                ),


              ),




              const SizedBox(height: 15),




              SizedBox(


                width: 280,


                height: 50,


                child: ElevatedButton(


                  onPressed: (){


                    Navigator.pushReplacement(


                      context,


                      MaterialPageRoute(


                        builder: (context)=>

                            const BottomNavigation(),


                      ),


                    );


                  },


                  child: const Text(
                    "Apple로 시작하기",
                  ),


                ),


              ),



            ],


          ),


        ),


      ),


    );


  }


}