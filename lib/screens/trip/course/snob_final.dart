import 'snob_sensitivity.dart';
import 'snob_substitutability.dart';

// ================================================================
// 최종 SNOB 계산 결과
// ================================================================
//
// Crowding         최대 45점
// Sensitivity      최대 20점
// Substitutability 최대 35점
//
// 총 최대 100점
//
// 최종 점수가 높을수록
// SNOB 관점에서 추천하기 좋은 관광지
// ================================================================

class SnobFinalResult {
  final Map<String, dynamic> spot;

  final double crowdingScore;
  final double sensitivityScore;
  final double substitutabilityScore;

  final double averageConcentration;

  final double totalScore;

  const SnobFinalResult({
    required this.spot,
    required this.crowdingScore,
    required this.sensitivityScore,
    required this.substitutabilityScore,
    required this.averageConcentration,
    required this.totalScore,
  });

  @override
  String toString() {
    final String name =
        spot['title'] ??
        spot['name'] ??
        spot['tAtsNm'] ??
        spot['hubTatsNm'] ??
        '이름 없음';

    return '''
$name
Crowding         : ${crowdingScore.toStringAsFixed(2)}
Sensitivity      : ${sensitivityScore.toStringAsFixed(2)}
Substitutability : ${substitutabilityScore.toStringAsFixed(2)}
--------------------------------
평균 집중률       : ${averageConcentration.toStringAsFixed(2)}
SNOB 최종 점수    : ${totalScore.toStringAsFixed(2)}
''';
  }
}

// ================================================================
// 최종 SNOB 계산
// ================================================================

class SnobFinal {
  // ==============================================================
  // 점수 설정
  // ==============================================================

  // Crowding 최대 점수
  static const double maxCrowdingScore = 45.0;

  // 집중률 데이터를 찾지 못했을 때 사용하는 기본 집중률
  static const double defaultConcentration = 50.0;

  // 집중률 데이터를 찾지 못했을 때 사용하는 중립 Crowding 점수
  static const double neutralCrowdingScore = 22.5;

  // ==============================================================
  // Substitutability 계산기
  // ==============================================================
  //
  // SnobSubstitutability의 calculate()가
  // static 메서드가 아니기 때문에 인스턴스로 생성
  // ==============================================================

  final SnobSubstitutability _substitutability =
      SnobSubstitutability();

  // ==============================================================
  // 최종 계산
  // ==============================================================

