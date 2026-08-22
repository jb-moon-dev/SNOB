import 'dart:convert';
import 'dart:io';

import 'services/tourism_api_service.dart';

import 'snob/tourism_spot.dart';
import 'snob/spot_vector.dart';
import 'snob/region_vector.dart';
import 'snob/vector_generator.dart';

Future<void> main() async {
  print("=======================================");
  print("SNOB RegionVector JSON 생성 시작");
  print("=======================================");

  // =====================================
  // 1. 관광지 API 호출
  // =====================================

  print("");
  print("[1] 관광지 API 호출");

  final List<TourismSpot> spots =
      await TourismApiService.getAllTourismSpots();

  print("");
  print("불러온 관광지 수 : ${spots.length}개");

  if (spots.isEmpty) {
    print("❌ 관광지 데이터가 없습니다.");
    return;
  }

  // =====================================
  // 2. TourismSpot → SpotVector
  // =====================================

  print("");
  print("[2] 관광지 → SpotVector");

  final List<SpotVector> spotVectors =
      spots
          .map(
            (spot) =>
                VectorGenerator.generateSpotVector(spot),
          )
          .toList();

  print(
    "생성된 SpotVector 수 : ${spotVectors.length}개",
  );

  // =====================================
  // 3. SpotVector → RegionVector
  // =====================================

  print("");
  print("[3] SpotVector → RegionVector");

  final List<RegionVector> regions =
      VectorGenerator.generateRegions(
    spotVectors,
  );

  print(
    "생성된 RegionVector 수 : ${regions.length}개",
  );

  if (regions.isEmpty) {
    print("❌ RegionVector가 생성되지 않았습니다.");
    return;
  }

  // =====================================
  // 4. RegionVector 확인
  // =====================================

  print("");
  print("[4] RegionVector 샘플");

  for (final region in regions.take(10)) {
    print(
      "지역 : ${region.regionName}",
    );

    print(
      "자연 : ${region.nature.toStringAsFixed(2)}",
    );

    print(
      "숨은 : ${region.hidden.toStringAsFixed(2)}",
    );

    print(
      "힐링 : ${region.healing.toStringAsFixed(2)}",
    );

    print(
      "혼잡도 : ${region.congestion.toStringAsFixed(2)}",
    );

    print("");
  }

  // =====================================
  // 5. RegionVector → JSON
  // =====================================

  print("");
  print("[5] region_vectors.json 생성");

  final List<Map<String, dynamic>> jsonData =
      regions
          .map(
            (region) => region.toJson(),
          )
          .toList();

  final String jsonString =
      const JsonEncoder.withIndent("  ")
          .convert(jsonData);

  // =====================================
  // 6. 파일 저장
  // =====================================

  final Directory directory =
      Directory("assets/data");

  if (!directory.existsSync()) {
    directory.createSync(
      recursive: true,
    );
  }

  final File file =
      File("assets/data/region_vectors.json");

  await file.writeAsString(
    jsonString,
    encoding: utf8,
  );

  print("");
  print("✅ JSON 파일 생성 완료!");
  print(
    "저장 위치 : ${file.path}",
  );

  print("");
  print("저장된 지역 수 : ${regions.length}개");

  print("");
  print("========================================");
  print("SNOB RegionVector JSON 생성 종료");
  print("========================================");
}