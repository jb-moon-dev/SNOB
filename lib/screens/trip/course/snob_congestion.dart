import '../../../services/congestion_service.dart';

class SnobCongestionResult {
  final Map<String, dynamic> spot;
  final double averageCongestion;
  final double snobScore;

  const SnobCongestionResult({
    required this.spot,
    required this.averageCongestion,
    required this.snobScore,
  });

  @override
  String toString() {
    final name = spot['hubTatsNm'] ?? '이름 없음';

    return '''
$name
30일 평균 혼잡도 : ${averageCongestion.toStringAsFixed(2)}
SNOB 점수        : ${snobScore.toStringAsFixed(2)}
''';
  }
}

class SnobCongestion {
  final CongestionService _service = CongestionService();

  /// center50.dart에서 받은 관광지 50개의
  /// 30일 평균 혼잡도를 계산하고
  /// SNOB 점수를 계산한다.
  ///
  /// 혼잡도 데이터가 없는 관광지도 목록에서 제외하지 않는다.
  ///
  /// 혼잡도 데이터가 있는 경우:
  ///     SNOB 점수 = 100 - 평균 혼잡도
  ///
  /// 혼잡도 데이터가 없는 경우:
  ///     평균 혼잡도 = 50
  ///     SNOB 점수 = 50
  ///
  /// 즉, 혼잡도 정보가 없는 관광지는 중립적인 점수를 부여한다.
  Future<List<SnobCongestionResult>> calculate(
    List<Map<String, dynamic>> spots,
  ) async {
    final results = <SnobCongestionResult>[];

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
        print('SNOB 혼잡도 계산');
        print('관광지 : $spotName');
        print('========================================');

        // 기본값
        double averageCongestion = 50.0;
        double snobScore = 50.0;

        // 해당 관광지의 30일 예측 혼잡도 조회
        final congestionData = await _service.getCongestion(
          areaCd: areaCd,
          signguCd: signguCd,
          touristSpotName: spotName,
          numOfRows: 30,
        );

        // 혼잡도 데이터가 있는 경우
        if (congestionData.isNotEmpty) {
          final rates = congestionData
              .map((data) {
                final value = data['cnctrRate'];

                if (value == null) {
                  return null;
                }

                return double.tryParse(value.toString());
              })
              .whereType<double>()
              .toList();

          // 유효한 혼잡도 데이터가 있는 경우에만 계산
          if (rates.isNotEmpty) {
            averageCongestion =
                rates.reduce((a, b) => a + b) / rates.length;

            // 혼잡도가 낮을수록 SNOB 점수가 높도록 계산
            snobScore =
                (100.0 - averageCongestion).clamp(0.0, 100.0);

            print('데이터 개수 : ${rates.length}');
            print(
              '30일 평균 혼잡도 : '
              '${averageCongestion.toStringAsFixed(2)}',
            );
            print(
              'SNOB 점수 : '
              '${snobScore.toStringAsFixed(2)}',
            );
          } else {
            print('유효한 혼잡도 데이터 없음');
            print('중립값 적용 → 혼잡도 50 / SNOB 50');
          }
        } else {
          print('혼잡도 데이터 없음');
          print('중립값 적용 → 혼잡도 50 / SNOB 50');
        }

        // ⭐ 혼잡도 데이터가 없어도 관광지는 결과에 추가
        results.add(
          SnobCongestionResult(
            spot: spot,
            averageCongestion: averageCongestion,
            snobScore: snobScore,
          ),
        );
      } catch (e) {
        print('혼잡도 계산 실패: $spotName');
        print(e);

        // ⭐ API 오류가 발생해도 관광지는 목록에 유지
        results.add(
          SnobCongestionResult(
            spot: spot,
            averageCongestion: 50.0,
            snobScore: 50.0,
          ),
        );
      }
    }

    // SNOB 점수가 높은 관광지부터 정렬
    results.sort(
      (a, b) => b.snobScore.compareTo(a.snobScore),
    );

    return results;
  }
}