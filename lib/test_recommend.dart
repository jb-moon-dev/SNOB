import 'snob/user_vector.dart';
import 'snob/region_vector.dart';
import 'snob/recommendation_engine.dart';


void main(){


  print("===== 추천 테스트 시작 =====");



  // =================================
  // 1. 심리테스트 결과 → UserVector
  // =================================


  final user = UserVector.fromScore(

    cityScore: 2,
    natureScore: 8,

    famousScore: 3,
    hiddenScore: 7,

    activeScore: 2,
    healingScore: 8,

  );



  print(user);





  // =================================
  // 2. 지역 벡터 임시 데이터
  // (나중에 API 데이터로 교체)
  // =================================


  final regions = [


    const RegionVector(

      regionName: "강원특별자치도 강릉시",

      nature: 40,

      hidden: 62.7,

      healing: 50,

      congestion: 0,

    ),



    const RegionVector(

      regionName: "제주특별자치도",

      nature: 85,

      hidden: 75,

      healing: 80,

      congestion: 0,

    ),



    const RegionVector(

      regionName: "서울특별시",

      nature: 20,

      hidden: 30,

      healing: 30,

      congestion: 80,

    ),


  ];





  // =================================
  // 3. 추천 실행
  // =================================


  final result =

  RecommendationEngine.recommendRegion(

    user,

    regions,

  );





  print("===== 추천 결과 =====");


  print(result);



  print("===== 테스트 종료 =====");


}