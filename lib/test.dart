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
  // 1. 한국관광공사 API에서 전국 관광지 데이터 가져오기
  //
  // ★ API 호출은 여기서 한 번만 실행한다.
  // ============================================================

  print("");
  print("[1] 전국 관광지 API 데이터 수집");
  print("");

  final List<TourismSpot> spots =
      await TourismApiService.getAllTourismSpots();

  print("");
  print("--------------------------------------------------");
  print("API에서 받은 관광지 수 : ${spots.length}개");
  print("--------------------------------------------------");

  if (spots.isEmpty) {
    print("");
    print("❌ 관광지 데이터가 없습니다.");
    print("JSON 생성을 중단합니다.");
    return;
  }

  // ============================================================
  // 2. TourismSpot → SpotVector
  //
  // 관광지의 lclsSystm1 / 2 / 3에 따라
  //
  // 자연
  // 숨은
  // 힐링
  //
  // 점수를 계산한다.
  //
  // 지역명 역시 VectorGenerator에서 처리한다.
  // ============================================================

  print("");
  print("[2] 관광지 → SpotVector");
  print("");

  final List<SpotVector> spotVectors =
      VectorGenerator.generateSpotVectors(
    spots,
  );

  print(
    "생성된 SpotVector : ${spotVectors.length}개",
  );

  // ============================================================
  // 3. 잘못된 지역명이 생성된 데이터 확인
  // ============================================================

  final List<SpotVector> invalidRegionSpots =
      spotVectors
          .where(
            (spot) =>
                spot.regionName.trim().isEmpty,
          )
          .toList();

  print(
    "지역명을 찾지 못한 관광지 : "
    "${invalidRegionSpots.length}개",
  );

  if (invalidRegionSpots.isNotEmpty) {
    print("");
    print("⚠️ 지역명을 찾지 못한 관광지 예시:");

    for (
      final spot
          in invalidRegionSpots.take(10)
    ) {
      print(
        "  - ${spot.spotName}",
      );
    }
  }

  // ============================================================
  // 4. SpotVector → RegionVector
  //
  // 같은 지역의 관광지를 하나로 묶고
  // 자연 / 숨은 / 힐링 점수의 평균을 계산한다.
  //
  // 예:
  //
  // 광주광역시 동구
  // 광주광역시 동구
  // 광주광역시 동구
  //
  // ↓
  //
  // 광주광역시 동구
  //
  // 하나의 RegionVector
  // ============================================================

  print("");
  print("[3] SpotVector → RegionVector");
  print("");

  final List<RegionVector> regions =
      VectorGenerator.generateRegions(
    spotVectors,
  );

  print(
    "생성된 RegionVector : ${regions.length}개",
  );

  if (regions.isEmpty) {
    print("");
    print("❌ RegionVector가 생성되지 않았습니다.");
    return;
  }

  // ============================================================
  // 5. 지역명 중복 검증
  //
  // generateRegions()에서 이미 그룹화되지만
  // 최종적으로 한 번 더 검사한다.
  // ============================================================

  final Set<String> regionNames = {};

  final List<String> duplicatedNames = [];

  for (final region in regions) {
    if (!regionNames.add(
      region.regionName,
    )) {
      duplicatedNames.add(
        region.regionName,
      );
    }
  }

  print("");
  print("[4] 지역 중복 검증");
  print("");

  if (duplicatedNames.isEmpty) {
    print("✅ 중복 지역명 없음");
  } else {
    print(
      "⚠️ 중복 지역명 : "
      "${duplicatedNames.length}개",
    );

    for (
      final name
          in duplicatedNames.toSet()
    ) {
      print("  - $name");
    }
  }

  // ============================================================
  // 6. 지역명 이상 여부 확인
  //
  // 이전에 발생했던 대표적인 오류:
  //
  // 광주광역사
  // 전남광주통합특별시
  //
  // 같은 잘못된 지역명이 들어갔는지 확인한다.
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
                name.contains(
                  "전남광주통합",
                ),
          )
          .toList();

  print("");
  print("[5] 지역명 오류 검증");
  print("");

  if (suspiciousRegions.isEmpty) {
    print("✅ 잘못된 지역명 없음");
  } else {
    print(
      "❌ 잘못된 지역명이 발견되었습니다:",
    );

    for (
      final name
          in suspiciousRegions
    ) {
      print("  - $name");
    }
  }

  // ============================================================
  // 7. RegionVector 샘플 출력
  // ============================================================

  print("");
  print("[6] RegionVector 샘플");
  print("");

  for (
    final region
        in regions.take(20)
  ) {
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
  // 8. JSON 데이터 생성
  // ============================================================

  print("[7] RegionVector → JSON");
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
  // 9. assets/data 폴더 생성
  // ============================================================

  final Directory directory =
      Directory(
    "assets/data",
  );

  if (!directory.existsSync()) {
    directory.createSync(
      recursive: true,
    );

    print(
      "assets/data 폴더 생성 완료",
    );
  }

  // ============================================================
  // 10. JSON 파일 저장
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
  // 11. 최종 결과
  // ============================================================

  print("");
  print("==================================================");
  print("          JSON 생성 완료");
  print("==================================================");

  print("");
  print(
    "관광지 데이터 : ${spots.length}개",
  );

  print(
    "SpotVector : ${spotVectors.length}개",
  );

  print(
    "RegionVector : ${regions.length}개",
  );

  print(
    "중복 지역명 : ${duplicatedNames.length}개",
  );

  print(
    "지역명 오류 : ${suspiciousRegions.length}개",
  );

  print("");
  print(
    "저장 위치 : ${file.path}",
  );

  print("");
  print(
    "==================================================",
  );

  // ============================================================
  // 12. 252개 지역 여부 확인
  // ============================================================

  if (regions.length == 252) {
    print(
      "✅ 목표 지역 수 252개가 정확하게 생성되었습니다.",
    );
  } else {
    print(
      "⚠️ 현재 생성된 지역 수 : "
      "${regions.length}개",
    );

    print(
      "   목표 지역 수 : 252개",
    );

    print(
      "   지역 수가 252개와 다릅니다.",
    );
  }

  print(
    "==================================================",
  );

  // ============================================================
  // 13. JSON 파일 존재 여부 최종 확인
  // ============================================================

  if (file.existsSync()) {
    final int fileSize =
        file.lengthSync();

    print("");
    print(
      "✅ region_vectors.json 파일 확인 완료",
    );

    print(
      "파일 크기 : $fileSize bytes",
    );
  } else {
    print("");
    print(
      "❌ JSON 파일 생성 확인 실패",
    );
  }

  print("");
  print(
    "==================================================",
  );
  print(
    "        SNOB RegionVector JSON 생성 종료",
  );
  print(
    "==================================================",
  );
}