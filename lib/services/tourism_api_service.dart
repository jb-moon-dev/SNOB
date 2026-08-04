import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:snob/snob/tourism_spot.dart';


class TourismApiService {


  static const String serviceKey =
      "cbea666b85656aa336898b2d32bfee6f7d6fdad29e7c840109a41b9bf449c8a9";


  static const String baseUrl =
      "https://apis.data.go.kr/B551011/KorService2";



  static Future<List<Map<String, String>>> getAreaCodes() async {


    List<Map<String, String>> areas = [];



    final url = Uri.parse(

      "$baseUrl/areaCode2"
          "?serviceKey=$serviceKey"
          "&MobileOS=AND"
          "&MobileApp=SNOB"
          "&_type=json"

    );



    final response =
        await http.get(url);



    if(response.statusCode == 200){


      final data =
          json.decode(response.body);



      final items =
          data["response"]
              ["body"]
              ["items"]
              ["item"];



      if(items != null){


        for(var item in items){


          areas.add({

            "code":
            item["code"].toString(),

            "name":
            item["name"].toString(),

          });


        }


      }


    }


    return areas;


  }
  static Future<List<TourismSpot>> getTourismSpotsByArea(
    String areaCode,
  ) async {

    List<TourismSpot> spots = [];


    final url = Uri.parse(
      "$baseUrl/areaBasedList2"
      "?serviceKey=$serviceKey"
      "&MobileOS=AND"
      "&MobileApp=SNOB"
      "&_type=json"
      "&areaCode=$areaCode"
      "&contentTypeId=12"
      "&numOfRows=20",
    );


    final response = await http.get(url);


    if (response.statusCode == 200) {


      final data = json.decode(response.body);


      final items =
          data["response"]
              ["body"]
              ["items"]
              ["item"];



      if (items != null) {


        for (var item in items) {


          spots.add(

            TourismSpot(

              contentId:
                  item["contentid"]?.toString() ?? "",


              title:
                  item["title"]?.toString() ?? "",


              address:
                  item["addr1"]?.toString() ?? "",


              areaName:
                  item["addr1"]?.toString() ?? "",


              contentTypeId:
                  item["contenttypeid"]?.toString() ?? "",


              cat1:
                  item["cat1"]?.toString() ?? "",


              cat2:
                  item["cat2"]?.toString() ?? "",


              cat3:
                  item["cat3"]?.toString() ?? "",


              areaCode:
                  item["areacode"]?.toString() ?? "",


              sigunguCode:
                  item["sigungucode"]?.toString() ?? "",


              modifiedTime:
                  item["modifiedtime"]?.toString() ?? "",

            ),

          );


        }

      }


    }


    return spots;

  }

}