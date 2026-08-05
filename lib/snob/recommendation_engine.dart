import 'dart:math';

import 'user_vector.dart';
import 'region_vector.dart';



class RecommendationEngine {


  // =====================================
  // Top3 중 랜덤 추천
  // =====================================

  static RegionVector recommendRandomRegion(
    UserVector user,
    List<RegionVector> regions,
  ) {


    if(regions.isEmpty){

      throw Exception(
        "추천 가능한 지역이 없습니다."
      );

    }



    final ranked =
        rankRegions(
          user,
          regions,
        );



    final top3 =
        ranked.take(3).toList();



    final random =
        Random();



    return top3[
      random.nextInt(top3.length)
    ];

  }






  // =====================================
  // 점수 계산 후 정렬
  // =====================================

  static List<RegionVector> rankRegions(
    UserVector user,
    List<RegionVector> regions,
  ) {


    final result =
        List<RegionVector>.from(regions);



    result.sort((a,b){


      final scoreA =
          similarity(
            user,
            a,
          );


      final scoreB =
          similarity(
            user,
            b,
          );



      return scoreB.compareTo(scoreA);


    });



    return result;


  }






  // =====================================
  // 사용자 - 지역 유사도
  // =====================================

  static double similarity(
    UserVector user,
    RegionVector region,
  ){


    double distance = 0;



    distance +=
        pow(
          user.nature - region.nature,
          2,
        );



    distance +=
        pow(
          user.hidden - region.hidden,
          2,
        );



    distance +=
        pow(
          user.healing - region.healing,
          2,
        );




    return 100 -
        sqrt(distance);



  }


}