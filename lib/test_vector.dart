import 'package:snob/services/tourism_api_service.dart';
import 'package:snob/snob/vector_generator.dart';
import 'package:snob/snob/user_vector.dart';
import 'package:snob/snob/recommendation_engine.dart';


void main() async {


  print("===== Vector 생성 테스트 시작 =====");



  final spots =

      await TourismApiService
          .getAllTourismSpots();



  print(
      "관광지 개수 : ${spots.length}"
  );




  final spotVectors = spots.map((spot){


    print("");

    print("===== 원본 TourismSpot =====");

    print(
        "이름 : ${spot.title}"
    );

    print(
        "lcls1 : ${spot.lclsSystm1}"
    );

    print(
        "lcls2 : ${spot.lclsSystm2}"
    );

    print(
        "lcls3 : ${spot.lclsSystm3}"
    );

    print("==========================");



    final vector =

    VectorGenerator
        .generateSpotVector(spot);



    print(vector);



    return vector;


  }).toList();






  final regionVectors =

  VectorGenerator
      .generateRegions(
        spotVectors,
      );





  print("");

  print("===== Region Vector =====");



  for(var region in regionVectors){

    print(region);

  }




  print("");

  print("===== 추천 테스트 =====");



  final user = UserVector(

    nature: 80,

    hidden: 70,

    healing: 90,

  );



  print(user);




  final recommendations =

  RecommendationEngine.recommend(

    user,

    regionVectors,

  );




  for(var region in recommendations){

    print(region);

  }



  print("===== 추천 테스트 종료 =====");


}