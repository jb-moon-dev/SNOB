import 'region_vector.dart';
import 'user_vector.dart';



class RecommendationEngine {



  // =================================
  // 사용자 - 지역 유사도 계산
  // =================================


  static double calculateDistance(

      UserVector user,

      RegionVector region,

      ){


    double distance = 0;



    distance +=
        (user.nature - region.nature)
            *
            (user.nature - region.nature);



    distance +=
        (user.hidden - region.hidden)
            *
            (user.hidden - region.hidden);



    distance +=
        (user.healing - region.healing)
            *
            (user.healing - region.healing);



    return distance;


  }







  // =================================
  // 가장 비슷한 지역 찾기
  // =================================


  static RegionVector recommendRegion(

      UserVector user,

      List<RegionVector> regions,

      ){



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


}