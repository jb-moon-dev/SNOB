import 'dart:convert';

import 'package:http/http.dart' as http;

import '../screens/trip/course/models/course_item.dart';

class RelatedSpotService {
  static const String serviceKey =
      "네 서비스키";

  static const String baseUrl =
      "https://apis.data.go.kr/B551011/TarRlteTarService1";

  static Future<List<CourseItem>> getRelatedSpots({
    required String areaCode,
    required String sigunguCode,
    required String baseYm,
  }) async {
    final url = Uri.parse(

      "$baseUrl/areaBasedList1"

      "?serviceKey=$serviceKey"

      "&pageNo=1"

      "&numOfRows=20"

      "&MobileOS=AND"

      "&MobileApp=SNOB"

      "&baseYm=$baseYm"

      "&areaCd=$areaCode"

      "&signguCd=$sigunguCode"

      "&_type=json",
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      return [];
    }

    final data = json.decode(response.body);

    dynamic items =
        data["response"]["body"]["items"]["item"];

    if (items == null) {
      return [];
    }

    if (items is Map) {
      items = [items];
    }

    return items
        .map<CourseItem>(
          (e) => CourseItem(
            contentId: e["baseAreaCd"]?.toString() ?? "",
            title: e["baseAreaNm"]?.toString() ?? "",
            address: "",
            areaCode: areaCode,
            sigunguCode: sigunguCode,
            mapX: 0,
            mapY: 0,
          ),
        )
        .toList();
  }
}