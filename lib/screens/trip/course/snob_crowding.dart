import '../../../services/congestion_service.dart';

// ================================================================
// Crowding 계산 결과
// ================================================================

class SnobCrowdingResult {
  final Map<String, dynamic> spot;

  // 관광지 집중률 평균
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
        spot['hubTatsNm'] ??
        spot['tAtsNm'] ??
        spot['touristSpotName'] ??
        spot['name'] ??
        spot['title'] ??
        '이름 없음';

    return '''
$name
관광지 집중률 평균 : ${averageConcentration.toStringAsFixed(2)}
Crowding 점수      : ${crowdingScore.toStringAsFixed(2)}
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
//
// (100 - 집중률) × 0.45
//
// 최대 45점
//
// 집중률 데이터가 없는 경우
// → 중립값 50%
// → Crowding 27.5점
//
// ================================================================

class SnobCrowding {
  final CongestionService _service =
      CongestionService();

  // Crowding 최대 점수
  static const double maxScore = 45.0;

  // 집중률 데이터가 없을 때 중립 점수
  static const double neutralScore = 27.5;

  // 기본 집중률
  static const double defaultConcentration = 50.0;


  // ==============================================================
  // 문자열 정리
  // ==============================================================

  String _normalizeName(dynamic value) {
    if (value == null) {
      return '';
    }

    return value
        .toString()
        .trim()
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll(' ', '')
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .replaceAll('\t', '');
  }


  // ==============================================================
  // 관광지 코드 가져오기
  // ==============================================================

  String _getSpotId(
    Map<String, dynamic> spot,
  ) {
    final candidates = [
      spot['hubTatsCd'],
      spot['tAtsCd'],
      spot['tatsCd'],
      spot['touristSpotId'],
      spot['touristSpotCode'],
      spot['contentid'],
      spot['contentId'],
      spot['contentID'],
      spot['id'],
    ];

    for (final value in candidates) {
      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return '';
  }


  // ==============================================================
  // 관광지 이름 가져오기
  // ==============================================================

  String _getSpotName(
    Map<String, dynamic> spot,
  ) {
    final candidates = [
      spot['hubTatsNm'],
      spot['tAtsNm'],
      spot['tatsNm'],
      spot['touristSpotName'],
      spot['touristSpotNm'],
      spot['name'],
      spot['title'],
      spot['spotName'],
    ];

    for (final value in candidates) {
      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return '';
  }


  // ==============================================================
  // 집중률 데이터 관광지 코드 가져오기
  // ==============================================================

  String _getConcentrationId(
    Map<String, dynamic> data,
  ) {
    final candidates = [
      data['hubTatsCd'],
      data['tAtsCd'],
      data['tatsCd'],
      data['touristSpotId'],
      data['touristSpotCode'],
      data['contentid'],
      data['contentId'],
      data['contentID'],
      data['id'],
    ];

    for (final value in candidates) {
      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return '';
  }


  // ==============================================================
  // 집중률 데이터 관광지 이름 가져오기
  // ==============================================================

  String _getConcentrationName(
    Map<String, dynamic> data,
  ) {
    final candidates = [
      data['tAtsNm'],
      data['hubTatsNm'],
      data['tatsNm'],
      data['touristSpotName'],
      data['touristSpotNm'],
      data['name'],
      data['title'],
      data['spotName'],
    ];

    for (final value in candidates) {
      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return '';
  }


  // ==============================================================
  // 집중률 값 가져오기
  // ==============================================================

  double? _getConcentrationRate(
    Map<String, dynamic> data,
  ) {
    final candidates = [
      data['cnctrRate'],
      data['concentrationRate'],
      data['concentration'],
      data['rate'],
    ];

    for (final value in candidates) {
      if (value == null) {
        continue;
      }

      final rate = double.tryParse(
        value.toString().trim(),
      );

      if (rate == null) {
        continue;
      }

      if (rate < 0 || rate > 100) {
        continue;
      }

      return rate;
    }

    return null;
  }


  // ==============================================================
  // 지역 코드 가져오기
  // ==============================================================

  String? _getAreaCode(
    Map<String, dynamic> spot,
  ) {
    final candidates = [
      spot['areaCd'],
      spot['areaCode'],
      spot['areacd'],
    ];

    for (final value in candidates) {
      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return null;
  }


  // ==============================================================
  // 시군구 코드 가져오기
  // ==============================================================

  String? _getSignguCode(
    Map<String, dynamic> spot,
  ) {
    final candidates = [
      spot['signguCd'],
      spot['sigunguCd'],
      spot['signguCode'],
      spot['sigunguCode'],
      spot['sigungu_cd'],
    ];

    for (final value in candidates) {
      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return null;
  }


  // ==============================================================
  // Crowding 계산
  // ==============================================================

  Future<List<SnobCrowdingResult>> calculate(
    List<Map<String, dynamic>> spots,
  ) async {
    final results =
        <SnobCrowdingResult>[];


    // ============================================================
    // 관광지 없음
    // ============================================================

    if (spots.isEmpty) {
      print('');
      print('❌ SNOB CROWDING');
      print('관광지 목록이 비어있습니다.');

      return results;
    }


    // ============================================================
    // 지역 코드 확인
    // ============================================================

    final firstSpot = spots.first;

    final areaCd =
        _getAreaCode(firstSpot);

    final signguCd =
        _getSignguCode(firstSpot);


    if (areaCd == null ||
        areaCd.isEmpty ||
        signguCd == null ||
        signguCd.isEmpty) {
      print('');
      print('❌ SNOB CROWDING 계산 실패');
      print('지역 코드가 없습니다.');
      print('areaCd   : $areaCd');
      print('signguCd : $signguCd');

      print('');
      print('첫 번째 관광지 데이터:');
      print(firstSpot);

      return results;
    }


    // ============================================================
    // 시작 로그
    // ============================================================

    print('');
    print(
      '============================================================',
    );
    print('SNOB CROWDING 시작');
    print('대상 관광지 수 : ${spots.length}');
    print('areaCd         : $areaCd');
    print('signguCd       : $signguCd');
    print(
      '============================================================',
    );


    // ============================================================
    // 관광지 집중률 API 호출
    //
    // 중요:
    // baseYm을 여기서 전달하지 않는다.
    //
    // CongestionService가
    // areaCd + signguCd만 사용해서 API를 호출한다.
    // ============================================================

    List<Map<String, dynamic>>
        concentrationData = [];

    try {
      concentrationData =
          await _service.getCongestion(
        areaCd: areaCd,
        signguCd: signguCd,
      );
    } catch (e) {
      print('');
      print('❌ 관광지 집중률 API 호출 실패');
      print(e);
    }


    // ============================================================
    // API 결과
    // ============================================================

    print('');
    print(
      '============================================================',
    );
    print('📡 집중률 API 결과');
    print(
      '집중률 API 데이터 수 : '
      '${concentrationData.length}',
    );
    print(
      '============================================================',
    );


    // ============================================================
    // CENTER50 관광지 확인
    // ==============================================================

    print('');
    print(
      '============================================================',
    );
    print('🔎 CENTER50 관광지');
    print(
      '============================================================',
    );

    for (final spot in spots) {
      final name =
          _getSpotName(spot);

      final id =
          _getSpotId(spot);

      print(
        'CENTER50 : "$name" | 코드 : "$id"',
      );
    }


    // ============================================================
    // API 관광지 확인
    // ==============================================================

    print('');
    print(
      '============================================================',
    );
    print('🔎 집중률 API 관광지');
    print(
      '============================================================',
    );

    if (concentrationData.isEmpty) {
      print('⚠️ 집중률 API 데이터가 없습니다.');
    }

    for (final data in concentrationData) {
      final name =
          _getConcentrationName(data);

      final id =
          _getConcentrationId(data);

      final rate =
          _getConcentrationRate(data);

      print(
        'API : "$name" '
        '| 코드 : "$id" '
        '| 집중률 : $rate',
      );
    }

    print(
      '============================================================',
    );


    // ============================================================
    // API 첫 번째 데이터 구조
    // ==============================================================

    if (concentrationData.isNotEmpty) {
      print('');
      print(
        '============================================================',
      );
      print('🔎 집중률 API 첫 번째 데이터 구조');
      print(
        '============================================================',
      );

      print(
        concentrationData.first,
      );

      print(
        '============================================================',
      );
    }


    // ============================================================
    // 코드 기반 Map
    // ==============================================================

    final Map<String, List<double>>
        concentrationById = {};


    // ============================================================
    // 이름 기반 Map
    // ==============================================================

    final Map<String, List<double>>
        concentrationByName = {};


    // ============================================================
    // API 데이터 저장
    // ==============================================================

    for (final data in concentrationData) {
      final rate =
          _getConcentrationRate(data);

      if (rate == null) {
        continue;
      }


      // ----------------------------------------------------------
      // 관광지 코드
      // ----------------------------------------------------------

      final id =
          _getConcentrationId(data);

      if (id.isNotEmpty) {
        concentrationById
            .putIfAbsent(
              id,
              () => <double>[],
            )
            .add(rate);
      }


      // ----------------------------------------------------------
      // 관광지 이름
      // ----------------------------------------------------------

      final rawName =
          _getConcentrationName(data);

      final name =
          _normalizeName(rawName);

      if (name.isNotEmpty) {
        concentrationByName
            .putIfAbsent(
              name,
              () => <double>[],
            )
            .add(rate);
      }
    }


    // ============================================================
    // Map 생성 결과
    // ==============================================================

    print('');
    print(
      '============================================================',
    );
    print('📊 집중률 매칭 데이터 준비');
    print(
      '코드로 매칭 가능한 관광지 수 : '
      '${concentrationById.length}',
    );
    print(
      '이름으로 매칭 가능한 관광지 수 : '
      '${concentrationByName.length}',
    );
    print(
      '============================================================',
    );


    // ============================================================
    // CENTER50 관광지별 계산
    // ==============================================================

    for (final spot in spots) {
      final spotName =
          _getSpotName(spot);

      final spotId =
          _getSpotId(spot);

      final normalizedSpotName =
          _normalizeName(spotName);


      print('');
      print(
        '============================================================',
      );
      print('SNOB CROWDING 계산');
      print('관광지 : $spotName');
      print('관광지 코드 : $spotId');
      print('정규화 이름 : $normalizedSpotName');
      print(
        '============================================================',
      );


      // ----------------------------------------------------------
      // 기본값
      // ----------------------------------------------------------

      double averageConcentration =
          defaultConcentration;

      double crowdingScore =
          neutralScore;

      List<double>? matchedRates;

      String matchMethod = '';


      // ==========================================================
      // 1순위 : 관광지 코드
      // ==========================================================

      if (spotId.isNotEmpty) {
        final rates =
            concentrationById[spotId];

        if (rates != null &&
            rates.isNotEmpty) {
          matchedRates = rates;
          matchMethod = '관광지 코드';
        }
      }


      // ==========================================================
      // 2순위 : 관광지 이름
      // ==========================================================

      if ((matchedRates == null ||
              matchedRates.isEmpty) &&
          normalizedSpotName.isNotEmpty) {
        final rates =
            concentrationByName[
                normalizedSpotName];

        if (rates != null &&
            rates.isNotEmpty) {
          matchedRates = rates;
          matchMethod = '관광지 이름';
        }
      }


      // ==========================================================
      // 매칭 성공
      // ==========================================================

      if (matchedRates != null &&
          matchedRates.isNotEmpty) {

        averageConcentration =
            matchedRates.reduce(
                  (a, b) => a + b,
                ) /
                matchedRates.length;


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


        print('');
        print('✅ 집중률 데이터 매칭 성공');
        print('매칭 방식 : $matchMethod');
        print('관광지명 : "$spotName"');
        print('관광지 코드 : "$spotId"');
        print(
          '집중률 데이터 개수 : '
          '${matchedRates.length}',
        );
        print(
          '집중률 : '
          '${matchedRates.map(
            (e) => e.toStringAsFixed(2),
          ).join(', ')}',
        );
        print(
          '평균 관광지 집중률 : '
          '${averageConcentration.toStringAsFixed(2)}',
        );
        print(
          'Crowding 점수 : '
          '${crowdingScore.toStringAsFixed(2)}',
        );
      }


      // ==========================================================
      // 매칭 실패
      // ==========================================================

      else {
        print('');
        print('❌ 해당 관광지의 집중률 데이터 없음');
        print(
          '매칭 시도 관광지명 : "$spotName"',
        );
        print(
          '정규화 이름 : "$normalizedSpotName"',
        );
        print(
          '매칭 시도 관광지 코드 : "$spotId"',
        );

        print('');
        print(
          '중립값 적용 → '
          '집중률 $defaultConcentration '
          '/ Crowding $neutralScore',
        );
      }


      // ==========================================================
      // 결과 저장
      // ==========================================================

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


    // ============================================================
    // 종료
    // ============================================================

    print('');
    print(
      '============================================================',
    );
    print('SNOB CROWDING 종료');
    print(
      '최종 관광지 수 : ${results.length}',
    );
    print(
      '============================================================',
    );


    // 정렬하지 않음
    //
    // 최종 SNOB 점수 정렬은
    // snob_final.dart에서 수행


    return results;
  }
}