import 'package:snob/services/tourism_api_service.dart';


Future<void> main() async {

  print("===== TourAPI 테스트 시작 =====");


  final spots =
      await TourismApiService.getTourismSpotsByArea("32");


  print("가져온 관광지 개수 : ${spots.length}");


  for (var spot in spots.take(10)) {


    print("");

    print("===== Tourism Spot =====");


    print("관광지명 : ${spot.title}");

    print("주소 : ${spot.address}");


    print("contentId : ${spot.contentId}");

    print("contentTypeId : ${spot.contentTypeId}");



    print("----- 법정동 코드 -----");

    print("lDongRegnCd : ${spot.lDongRegnCd}");

    print("lDongSignguCd : ${spot.lDongSignguCd}");



    print("----- 새로운 분류체계 -----");

    print("lclsSystm1 : ${spot.lclsSystm1}");

    print("lclsSystm2 : ${spot.lclsSystm2}");

    print("lclsSystm3 : ${spot.lclsSystm3}");



    print("modifiedTime : ${spot.modifiedTime}");


    print("========================");

  }



  print("");

  print("===== 테스트 종료 =====");

}