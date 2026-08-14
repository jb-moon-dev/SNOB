/// 코스 추천 과정에서 사용하는 관광지 후보
///
/// 기존 SpotVector와 별개로,
/// "이 관광지를 코스에 넣을 것인가?"를 판단하기 위한 모델이다.
///
/// 역할:
/// - 중심 관광지 API 결과 저장
/// - 연관 관광지 API 결과 저장
/// - 혼잡도 정보 연결
/// - 기존 SpotVector 연결
/// - 코스 내 순서 및 이동 정보 저장

class CourseCandidate {
  // ============================================================
  // 관광지 기본 정보
  // ============================================================

  final String spotName;
  final String? address;
  final String? areaName;

  /// 관광지 콘텐츠 ID
  final String? contentId;

  /// 관광지 콘텐츠 타입
  final String? contentTypeId;


  // ============================================================
  // 지역 정보
  // ============================================================

  /// 시도 코드
  final String? areaCode;

  /// 시군구 코드
  final String? sigunguCode;

  /// 시군구 이름
  final String? sigunguName;


  // ============================================================
  // 이동 정보
  // ============================================================

  /// 이전 관광지에서 현재 관광지까지의 이동 거리(km)
  final double? distanceKm;

  /// 이전 관광지에서 현재 관광지까지의 예상 이동 시간(분)
  final double? durationMin;


  // ============================================================
  // 추천 관련 정보
  // ============================================================

  /// 기존 SpotVector
  ///
  /// nullable인 이유:
  /// API에서 받아온 관광지가 아직 SpotVector와
  /// 연결되지 않았을 수도 있기 때문이다.
  final dynamic spotVector;


  // ============================================================
  // 혼잡도
  // ============================================================

  /// 혼잡도 점수
  ///
  /// 0 = 매우 여유
  /// 100 = 매우 혼잡
  final double? congestionScore;

  /// 혼잡도 상태
  ///
  /// 예:
  /// "매우 여유"
  /// "여유"
  /// "보통"
  /// "혼잡"
  /// "매우 혼잡"
  final String? congestionLevel;


  // ============================================================
  // 코스 추천 점수
  // ============================================================

  /// 사용자 성향과 관광지 성향의 유사도
  ///
  /// 높을수록 사용자에게 잘 맞는 관광지
  final double preferenceScore;

  /// 혼잡도를 반영한 최종 점수
  ///
  /// 오버투어리즘 완화를 위해
  /// 혼잡도가 낮을수록 높은 점수를 주는 방향으로 사용한다.
  final double courseScore;


  // ============================================================
  // 중심 관광지 여부
  // ============================================================

  /// 지역의 중심 관광지 API에서 나온 관광지인지 여부
  final bool isCenterSpot;


  // ============================================================
  // 대체 관광지 여부
  // ============================================================

  /// 혼잡 관광지를 제거하고 대신 삽입된 관광지인지 여부
  final bool isAlternative;


  // ============================================================
  // 생성자
  // ============================================================

  CourseCandidate({
    required this.spotName,

    this.address,
    this.areaName,

    this.contentId,
    this.contentTypeId,

    this.areaCode,
    this.sigunguCode,
    this.sigunguName,

    this.distanceKm,
    this.durationMin,

    this.spotVector,

    this.congestionScore,
    this.congestionLevel,

    this.preferenceScore = 0,
    this.courseScore = 0,

    this.isCenterSpot = false,
    this.isAlternative = false,
  });


  // ============================================================
  // 복사
  // ============================================================

  CourseCandidate copyWith({
    String? spotName,

    String? address,
    String? areaName,

    String? contentId,
    String? contentTypeId,

    String? areaCode,
    String? sigunguCode,
    String? sigunguName,

    double? distanceKm,
    double? durationMin,

    dynamic spotVector,

    double? congestionScore,
    String? congestionLevel,

    double? preferenceScore,
    double? courseScore,

    bool? isCenterSpot,
    bool? isAlternative,
  }) {
    return CourseCandidate(
      spotName: spotName ?? this.spotName,

      address: address ?? this.address,
      areaName: areaName ?? this.areaName,

      contentId: contentId ?? this.contentId,
      contentTypeId:
          contentTypeId ?? this.contentTypeId,

      areaCode:
          areaCode ?? this.areaCode,
      sigunguCode:
          sigunguCode ?? this.sigunguCode,
      sigunguName:
          sigunguName ?? this.sigunguName,

      distanceKm:
          distanceKm ?? this.distanceKm,
      durationMin:
          durationMin ?? this.durationMin,

      spotVector:
          spotVector ?? this.spotVector,

      congestionScore:
          congestionScore ?? this.congestionScore,
      congestionLevel:
          congestionLevel ?? this.congestionLevel,

      preferenceScore:
          preferenceScore ?? this.preferenceScore,
      courseScore:
          courseScore ?? this.courseScore,

      isCenterSpot:
          isCenterSpot ?? this.isCenterSpot,
      isAlternative:
          isAlternative ?? this.isAlternative,
    );
  }


  // ============================================================
  // 디버깅용
  // ============================================================

  @override
  String toString() {
    return '''
CourseCandidate(
  spotName: $spotName,
  areaName: $areaName,
  sigunguName: $sigunguName,
  distanceKm: $distanceKm,
  durationMin: $durationMin,
  congestionScore: $congestionScore,
  congestionLevel: $congestionLevel,
  preferenceScore: $preferenceScore,
  courseScore: $courseScore,
  isCenterSpot: $isCenterSpot,
  isAlternative: $isAlternative,
)
''';
  }
}