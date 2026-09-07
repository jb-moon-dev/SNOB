class RegionMappingService {
  static List<RegionQuery> getQueryRegions({
    required String regionCode,
    required String sigunguCode,
    required String regionName,
  }) {
    // ============================================================
    // 인천
    // ============================================================

    if (_isIncheon(regionCode, regionName)) {
      return _getIncheonQueries(
        regionName: regionName,
      );
    }

    // ============================================================
    // 전남광주통합특별시
    // ============================================================

    if (_isJeonnamGwangju(regionName)) {
      return _getJeonnamGwangjuQueries(
        regionName: regionName,
      );
    }

    // ============================================================
    // 화성시
    // ============================================================

    if (_isHwaseong(regionName)) {
      return _getHwaseongQueries(
        regionName: regionName,
      );
    }

    // ============================================================
    // 일반 지역
    //
    // 주의:
    // TourAPI의 현재 sigunguCode와
    // 집중률 API의 sigunguCd가 같은 지역의 경우에만
    // 그대로 사용
    // ============================================================

    return [
      RegionQuery(
        areaCd: regionCode,
        signguCd: sigunguCode,
        regionName: regionName,
        reason: '일반 지역',
      ),
    ];
  }

  // ============================================================
  // 인천
  // ============================================================

  static List<RegionQuery> _getIncheonQueries({
    required String regionName,
  }) {
    final String normalizedName =
        _normalizeRegionName(regionName);

    // 영종구 → 과거 인천 중구
    if (normalizedName.contains('영종구')) {
      return [
        RegionQuery(
          areaCd: '28',
          signguCd: '28110',
          regionName: regionName,
          reason: '영종구 → 기존 인천 중구 집중률 데이터 조회',
        ),
      ];
    }

    // 제물포구 → 과거 인천 중구
    if (normalizedName.contains('제물포구')) {
      return [
        RegionQuery(
          areaCd: '28',
          signguCd: '28110',
          regionName: regionName,
          reason: '제물포구 → 기존 인천 중구 집중률 데이터 조회',
        ),
      ];
    }

    // 서해구 → 과거 인천 서구
    if (normalizedName.contains('서해구')) {
      return [
        RegionQuery(
          areaCd: '28',
          signguCd: '28260',
          regionName: regionName,
          reason: '서해구 → 기존 인천 서구 집중률 데이터 조회',
        ),
      ];
    }

    // 검단구 → 과거 인천 서구
    if (normalizedName.contains('검단구')) {
      return [
        RegionQuery(
          areaCd: '28',
          signguCd: '28260',
          regionName: regionName,
          reason: '검단구 → 기존 인천 서구 집중률 데이터 조회',
        ),
      ];
    }

    return [
      RegionQuery(
        areaCd: '28',
        signguCd: '',
        regionName: regionName,
        reason: '인천 일반 지역',
      ),
    ];
  }

  // ============================================================
  // 전남광주통합특별시
  // ============================================================

  static List<RegionQuery> _getJeonnamGwangjuQueries({
    required String regionName,
  }) {
    final String normalizedName =
        _normalizeRegionName(regionName);

    // ------------------------------------------------------------
    // 기존 광주광역시
    // ------------------------------------------------------------

    if (normalizedName.contains('광산구')) {
      return [
        RegionQuery(
          areaCd: '29',
          signguCd: '29200',
          regionName: regionName,
          reason: '기존 광주광역시 광산구 데이터 조회',
        ),
      ];
    }

    if (normalizedName.contains('동구')) {
      return [
        RegionQuery(
          areaCd: '29',
          signguCd: '29110',
          regionName: regionName,
          reason: '기존 광주광역시 동구 데이터 조회',
        ),
      ];
    }

    if (normalizedName.contains('서구')) {
      return [
        RegionQuery(
          areaCd: '29',
          signguCd: '29140',
          regionName: regionName,
          reason: '기존 광주광역시 서구 데이터 조회',
        ),
      ];
    }

    if (normalizedName.contains('남구')) {
      return [
        RegionQuery(
          areaCd: '29',
          signguCd: '29155',
          regionName: regionName,
          reason: '기존 광주광역시 남구 데이터 조회',
        ),
      ];
    }

    if (normalizedName.contains('북구')) {
      return [
        RegionQuery(
          areaCd: '29',
          signguCd: '29170',
          regionName: regionName,
          reason: '기존 광주광역시 북구 데이터 조회',
        ),
      ];
    }

    // ------------------------------------------------------------
    // 기존 전라남도
    // ------------------------------------------------------------

    if (normalizedName.contains('목포시')) {
      return [
        RegionQuery(
          areaCd: '46',
          signguCd: '46110',
          regionName: regionName,
          reason: '기존 전라남도 목포시 데이터 조회',
        ),
      ];
    }

    if (normalizedName.contains('여수시')) {
      return [
        RegionQuery(
          areaCd: '46',
          signguCd: '46130',
          regionName: regionName,
          reason: '기존 전라남도 여수시 데이터 조회',
        ),
      ];
    }

    if (normalizedName.contains('순천시')) {
      return [
        RegionQuery(
          areaCd: '46',
          signguCd: '46150',
          regionName: regionName,
          reason: '기존 전라남도 순천시 데이터 조회',
        ),
      ];
    }

    if (normalizedName.contains('나주시')) {
      return [
        RegionQuery(
          areaCd: '46',
          signguCd: '46170',
          regionName: regionName,
          reason: '기존 전라남도 나주시 데이터 조회',
        ),
      ];
    }

    return [];
  }

  // ============================================================
  // 화성시
  // ============================================================

  static List<RegionQuery> _getHwaseongQueries({
    required String regionName,
  }) {
    final String normalizedName =
        _normalizeRegionName(regionName);

    if (normalizedName.contains('만세구') ||
        normalizedName.contains('효행구') ||
        normalizedName.contains('병점구') ||
        normalizedName.contains('동탄구') ||
        normalizedName.contains('화성시')) {
      return [
        RegionQuery(
          areaCd: '41',
          signguCd: '41590',
          regionName: regionName,
          reason: '화성시 → 기존 화성시 집중률 데이터 조회',
        ),
      ];
    }

    return [];
  }

  // ============================================================
  // 지역 판별
  // ============================================================

  static bool _isIncheon(
    String regionCode,
    String regionName,
  ) {
    final String normalizedName =
        _normalizeRegionName(regionName);

    return normalizedName.contains('인천광역시');
  }

  static bool _isJeonnamGwangju(
    String regionName,
  ) {
    final String normalizedName =
        _normalizeRegionName(regionName);

    return normalizedName.contains('전남광주통합특별시');
  }

  static bool _isHwaseong(
    String regionName,
  ) {
    final String normalizedName =
        _normalizeRegionName(regionName);

    return normalizedName.contains('화성시') ||
        normalizedName.contains('만세구') ||
        normalizedName.contains('효행구') ||
        normalizedName.contains('병점구') ||
        normalizedName.contains('동탄구');
  }

  // ============================================================
  // 지역명 정리
  // ============================================================

  static String _normalizeRegionName(String name) {
    return name
        .replaceAll(' ', '')
        .trim();
  }
}

// ================================================================
// 집중률 API 조회 지역
// ================================================================

class RegionQuery {
  final String areaCd;
  final String signguCd;
  final String regionName;
  final String reason;

  const RegionQuery({
    required this.areaCd,
    required this.signguCd,
    required this.regionName,
    required this.reason,
  });

  @override
  String toString() {
    return '''
RegionQuery(
  areaCd: $areaCd,
  signguCd: $signguCd,
  regionName: $regionName,
  reason: $reason,
)
''';
  }
}