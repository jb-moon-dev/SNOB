class CourseItem {
  // ============================================================
  // 기본 관광지 정보
  // ============================================================

  // 관광지 고유 ID
  final String contentId;

  // 관광지 이름
  final String title;

  // 관광지 주소
  final String address;

  // 지역 코드
  final String areaCode;

  // 시군구 코드
  final String sigunguCode;

  // 지도 X 좌표
  final double mapX;

  // 지도 Y 좌표
  final double mapY;


  // ============================================================
  // SNOB 관련 정보
  // ============================================================

  // SNOB 지수
  //
  // 낮을수록 추천 우선순위가 높음
  //
  // 아직 계산되지 않은 경우 0으로 저장
  final double snobIndex;


  // ============================================================
  // 생성자
  // ============================================================

  const CourseItem({
    required this.contentId,
    required this.title,
    required this.address,
    required this.areaCode,
    required this.sigunguCode,
    required this.mapX,
    required this.mapY,
    required this.snobIndex,
  });


  // ============================================================
  // API JSON → CourseItem
  // ============================================================

  factory CourseItem.fromJson(
    Map<String, dynamic> json,
  ) {
    return CourseItem(
      contentId:
          json['contentid']?.toString() ?? '',

      title:
          json['title']?.toString() ?? '',

      address:
          json['addr1']?.toString() ?? '',

      areaCode:
          json['areacode']?.toString() ?? '',

      sigunguCode:
          json['sigungucode']?.toString() ?? '',

      mapX:
          double.tryParse(
                json['mapx']?.toString() ?? '0',
              ) ??
              0,

      mapY:
          double.tryParse(
                json['mapy']?.toString() ?? '0',
              ) ??
              0,

      // API에서 직접 내려오는 값은 아니지만
      // 나중에 SNOB 지수 계산 결과를 넣을 수 있도록 준비
      snobIndex:
          double.tryParse(
                json['snobIndex']?.toString() ?? '0',
              ) ??
              0,
    );
  }


  // ============================================================
  // CourseItem → JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'contentid': contentId,
      'title': title,
      'addr1': address,
      'areacode': areaCode,
      'sigungucode': sigunguCode,
      'mapx': mapX,
      'mapy': mapY,
      'snobIndex': snobIndex,
    };
  }


  // ============================================================
  // SNOB 지수만 변경한 새로운 CourseItem 생성
  //
  // 나중에 CourseRecommender에서
  //
  // API 관광지
  //      ↓
  // SNOB 지수 계산
  //      ↓
  // copyWith(snobIndex: ...)
  //
  // 형태로 사용할 수 있음
  // ============================================================

  CourseItem copyWith({
    String? contentId,
    String? title,
    String? address,
    String? areaCode,
    String? sigunguCode,
    double? mapX,
    double? mapY,
    double? snobIndex,
  }) {
    return CourseItem(
      contentId:
          contentId ?? this.contentId,

      title:
          title ?? this.title,

      address:
          address ?? this.address,

      areaCode:
          areaCode ?? this.areaCode,

      sigunguCode:
          sigunguCode ?? this.sigunguCode,

      mapX:
          mapX ?? this.mapX,

      mapY:
          mapY ?? this.mapY,

      snobIndex:
          snobIndex ?? this.snobIndex,
    );
  }


  // ============================================================
  // 디버깅용
  // ============================================================

  @override
  String toString() {
    return '''
===== Course Item =====
관광지 : $title
주소 : $address
contentId : $contentId
areaCode : $areaCode
sigunguCode : $sigunguCode
mapX : $mapX
mapY : $mapY
SNOB 지수 : ${snobIndex.toStringAsFixed(1)}
=======================
''';
  }
}