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
  /// SNOB 점수:
  ///     100 - 평균 혼잡도
  ///
  /// 혼잡도가 낮을수록 SNOB 점수가 높다.
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

        // 해당 관광지의 30일 예측 혼잡도 조회
        final congestionData = await _service.getCongestion(
          areaCd: areaCd,
          signguCd: signguCd,
          touristSpotName: spotName,
          numOfRows: 30,
        );

        if (congestionData.isEmpty) {
          print('혼잡도 데이터 없음: $spotName');
          continue;
        }

        // cnctrRate 숫자만 추출
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

        if (rates.isEmpty) {
          print('유효한 혼잡도 데이터 없음: $spotName');
          continue;
        }

        // 실제 반환된 데이터 개수를 기준으로 평균 계산
        final averageCongestion =
            rates.reduce((a, b) => a + b) / rates.length;

        // 혼잡도가 낮을수록 SNOB 점수가 높도록 계산
        final snobScore =
            (100.0 - averageCongestion).clamp(0.0, 100.0);

        results.add(
          SnobCongestionResult(
            spot: spot,
            averageCongestion: averageCongestion,
            snobScore: snobScore,
          ),
        );

        print('데이터 개수 : ${rates.length}');
        print(
          '30일 평균 혼잡도 : '
          '${averageCongestion.toStringAsFixed(2)}',
        );
        print(
          'SNOB 점수 : '
          '${snobScore.toStringAsFixed(2)}',
        );
      } catch (e) {
        print('혼잡도 계산 실패: $spotName');
        print(e);
      }
    }

    // SNOB 점수가 높은 관광지부터 정렬
    results.sort(
      (a, b) => b.snobScore.compareTo(a.snobScore),
    );

    return results;
  }
}