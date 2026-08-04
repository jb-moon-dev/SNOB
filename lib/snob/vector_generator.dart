import 'spot_vector.dart';
import 'region_vector.dart';
import 'tourism_spot.dart';


class VectorGenerator {



  // =================================
  // TourismSpot → SpotVector 생성
  // =================================

  static SpotVector generateSpotVector(

      TourismSpot spot,

      ){


    double nature = 50;

    double hidden = 50;

    double healing = 50;



    // 🌆 도시 ↔ 🌿 자연

    if(
    spot.cat1.contains("자연") ||
        spot.cat2.contains("자연") ||
        spot.cat3.contains("산") ||
        spot.cat3.contains("해변") ||
        spot.cat3.contains("공원")
    ){

      nature += 30;

    }



    if(
    spot.cat3.contains("쇼핑") ||
        spot.cat3.contains("문화") ||
        spot.cat3.contains("역사")
    ){

      nature -= 30;

    }





    // ⭐ 유명 ↔ 🔍 숨은

    if(
    spot.cat3.contains("명소") ||
        spot.cat3.contains("대표")
    ){

      hidden -= 30;

    }



    if(
    spot.cat3.contains("마을") ||
        spot.cat3.contains("골목")
    ){

      hidden += 20;

    }





    // ⚡ 활동 ↔ 🌙 힐링

    if(
    spot.cat3.contains("레포츠") ||
        spot.cat3.contains("체험") ||
        spot.cat3.contains("액티비티")
    ){

      healing -= 30;

    }



    if(
    spot.cat3.contains("휴양") ||
        spot.cat3.contains("산책") ||
        spot.cat3.contains("온천")
    ){

      healing += 30;

    }





    nature =
        nature.clamp(0,100).toDouble();

    hidden =
        hidden.clamp(0,100).toDouble();

    healing =
        healing.clamp(0,100).toDouble();





    return SpotVector(

      spotName: spot.title,

      regionName: extractRegion(spot.areaName),

      nature: nature,

      hidden: hidden,

      healing: healing,

      // API 연결 전 임시값
      congestion: 0,

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


      return "${parts[0]} ${parts[1]}";


    }



    return address;


  }  

  // =================================
  // SpotVector → RegionVector 생성
  // =================================

  static List<RegionVector> generateRegions(

      List<SpotVector> spots,

      ){


    Map<String,List<SpotVector>> grouped = {};





    // 지역별 그룹화

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