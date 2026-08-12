import 'package:snob/services/center_spot_service.dart';
import 'package:snob/services/related_spot_service.dart';
import 'congestion_service.dart';

class CourseRecommendationService {
  final CenterSpotService centerSpotService;
  final RelatedSpotService relatedSpotService;
  final CongestionService congestionService;

  CourseRecommendationService({
    required this.centerSpotService,
    required this.relatedSpotService,
    required this.congestionService,
  });

  // ============================================================
  // 최종 코스 추천
  //
  // 흐름
  // 사용자 성향
  //     ↓
  // 중심 관광지
  //     ↓
  // 연관 관광지
  //     ↓
  // 혼잡도 확인
  //     ↓
  // 혼잡하면 대체 관광지 탐색
  //     ↓
  // 최종 코스
  // ============================================================

  Future<List<Map<String, dynamic>>> recommendCourse({
    required String areaCd,
    required String signguCd,
    required String baseYm,

    required double userNature,
    required double userHidden,
    required double userHealing,

    int courseLength = 4,
  }) async {

    // ----------------------------------------------------------
    // 1. 혼잡도 데이터 준비
    // ----------------------------------------------------------

    await congestionService.loadData();


    // ----------------------------------------------------------
    // 2. 지역의 중심 관광지 조회
    // ----------------------------------------------------------

    final centerSpots =
        await centerSpotService.getCenterSpots(
      pageNo: 1,
      numOfRows: 20,
      mobileOS: 'AND',
      mobileApp: 'SNOB',
      baseYm: baseYm,
      areaCd: areaCd,
      signguCd: signguCd,
    );


    if (centerSpots.isEmpty) {
      return [];
    }


    // ----------------------------------------------------------
    // 3. 중심 관광지 중 하나를 시작점으로 선택
    //
    // 현재는 첫 번째 중심 관광지를 사용.
    //
    // 나중에는 사용자 성향과 중심 관광지 특성을 비교해서
    // 가장 적합한 관광지를 시작점으로 선택할 예정.
    // ----------------------------------------------------------

    final startSpot = centerSpots.first;


    // ----------------------------------------------------------
    // 4. 시작 관광지의 연관 관광지 조회
    // ----------------------------------------------------------

    final relatedSpots =
        await relatedSpotService.getRelatedSpots(
      pageNo: 1,
      numOfRows: 30,
      mobileOS: 'AND',
      mobileApp: 'SNOB',
      baseYm: baseYm,
      areaCd: areaCd,
      signguCd: signguCd,
    );


    // ----------------------------------------------------------
    // 5. 시작 관광지 + 연관 관광지 후보 생성
    // ----------------------------------------------------------

    final List<Map<String, dynamic>> candidates = [];

    candidates.add(startSpot);
    candidates.addAll(relatedSpots);


    // ----------------------------------------------------------
    // 6. 중복 관광지 제거
    // ----------------------------------------------------------

    final List<Map<String, dynamic>> uniqueCandidates = [];

    final Set<String> usedNames = {};

    for (final spot in candidates) {

      final name = _getSpotName(spot);

      if (name.isEmpty) {
        continue;
      }

      if (usedNames.contains(name)) {
        continue;
      }

      usedNames.add(name);

      uniqueCandidates.add(spot);
    }


    // ----------------------------------------------------------
    // 7. 혼잡도 기반으로 후보 필터링
    //
    // absoluteScore >= 60
    // → 혼잡 관광지
    //
    // 혼잡 관광지는 일단 뒤로 보냄.
    // ----------------------------------------------------------

    final List<Map<String, dynamic>> availableSpots = [];

    final List<Map<String, dynamic>> crowdedSpots = [];

    for (final spot in uniqueCandidates) {

      final code = _getRegionCode(spot);

      if (code.isEmpty) {
        availableSpots.add(spot);
        continue;
      }

      if (congestionService.isCrowded(code)) {
        crowdedSpots.add(spot);
      } else {
        availableSpots.add(spot);
      }
    }


    // ----------------------------------------------------------
    // 8. 사용자 성향에 맞는 관광지 정렬
    //
    // 현재는 관광지 API에서 성향 벡터를 가져오는 구조가
    // 아직 연결되지 않았기 때문에 임시로 유지.
    //
    // 다음 단계에서 SpotVector와 연결한다.
    // ----------------------------------------------------------

    availableSpots.sort(
      (a, b) {
        return _calculateTemporaryScore(
          b,
          userNature,
          userHidden,
          userHealing,
        ).compareTo(
          _calculateTemporaryScore(
            a,
            userNature,
            userHidden,
            userHealing,
          ),
        );
      },
    );


    // ----------------------------------------------------------
    // 9. 최종 코스 생성
    // ----------------------------------------------------------

    final List<Map<String, dynamic>> finalCourse = [];

    for (final spot in availableSpots) {

      if (finalCourse.length >= courseLength) {
        break;
      }

      finalCourse.add(spot);
    }


    // ----------------------------------------------------------
    // 10. 코스가 부족하면 혼잡 관광지도 후보로 사용
    //
    // 모든 관광지가 혼잡한 지역일 수도 있기 때문에
    // 무조건 빈 코스를 반환하지 않도록 한다.
    //
    // 단, 혼잡 관광지는 최후의 수단.
    // ----------------------------------------------------------

    if (finalCourse.length < courseLength) {

      for (final spot in crowdedSpots) {

        if (finalCourse.length >= courseLength) {
          break;
        }

        finalCourse.add(spot);
      }
    }


    return finalCourse;
  }


  // ============================================================
  // 관광지 이름 가져오기
  // ============================================================

  String _getSpotName(
    Map<String, dynamic> spot,
  ) {

    return (
      spot['spotNm'] ??
      spot['tarNm'] ??
      spot['title'] ??
      spot['name'] ??
      ''
    ).toString().trim();
  }


  // ============================================================
  // 지역 코드 가져오기
  //
  // 실제 API 응답 필드 확인 후 수정 가능
  // ============================================================

  String _getRegionCode(
    Map<String, dynamic> spot,
  ) {

    return (
      spot['signguCd'] ??
      spot['sigunguCd'] ??
      spot['cd'] ??
      ''
    ).toString().trim();
  }


  // ============================================================
  // 임시 성향 점수
  //
  // 아직 SpotVector와 연결하기 전까지 사용하는 임시 함수.
  //
  // 다음 단계에서 제거하고
  //
  // UserVector
  //     ↓
  // SpotVector
  //     ↓
  // 성향 거리 계산
  //
  // 으로 변경한다.
  // ============================================================

  double _calculateTemporaryScore(
    Map<String, dynamic> spot,
    double userNature,
    double userHidden,
    double userHealing,
  ) {

    // 아직 관광지별 nature / hidden / healing 값이
    // API 응답에 연결되지 않았기 때문에
    // 현재는 동일 점수로 처리한다.

    return 0;
  }
}