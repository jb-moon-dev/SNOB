import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:snob/snob/tourism_spot.dart';

class TourismApiService {
  static const String serviceKey =
      "cbea666b85656aa336898b2d32bfee6f7d6fdad29e7c840109a41b9bf449c8a9";

  static const String baseUrl =
      "https://apis.data.go.kr/B551011/KorService2";

  // =====================================
  // 공통 API 응답에서 item 추출
  // =====================================

  static List<dynamic> _extractItems(dynamic data) {
    try {
      if (data is! Map) {
        return [];
      }

      final response = data["response"];

      if (response is! Map) {
        return [];
      }

      final body = response["body"];

      if (body is! Map) {
        return [];
      }

      final items = body["items"];

      if (items is! Map) {
        return [];
      }

      final item = items["item"];

      if (item == null) {
        return [];
      }

      // item이 비어있는 문자열로 오는 경우
      if (item is String) {
        return [];
      }

      // 관광지가 1개인 경우
      if (item is Map) {
        return [item];
      }

      // 관광지가 여러 개인 경우
      if (item is List) {
        return item;
      }

      return [];
    } catch (e) {
      print("API item 추출 실패 : $e");
      return [];
    }
  }

  // =====================================
  // 시도 코드 조회
  // ldongCode2
  // =====================================

  static Future<List<String>> getRegionCodes() async {
    final List<String> codes = [];

    final url = Uri.parse(
      "$baseUrl/ldongCode2"
      "?serviceKey=$serviceKey"
      "&MobileOS=AND"
      "&MobileApp=SNOB"
      "&_type=json"
      "&numOfRows=100",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        print(
          "시도 코드 API 오류 : ${response.statusCode}",
        );
        return [];
      }

      final data = json.decode(response.body);

      final items = _extractItems(data);

      for (final item in items) {
        if (item is! Map) {
          continue;
        }

        final code = item["code"]?.toString();

        if (code != null && code.isNotEmpty) {
          codes.add(code);
        }
      }
    } catch (e) {
      print("시도 코드 조회 실패 : $e");
    }

    return codes;
  }

  // =====================================
  // 시군구 코드 조회
  // =====================================

  static Future<List<String>> getSigunguCodes(
    String regionCode,
  ) async {
    final List<String> codes = [];

    final url = Uri.parse(
      "$baseUrl/ldongCode2"
      "?serviceKey=$serviceKey"
      "&MobileOS=AND"
      "&MobileApp=SNOB"
      "&_type=json"
      "&numOfRows=100"
      "&lDongRegnCd=$regionCode",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        print(
          "시군구 코드 API 오류 : "
          "$regionCode / ${response.statusCode}",
        );
        return [];
      }

      final data = json.decode(response.body);

      final items = _extractItems(data);

      for (final item in items) {
        if (item is! Map) {
          continue;
        }

        final code = item["code"]?.toString();

        if (code != null && code.isNotEmpty) {
          codes.add(code);
        }
      }
    } catch (e) {
      print(
        "시군구 코드 조회 실패 : "
        "$regionCode / $e",
      );
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
    final List<TourismSpot> spots = [];

    int pageNo = 1;

    while (true) {
      final url = Uri.parse(
        "$baseUrl/areaBasedList2"
        "?serviceKey=$serviceKey"
        "&MobileOS=AND"
        "&MobileApp=SNOB"
        "&_type=json"
        "&numOfRows=100"
        "&pageNo=$pageNo"
        "&contentTypeId=12"
        "&lDongRegnCd=$regnCd"
        "&lDongSignguCd=$signguCd",
      );

      try {
        print(
          "    관광지 조회 : "
          "$regnCd / $signguCd "
          "(page $pageNo)",
        );

        final response = await http.get(url);

        if (response.statusCode != 200) {
          print(
            "    API HTTP 오류 : "
            "${response.statusCode}",
          );
          break;
        }

        final data = json.decode(response.body);

        final items = _extractItems(data);

        // 더 이상 데이터가 없는 경우
        if (items.isEmpty) {
          break;
        }

        int addedCount = 0;

        for (final item in items) {
          if (item is! Map) {
            continue;
          }

          try {
            final spot = TourismSpot(
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
            );

            // 관광지 이름이 없는 잘못된 데이터는 제외
            if (spot.title.isEmpty) {
              continue;
            }

            spots.add(spot);
            addedCount++;
          } catch (e) {
            print(
              "    관광지 데이터 변환 실패 : $e",
            );
          }
        }

        print(
          "      → $addedCount개",
        );

        // 100개보다 적게 왔다면 마지막 페이지
        if (items.length < 100) {
          break;
        }

        pageNo++;
      } catch (e) {
        print(
          "API 데이터 구조 확인 실패 : $e",
        );
        break;
      }
    }

    print(
      "    관광지 합계 : ${spots.length}개",
    );

    return spots;
  }

  // =====================================
  // 전국 관광지 조회
  // =====================================

  static Future<List<TourismSpot>>
      getAllTourismSpots() async {
    final List<TourismSpot> allSpots = [];

    print("");
    print("==================================================");
    print("SNOB 전국 관광지 데이터 수집 시작");
    print("==================================================");

    // -------------------------------------
    // 1. 시도 코드 조회
    // -------------------------------------

    final regions = await getRegionCodes();

    print("");
    print(
      "전체 시도 : ${regions.length}개",
    );

    if (regions.isEmpty) {
      print("❌ 시도 데이터를 가져오지 못했습니다.");
      return [];
    }

    // -------------------------------------
    // 2. 시도별 관광지 조회
    // -------------------------------------

    for (int regionIndex = 0;
        regionIndex < regions.length;
        regionIndex++) {
      final region = regions[regionIndex];

      print("");
      print(
        "[시도 ${regionIndex + 1}/${regions.length}] "
        "code=$region",
      );

      // -----------------------------------
      // 시군구 코드 조회
      // -----------------------------------

      final sigungus =
          await getSigunguCodes(region);

      print(
        "시군구 : ${sigungus.length}개",
      );

      if (sigungus.isEmpty) {
        print(
          "  ⚠️ 시군구 데이터가 없습니다.",
        );
        continue;
      }

      // -----------------------------------
      // 시군구별 관광지 조회
      // -----------------------------------

      for (int sigunguIndex = 0;
          sigunguIndex < sigungus.length;
          sigunguIndex++) {
        final sigungu = sigungus[sigunguIndex];

        print(
          "  [${sigunguIndex + 1}/${sigungus.length}] "
          "$region / $sigungu",
        );

        final spots =
            await getTourismSpotsByLegalDong(
          region,
          sigungu,
        );

        allSpots.addAll(spots);
      }
    }

    // -------------------------------------
    // 3. 최종 결과
    // -------------------------------------

    print("");
    print("==================================================");
    print("SNOB 전국 관광지 데이터 수집 완료");
    print("==================================================");
    print(
      "전체 관광지 : ${allSpots.length}개",
    );

    return allSpots;
  }
}