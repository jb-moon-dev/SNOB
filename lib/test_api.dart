import 'services/tourism_api_service.dart';
import 'snob/spot_vector_generator.dart';
import 'snob/vector_generator.dart';
import 'snob/spot_vector.dart';


void main() async {


  print("RegionVector 생성 테스트 시작");


  final spots =
      await TourismApiService.getTourismSpotsByArea("32");



  List<SpotVector> spotVectors = [];



  for(var spot in spots){


    spotVectors.add(
      SpotVectorGenerator.generate(spot),
    );


  }



  final regions =
      VectorGenerator.generateRegions(
        spotVectors,
      );



  for(var region in regions){

    print(region);

  }



  print("RegionVector 생성 테스트 종료");


}