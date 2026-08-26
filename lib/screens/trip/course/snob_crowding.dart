import '../../../services/congestion_service.dart';

// ================================================================
// Crowding 계산 결과
// ================================================================

class SnobCrowdingResult {
  final Map<String, dynamic> spot;

  // 30일 평균 관광지 집중률
  final double averageConcentration;

  // Crowding 점수 (최대 45점)
  final double crowdingScore;

  const SnobCrowdingResult({
    required this.spot,
    required this.averageConcentration,
    required this.crowdingScore,
  });

  @override
  String toString() {
    final name =
        spot['hubTatsNm'] ?? '이름 없음';

    return '''
$name
30일 평균 관광지 집중률 : ${averageConcentration.toStringAsFixed(2)}
Crowding 점수           : ${crowdingScore.toStringAsFixed(2)}
''';
  }
}

// ================================================================
// Crowding 계산
// ================================================================
//
// 관광지 집중률이 낮을수록 추천하기 좋은 관광지.
//
// Crowding 점수
// = (100 - 관광지 집중률) × 0.45
//
// 최대 45점
//
// 관광지 집중률 데이터가 없는 경우
// = 27.5점
//
// ================================================================

class SnobCrowding {
  final CongestionService _service =
      CongestionService();

  // Crowding 최대 점수
  static const double maxScore = 45.0;

  // 집중률 데이터가 없을 때 중립 점수
  static const double neutralScore = 27.5;

  /// Center50에서 받은 관광지 목록을 대상으로
  /// 관광지별 집중률을 계산한다.
  ///
  /// 집중률 API는 지역별로 한 번만 호출한 뒤
  /// hubTatsCd를 기준으로 관광지를 매칭한다.
  Future<List<SnobCrowdingResult>> calculate(
    List<Map<String, dynamic>> spots,
  ) async {
    final results =
        <SnobCrowdingResult>[];

    if (spots.isEmpty) {
      return results;
    }

    // ============================================================
    // 지역 코드 확인
    // ============================================================

    final firstSpot = spots.first;

    final areaCd =
        firstSpot['areaCd']?.toString();

    final signguCd =
        firstSpot['signguCd']?.toString();

    if (areaCd == null ||
        areaCd.isEmpty ||
        signguCd == null ||
        signguCd.isEmpty) {
      print(
        'Crowding 계산 실패: 지역 코드가 없습니다.',
      );

      return results;
    }

    print('');
    print('============================================================');
    print('SNOB CROWDING 시작');
    print('대상 관광지 수 : ${spots.length}');
    print('areaCd : $areaCd');
    print('signguCd : $signguCd');
    print('============================================================');

    // ============================================================
    // 집중률 API 호출
    //
    // 관광지마다 호출하지 않고
    // 해당 지역의 집중률 데이터를 한 번만 조회한다.
    // ============================================================

    List<Map<String, dynamic>> concentrationData = [];

    try {
      concentrationData =
          await _service.getCongestion(
        areaCd: areaCd,
        signguCd: signguCd,
      );
    } catch (e) {
      print(
        '관광지 집중률 API 호출 실패: $e',
      );
    }

    print('');
    print(
      '집중률 API 관광지 수 : '
      '${concentrationData.length}',
    );

    // ============================================================
    // 집중률 데이터를 hubTatsCd 기준 Map으로 변환
    // ============================================================

    final Map<String, List<double>>
        concentrationMap = {};

    for (final data in concentrationData) {
      final id =
          data['hubTatsCd']?.toString();

      if (id == null || id.isEmpty) {
        continue;
      }

      final value =
          data['cnctrRate'];

      if (value == null) {
        continue;
      }

      final rate =
          double.tryParse(
        value.toString(),
      );

      if (rate == null ||
          rate < 0 ||
          rate > 100) {
        continue;
      }

      concentrationMap
          .putIfAbsent(
            id,
            () => <double>[],
          )
          .add(rate);
    }

    print(
      '매칭 가능한 관광지 수 : '
      '${concentrationMap.length}',
    );

    // ============================================================
    // Center50 관광지별 계산
    // ============================================================

    for (final spot in spots) {
      final spotName =
          spot['hubTatsNm']?.toString() ??
              '이름 없음';

      final spotId =
          spot['hubTatsCd']?.toString();

      print('');
      print('========================================');
      print('SNOB CROWDING 계산');
      print('관광지 : $spotName');
      print('관광지 코드 : $spotId');
      print('========================================');

      // ----------------------------------------------------------
      // 기본값
      // ----------------------------------------------------------

      double averageConcentration = 50.0;
      double crowdingScore = neutralScore;

      // ----------------------------------------------------------
      // 관광지 ID가 있고 집중률 데이터가 있는 경우
      // ----------------------------------------------------------

      if (spotId != null &&
          spotId.isNotEmpty &&
          concentrationMap.containsKey(
            spotId,
          )) {
        final rates =
            concentrationMap[spotId]!;

        if (rates.isNotEmpty) {
          averageConcentration =
              rates.reduce(
                    (a, b) => a + b,
                  ) /
                  rates.length;

          // --------------------------------------------------------
          // Crowding 점수
          //
          // (100 - 집중률) × 0.45
          // --------------------------------------------------------

          crowdingScore =
              (100.0 -
                      averageConcentration) *
                  0.45;

          crowdingScore =
              crowdingScore.clamp(
            0.0,
            maxScore,
          );

          print(
            '집중률 데이터 개수 : '
            '${rates.length}',
          );

          print(
            '30일 평균 관광지 집중률 : '
            '${averageConcentration.toStringAsFixed(2)}',
          );

          print(
            'Crowding 점수 : '
            '${crowdingScore.toStringAsFixed(2)}',
          );
        }
      }

      // ----------------------------------------------------------
      // 데이터가 없는 경우
      // ----------------------------------------------------------

      else {
        print(
          '해당 관광지의 집중률 데이터 없음',
        );

        print(
          '중립값 적용 → Crowding 27.5',
        );
      }

      // ----------------------------------------------------------
      // 결과 추가
      // ----------------------------------------------------------

      results.add(
        SnobCrowdingResult(
          spot: spot,
          averageConcentration:
              averageConcentration,
          crowdingScore:
              crowdingScore,
        ),
      );
    }

    print('');
    print('============================================================');
    print('SNOB CROWDING 종료');
    print('최종 관광지 수 : ${results.length}');
    print('============================================================');

    // ============================================================
    // 정렬하지 않음
    //
    // 최종 SNOB 점수 정렬은
    // snob_final.dart에서 수행한다.
    // ============================================================

    return results;
  }
}
