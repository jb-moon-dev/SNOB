import 'snob/user_vector.dart';
import 'snob/recommendation_engine.dart';
import 'snob/vector_generator.dart';

import 'services/tourism_api_service.dart';



void main() async {



  print("===== 추천 테스트 시작 =====");



  // 관광 데이터 가져오기

  final spots =
      await TourismApiService
          .getTourismSpots();



  // 지역 벡터 생성

  final spotVectors =
      spots.map(

          (spot)=>
              VectorGenerator
                  .generateSpotVector(spot)

  ).toList();



  final regions =
      VectorGenerator
          .generateRegions(
              spotVectors
          );





  // 사용자 성향 (임시 테스트)

  final user = UserVector(

    nature: 80,

    hidden: 80,

    healing: 70,

  );





  final result =

      RecommendationEngine
          .recommend(

              user,

              regions,

          );





  print("");

  print("===== 추천 결과 =====");



  for(var region in result){


    print(
      """
지역 : ${region.regionName}

자연 : ${region.nature}

숨은 : ${region.hidden}

힐링 : ${region.healing}

--------------------
"""
    );


  }



  print("===== 테스트 종료 =====");

}