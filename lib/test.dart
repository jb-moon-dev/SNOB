import 'dart:math';

import '../services/tourism_api_service.dart';
import 'package:snob/snob/vector_generator.dart';
import 'package:snob/snob/user_vector.dart';
import 'package:snob/snob/recommendation_engine.dart';


Future<void> main() async {

  print("========================================");
  print("SNOB 추천 시스템 테스트 시작");
  print("========================================");


  // =====================================
  // 1. API → TourismSpot
  // =====================================

  print("");
  print("[1] 관광지 API 호출");


  final spots =
      await TourismApiService.getAllTourismSpots();


  print(
    "불러온 관광지 수 : ${spots.length}",
  );


  if (spots.isEmpty) {

    print("❌ 관광지 데이터가 없습니다.");
    return;

  }


  // =====================================
  // 2. TourismSpot → SpotVector
  // =====================================

  print("");
  print("[2] 관광지 → SpotVector");


  final spotVectors =
      spots
          .map(
            (spot) =>
                VectorGenerator.generateSpotVector(
              spot,
            ),
          )
          .toList();


  print(
    "생성된 SpotVector 수 : ${spotVectors.length}",
  );


  // 샘플 확인

  print("");
  print("--- SpotVector 샘플 ---");


  for (
    final vector
    in spotVectors.take(5)
  ) {

    print(
      "관광지 : ${vector.spotName}",
    );

    print(
      "지역 : ${vector.regionName}",
    );

    print(
      "자연 : ${vector.nature.toStringAsFixed(2)}",
    );

    print(
      "숨은 : ${vector.hidden.toStringAsFixed(2)}",
    );

    print(
      "힐링 : ${vector.healing.toStringAsFixed(2)}",
    );

    print("");

  }


  // =====================================
  // 3. SpotVector → RegionVector
  // =====================================

  print("[3] SpotVector → RegionVector");


  final regions =
      VectorGenerator.generateRegions(
    spotVectors,
  );


  print(
    "생성된 지역 수 : ${regions.length}",
  );


  print("");
  print("--- RegionVector 샘플 ---");


  for (
    final region
    in regions.take(10)
  ) {

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

    print("");

  }


  // =====================================
  // 4. 테스트 사용자 성향
  // =====================================
  //
  // 예시:
  // 자연 80
  // 숨은 70
  // 힐링 90
  //
  // 실제 앱에서는 PersonalityTest의
  // ScoreManager 결과가 들어감.
  // =====================================

  print("[4] 사용자 성향 벡터 생성");


  final user =
      UserVector(
        nature: 80,
        hidden: 70,
        healing: 90,
      );


  print(
    "사용자 자연 : ${user.nature}",
  );

  print(
    "사용자 숨은 : ${user.hidden}",
  );

  print(
    "사용자 힐링 : ${user.healing}",
  );


  // =====================================
  // 5. 지역 유사도 순위
  // =====================================

  print("");
  print("[5] 지역 유사도 계산");


  final ranked =
      RecommendationEngine.rankRegions(
    user,
    regions,
  );


  print("");
  print("========== TOP 10 ==========");


  for (
    int i = 0;
    i < min(10, ranked.length);
    i++
  ) {

    final region =
        ranked[i];


    final score =
        RecommendationEngine.similarity(
      user,
      region,
    );


    print(
      "${i + 1}위 "
      "${region.regionName} "
      "| 유사도 : ${score.toStringAsFixed(2)} "
      "| 자연 : ${region.nature.toStringAsFixed(1)} "
      "| 숨은 : ${region.hidden.toStringAsFixed(1)} "
      "| 힐링 : ${region.healing.toStringAsFixed(1)}",
    );

  }


  // =====================================
  // 6. Top 3 중 랜덤 추천
  // =====================================

  print("");
  print("[6] 최종 추천");


  final recommended =
      RecommendationEngine
          .recommendRandomRegion(
    user,
    regions,
  );


  print(
    "🎯 추천 지역 : ${recommended.regionName}",
  );

  print(
    "자연 : ${recommended.nature.toStringAsFixed(2)}",
  );

  print(
    "숨은 : ${recommended.hidden.toStringAsFixed(2)}",
  );

  print(
    "힐링 : ${recommended.healing.toStringAsFixed(2)}",
  );


  print("");
  print("========================================");
  print("SNOB 추천 시스템 테스트 종료");
  print("========================================");

}