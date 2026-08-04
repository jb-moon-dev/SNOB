import '../snob/tourism_spot.dart';
import '../snob/spot_vector.dart';
import '../snob/region_vector.dart';
import '../snob/vector_generator.dart';

import 'tourism_api_service.dart';



class RegionRepository {



  // ===================================
  // 전국 지역 코드
  // ===================================


  static const List<String> areaCodes = [


    "1",   // 서울

    "2",   // 인천

    "3",   // 대전

    "4",   // 대구

    "5",   // 광주

    "6",   // 부산

    "7",   // 울산

    "8",   // 세종


    "31",  // 경기도

    "32",  // 강원특별자치도

    "33",  // 충청북도

    "34",  // 충청남도

    "35",  // 경상북도

    "36",  // 경상남도

    "37",  // 전북특별자치도

    "38",  // 전라남도

    "39",  // 제주특별자치도


  ];







  // ===================================
  // 전국 RegionVector 생성
  // ===================================


  static Future<List<RegionVector>> getRegions() async {



    List<TourismSpot> allSpots = [];





    // 1. 전국 관광지 데이터 수집

    for(var areaCode in areaCodes){



      final spots =

      await TourismApiService.getTourismSpotsByArea(

        areaCode,

      );



      allSpots.addAll(spots);



    }







    // 2. TourismSpot → SpotVector


    List<SpotVector> spotVectors = [];





    for(var spot in allSpots){



      spotVectors.add(

        VectorGenerator.generateSpotVector(

          spot,

        ),

      );


    }








    // 3. SpotVector → RegionVector


    final regions =

    VectorGenerator.generateRegions(

      spotVectors,

    );





    return regions;



  }



}