import '../../../services/congestion_service.dart';

// ================================================================
// Crowding 계산 결과
// ================================================================

class SnobCrowdingResult {
  final Map<String, dynamic> spot;

  // 30일 평균 관광지 집중률
  // 데이터가 없으면 null
  final double? averageConcentration;

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
30일 평균 관광지 집중률 : ${
      averageConcentration != null
          ? averageConcentration!.toStringAsFixed(2)
          : '데이터 없음'
    }
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
// = 27.5점 (중간값)
//
// ================================================================

class SnobCrowding {
  final CongestionService _service =
      CongestionService();

  static const double maxScore = 45.0;

  // 데이터가 없을 때 사용할 중립값
  static const double neutralScore = 27.5;

  /// center50에서 받은 관광지 목록의
  /// 관광지 집중률을 이용하여 Crowding 점수를 계산한다.
  Future<List<SnobCrowdingResult>> calculate(
    List<Map<String, dynamic>> spots,
  ) async {
    final results =
        <SnobCrowdingResult>[];

    for (final spot in spots) {
      final areaCd =
          spot['areaCd']?.toString();

      final signguCd =
          spot['signguCd']?.toString();

      final spotName =
          spot['hubTatsNm']?.toString();

      // ------------------------------------------------------------
      // 관광지 기본 정보 확인
      // ------------------------------------------------------------

      if (areaCd == null ||
          signguCd == null ||
          spotName == null ||
          spotName.isEmpty) {
        print(
          '관광지 정보가 부족하여 건너뜀: $spot',
        );

        continue;
      }

      try {
        print('');
        print('========================================');
        print('SNOB CROWDING 계산');
        print('관광지 : $spotName');
        print('========================================');

        // ----------------------------------------------------------
        // 기본값
        // ----------------------------------------------------------
        //
        // 관광지 집중률 데이터를 가져오지 못하면
        // Crowding 27.5점을 바로 적용한다.
        //
        // averageConcentration은
        // 데이터가 없을 경우 null로 둔다.
        // ----------------------------------------------------------

        double? averageConcentration;
        double crowdingScore = neutralScore;

        // ----------------------------------------------------------
        // 관광지 집중률 API 조회
        //
        // 향후 30일 데이터
        // ----------------------------------------------------------

        final concentrationData =
            await _service.getCongestion(
          areaCd: areaCd,
          signguCd: signguCd,
          touristSpotName: spotName,
          numOfRows: 30,
        );

        // ----------------------------------------------------------
        // 관광지 집중률 데이터가 있는 경우
        // ----------------------------------------------------------

        if (concentrationData.isNotEmpty) {
          final rates =
              concentrationData
                  .map((data) {
                    // API의 관광지 집중률 값
                    final value =
                        data['cnctrRate'];

                    if (value == null) {
                      return null;
                    }

                    return double.tryParse(
                      value.toString(),
                    );
                  })
                  .whereType<double>()
                  .where(
                    (value) =>
                        value >= 0 &&
                        value <= 100,
                  )
                  .toList();

          // --------------------------------------------------------
          // 유효한 집중률 데이터가 있는 경우
          // --------------------------------------------------------

          if (rates.isNotEmpty) {
            averageConcentration =
                rates.reduce(
                      (a, b) => a + b,
                    ) /
                    rates.length;

            // ------------------------------------------------------
            // Crowding 점수
            //
            // (100 - 관광지 집중률) × 0.45
            //
            // 최대 45점
            // ------------------------------------------------------

            crowdingScore =
                (100.0 -
                        averageConcentration!) *
                    0.45;

            // 혹시 모를 범위 초과 방지
            crowdingScore =
                crowdingScore.clamp(
              0.0,
              maxScore,
            );

            print(
              '데이터 개수 : ${rates.length}',
            );

            print(
              '30일 평균 관광지 집중률 : '
              '${averageConcentration!.toStringAsFixed(2)}',
            );

            print(
              'Crowding 점수 : '
              '${crowdingScore.toStringAsFixed(2)}',
            );
          }

          // --------------------------------------------------------
          // 데이터는 있지만 유효한 집중률이 없는 경우
          // --------------------------------------------------------

          else {
            print(
              '유효한 관광지 집중률 데이터 없음',
            );

            print(
              '중립값 적용 → Crowding 27.5',
            );
          }
        }

        // ----------------------------------------------------------
        // 관광지 집중률 데이터 자체가 없는 경우
        // ----------------------------------------------------------

        else {
          print(
            '관광지 집중률 데이터 없음',
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
      } catch (e) {
        // ----------------------------------------------------------
        // API 오류가 발생해도 관광지는 유지
        // ----------------------------------------------------------

        print(
          'Crowding 계산 실패: $spotName',
        );

        print(e);

        results.add(
          SnobCrowdingResult(
            spot: spot,
            averageConcentration: null,
            crowdingScore: neutralScore,
          ),
        );
      }
    }

    return results;
  }
}