import 'dart:math';

import 'user_vector.dart';
import 'region_vector.dart';


class RecommendationEngine {

  // =====================================
  // 지역 유사도 순위
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

    return 100 - distance;
  }


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

    final ranked =
        rankRegions(
      user,
      regions,
    );

    final top3 = ranked
        .take(min(3, ranked.length))
        .toList();

    final random = Random();

    return top3[
      random.nextInt(top3.length)
    ];
  }

}