import 'snob/tourism_spot.dart';
import 'snob/spot_vector.dart';
import 'snob/vector_generator.dart';
import 'services/tourism_api_service.dart';



void main() async {


  print("RegionVector 생성 테스트 시작");



  // =================================
  // 1. 관광 API 호출
  // =================================

  final List<TourismSpot> spots =
      await TourismApiService.getTourismSpotsByArea("32");



  print("가져온 관광지 개수 : ${spots.length}");




  // =================================
  // 2. TourismSpot → SpotVector
  // =================================

  List<SpotVector> spotVectors = [];



  for(var spot in spots){


    final vector =

    VectorGenerator.generateSpotVector(
        spot
    );



    spotVectors.add(vector);



    print(vector);


  }





  // =================================
  // 3. SpotVector → RegionVector
  // =================================


  final regions =

  VectorGenerator.generateRegions(
      spotVectors
  );



  for(var region in regions){


    print(region);


  }





  print("RegionVector 생성 테스트 종료");


}