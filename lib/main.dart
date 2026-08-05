import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';

import 'screens/onboarding_screen.dart';


void main() {

  WidgetsFlutterBinding.ensureInitialized();


  KakaoSdk.init(

    nativeAppKey: 'f5c2a76b9629d32baa7816b9320e1453',

  );


  runApp(
    const TravelApp(),
  );

}



class TravelApp extends StatelessWidget {

  const TravelApp({super.key});


  @override
  Widget build(BuildContext context) {


    return MaterialApp(

      debugShowCheckedModeBanner: false,


      title: 'SNOB',



      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(

          seedColor: Colors.blue,

        ),


        useMaterial3: true,

      ),



      home: const OnboardingScreen(),



      onUnknownRoute: (settings) {


        print(
          "Unknown route : ${settings.name}"
        );


        // 카카오 redirect 발생 시
        if(settings.name != null &&
            settings.name!.contains("code=")) {


          print(
            "🔥 카카오 redirect 감지"
          );


        }



        return MaterialPageRoute(


          builder: (_) {


            return const OnboardingScreen();


          },


        );


      },


    );

  }

}