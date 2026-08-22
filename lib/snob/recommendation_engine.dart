import 'dart:math';

import 'user_vector.dart';
import 'region_vector.dart';


class RecommendationEngine {


  // =====================================
  // Top 3 중 랜덤 추천
  // =====================================

  static RegionVector recommendRandomRegion(
    UserVector user,
    List<RegionVector> regions,
  ) {

    if (regions.isEmpty) {

      throw Exception(
        "추천 가능한 지역이 없습니다.",
      );

    }


    // 지역 유사도 순위 계산
    final ranked = rankRegions(
      user,
      regions,
    );


    // 상위 3개
    final top3 = ranked
        .take(min(3, ranked.length))
        .toList();


    // 상위 3개 중 랜덤
    final random = Random();

    final recommended =
        top3[random.nextInt(top3.length)];


    // 최종 추천 지역 반환
    return recommended;

  }


  // =====================================
  // 지역 유사도 순위 계산
  // =====================================

  static List<RegionVector> rankRegions(
    UserVector user,
    List<RegionVector> regions,
  ) {

    final result =
        List<RegionVector>.from(regions);


    result.sort((a, b) {

      final scoreA = similarity(
        user,
        a,
      );

      final scoreB = similarity(
        user,
        b,
      );


      return scoreB.compareTo(scoreA);

    });


    return result;

  }


  // =====================================
  // 사용자 - 지역 유사도
  // =====================================

  static double similarity(
    UserVector user,
    RegionVector region,
  ) {

    final natureDistance =
        user.nature - region.nature;

    final hiddenDistance =
        user.hidden - region.hidden;

    final healingDistance =
        user.healing - region.healing;


    final distance = sqrt(
      pow(natureDistance, 2) +
      pow(hiddenDistance, 2) +
      pow(healingDistance, 2),
    );


    // 유사할수록 높은 점수
    return 100 - distance;

  }

}