import '../snob/tourism_spot.dart';
import '../snob/spot_vector.dart';
import '../snob/region_vector.dart';
import '../snob/vector_generator.dart';

import 'tourism_api_service.dart';



class RegionRepository {



  static Future<List<RegionVector>> getRegions() async {



    List<TourismSpot> allSpots = [];





    // 1. 전국 관광지 가져오기

    allSpots =
        await TourismApiService.getAllTourismSpots();





    print(
      "전체 관광지 개수 : ${allSpots.length}"
    );







    // 2. TourismSpot → SpotVector



    List<SpotVector> spotVectors = [];



    for(var spot in allSpots){


      final vector =

      VectorGenerator.generateSpotVector(

        spot,

      );



      spotVectors.add(vector);



    }







    // 3. SpotVector → RegionVector



    final regions =

    VectorGenerator.generateRegions(

      spotVectors,

    );




    return regions;



  }



}