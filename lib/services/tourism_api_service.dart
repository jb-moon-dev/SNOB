import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:snob/snob/tourism_spot.dart';

class TourismApiService {
  // ============================================================
  // API 설정
  // ============================================================

  static const String serviceKey =
      "cbea666b85656aa336898b2d32bfee6f7d6fdad29e7c840109a41b9bf449c8a9";

  static const String baseUrl =
      "https://apis.data.go.kr/B551011/KorService2";

  // ============================================================
  // API 응답에서 item 추출
  // ============================================================

  static List<dynamic> _extractItems(dynamic data) {
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

    // API가 데이터가 없을 때 ""로 반환하는 경우
    if (item is String) {
      return [];
    }

    // 데이터가 1개인 경우
    if (item is Map) {
      return [item];
    }

    // 데이터가 여러 개인 경우
    if (item is List) {
      return item;
    }

    return [];
  }

  // ============================================================
  // 시도 코드 조회
  //
  // 반환 예:
  // 11
  // 26
  // 27
  // ...
  // 50
  // ============================================================

  static Future<List<String>> getRegionCodes() async {
    final Set<String> codes = {};

    final Uri url = Uri.parse(
      "$baseUrl/ldongCode2"
      "?serviceKey=$serviceKey"
      "&MobileOS=AND"
      "&MobileApp=SNOB"
      "&_type=json"
      "&numOfRows=100",
    );

    try {
      print("시도 코드 조회 중...");

      final response = await http.get(url);

      if (response.statusCode != 200) {
        print(
          "시도 코드 API 오류 : ${response.statusCode}",
        );
        return [];
      }

      final dynamic data = json.decode(response.body);

      final List<dynamic> items =
          _extractItems(data);

      for (final dynamic item in items) {
        if (item is! Map) {
          continue;
        }

        final String code =
            item["code"]?.toString().trim() ?? "";

        // 시도 코드는 2자리만 사용
        if (RegExp(r'^\d{2}$').hasMatch(code)) {
          codes.add(code);
        }
      }
    } catch (e) {
      print("시도 코드 조회 실패 : $e");
      return [];
    }

    final List<String> result =
        codes.toList()..sort();

    return result;
  }

  // ============================================================
  // 시군구 코드 조회
  //
  // regionCode:
  // 11 → 서울
  // 26 → 부산
  // 36 → 세종
  //
  // 반환 예:
  // 11110
  // 11140
  // ...
  //
  // ★ 핵심
  // 반드시 해당 시도의 코드만 가져온다.
  // ============================================================

  static Future<List<String>> getSigunguCodes(
    String regionCode,
  ) async {
    final Set<String> codes = {};

    final String regnCd =
        regionCode.trim().padLeft(2, "0");

    final Uri url = Uri.parse(
      "$baseUrl/ldongCode2"
      "?serviceKey=$serviceKey"
      "&MobileOS=AND"
      "&MobileApp=SNOB"
      "&_type=json"
      "&numOfRows=100"
      "&lDongRegnCd=$regnCd",
    );

    try {
      print(
        "  시군구 코드 조회 : $regnCd",
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        print(
          "  시군구 코드 API 오류 : "
          "${response.statusCode}",
        );
        return [];
      }

      final dynamic data = json.decode(response.body);

      final List<dynamic> items =
          _extractItems(data);

      for (final dynamic item in items) {
        if (item is! Map) {
          continue;
        }

        final String code =
            item["code"]?.toString().trim() ?? "";

        // 시군구 코드는 5자리
        if (!RegExp(r'^\d{5}$').hasMatch(code)) {
          continue;
        }

        // 반드시 현재 시도 코드로 시작해야 한다.
        if (!code.startsWith(regnCd)) {
          continue;
        }

        codes.add(code);
      }
    } catch (e) {
      print(
        "  시군구 코드 조회 실패 : "
        "$regnCd / $e",
      );
      return [];
    }

    final List<String> result =
        codes.toList()..sort();

    return result;
  }

  // ============================================================
  // 특정 시군구의 관광지 조회
  //
  // ★ 여기서는 지역명을 만들지 않는다.
  //
  // API에서 받은
  // lDongRegnCd
  // lDongSignguCd
  //
  // 를 그대로 TourismSpot에 저장한다.
  // ============================================================

