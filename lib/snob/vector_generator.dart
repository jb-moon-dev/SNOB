import 'spot_vector.dart';
import 'region_vector.dart';
import 'tourism_spot.dart';



class VectorGenerator {



  // =================================
  // TourismSpot → SpotVector
  // =================================

  static SpotVector generateSpotVector(

      TourismSpot spot,

      ){



    double nature = 50;

    double hidden = 50;

    double healing = 50;





    // =================================
    // 🌿 1차 분류 (lclsSystm1)
    // =================================


    switch(spot.lclsSystm1){



      // 자연관광
      case "NA":

        nature += 30;

        healing += 20;

        break;



      // 역사관광
      case "HS":

        hidden += 20;

        healing += 20;

        break;



      // 체험관광
      case "EX":

        hidden += 10;

        healing += 10;

        break;



      // 레저스포츠
      case "VE":

        nature += 20;

        healing -= 10;

        break;



    }






    // =================================
    // 🔍 2차 분류 (lclsSystm2)
    // =================================


    switch(spot.lclsSystm2){



      // 산/산림
      case "NA01":

        nature += 20;

        healing += 20;

        hidden += 10;

        break;



      // 바다/해변
      case "NA02":

        nature += 30;

        healing += 20;

        break;



      // 자연휴양
      case "NA04":

        nature += 20;

        healing += 30;

        hidden += 10;

        break;



      // 역사
      case "HS01":

        hidden += 20;

        healing += 10;

        break;



      // 자연 경관
      case "HS03":

        nature += 20;

        healing += 20;

        hidden += 20;

        break;



      // 체험
      case "EX07":

        hidden += 20;

        break;



      // 레저
      case "VE03":

        nature += 10;

        break;



    }







    // =================================
    // 🌙 3차 분류 (lclsSystm3)
    // =================================


    switch(spot.lclsSystm3){



      // 산
      case "NA010100":

        nature += 20;

        healing += 20;

        break;



      // 폭포
      case "NA010300":

        nature += 20;

        healing += 20;

        break;



      // 약수터
      case "NA010500":

        healing += 30;

        break;



      // 항구
      case "NA020700":

        nature += 20;

        break;



      // 해변
      case "NA020900":

        nature += 30;

        healing += 20;

        break;



      // 온천
      case "HS030100":

        healing += 40;

        break;



      // 문화재
      case "HS010900":

        hidden += 20;

        healing += 10;

        break;



    }






    nature =

        nature.clamp(0,100).toDouble();



    hidden =

        hidden.clamp(0,100).toDouble();



    healing =

        healing.clamp(0,100).toDouble();







    return SpotVector(


      spotName:

      spot.title,



      regionName:

      extractRegion(

          spot.address

      ),



      nature:

      nature,



      hidden:

      hidden,



      healing:

      healing,



      congestion:

      0,

    );

  }








  // =================================
  // 주소 → 지역명 추출
  // =================================

  static String extractRegion(

    String address,

      ){

      final parts =
        address.split(" ");



    if(parts.length >= 2){


      String sido = parts[0];

      String sigungu = parts[1];



      if(sido == "서울"){

        sido = "서울특별시";

      }



      return "$sido $sigungu";


    }



    return address;


  }








  // =================================
  // SpotVector → RegionVector
  // =================================


  static List<RegionVector> generateRegions(

      List<SpotVector> spots,

      ){



    Map<String,List<SpotVector>> grouped = {};





    for(var spot in spots){


      grouped.putIfAbsent(

        spot.regionName,

            () => [],

      );



      grouped[spot.regionName]!.add(spot);


    }







    List<RegionVector> regions = [];






    grouped.forEach(

            (regionName, spotList){



          double nature = 0;

          double hidden = 0;

          double healing = 0;

          double congestion = 0;





          for(var spot in spotList){


            nature += spot.nature;

            hidden += spot.hidden;

            healing += spot.healing;

            congestion += spot.congestion;


          }







          double count =

          spotList.length.toDouble();







          regions.add(

            RegionVector(


              regionName:

              regionName,



              nature:

              nature / count,



              hidden:

              hidden / count,



              healing:

              healing / count,



              congestion:

              congestion / count,


            ),

          );




        }

    );






    return regions;



}


}