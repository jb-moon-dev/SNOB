import 'snob_crowding.dart';
import 'snob_sensitivity.dart';
import 'snob_substitutability.dart';

// ================================================================
// 최종 SNOB 계산 결과
// ================================================================
//
// Crowding        최대 45점
// Sensitivity     최대 20점
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

  final double averageCongestion;

  final double totalScore;

  const SnobFinalResult({
    required this.spot,
    required this.crowdingScore,
    required this.sensitivityScore,
    required this.substitutabilityScore,
    required this.averageCongestion,
    required this.totalScore,
  });

  @override
  String toString() {
    final name =
        spot['hubTatsNm'] ?? '이름 없음';

    return '''
$name
Crowding          : ${crowdingScore.toStringAsFixed(2)}
Sensitivity       : ${sensitivityScore.toStringAsFixed(2)}
Substitutability  : ${substitutabilityScore.toStringAsFixed(2)}
--------------------------------
SNOB 최종 점수     : ${totalScore.toStringAsFixed(2)}
''';
  }
}


// ================================================================
// 최종 SNOB 계산
// ================================================================

class SnobFinal {
  // ==============================================================
  // 세 가지 SNOB 지표 계산기
  // ==============================================================

  final SnobCrowding _crowding =
      SnobCrowding();

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


    // ============================================================
    // 1. Crowding 계산
    // ============================================================

    print('');
    print('----------------------------------------');
    print('1. CROWDING 계산');
    print('----------------------------------------');

    final crowdingResults =
        await _crowding.calculate(spots);


    // ============================================================
    // 2. Sensitivity 계산
    // ============================================================

    print('');
    print('----------------------------------------');
    print('2. SENSITIVITY 계산');
    print('----------------------------------------');

    final sensitivityResults =
        await SnobSensitivity.calculate(spots);


    // ============================================================
    // 3. Substitutability 계산
    // ============================================================

    print('');
    print('----------------------------------------');
    print('3. SUBSTITUTABILITY 계산');
    print('----------------------------------------');

    final substitutabilityResults =
        await _substitutability.calculate(spots);


    // ============================================================
    // 4. 관광지별 결과를 ID 기준으로 Map에 저장
    // ============================================================
    //
    // 세 계산 결과가 같은 관광지를 가리키도록
    // hubTatsCd를 기준으로 연결한다.
    //
    // 관광지 이름을 기준으로 연결하면
    // 이름 중복 가능성이 있기 때문에
    // hubTatsCd를 우선 사용한다.
    // ============================================================

    final Map<String, SnobCrowdingResult>
        crowdingMap = {};

    for (final result in crowdingResults) {
      final id =
          result.spot['hubTatsCd']?.toString();

      if (id != null && id.isNotEmpty) {
        crowdingMap[id] = result;
      }
    }


    final Map<String, SnobSensitivityResult>
        sensitivityMap = {};

    for (final result in sensitivityResults) {
      final id =
          result.spot['hubTatsCd']?.toString();

      if (id != null && id.isNotEmpty) {
        sensitivityMap[id] = result;
      }
    }


    final Map<String, SnobSubstitutabilityResult>
        substitutabilityMap = {};

    for (final result in substitutabilityResults) {
      final id =
          result.spot['hubTatsCd']?.toString();

      if (id != null && id.isNotEmpty) {
        substitutabilityMap[id] = result;
      }
    }


    // ============================================================
    // 5. 세 점수 합산
    // ============================================================

    final List<SnobFinalResult> results = [];


    for (final spot in spots) {

      final id =
          spot['hubTatsCd']?.toString();

      if (id == null || id.isEmpty) {
        print(
          '관광지 코드가 없어 최종 계산에서 제외: $spot',
        );

        continue;
      }


      // ----------------------------------------------------------
      // 각 지표 결과 가져오기
      // ----------------------------------------------------------

      final crowding =
          crowdingMap[id];

      final sensitivity =
          sensitivityMap[id];

      final substitutability =
          substitutabilityMap[id];


      // ==========================================================
      // ID MATCH 확인
      // ==========================================================
      //
      // 여기서 세 지표의 결과가
      // 동일한 hubTatsCd를 기준으로
      // 정상적으로 연결되는지 확인한다.
      // ==========================================================

      print('');
      print('================ ID MATCH 확인 ================');
      print('관광지: ${spot['hubTatsNm']}');
      print('ID: "$id"');

      print(
        'Crowding: '
        '${crowding != null ? "MATCH" : "❌ NO MATCH"}',
      );

      print(
        'Sensitivity: '
        '${sensitivity != null ? "MATCH" : "❌ NO MATCH"}',
      );

      print(
        'Substitutability: '
        '${substitutability != null ? "MATCH" : "❌ NO MATCH"}',
      );

      print('===============================================');


      // ----------------------------------------------------------
      // 점수
      //
      // 결과가 없는 경우 0점
      // ----------------------------------------------------------

      final crowdingScore =
          crowding?.crowdingScore ?? 0.0;

      final sensitivityScore =
          sensitivity?.sensitivityScore ?? 0.0;

      final substitutabilityScore =
          substitutability
                  ?.substitutabilityScore ??
              0.0;


      // ----------------------------------------------------------
      // 최종 SNOB 점수
      //
      // 45 + 20 + 35 = 최대 100점
      // ----------------------------------------------------------

      final totalScore =
          crowdingScore +
          sensitivityScore +
          substitutabilityScore;


      results.add(
        SnobFinalResult(
          spot: spot,
          crowdingScore: crowdingScore,
          sensitivityScore: sensitivityScore,
          substitutabilityScore:
              substitutabilityScore,
          averageCongestion:
              crowding?.averageConcentration ?? 50.0,
          totalScore: totalScore,
        ),
      );
    }


    // ============================================================
    // 6. 최종 점수 내림차순 정렬
    // ============================================================
    //
    // 높은 SNOB 점수
    //        ↓
    // 낮은 SNOB 점수
    // ============================================================

    results.sort(
      (a, b) =>
          b.totalScore.compareTo(
        a.totalScore,
      ),
    );


    // ============================================================
    // 7. 최종 결과 출력
    // ============================================================

    print('');
    print('============================================================');
    print('SNOB FINAL 결과');
    print('============================================================');

    for (int i = 0; i < results.length; i++) {

      final result =
          results[i];

      final name =
          result.spot['hubTatsNm'] ??
              '이름 없음';

      print(
        '[${i + 1}] $name '
        '| Crowding ${result.crowdingScore.toStringAsFixed(2)}'
        ' | Sensitivity ${result.sensitivityScore.toStringAsFixed(2)}'
        ' | Substitutability ${result.substitutabilityScore.toStringAsFixed(2)}'
        ' | SNOB ${result.totalScore.toStringAsFixed(2)}',
      );
    }

    print('');
    print('============================================================');
    print('SNOB FINAL 종료');
    print('최종 관광지 수 : ${results.length}');
    print('============================================================');


    return results;
  }
}