  static Future<List<TourismSpot>>
      getTourismSpotsByLegalDong(
    String regnCd,
    String signguCd,
  ) async {
    final List<TourismSpot> spots = [];

    final String regionCode =
        regnCd.trim().padLeft(2, "0");

    final String sigunguCode =
        signguCd.trim().padLeft(5, "0");

    int pageNo = 1;

    while (true) {
      final Uri url = Uri.parse(
        "$baseUrl/areaBasedList2"
        "?serviceKey=$serviceKey"
        "&MobileOS=AND"
        "&MobileApp=SNOB"
        "&_type=json"
        "&numOfRows=100"
        "&pageNo=$pageNo"
        "&contentTypeId=12"
        "&lDongRegnCd=$regionCode"
        "&lDongSignguCd=$sigunguCode",
      );

      try {
        print(
          "    관광지 조회 : "
          "$regionCode / $sigunguCode "
          "(page $pageNo)",
        );

        final response =
            await http.get(url);

        if (response.statusCode != 200) {
          print(
            "    API HTTP 오류 : "
            "${response.statusCode}",
          );
          break;
        }

        final dynamic data =
            json.decode(response.body);

        final List<dynamic> items =
            _extractItems(data);

        if (items.isEmpty) {
          break;
        }

        int addedCount = 0;

        for (final dynamic item in items) {
          // ★ 반드시 Map인지 확인
          if (item is! Map) {
            continue;
          }

          try {
            final TourismSpot spot =
                TourismSpot(
              contentId:
                  item["contentid"]?.toString() ?? "",

              title:
                  item["title"]?.toString() ?? "",

              address:
                  item["addr1"]?.toString() ?? "",

              contentTypeId:
                  item["contenttypeid"]?.toString() ?? "",

              // ★ API가 준 지역코드를 우선 사용
              // 값이 없으면 현재 조회 중인 코드 사용
              lDongRegnCd:
                  item["lDongRegnCd"]
                          ?.toString()
                          .trim()
                          .isNotEmpty ==
                      true
                      ? item["lDongRegnCd"]
                          .toString()
                          .trim()
                      : regionCode,

              lDongSignguCd:
                  item["lDongSignguCd"]
                          ?.toString()
                          .trim()
                          .isNotEmpty ==
                      true
                      ? item["lDongSignguCd"]
                          .toString()
                          .trim()
                      : sigunguCode,

              lclsSystm1:
                  item["lclsSystm1"]
                          ?.toString() ??
                      "",

              lclsSystm2:
                  item["lclsSystm2"]
                          ?.toString() ??
                      "",

              lclsSystm3:
                  item["lclsSystm3"]
                          ?.toString() ??
                      "",

              modifiedTime:
                  item["modifiedtime"]
                          ?.toString() ??
                      "",
            );

            // 관광지 이름이 없는 데이터 제외
            if (spot.title.trim().isEmpty) {
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

        // 마지막 페이지
        if (items.length < 100) {
          break;
        }

        pageNo++;
      } catch (e) {
        print(
          "    API 데이터 처리 실패 : $e",
        );
        break;
      }
    }

    print(
      "    관광지 합계 : ${spots.length}개",
    );

    return spots;
  }

  // ============================================================
  // 전국 관광지 조회
  //
  // 결과:
  //
  // TourismSpot {
  //   title
  //   address
  //   lDongRegnCd
  //   lDongSignguCd
  //   lclsSystm1
  //   lclsSystm2
  //   lclsSystm3
  // }
  //
  // ★ 여기서는 regionName을 만들지 않는다.
  // ============================================================

  static Future<List<TourismSpot>>
      getAllTourismSpots() async {
    final List<TourismSpot> allSpots = [];

    print("");
    print(
      "==================================================",
    );
    print(
      "SNOB 전국 관광지 데이터 수집 시작",
    );
    print(
      "==================================================",
    );

    // ==========================================================
    // 1. 시도 코드
    // ==========================================================

    final List<String> regions =
        await getRegionCodes();

    print("");
    print(
      "전체 시도 : ${regions.length}개",
    );

    if (regions.isEmpty) {
      print(
        "❌ 시도 데이터를 가져오지 못했습니다.",
      );
      return [];
    }

    // ==========================================================
    // 2. 시도별
    // ==========================================================

    for (
      int regionIndex = 0;
      regionIndex < regions.length;
      regionIndex++
    ) {
      final String region =
          regions[regionIndex];

      print("");
      print(
        "[시도 ${regionIndex + 1}/${regions.length}] "
        "code=$region",
      );

      // ========================================================
      // 시군구 코드
      // ========================================================

      final List<String> sigungus =
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

      // ========================================================
      // 시군구별 관광지
      // ========================================================

      for (
        int sigunguIndex = 0;
        sigunguIndex < sigungus.length;
        sigunguIndex++
      ) {
        final String sigungu =
            sigungus[sigunguIndex];

        print(
          "  [${sigunguIndex + 1}/${sigungus.length}] "
          "$region / $sigungu",
        );

        final List<TourismSpot> spots =
            await getTourismSpotsByLegalDong(
          region,
          sigungu,
        );

        allSpots.addAll(spots);
      }
    }

    // ==========================================================
    // 3. contentId 기준 중복 제거
    //
    // 같은 관광지가 여러 번 들어오는 경우 방지
    // ==========================================================

    final Map<String, TourismSpot>
        uniqueSpots = {};

    for (final TourismSpot spot
        in allSpots) {
      if (spot.contentId.trim().isEmpty) {
        continue;
      }

      uniqueSpots[spot.contentId] = spot;
    }

    final List<TourismSpot> result =
        uniqueSpots.values.toList();

    // ==========================================================
    // 4. 결과
    // ==========================================================

    print("");
    print(
      "==================================================",
    );
    print(
      "SNOB 전국 관광지 데이터 수집 완료",
    );
    print(
      "==================================================",
    );

    print(
      "API 관광지 : ${allSpots.length}개",
    );

    print(
      "중복 제거 후 : ${result.length}개",
    );

    return result;
  }
}