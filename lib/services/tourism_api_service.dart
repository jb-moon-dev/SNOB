import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:snob/snob/tourism_spot.dart';


class TourismApiService {


  static const String serviceKey =
      "cbea666b85656aa336898b2d32bfee6f7d6fdad29e7c840109a41b9bf449c8a9";


  static const String baseUrl =
      "https://apis.data.go.kr/B551011/KorService2";



  // =====================================
  // 시도 코드 조회
  // ldongCode2
  // =====================================

  static Future<List<String>> getRegionCodes() async {


    List<String> codes = [];



    final url = Uri.parse(

      "$baseUrl/ldongCode2"
          "?serviceKey=$serviceKey"
          "&MobileOS=AND"
          "&MobileApp=SNOB"
          "&_type=json"
          "&numOfRows=100"

    );



    final response =
        await http.get(url);



    if(response.statusCode != 200){

      return [];

    }



    final data =
        json.decode(response.body);



    dynamic items =
        data["response"]
            ["body"]
            ["items"]
            ["item"];



    if(items == null){

      return [];

    }



    if(items is Map){

      items = [items];

    }



    for(var item in items){


      print("시도 API item : $item");

      codes.add(
        item["code"].toString()
      );


    }



    return codes;

  }






  // =====================================
  // 시군구 코드 조회
  // =====================================

  static Future<List<String>> getSigunguCodes(
      String regionCode,
      ) async {


    List<String> codes = [];



    final url = Uri.parse(

      "$baseUrl/ldongCode2"
          "?serviceKey=$serviceKey"
          "&MobileOS=AND"
          "&MobileApp=SNOB"
          "&_type=json"
          "&lDongRegnCd=$regionCode"

    );



    final response =
        await http.get(url);



    if(response.statusCode != 200){

      return [];

    }



    final data =
        json.decode(response.body);



    dynamic items =
        data["response"]
            ["body"]
            ["items"]
            ["item"];




    if(items == null){

      return [];

    }



    if(items is Map){

      items = [items];

    }



    for(var item in items){


      final sigungu =
          item["code"]?.toString();



      if(sigungu != null){

        codes.add(sigungu);

      }


    }



    return codes;

  }
    // =====================================
  // 법정동 기반 관광지 조회
  // =====================================

  static Future<List<TourismSpot>>

  getTourismSpotsByLegalDong(

      String regnCd,

      String signguCd,

      ) async {


    List<TourismSpot> spots = [];



    final url = Uri.parse(

      "$baseUrl/areaBasedList2"

          "?serviceKey=$serviceKey"

          "&MobileOS=AND"

          "&MobileApp=SNOB"

          "&_type=json"

          "&numOfRows=100"

          "&pageNo=1"

          "&contentTypeId=12"

          "&lDongRegnCd=$regnCd"

          "&lDongSignguCd=$signguCd"

    );



    final response =
        await http.get(url);



    if(response.statusCode != 200){

      return [];

    }



    final data =
        json.decode(response.body);



    dynamic items =
        data["response"]
            ["body"]
            ["items"]
            ["item"];



    if(items == null){

      return [];

    }



    if(items is Map){

      items = [items];

    }



    for(var item in items){


      spots.add(

        TourismSpot(

          contentId:
          item["contentid"]?.toString() ?? "",


          title:
          item["title"]?.toString() ?? "",


          address:
          item["addr1"]?.toString() ?? "",


          contentTypeId:
          item["contenttypeid"]?.toString() ?? "",


          lDongRegnCd:
          item["lDongRegnCd"]?.toString() ?? "",


          lDongSignguCd:
          item["lDongSignguCd"]?.toString() ?? "",


          lclsSystm1:
          item["lclsSystm1"]?.toString() ?? "",


          lclsSystm2:
          item["lclsSystm2"]?.toString() ?? "",


          lclsSystm3:
          item["lclsSystm3"]?.toString() ?? "",


          modifiedTime:
          item["modifiedtime"]?.toString() ?? "",

        ),

      );


    }



    return spots;


  }







  // =====================================
  // 전국 관광지 조회
  // =====================================

  static Future<List<TourismSpot>>

  getAllTourismSpots() async {


    List<TourismSpot> allSpots = [];



    final regions =
        await getRegionCodes();



    print(
        "시도 개수 : ${regions.length}"
    );



    // 테스트용 1개 지역
    for(var region in regions.take(1)){


      final sigungus =
          await getSigunguCodes(region);



      print(
          "시군구 개수 : ${sigungus.length}"
      );



      for(var sigungu in sigungus.take(3)){


        print(
          "조회 : $region / $sigungu"
        );



        final spots =
            await getTourismSpotsByLegalDong(

              region,

              sigungu,

            );



        print(
          "관광지 : ${spots.length}"
        );



        allSpots.addAll(spots);


      }


    }



    return allSpots;


  }


}