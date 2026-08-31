import '../../../services/congestion_service.dart';

// ================================================================
// SNOB Crowding Result
// ================================================================

class SnobCrowdingResult {
  final Map<String, dynamic> spot;

  final double averageConcentration;

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
// SNOB Crowding
// ================================================================

class SnobCrowding {
  final CongestionService _service = CongestionService();

  static const double maxScore = 45.0;

  static const double neutralScore = 27.5;

  static const double defaultConcentration = 50.0;

  // ==============================================================
  // 이름 정규화
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
        .replaceAll('\t', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .toLowerCase();
  }

  // ==============================================================
  // 관광지 이름
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
  // API 관광지 이름
  // ==============================================================

  String _getConcentrationName(
    Map<String, dynamic> data,
  ) {
    final candidates = [
      data['hubTatsNm'],
      data['tAtsNm'],
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
  // 집중률
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
  // 지역 코드
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
  // 시군구 코드
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
  // 문자열 유사도용 정규화
  // ==============================================================

  String _cleanName(String name) {
    return _normalizeName(name)
        .replaceAll('관광지', '')
        .replaceAll('문화관광', '')
        .replaceAll('유원지', '')
        .replaceAll('공원', '');
  }

  // ==============================================================
  // 이름 매칭
  // ==============================================================
  //
  // 우선순위
  //
  // 1. 완전히 동일
  // 2. 한쪽 이름이 다른 쪽에 포함
  // 3. 핵심 이름 포함
  //
  // ==============================================================

  List<double>? _findRatesByName(
    String spotName,
    Map<String, List<double>> concentrationByName,
  ) {
    final normalizedSpotName =
        _normalizeName(spotName);

    if (normalizedSpotName.isEmpty) {
      return null;
    }

    // ------------------------------------------------------------
    // 1. 정확히 일치
    // ------------------------------------------------------------

    final exact =
        concentrationByName[normalizedSpotName];

    if (exact != null && exact.isNotEmpty) {
      print('✅ 이름 정확히 일치');
      return exact;
    }

    // ------------------------------------------------------------
    // 2. 부분 문자열
    // ------------------------------------------------------------

    for (final entry in concentrationByName.entries) {
      final apiName = entry.key;

      if (apiName.contains(normalizedSpotName) ||
          normalizedSpotName.contains(apiName)) {
        print('✅ 이름 부분 일치');
        print('CENTER50 : $normalizedSpotName');
        print('API      : $apiName');

        return entry.value;
      }
    }

    // ------------------------------------------------------------
    // 3. 핵심 이름 비교
    // ------------------------------------------------------------

    final cleanSpotName =
        _cleanName(spotName);

    if (cleanSpotName.isNotEmpty) {
      for (final entry in concentrationByName.entries) {
        final cleanApiName =
            _cleanName(entry.key);

        if (cleanApiName.isEmpty) {
          continue;
        }

        if (cleanApiName.contains(cleanSpotName) ||
            cleanSpotName.contains(cleanApiName)) {
          print('✅ 핵심 이름 일치');
          print('CENTER50 : $cleanSpotName');
          print('API      : $cleanApiName');

          return entry.value;
        }
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
    final results = <SnobCrowdingResult>[];

    if (spots.isEmpty) {
      print('');
      print('❌ SNOB CROWDING');
      print('관광지 목록이 비어있습니다.');
      return results;
    }

    // ============================================================
    // 지역 코드
    // ============================================================

    final firstSpot = spots.first;

    final areaCd = _getAreaCode(firstSpot);

    final signguCd = _getSignguCode(firstSpot);

    if (areaCd == null ||
        signguCd == null ||
        areaCd.isEmpty ||
        signguCd.isEmpty) {
      print('');
      print('❌ SNOB CROWDING 계산 실패');
      print('지역 코드가 없습니다.');
      print('areaCd   : $areaCd');
      print('signguCd : $signguCd');
      print(firstSpot);

      return results;
    }

    // ============================================================
    // API 호출
    // ============================================================

    List<Map<String, dynamic>> concentrationData = [];

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
    print('============================================================');
    print('📡 집중률 API 결과');
    print('============================================================');
    print('areaCd   = "$areaCd"');
    print('signguCd = "$signguCd"');
    print(
      'API 데이터 수 = ${concentrationData.length}',
    );
    print('============================================================');

    // ============================================================
    // CENTER50 관광지
    // ============================================================

    print('');
    print('============================================================');
    print('🔎 CENTER50 관광지');
    print('============================================================');

    for (final spot in spots) {
      final name = _getSpotName(spot);

      print(
        'CENTER50 : "$name"',
      );
    }

    // ============================================================
    // API 관광지
    // ============================================================

    print('');
    print('============================================================');
    print('🔎 집중률 API 관광지');
    print('============================================================');

    for (final data in concentrationData) {
      print(
        'API : "${_getConcentrationName(data)}" '
        '| 집중률 : ${_getConcentrationRate(data)} '
        '| 날짜 : ${data['baseYmd']}',
      );
    }

    // ============================================================
    // 이름 Map
    // ============================================================

    final Map<String, List<double>>
        concentrationByName = {};

    for (final data in concentrationData) {
      final rate =
          _getConcentrationRate(data);

      if (rate == null) {
        continue;
      }

      final name =
          _normalizeName(
        _getConcentrationName(data),
      );

      if (name.isEmpty) {
        continue;
      }

      concentrationByName
          .putIfAbsent(
            name,
            () => <double>[],
          )
          .add(rate);
    }

    // ============================================================
    // Map 확인
    // ============================================================

    print('');
    print('============================================================');
    print('📊 이름 기반 집중률 데이터');
    print('============================================================');

    print(
      'API 관광지 이름 수 = '
      '${concentrationByName.length}',
    );

    for (final name
        in concentrationByName.keys.take(20)) {
      print(
        'API 이름 : "$name"',
      );
    }

    print('============================================================');

    // ============================================================
    // 관광지별 계산
    // ============================================================

    for (final spot in spots) {
      final spotName =
          _getSpotName(spot);

      final normalizedSpotName =
          _normalizeName(spotName);

      print('');
      print('============================================================');
      print('🎯 SNOB CROWDING 계산');
      print('============================================================');
      print('CENTER50 관광지 : "$spotName"');
      print('정규화 이름     : "$normalizedSpotName"');
      print('============================================================');

      double averageConcentration =
          defaultConcentration;

      double crowdingScore =
          neutralScore;

      List<double>? matchedRates;

      String matchMethod = '중립값';

      // ==========================================================
      // 이름으로 매칭
      // ==========================================================

      matchedRates = _findRatesByName(
        spotName,
        concentrationByName,
      );

      if (matchedRates != null &&
          matchedRates.isNotEmpty) {
        matchMethod = '이름';
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

        crowdingScore =
            (100.0 - averageConcentration) *
                0.45;

        crowdingScore =
            crowdingScore.clamp(
          0.0,
          maxScore,
        );

        print('');
        print('✅ 집중률 데이터 매칭 성공');
        print('매칭 방식 : $matchMethod');
        print('관광지    : "$spotName"');
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
          '평균 집중률 : '
          '${averageConcentration.toStringAsFixed(2)}',
        );

        print(
          'Crowding : '
          '${crowdingScore.toStringAsFixed(2)}',
        );
      }

      // ==========================================================
      // 매칭 실패
      // ==========================================================

      else {
        print('');
        print('❌ 집중률 데이터 매칭 실패');

        print(
          'CENTER50 이름 : "$spotName"',
        );

        print(
          '정규화 이름 : "$normalizedSpotName"',
        );

        print('');
        print('🔍 가장 비슷한 API 이름');

        final similarNames =
            concentrationByName.keys
                .where(
                  (name) {
                    final cleanApi =
                        _cleanName(name);

                    final cleanSpot =
                        _cleanName(spotName);

                    return name.contains(
                          normalizedSpotName,
                        ) ||
                        normalizedSpotName.contains(
                          name,
                        ) ||
                        (cleanSpot.isNotEmpty &&
                            (cleanApi.contains(
                                  cleanSpot,
                                ) ||
                                cleanSpot.contains(
                                  cleanApi,
                                )));
                  },
                )
                .take(10)
                .toList();

        if (similarNames.isEmpty) {
          print(
            '비슷한 이름도 찾지 못했습니다.',
          );
        } else {
          for (final name in similarNames) {
            print(
              '  → "$name"',
            );
          }
        }

        print('');
        print('⚠️ 중립값 적용');
        print(
          '집중률 = $defaultConcentration',
        );
        print(
          'Crowding = $neutralScore',
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
    print('============================================================');
    print('🏁 SNOB CROWDING 종료');
    print(
      '최종 관광지 수 : ${results.length}',
    );
    print('============================================================');

    return results;
  }
}