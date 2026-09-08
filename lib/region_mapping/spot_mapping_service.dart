import '../snob/tourism_spot.dart';
import 'snob_spot.dart';

class SpotMappingService {
  // ============================================================
  // 매칭 결과
  // ============================================================

  static const int exactMatchScore = 100;
  static const int normalizedMatchScore = 90;
  static const int simplifiedMatchScore = 80;
  static const int regionMatchBonus = 20;

  // ============================================================
  // 관광지 이름 정규화
  // ============================================================
  //
  // 목적:
  //
  // "경복궁"
  // "경복궁 "
  // "경 복 궁"
  // "경복궁(사적)"
  //
  // 등의 차이를 줄이기 위한 전처리
  // ============================================================

  static String normalizeName(String name) {
    String result = name.trim().toLowerCase();

    // 공백 제거
    result = result.replaceAll(RegExp(r'\s+'), '');

    // 특수문자 제거
    result = result.replaceAll(
      RegExp(r'[^\p{L}\p{N}]', unicode: true),
      '',
    );

    return result;
  }

  // ============================================================
  // 괄호 안의 부가 정보 제거
  // ============================================================
  //
  // 예:
  //
  // "경복궁(사적)" → "경복궁"
  // "남산(서울)"   → "남산"
  //
  // ============================================================

  static String simplifyName(String name) {
    String result = name.trim();

    // 괄호와 괄호 안 내용 제거
    result = result.replaceAll(
      RegExp(r'\([^)]*\)'),
      '',
    );

    result = result.replaceAll(
      RegExp(r'\[[^\]]*\]'),
      '',
    );

    result = result.replaceAll(
      RegExp(r'\{[^}]*\}'),
      '',
    );

    return normalizeName(result);
  }

  // ============================================================
  // 숫자 변환
  // ============================================================

  static double? _parseDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    final String text = value
        .toString()
        .trim()
        .replaceAll(',', '');

