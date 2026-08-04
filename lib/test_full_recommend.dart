import 'snob/vector_generator.dart';
import 'snob/recommendation_engine.dart';
import 'snob/user_vector.dart';
import 'services/tourism_api_service.dart';



void main() async {


  print("===== 전체 추천 테스트 시작 =====");



  // =================================
  // 1. 관광 API 데이터 가져오기
  // =================================


  final spots =

  await TourismApiService.getTourismSpotsByArea(

      "32"

  );



  print("가져온 관광지 개수 : ${spots.length}");





  // =================================
  // 2. TourismSpot → SpotVector
  // =================================


  final spotVectors = spots.map((spot){


    return VectorGenerator.generateSpotVector(spot);


  }).toList();





  print("SpotVector 생성 완료");





  // =================================
  // 3. SpotVector → RegionVector
  // =================================


  final regions =

  VectorGenerator.generateRegions(

      spotVectors

  );





  print("지역 벡터 개수 : ${regions.length}");





  for(var region in regions){


    print(region);


  }







  // =================================
  // 4. 사용자 성향
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
  // 5. 추천 실행
  // =================================


  final recommend =


  RecommendationEngine.recommendRegion(

      user,

      regions

  );





  print("===== 최종 추천 결과 =====");


  print(recommend);





  print("===== 테스트 종료 =====");


}