  Future<List<SnobFinalResult>> calculate(
    List<Map<String, dynamic>> spots,
  ) async {
    print('');
    print('============================================================');
    print('SNOB FINAL 시작');
    print('대상 관광지 수 : ${spots.length}');
    print('============================================================');

    if (spots.isEmpty) {
      print('');
      print('❌ 대상 관광지가 없습니다.');
      return [];
    }

    // ============================================================
    // 1. Crowding 계산
    // ============================================================
    //
    // 이제 snob_crowding.dart를 사용하지 않는다.
    //
    // 이미 SpotMappingService에서 매핑된
    // concentrationRate를 사용한다.
    //
    // 집중률이 낮을수록 높은 점수
    //
    // Crowding 점수:
    //
    // (100 - 집중률) × 0.45
    //
    // 최대 45점
    // ============================================================

    print('');
    print('----------------------------------------');
    print('1. CROWDING 계산');
    print('----------------------------------------');

    final Map<String, _CrowdingData> crowdingMap =
        {};

    for (final spot in spots) {
      final String? id =
          _getSpotId(spot);

      final String spotName =
          _getSpotName(spot);

      if (id == null) {
        print('');
        print(
          '⚠️ contentId가 없어 Crowding 결과를 '
          'ID Map에 저장하지 않습니다.',
        );
        print('관광지 : $spotName');

        continue;
      }

      final double concentration =
          _getConcentration(spot);

      final double crowdingScore =
          _calculateCrowdingScore(
        concentration,
      );

      crowdingMap[id] =
          _CrowdingData(
        averageConcentration:
            concentration,
        crowdingScore:
            crowdingScore,
      );

      print(
        '$spotName'
        ' | 집중률 ${concentration.toStringAsFixed(2)}'
        ' | Crowding ${crowdingScore.toStringAsFixed(2)}',
      );
    }

    // ============================================================
    // 2. Sensitivity 계산
    // ============================================================

    print('');
    print('----------------------------------------');
    print('2. SENSITIVITY 계산');
    print('----------------------------------------');

    final List<SnobSensitivityResult>
        sensitivityResults =
        await SnobSensitivity.calculate(
      spots,
    );

    // ============================================================
    // 3. Substitutability 계산
    // ============================================================

    print('');
    print('----------------------------------------');
    print('3. SUBSTITUTABILITY 계산');
    print('----------------------------------------');

    final List<SnobSubstitutabilityResult>
        substitutabilityResults =
        await _substitutability.calculate(
      spots,
    );

    // ============================================================
    // 4. Sensitivity 결과 Map
    // ============================================================
    //
    // 관광지 식별자는 contentId 사용
    // ==============================================================

    final Map<String, SnobSensitivityResult>
        sensitivityMap = {};

    for (final result in sensitivityResults) {
      final String? id =
          _getSpotId(result.spot);

      if (id != null) {
        sensitivityMap[id] = result;
      }
    }

    // ============================================================
    // 5. Substitutability 결과 Map
    // ============================================================

    final Map<String, SnobSubstitutabilityResult>
        substitutabilityMap = {};

    for (final result in substitutabilityResults) {
      final String? id =
          _getSpotId(result.spot);

      if (id != null) {
        substitutabilityMap[id] = result;
      }
    }

    // ============================================================
    // 6. 최종 결과 생성
    // ============================================================

    final List<SnobFinalResult> results = [];

    for (final spot in spots) {
      final String? id =
          _getSpotId(spot);

      final String spotName =
          _getSpotName(spot);

      // ----------------------------------------------------------
      // contentId가 없으면 제외
      // ----------------------------------------------------------

      if (id == null) {
        print('');
        print(
          '⚠️ contentId가 없어 최종 계산에서 제외: '
          '$spotName',
        );

        continue;
      }

      // ----------------------------------------------------------
      // 각 지표 결과 가져오기
      // ----------------------------------------------------------

      final _CrowdingData? crowding =
          crowdingMap[id];

      final SnobSensitivityResult?
          sensitivity =
          sensitivityMap[id];

      final SnobSubstitutabilityResult?
          substitutability =
          substitutabilityMap[id];

      // ----------------------------------------------------------
      // ID MATCH 확인
      // ----------------------------------------------------------

      print('');
      print(
        '================ ID MATCH 확인 ================',
      );

      print(
        '관광지: $spotName',
      );

      print(
        'contentId: "$id"',
      );

      print(
        'Crowding: '
        '${crowding != null ? "MATCH" : "⚠️ NO MATCH"}',
      );

      print(
        'Sensitivity: '
        '${sensitivity != null ? "MATCH" : "⚠️ NO MATCH"}',
      );

      print(
        'Substitutability: '
        '${substitutability != null ? "MATCH" : "⚠️ NO MATCH"}',
      );

      print(
        '===============================================',
      );

      // ----------------------------------------------------------
      // 점수
      // ----------------------------------------------------------

      final double crowdingScore =
          crowding?.crowdingScore ??
              neutralCrowdingScore;

      final double sensitivityScore =
          sensitivity?.sensitivityScore ??
              0.0;

      final double substitutabilityScore =
          substitutability
                  ?.substitutabilityScore ??
              0.0;

      final double averageConcentration =
          crowding?.averageConcentration ??
              defaultConcentration;

      // ----------------------------------------------------------
      // 최종 SNOB 점수
      //
      // 최대:
      // 45 + 20 + 35 = 100
      // ----------------------------------------------------------

      final double totalScore =
          crowdingScore +
          sensitivityScore +
          substitutabilityScore;

      results.add(
        SnobFinalResult(
          spot: spot,
          crowdingScore:
              crowdingScore,
          sensitivityScore:
              sensitivityScore,
          substitutabilityScore:
              substitutabilityScore,
          averageConcentration:
              averageConcentration,
          totalScore:
              totalScore,
        ),
      );
    }

    // ============================================================
    // 7. 최종 점수 내림차순 정렬
    // ============================================================

    results.sort(
      (a, b) =>
          b.totalScore.compareTo(
        a.totalScore,
      ),
    );

    // ============================================================
    // 8. 최종 결과 출력
    // ============================================================

    print('');
    print('============================================================');
    print('SNOB FINAL 결과');
    print('============================================================');

    for (int i = 0;
        i < results.length;
        i++) {
      final SnobFinalResult result =
          results[i];

      print(
        '[${i + 1}] '
        '${_getSpotName(result.spot)}'
        ' | 집중률 '
        '${result.averageConcentration.toStringAsFixed(2)}'
        ' | Crowding '
        '${result.crowdingScore.toStringAsFixed(2)}'
        ' | Sensitivity '
        '${result.sensitivityScore.toStringAsFixed(2)}'
        ' | Substitutability '
        '${result.substitutabilityScore.toStringAsFixed(2)}'
        ' | SNOB '
        '${result.totalScore.toStringAsFixed(2)}',
      );
    }

    print('');
    print('============================================================');
    print('SNOB FINAL 종료');
    print(
      '최종 관광지 수 : ${results.length}',
    );
    print('============================================================');

    return results;
  }

