import 'snob/user_vector.dart';
import 'snob/region_vector.dart';
import 'snob/recommendation_engine.dart';



void main(){



  print("===== 추천 테스트 시작 =====");





  // =================================
  // 1. 사용자 성향 생성
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
  // 2. 지역 벡터 데이터
  // (현재는 테스트용)
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


      regionName: "강원특별자치도 양양군",


      nature: 80,

      hidden: 70,

      healing: 60,

      congestion: 0,


    ),





    const RegionVector(


      regionName: "강원특별자치도 삼척시",


      nature: 53.3,

      hidden: 60,

      healing: 63.3,

      congestion: 0,


    ),





    const RegionVector(


      regionName: "강원특별자치도 동해시",


      nature: 60,

      hidden: 65,

      healing: 55,

      congestion: 0,


    ),





    const RegionVector(


      regionName: "제주특별자치도",


      nature: 85,

      hidden: 75,

      healing: 80,

      congestion: 0,


    ),



  ];







  // =================================
  // 3. TOP3 추천 실행
  // =================================


  final results =


  RecommendationEngine.recommendTopRegions(


      user,


      regions


  );








  // =================================
  // 4. 결과 출력
  // =================================


  print("===== TOP3 추천 결과 =====");




  for(int i = 0; i < results.length; i++){



    print("${i + 1}위 추천");



    print(results[i]);



  }





  print("===== 테스트 종료 =====");



}