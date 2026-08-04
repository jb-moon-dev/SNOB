import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'services/tourism_api_service.dart';

void testApi() async {

  final areas =
      await TourismApiService.getAreaCodes();


  for (var area in areas) {

    print(
      "${area["code"]} : ${area["name"]}"
    );

  }

}

void main() {

  testApi();
  
  runApp(const TravelApp());
}

class TravelApp extends StatelessWidget {
  const TravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 앱 이름
      title: 'SNOB',

      // 전체 테마
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),

      // 앱 시작 화면
      home: const LoginScreen(),
    );
  }
}