  // ==============================================================
  // 관광지 ID
  // ==============================================================
  //
  // TourAPI contentId 사용
  // ==============================================================

  String? _getSpotId(
    Map<String, dynamic> spot,
  ) {
    final dynamic value =
        spot['contentId'];

    if (value == null) {
      return null;
    }

    final String id =
        value.toString().trim();

    if (id.isEmpty) {
      return null;
    }

    return id;
  }

  // ==============================================================
  // 관광지 이름
  // ==============================================================

  String _getSpotName(
    Map<String, dynamic> spot,
  ) {
    final List<dynamic> candidates = [
      spot['title'],
      spot['name'],
      spot['tAtsNm'],
      spot['spotName'],
      spot['hubTatsNm'],
    ];

    for (final value in candidates) {
      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return '이름 없음';
  }

  // ==============================================================
  // 집중률
  // ==============================================================
  //
  // SpotMappingService에서 들어온
  // concentrationRate를 가장 우선해서 사용
  //
  // 없을 경우:
  // concentration
  // cnctrRate
  //
  // 모두 없으면 50
  // ==============================================================

  double _getConcentration(
    Map<String, dynamic> spot,
  ) {
    final List<dynamic> candidates = [
      spot['concentrationRate'],
      spot['concentration'],
      spot['cnctrRate'],
    ];

    for (final value in candidates) {
      final double? parsed =
          _toDouble(value);

      if (parsed != null &&
          parsed >= 0 &&
          parsed <= 100) {
        return parsed;
      }
    }

    return defaultConcentration;
  }

  // ==============================================================
  // 집중률 → Crowding 점수
  // ==============================================================
  //
  // 집중률이 낮을수록 높은 점수
  //
  // 0%   → 45점
  // 50%  → 22.5점
  // 100% → 0점
  // ==============================================================

  double _calculateCrowdingScore(
    double concentration,
  ) {
    final double score =
        (100.0 - concentration) *
            0.45;

    return score.clamp(
      0.0,
      maxCrowdingScore,
    );
  }

  // ==============================================================
  // 숫자 변환
  // ==============================================================

  double? _toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    final String text =
        value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return double.tryParse(text);
  }
}

// ================================================================
// Crowding 내부 데이터
// ================================================================

class _CrowdingData {
  final double averageConcentration;
  final double crowdingScore;

  const _CrowdingData({
    required this.averageConcentration,
    required this.crowdingScore,
  });
}