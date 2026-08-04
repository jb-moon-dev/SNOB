import 'dart:math';

import 'region_vector.dart';
import 'user_vector.dart';



class RecommendationEngine {



  // =================================
  // 사용자 - 지역 거리 계산
  // =================================


  static double calculateDistance(

      UserVector user,

      RegionVector region,

      ) {



    double distance = 0;



    distance +=

        pow(user.nature - region.nature, 2);



    distance +=

        pow(user.hidden - region.hidden, 2);



    distance +=

        pow(user.healing - region.healing, 2);




    return distance;



  }







  // =================================
  // 완전 일치 확인
  // =================================


  static bool isSameVector(

      UserVector user,

      RegionVector region,

      ) {



    return

      user.nature == region.nature &&

      user.hidden == region.hidden &&

      user.healing == region.healing;



  }









  // =================================
  // 단일 추천
  // =================================


  static RegionVector recommendRegion(

      UserVector user,

      List<RegionVector> regions,

      ) {



    RegionVector best = regions.first;



    double minDistance =

    calculateDistance(

        user,

        best

    );





    for(var region in regions){


      double distance =

      calculateDistance(

          user,

          region

      );




      if(distance < minDistance){


        minDistance = distance;


        best = region;


      }



    }




    return best;



  }









  // =================================
  // TOP3 추천
  // =================================


  static List<RegionVector> recommendTopRegions(

      UserVector user,

      List<RegionVector> regions,

      ) {



    List<Map<String,dynamic>> scores = [];





    for(var region in regions){


      scores.add({

        "region": region,

        "distance":

        calculateDistance(

            user,

            region

        ),

      });


    }







    scores.sort(

          (a,b) =>

          a["distance"]

              .compareTo(

              b["distance"]

          ),

    );







    return scores

        .take(3)

        .map(

          (e) =>

      e["region"] as RegionVector,

    )

        .toList();



  }









  // =================================
  // 최종 추천 ⭐
  // =================================


  static RegionVector recommendRandomRegion(

      UserVector user,

      List<RegionVector> regions,

      ) {



    final random = Random();




    // -----------------------------
    // 1. 완전 일치 지역 찾기
    // -----------------------------


    final sameRegions =

    regions.where(

          (region) =>

          isSameVector(

              user,

              region

          ),

    )

        .toList();







    // 완전 일치 존재

    if(sameRegions.isNotEmpty){


      return sameRegions[

      random.nextInt(

          sameRegions.length

      )

      ];


    }







    // -----------------------------
    // 2. 없으면 TOP3 생성
    // -----------------------------


    final top3 =

    recommendTopRegions(

        user,

        regions

    );







    // TOP3 중 랜덤 선택


    return top3[

    random.nextInt(

        top3.length

    )

    ];



  }




}