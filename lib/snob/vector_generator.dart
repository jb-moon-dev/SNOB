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
    // 🌿 자연 성향
    // =================================


    switch(spot.cat1){


      // 자연관광
      case "A01":

        nature += 30;

        healing += 10;

        break;



      // 문화관광
      case "A02":

        nature -= 10;

        break;



      // 체험관광
      case "A03":

        nature += 10;

        healing -= 10;

        break;


    }





    // =================================
    // 🔍 숨은 성향
    // =================================


    switch(spot.cat2){


      // 자연 속 관광
      case "A0101":

        hidden += 20;

        break;



      // 역사/문화
      case "A0201":

        hidden += 10;

        break;



      // 관광시설
      case "A0202":

        hidden -= 10;

        break;



      // 체험/레저
      case "A0203":

        hidden += 20;

        break;


    }





    // =================================
    // 🌙 힐링 성향
    // =================================


    switch(spot.cat3){


      // 온천
      case "A02020300":

        healing += 30;

        break;



      // 산
      case "A01010400":

        nature += 20;

        healing += 20;

        break;



      // 해변
      case "A01010700":

        nature += 20;

        healing += 20;

        break;



      default:

        break;


    }





    nature =
        nature.clamp(0,100).toDouble();


    hidden =
        hidden.clamp(0,100).toDouble();


    healing =
        healing.clamp(0,100).toDouble();





    return SpotVector(

      spotName: spot.title,


      regionName:
      extractRegion(spot.areaName),


      nature: nature,


      hidden: hidden,


      healing: healing,


      congestion: 0,

    );


  }







  // =================================
  // 주소 → 지역명 변환
  // =================================


  static String extractRegion(

      String address,

      ){


    final parts =

    address.split(" ");



    if(parts.length >= 2){


      return "${parts[0]} ${parts[1]}";


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


      grouped[spot.regionName]!
          .add(spot);


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


              regionName: regionName,


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