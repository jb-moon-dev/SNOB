import 'dart:convert';
import 'dart:io';

import 'services/tourism_api_service.dart';

import 'snob/tourism_spot.dart';
import 'snob/spot_vector.dart';
import 'snob/region_vector.dart';
import 'snob/vector_generator.dart';

Future<void> main() async {
  print("");
  print("==================================================");
  print("        SNOB RegionVector JSON 생성 시작");
  print("==================================================");

  // ============================================================
  // 1. API 관광지 데이터 수집
  // ============================================================

  print("");
  print("[1] 전국 관광지 API 데이터 수집");
  print("");

  final List<TourismSpot> spots =
      await TourismApiService.getAllTourismSpots();

  print("");
  print("--------------------------------------------------");
  print(
    "API에서 받은 관광지 수 : ${spots.length}개",
  );
  print("--------------------------------------------------");

  if (spots.isEmpty) {
    print("");
    print("❌ 관광지 데이터가 없습니다.");
    print("JSON 생성을 중단합니다.");
    return;
  }

  // ============================================================
  // 1-1. 관광지 원본 데이터 CSV 저장
  //
  // ⭐ 보호구역 공간 매칭을 위해
  // 관광지의 위도/경도를 CSV로 저장
  // ============================================================

  print("");
  print("[1-1] 관광지 원본 데이터 CSV 저장");
  print("");

  final Directory dataDirectory =
      Directory("data");

  if (!dataDirectory.existsSync()) {
    dataDirectory.createSync(
      recursive: true,
    );
  }

  // CSV에 들어가는 문자열 안전하게 처리
  String csvEscape(String value) {
    final String escaped =
        value.replaceAll('"', '""');

    return '"$escaped"';
  }

  final StringBuffer csv =
      StringBuffer();

  // ------------------------------------------------------------
  // CSV 헤더
  // ------------------------------------------------------------

  csv.writeln(
    "contentId,"
    "title,"
    "address,"
    "contentTypeId,"
    "lDongRegnCd,"
    "lDongSignguCd,"
    "regionName,"
    "lclsSystm1,"
    "lclsSystm2,"
    "lclsSystm3,"
    "modifiedTime,"
    "latitude,"
    "longitude",
  );

  // ------------------------------------------------------------
  // 관광지 데이터
  // ------------------------------------------------------------

  for (final TourismSpot spot in spots) {
    csv.writeln(
      "${csvEscape(spot.contentId)},"
      "${csvEscape(spot.title)},"
      "${csvEscape(spot.address)},"
      "${csvEscape(spot.contentTypeId)},"
      "${csvEscape(spot.lDongRegnCd)},"
      "${csvEscape(spot.lDongSignguCd)},"
      "${csvEscape(spot.regionName)},"
      "${csvEscape(spot.lclsSystm1)},"
      "${csvEscape(spot.lclsSystm2)},"
      "${csvEscape(spot.lclsSystm3)},"
      "${csvEscape(spot.modifiedTime)},"
      "${spot.latitude ?? ""},"
      "${spot.longitude ?? ""}",
    );
  }

  final File tourismCsvFile =
      File("data/tourism_spots.csv");

  await tourismCsvFile.writeAsString(
    csv.toString(),
    encoding: utf8,
  );

  print(
    "✅ 관광지 CSV 저장 완료",
  );

  print(
    "저장 위치 : ${tourismCsvFile.path}",
  );

  print(
    "관광지 수 : ${spots.length}개",
  );

  // ============================================================
  // 1-2. 좌표 보유 여부 확인
  // ============================================================

  final int spotsWithCoordinates =
      spots.where(
    (spot) =>
        spot.latitude != null &&
        spot.longitude != null,
  ).length;

  final int spotsWithoutCoordinates =
      spots.length -
      spotsWithCoordinates;

  print("");
  print(
    "좌표 보유 관광지 : "
    "$spotsWithCoordinates개",
  );

  print(
    "좌표 없는 관광지 : "
    "$spotsWithoutCoordinates개",
  );

  // ============================================================
  // 2. 지역명 확인
  // ============================================================

  print("");
  print("[2] 지역명 데이터 검증");
  print("");

  final Set<String> regionNames = {};

  int emptyRegionCount = 0;

  for (final TourismSpot spot in spots) {
    final String name =
        spot.regionName.trim();

    if (name.isEmpty) {
      emptyRegionCount++;
    } else {
      regionNames.add(name);
    }
  }

  print(
    "관광지에서 확인된 지역 수 : "
    "${regionNames.length}개",
  );

  print(
    "빈 지역명 : "
    "$emptyRegionCount개",
  );

  // ============================================================
  // 3. 주요 지역 매핑 확인
  // ============================================================

  print("");
  print("[3] 주요 지역 매핑 확인");
  print("");

  const List<String> requiredRegions = [
    "서울특별시 종로구",
    "서울특별시 노원구",
    "부산광역시 해운대구",
    "대구광역시 중구",
    "인천광역시 중구",
    "광주광역시 동구",
    "대전광역시 중구",
    "울산광역시 중구",
    "세종특별자치시",
  ];

  for (final String region in requiredRegions) {
    if (regionNames.contains(region)) {
      print("✅ $region");
    } else {
      print("❌ $region");
    }
  }

  // ============================================================
  // 4. TourismSpot → SpotVector
  // ============================================================

  print("");
  print("[4] 관광지 → SpotVector");
  print("");

  final List<SpotVector> spotVectors =
      VectorGenerator.generateSpotVectors(
    spots,
  );

  print(
    "SpotVector : "
    "${spotVectors.length}개",
  );

  // ============================================================
  // 5. SpotVector → RegionVector
  // ============================================================

  print("");
  print("[5] SpotVector → RegionVector");
  print("");

  final List<RegionVector> regions =
      VectorGenerator.generateRegions(
    spotVectors,
  );

  print(
    "RegionVector : "
    "${regions.length}개",
  );

  if (regions.isEmpty) {
    print("");
    print("❌ RegionVector가 생성되지 않았습니다.");
    return;
  }

  // ============================================================
  // 6. 중복 지역명 검사
  // ============================================================

  print("");
  print("[6] 중복 지역명 검사");
  print("");

  final Set<String> uniqueRegionNames = {};

  final List<String> duplicatedNames = [];

  for (final RegionVector region in regions) {
    if (!uniqueRegionNames.add(
      region.regionName,
    )) {
      duplicatedNames.add(
        region.regionName,
      );
    }
  }

  if (duplicatedNames.isEmpty) {
    print("✅ 중복 지역명 없음");
  } else {
    print(
      "❌ 중복 지역명 "
      "${duplicatedNames.length}개",
    );

    for (final String name
        in duplicatedNames.toSet()) {
      print("  - $name");
    }
  }

  // ============================================================
  // 7. 빈 지역명 검사
  // ============================================================

  print("");
  print("[7] 지역명 오류 검사");
  print("");

  final List<RegionVector> emptyRegions =
      regions
          .where(
            (region) =>
                region.regionName
                    .trim()
                    .isEmpty,
          )
          .toList();

  if (emptyRegions.isEmpty) {
    print("✅ 빈 지역명 없음");
  } else {
    print(
      "❌ 빈 지역명 : "
      "${emptyRegions.length}개",
    );
  }

  // ============================================================
  // 8. 잘못된 지역명 검사
  // ============================================================

  final List<String> suspiciousRegions =
      regions
          .map(
            (region) =>
                region.regionName,
          )
          .where(
            (name) =>
                name.contains("광주광역사") ||
                name.contains("전남광주통합"),
          )
          .toList();

  if (suspiciousRegions.isEmpty) {
    print("✅ 이상 지역명 없음");
  } else {
    print("❌ 이상 지역명 발견");

    for (final String name
        in suspiciousRegions) {
      print("  - $name");
    }
  }

  // ============================================================
  // 9. RegionVector 샘플
  // ============================================================

  print("");
  print("[8] RegionVector 샘플");
  print("");

  for (final RegionVector region
      in regions.take(20)) {
    print(
      "지역 : ${region.regionName}",
    );

    print(
      "  자연 : "
      "${region.nature.toStringAsFixed(2)}",
    );

    print(
      "  숨은 : "
      "${region.hidden.toStringAsFixed(2)}",
    );

    print(
      "  힐링 : "
      "${region.healing.toStringAsFixed(2)}",
    );

    print(
      "  혼잡도 : "
      "${region.congestion.toStringAsFixed(2)}",
    );

    print("");
  }

  // ============================================================
  // 10. JSON 데이터 생성
  // ============================================================

  print("[9] region_vectors.json 생성");
  print("");

  final List<Map<String, dynamic>> jsonData =
      regions
          .map(
            (region) => region.toJson(),
          )
          .toList();

  final String jsonString =
      const JsonEncoder.withIndent(
        "  ",
      ).convert(jsonData);

  // ============================================================
  // 11. assets/data 폴더 생성
  // ============================================================

  final Directory assetsDataDirectory =
      Directory("assets/data");

  if (!assetsDataDirectory.existsSync()) {
    assetsDataDirectory.createSync(
      recursive: true,
    );
  }

  // ============================================================
  // 12. JSON 저장
  // ============================================================

  final File file =
      File(
    "assets/data/region_vectors.json",
  );

  await file.writeAsString(
    jsonString,
    encoding: utf8,
  );

  // ============================================================
  // 13. 최종 결과
  // ============================================================

  print("");
  print("==================================================");
  print("              JSON 생성 완료");
  print("==================================================");

  print("");
  print(
    "관광지 데이터 : "
    "${spots.length}개",
  );

  print(
    "좌표 보유 관광지 : "
    "$spotsWithCoordinates개",
  );

  print(
    "좌표 없는 관광지 : "
    "$spotsWithoutCoordinates개",
  );

  print(
    "SpotVector : "
    "${spotVectors.length}개",
  );

  print(
    "RegionVector : "
    "${regions.length}개",
  );

  print(
    "중복 지역명 : "
    "${duplicatedNames.length}개",
  );

  print(
    "이상 지역명 : "
    "${suspiciousRegions.length}개",
  );

  print(
    "빈 지역명 : "
    "$emptyRegionCount개",
  );

  print("");
  print(
    "관광지 CSV 저장 위치 : "
    "${tourismCsvFile.path}",
  );

  print(
    "JSON 저장 위치 : "
    "${file.path}",
  );

  // ============================================================
  // 14. CSV 파일 확인
  // ============================================================

  print("");
  print("[10] 관광지 CSV 파일 확인");
  print("");

  if (tourismCsvFile.existsSync()) {
    final int csvFileSize =
        tourismCsvFile.lengthSync();

    print(
      "✅ tourism_spots.csv 파일 확인 완료",
    );

    print(
      "파일 크기 : "
      "$csvFileSize bytes",
    );
  } else {
    print(
      "❌ tourism_spots.csv 파일 생성 확인 실패",
    );
  }

  // ============================================================
  // 15. JSON 파일 확인
  // ============================================================

  print("");
  print("[11] JSON 파일 확인");
  print("");

  if (file.existsSync()) {
    final int fileSize =
        file.lengthSync();

    print(
      "✅ region_vectors.json 파일 확인 완료",
    );

    print(
      "파일 크기 : "
      "$fileSize bytes",
    );
  } else {
    print(
      "❌ JSON 파일 생성 확인 실패",
    );
  }

  // ============================================================
  // 16. 최종 지역 수
  // ============================================================

  print("");
  print("==================================================");
  print("              최종 지역 수 검증");
  print("==================================================");

  print("");

  if (regions.length == 252) {
    print(
      "🎉 252개 지역이 정확하게 생성되었습니다!",
    );
  } else {
    print(
      "⚠️ 목표 지역 수와 다릅니다.",
    );

    print(
      "현재 : ${regions.length}개",
    );

    print(
      "목표 : 252개",
    );

    print("");
    print(
      "현재 생성된 지역 목록:",
    );

    for (final region in regions) {
      print(
        "  - ${region.regionName}",
      );
    }
  }

  // ============================================================
  // 17. 관광지 CSV 샘플 확인
  // ============================================================

  print("");
  print("==================================================");
  print("          관광지 좌표 데이터 최종 확인");
  print("==================================================");

  print("");

  int sampleCount = 0;

  for (final TourismSpot spot in spots) {
    if (spot.latitude != null &&
        spot.longitude != null) {
      print(
        "${spot.title} | "
        "${spot.regionName} | "
        "위도=${spot.latitude} | "
        "경도=${spot.longitude}",
      );

      sampleCount++;

      if (sampleCount >= 5) {
        break;
      }
    }
  }

  if (sampleCount == 0) {
    print(
      "⚠️ 좌표가 있는 관광지 샘플이 없습니다.",
    );
  }

  // ============================================================
  // 종료
  // ============================================================

  print("");
  print("==================================================");
  print("        SNOB RegionVector JSON 생성 종료");
  print("==================================================");
  print("");

  print("다음 단계:");
  print("1. data/tourism_spots.csv 생성 확인");
  print("2. Python 보호구역 매칭 실행");
  print("");
}