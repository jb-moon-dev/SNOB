import '../../../services/congestion_service.dart';

class SnobCrowdingResult {
  final Map<String, dynamic> spot;

  // 관광지 집중률 (%)
  final double crowdingRate;

  // Crowding 점수 (35점 만점)
  final double crowdingScore;

  const SnobCrowdingResult({
    required this.spot,
    required this.crowdingRate,
    required this.crowdingScore,
  });

  @override
  String toString() {
    final name = spot['hubTatsNm'] ?? '이름 없음';

    return '''
$name
관광지 집중률 : ${crowdingRate.toStringAsFixed(2)}%
Crowding 점수 : ${crowdingScore.toStringAsFixed(2)} / 35
''';
  }
}


class SnobCrowding {
  final CongestionService _service = CongestionService();

  // ============================================================
  // Crowding 점수 계산
  //
  // 관광지 집중률이 낮을수록 추천 점수가 높아진다.
  //
  // 관광지 집중률 0%
  // → 35점
  //
  // 관광지 집중률 50%
  // → 17.5점
  //
  // 관광지 집중률 100%
  // → 0점
  //
  // 혼잡도 데이터가 없는 경우
  // → 중립값 17.5점
  // ============================================================

  Future<List<SnobCrowdingResult>> calculate(
    List<Map<String, dynamic>> spots,
  ) async {
    final results = <SnobCrowdingResult>[];

    for (final spot in spots) {
      final areaCd = spot['areaCd']?.toString();
      final signguCd = spot['signguCd']?.toString();
      final spotName = spot['hubTatsNm']?.toString();

      if (areaCd == null ||
          signguCd == null ||
          spotName == null ||
          spotName.isEmpty) {
        print('관광지 정보가 부족하여 건너뜀: $spot');
        continue;
      }

      try {
        print('');
        print('========================================');
        print('SNOB CROWDING 계산');
        print('관광지 : $spotName');
        print('========================================');

        // --------------------------------------------------------
        // 기본값
        //
        // 데이터가 없으면 중립값
        // 50% → 17.5점
        // --------------------------------------------------------

        double crowdingRate = 50.0;
        double crowdingScore = 17.5;

        // --------------------------------------------------------
        // 관광지 집중률 조회
        // 향후 30일 데이터
        // --------------------------------------------------------

        final congestionData =
            await _service.getCongestion(
          areaCd: areaCd,
          signguCd: signguCd,
          touristSpotName: spotName,
          numOfRows: 30,
        );

        // --------------------------------------------------------
        // 유효한 관광지 집중률 추출
        // --------------------------------------------------------

        if (congestionData.isNotEmpty) {
          final rates = congestionData
              .map((data) {
                final value = data['cnctrRate'];

                if (value == null) {
                  return null;
                }

                return double.tryParse(
                  value.toString(),
                );
              })
              .whereType<double>()
              .toList();

          // ------------------------------------------------------
          // 30일 평균 관광지 집중률
          // ------------------------------------------------------

          if (rates.isNotEmpty) {
            crowdingRate =
                rates.reduce((a, b) => a + b) /
                    rates.length;

            // ----------------------------------------------------
            // Crowding 점수
            //
            // (100 - 관광지 집중률) × 0.35
            //
            // 최대 35점
            // ----------------------------------------------------

            crowdingScore =
                (100.0 - crowdingRate) * 0.35;

            crowdingScore =
                crowdingScore.clamp(0.0, 35.0);

            print(
              '데이터 개수 : ${rates.length}',
            );

            print(
              '30일 평균 관광지 집중률 : '
              '${crowdingRate.toStringAsFixed(2)}%',
            );

            print(
              'Crowding 점수 : '
              '${crowdingScore.toStringAsFixed(2)} / 35',
            );
          } else {
            print('유효한 관광지 집중률 데이터 없음');
            print(
              '중립값 적용 → '
              '집중률 50% / Crowding 17.5점',
            );
          }
        } else {
          print('관광지 집중률 데이터 없음');
          print(
            '중립값 적용 → '
            '집중률 50% / Crowding 17.5점',
          );
        }

        // --------------------------------------------------------
        // 결과 추가
        // --------------------------------------------------------

        results.add(
          SnobCrowdingResult(
            spot: spot,
            crowdingRate: crowdingRate,
            crowdingScore: crowdingScore,
          ),
        );
      } catch (e) {
        print('Crowding 계산 실패: $spotName');
        print(e);

        // --------------------------------------------------------
        // API 오류가 발생해도 관광지는 유지
        // --------------------------------------------------------

        results.add(
          SnobCrowdingResult(
            spot: spot,
            crowdingRate: 50.0,
            crowdingScore: 17.5,
          ),
        );
      }
    }

    return results;
  }
}