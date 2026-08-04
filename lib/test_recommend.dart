import 'package:snob/snob/user_vector.dart';
import 'package:snob/snob/recommendation_engine.dart';

import 'package:snob/services/region_repository.dart';


void main() async {


  print("===== 추천 테스트 시작 =====");



  final user = UserVector.fromScore(


    cityScore: 5,

    natureScore: 8,


    famousScore: 2,

    hiddenScore: 8,


    activeScore: 3,

    healingScore: 7,


  );




  final regions =

  await RegionRepository.getRegions();




  final result =

  RecommendationEngine.recommendRandomRegion(

    user,

    regions,

  );




  print("===== 추천 결과 =====");


  print(result);



}