    return double.tryParse(text);
  }

  // ============================================================
  // 문자열 비교
  // ============================================================

  static bool _isSameName(
    String tourismName,
    String congestionName,
  ) {
    final String tourismNormalized =
        normalizeName(tourismName);

    final String congestionNormalized =
        normalizeName(congestionName);

    return tourismNormalized ==
        congestionNormalized;
  }

  // ============================================================
  // 간소화된 이름 비교
  // ============================================================

  static bool _isSameSimplifiedName(
    String tourismName,
    String congestionName,
  ) {
    final String tourismSimplified =
        simplifyName(tourismName);

    final String congestionSimplified =
        simplifyName(congestionName);

    return tourismSimplified ==
        congestionSimplified;
  }

  // ============================================================
  // 지역 코드 비교
  // ============================================================
  //
  // 집중률 API의 signguCd와
  // TourAPI의 lDongSignguCd 비교
  //
  // 행정구역 개편 때문에 코드가 다를 수 있으므로
  // "보조 점수"로만 사용한다.
  // ============================================================

  static bool _isSameRegion(
    TourismSpot spot,
    Map<String, dynamic> congestion,
  ) {
    final String tourismRegion =
        spot.lDongRegnCd.trim();

    final String tourismSigungu =
        spot.lDongSignguCd.trim();

    final String congestionRegion =
        congestion['areaCd']?.toString().trim() ?? '';

    final String congestionSigungu =
        congestion['signguCd']?.toString().trim() ?? '';

    if (tourismRegion.isEmpty ||
        congestionRegion.isEmpty) {
      return false;
    }

    if (tourismRegion != congestionRegion) {
      return false;
    }

    if (tourismSigungu.isEmpty ||
        congestionSigungu.isEmpty) {
      return true;
    }

    return tourismSigungu == congestionSigungu;
  }

  // ============================================================
  // 매칭 점수 계산
  // ============================================================

  static int _calculateMatchScore({
    required TourismSpot tourismSpot,
    required Map<String, dynamic> congestion,
  }) {
    final String tourismName =
        tourismSpot.title.trim();

    final String congestionName =
        congestion['tAtsNm']?.toString().trim() ?? '';

    if (tourismName.isEmpty ||
        congestionName.isEmpty) {
      return 0;
    }

    // ----------------------------------------------------------
    // 1. 완전 일치
    // ----------------------------------------------------------

    if (tourismName == congestionName) {
      int score = exactMatchScore;

      if (_isSameRegion(
        tourismSpot,
        congestion,
      )) {
        score += regionMatchBonus;
      }

      return score;
    }

    // ----------------------------------------------------------
    // 2. 정규화 후 일치
    // ----------------------------------------------------------

    if (_isSameName(
      tourismName,
      congestionName,
    )) {
      int score = normalizedMatchScore;

      if (_isSameRegion(
        tourismSpot,
        congestion,
      )) {
        score += regionMatchBonus;
      }

      return score;
    }

    // ----------------------------------------------------------
    // 3. 괄호/부가정보 제거 후 일치
    // ----------------------------------------------------------

    if (_isSameSimplifiedName(
      tourismName,
      congestionName,
    )) {
      int score = simplifiedMatchScore;

      if (_isSameRegion(
        tourismSpot,
        congestion,
      )) {
        score += regionMatchBonus;
      }

      return score;
    }

    return 0;
  }

  // ============================================================
  // 가장 적합한 집중률 데이터 찾기
  // ============================================================

  static Map<String, dynamic>? _findBestMatch({
    required TourismSpot tourismSpot,
    required List<Map<String, dynamic>> congestionData,
  }) {
    Map<String, dynamic>? bestMatch;
    int bestScore = 0;

    for (final Map<String, dynamic> congestion
        in congestionData) {
      final int score = _calculateMatchScore(
        tourismSpot: tourismSpot,
        congestion: congestion,
      );

      if (score > bestScore) {
        bestScore = score;
        bestMatch = congestion;
      }
    }

    return bestMatch;
  }

  // ============================================================
  // 집중률 데이터 → SNOB 점수
  // ============================================================

  static double? calculateSnobScore(
    double? concentrationRate,
  ) {
    if (concentrationRate == null) {
      return null;
    }

    final double score =
        100 - concentrationRate;

    return score.clamp(0, 100).toDouble();
  }

  // ============================================================
  // 집중률 데이터 Map 생성
  // ============================================================
  //
  // 동일한 관광지명이 여러 번 나올 수 있기 때문에
  // Map<String, List<...>> 구조 사용
  //
  // 예:
  //
  // "남산"
  //   ├─ 데이터 1
  //   ├─ 데이터 2
  //   └─ 데이터 3
  //
  // ============================================================

  static Map<String, List<Map<String, dynamic>>>
      _createCongestionIndex(
    List<Map<String, dynamic>> congestionData,
  ) {
    final Map<String, List<Map<String, dynamic>>>
        index = {};

    for (final Map<String, dynamic> data
        in congestionData) {
      final String name =
          data['tAtsNm']?.toString().trim() ?? '';

      if (name.isEmpty) {
        continue;
      }

      final String normalizedName =
          normalizeName(name);

      if (normalizedName.isEmpty) {
        continue;
      }

      index.putIfAbsent(
        normalizedName,
        () => [],
      );

      index[normalizedName]!.add(data);
    }

    return index;
  }

  // ============================================================
  // 관광지 매핑
  // ============================================================

  static List<SnobSpot> mapSpots({
    required List<TourismSpot> tourismSpots,
    required List<Map<String, dynamic>> congestionData,
  }) {
    final List<SnobSpot> result = [];

    // ----------------------------------------------------------
    // 집중률 데이터 인덱스 생성
    // ----------------------------------------------------------

    final Map<String, List<Map<String, dynamic>>>
        congestionIndex =
        _createCongestionIndex(congestionData);

    int exactMatched = 0;
    int normalizedMatched = 0;
    int simplifiedMatched = 0;
    int unmatched = 0;

    // ==========================================================
    // TourAPI 관광지 하나씩 처리
    // ==========================================================

    for (final TourismSpot spot in tourismSpots) {
      Map<String, dynamic>? bestMatch;

      final String normalizedName =
          normalizeName(spot.title);

      // --------------------------------------------------------
      // 1차: 정규화 이름으로 빠르게 후보 검색
      // --------------------------------------------------------

      final List<Map<String, dynamic>> candidates =
          congestionIndex[normalizedName] ?? [];

      if (candidates.isNotEmpty) {
        bestMatch = _findBestMatch(
          tourismSpot: spot,
          congestionData: candidates,
        );
      }

      // --------------------------------------------------------
      // 2차: 정규화 이름에서 못 찾았으면
      // 전체 데이터를 대상으로 검색
      // --------------------------------------------------------

      if (bestMatch == null) {
        bestMatch = _findBestMatch(
          tourismSpot: spot,
          congestionData: congestionData,
        );
      }

      // --------------------------------------------------------
      // 매칭 실패
      // --------------------------------------------------------

      if (bestMatch == null) {
        unmatched++;

        print(
          '❌ 집중률 매칭 실패 : ${spot.title}',
        );

        result.add(
          _createSnobSpot(
            spot: spot,
            congestion: null,
          ),
        );

        continue;
      }

      // --------------------------------------------------------
      // 매칭 방식 확인
      // --------------------------------------------------------

      final String tourismName =
          normalizeName(spot.title);

      final String matchedName =
          normalizeName(
        bestMatch['tAtsNm']?.toString() ?? '',
      );

      if (tourismName ==
          matchedName) {
        if (spot.title.trim() ==
            bestMatch['tAtsNm']?.toString().trim()) {
          exactMatched++;
        } else {
          normalizedMatched++;
        }
      } else if (_isSameSimplifiedName(
        spot.title,
        bestMatch['tAtsNm']?.toString() ?? '',
      )) {
        simplifiedMatched++;
      }

      // --------------------------------------------------------
      // 최종 SnobSpot 생성
      // --------------------------------------------------------

      result.add(
        _createSnobSpot(
          spot: spot,
          congestion: bestMatch,
        ),
      );
    }

    // ==========================================================
    // 결과 출력
    // ==========================================================

    print('');
    print('==========================================');
    print('SNOB 관광지 매핑 결과');
    print('==========================================');
    print('TourAPI 관광지 : ${tourismSpots.length}개');
    print('집중률 API 데이터 : ${congestionData.length}개');
    print('');
    print('완전 일치 : $exactMatched개');
    print('정규화 일치 : $normalizedMatched개');
    print('간소화 일치 : $simplifiedMatched개');
    print('매칭 실패 : $unmatched개');
    print('');
    print('최종 SNOB 관광지 : ${result.length}개');
    print('==========================================');

    return result;
  }

  // ============================================================
  // TourismSpot → SnobSpot
  // ============================================================

  static SnobSpot _createSnobSpot({
    required TourismSpot spot,
    required Map<String, dynamic>? congestion,
  }) {
    // ----------------------------------------------------------
    // 집중률
    // ----------------------------------------------------------

    final double? concentrationRate =
        congestion == null
            ? null
            : _parseDouble(
                congestion['cnctrRate'],
              );

    // ----------------------------------------------------------
    // SNOB 점수
    // ----------------------------------------------------------

    final double? snobScore =
        calculateSnobScore(
      concentrationRate,
    );

    return SnobSpot(
      contentId: spot.contentId,
      title: spot.title,
      address: spot.address,
      contentTypeId: spot.contentTypeId,
      lDongRegnCd: spot.lDongRegnCd,
      lDongSignguCd: spot.lDongSignguCd,
      regionName: spot.regionName,
      lclsSystm1: spot.lclsSystm1,
      lclsSystm2: spot.lclsSystm2,
      lclsSystm3: spot.lclsSystm3,
      modifiedTime: spot.modifiedTime,
      latitude: spot.latitude,
      longitude: spot.longitude,

      // --------------------------------------------------------
      // 집중률 API 정보
      // --------------------------------------------------------

      concentrationRate:
          concentrationRate,

      concentrationBaseYmd:
          congestion?['baseYmd']?.toString(),

      concentrationAreaCd:
          congestion?['areaCd']?.toString(),

      concentrationAreaNm:
          congestion?['areaNm']?.toString(),

      concentrationSignguCd:
          congestion?['signguCd']?.toString(),

      concentrationSignguNm:
          congestion?['signguNm']?.toString(),

      // --------------------------------------------------------
      // SNOB 점수
      // --------------------------------------------------------

      snobScore: snobScore,
    );
  }

  // ============================================================
  // 단일 관광지 매칭
  // ============================================================

  static SnobSpot? mapSingleSpot({
    required TourismSpot tourismSpot,
    required List<Map<String, dynamic>> congestionData,
  }) {
    final List<SnobSpot> result =
        mapSpots(
      tourismSpots: [tourismSpot],
      congestionData: congestionData,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }
}