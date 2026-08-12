import 'models/course_candidate.dart';
import 'models/course_result.dart';

// 기존 모델
import '../../../snob/spot_vector.dart';
import '../../../snob/user_vector.dart';

// API Service
import 'package:snob/services/center_spot_service.dart';
import 'package:snob/services/related_spot_service.dart';
import 'congestion_service.dart';


/// ============================================================
/// 코스 추천기
/// ============================================================
///
/// 목적:
/// 사용자의 여행 성향에 맞으면서도
/// 혼잡한 관광지에 방문객이 집중되지 않도록
/// 대체 관광지를 활용해 코스를 생성한다.
///
/// 전체 흐름:
///
/// 사용자 성향
///     ↓
/// 추천 지역
///     ↓
/// 중심 관광지 조회
///     ↓
/// 연관 관광지 조회
///     ↓
/// 후보 관광지 생성
///     ↓
/// 성향 점수 계산
///     ↓
/// 혼잡도 확인
///     ↓
/// 혼잡 관광지 제거
///     ↓
/// 대체 관광지 탐색
///     ↓
/// 최종 코스 생성
///
class CourseRecommender {
  // ============================================================
  // Service
  // ============================================================

  final CenterSpotService centerSpotService;
  final RelatedSpotService relatedSpotService;
  final CongestionService congestionService;


  CourseRecommender({
    required this.centerSpotService,
    required this.relatedSpotService,
    required this.congestionService,
  });


  // ============================================================
  // 설정값
  // ============================================================

  /// 코스에 포함할 기본 관광지 수
  static const int defaultCourseSize = 3;

  /// 이 점수 이상이면 혼잡 관광지로 판단
  ///
  /// 현재 혼잡도 지도에서
  /// 60 이상 = 혼잡
  /// 80 이상 = 매우 혼잡
  ///
  /// 으로 사용하고 있으므로 일단 60으로 둔다.
  static const double congestionThreshold = 60.0;


  /// 대체 관광지를 찾을 때
  /// 원래 관광지와 허용할 수 있는 성향 차이
  static const double preferenceTolerance = 30.0;


  // ============================================================
  // 메인 추천 함수
  // ============================================================

  Future<CourseResult> recommendCourse({
    required UserVector userVector,

    required String areaCode,
    required String sigunguCode,

    int courseSize = defaultCourseSize,
  }) async {

    // ----------------------------------------------------------
    // 1. 중심 관광지 조회
    // ----------------------------------------------------------

    final centerSpots =
        await centerSpotService.getCenterSpots(
      areaCode: areaCode,
      sigunguCode: sigunguCode,
    );


    // ----------------------------------------------------------
    // 2. 중심 관광지가 없는 경우
    // ----------------------------------------------------------

    if (centerSpots.isEmpty) {

      return CourseResult.empty(
        regionName: sigunguCode,
      );
    }


    // ----------------------------------------------------------
    // 3. 중심 관광지를 후보로 변환
    // ----------------------------------------------------------

    List<CourseCandidate> candidates = [];

    for (final spot in centerSpots) {

      final candidate =
          _createCandidateFromCenterSpot(
        spot,
        userVector,
      );

      candidates.add(candidate);
    }


    // ----------------------------------------------------------
    // 4. 각 중심 관광지의 연관 관광지 조회
    // ----------------------------------------------------------

    List<CourseCandidate> relatedCandidates = [];

    for (final candidate in candidates) {

      if (candidate.contentId == null) {
        continue;
      }

      final relatedSpots =
          await relatedSpotService.getRelatedSpots(
        contentId: candidate.contentId!,
        areaCode: areaCode,
        sigunguCode: sigunguCode,
      );


      for (final relatedSpot in relatedSpots) {

        final relatedCandidate =
            _createCandidateFromRelatedSpot(
          relatedSpot,
          userVector,
          centerSpot: candidate,
        );

        relatedCandidates.add(
          relatedCandidate,
        );
      }
    }


    // ----------------------------------------------------------
    // 5. 중심 관광지 + 연관 관광지 합치기
    // ----------------------------------------------------------

    candidates.addAll(
      relatedCandidates,
    );


    // ----------------------------------------------------------
    // 6. 중복 제거
    // ----------------------------------------------------------

    candidates =
        _removeDuplicates(candidates);


    // ----------------------------------------------------------
    // 7. 사용자 성향 점수 계산
    // ----------------------------------------------------------

    candidates =
        _calculatePreferenceScores(
      candidates,
      userVector,
    );


    // ----------------------------------------------------------
    // 8. 혼잡도 조회
    // ----------------------------------------------------------

    candidates =
        await _attachCongestion(
      candidates,
    );


    // ----------------------------------------------------------
    // 9. 혼잡 관광지 제거 + 대체 관광지 탐색
    // ----------------------------------------------------------

    candidates =
        await _replaceCongestedSpots(
      candidates,
      userVector,
    );


    // ----------------------------------------------------------
    // 10. 최종 코스 선정
    // ----------------------------------------------------------

    final selected =
        _selectCourse(
      candidates,
      courseSize,
    );


    // ----------------------------------------------------------
    // 11. 코스 결과 생성
    // ----------------------------------------------------------

    return _buildCourseResult(
      selected,
      sigunguCode,
    );
  }


  // ============================================================
  // 중심 관광지 → CourseCandidate
  // ============================================================

  CourseCandidate _createCandidateFromCenterSpot(
    dynamic spot,
    UserVector userVector,
  ) {

    return CourseCandidate(
      spotName: spot.title ?? '',
      address: spot.address,
      areaName: spot.areaName,

      contentId: spot.contentId,
      contentTypeId: spot.contentTypeId,

      areaCode: spot.areaCode,
      sigunguCode: spot.sigunguCode,
      sigunguName: spot.sigunguName,

      preferenceScore: 0,

      courseScore: 0,

      isCenterSpot: true,
      isAlternative: false,
    );
  }


  // ============================================================
  // 연관 관광지 → CourseCandidate
  // ============================================================

  CourseCandidate _createCandidateFromRelatedSpot(
    dynamic spot,
    UserVector userVector, {
    required CourseCandidate centerSpot,
  }) {

    return CourseCandidate(
      spotName: spot.title ?? '',
      address: spot.address,
      areaName: spot.areaName,

      contentId: spot.contentId,
      contentTypeId: spot.contentTypeId,

      areaCode: spot.areaCode,
      sigunguCode: spot.sigunguCode,
      sigunguName: spot.sigunguName,

      distanceKm:
          spot.distanceKm,

      durationMin:
          spot.durationMin,

      preferenceScore: 0,

      courseScore: 0,

      isCenterSpot: false,
      isAlternative: false,
    );
  }


  // ============================================================
  // 사용자 성향 점수 계산
  // ============================================================

  List<CourseCandidate> _calculatePreferenceScores(
    List<CourseCandidate> candidates,
    UserVector userVector,
  ) {

    return candidates.map((candidate) {

      final SpotVector? vector =
          _getSpotVector(candidate);


      // SpotVector가 아직 연결되지 않은 관광지는
      // 일단 기본 점수를 준다.
      if (vector == null) {

        return candidate.copyWith(
          preferenceScore: 50,
        );
      }


      final double distance =
          _vectorDistance(
        userVector,
        vector,
      );


      // 거리 ↓ → 선호도 ↑
      final double preferenceScore =
          (100 - distance)
              .clamp(0, 100)
              .toDouble();


      return candidate.copyWith(
        preferenceScore:
            preferenceScore,
      );
    }).toList();
  }


  // ============================================================
  // 성향 거리
  // ============================================================

  double _vectorDistance(
    UserVector user,
    SpotVector spot,
  ) {

    final double nature =
        (user.nature - spot.nature).abs();

    final double hidden =
        (user.hidden - spot.hidden).abs();

    final double healing =
        (user.healing - spot.healing).abs();


    return (
      nature +
      hidden +
      healing
    ) / 3;
  }


  // ============================================================
  // SpotVector 가져오기
  // ============================================================

  SpotVector? _getSpotVector(
    CourseCandidate candidate,
  ) {

    if (candidate.spotVector
        is SpotVector) {

      return candidate.spotVector
          as SpotVector;
    }

    return null;
  }


  // ============================================================
  // 혼잡도 연결
  // ============================================================

  Future<List<CourseCandidate>> _attachCongestion(
    List<CourseCandidate> candidates,
  ) async {

    return candidates.map((candidate) {

      final congestion =
          congestionService.getCongestionData(
        candidate.sigunguName ??
            candidate.areaName ??
            '',
        regionCode:
            candidate.sigunguCode,
      );


      if (congestion == null) {
        return candidate;
      }


      return candidate.copyWith(
        congestionScore:
            congestion.absoluteScore,

        congestionLevel:
            congestion.levelStr,
      );
    }).toList();
  }


  // ============================================================
  // 혼잡 관광지 제거 + 대체 관광지
  // ============================================================

  Future<List<CourseCandidate>> _replaceCongestedSpots(
    List<CourseCandidate> candidates,
    UserVector userVector,
  ) async {

    List<CourseCandidate> result = [];


    for (final candidate in candidates) {

      final double congestion =
          candidate.congestionScore ?? 0;


      // --------------------------------------------------------
      // 한산한 관광지
      // --------------------------------------------------------

      if (congestion < congestionThreshold) {

        result.add(
          candidate.copyWith(
            courseScore:
                _calculateCourseScore(candidate),
          ),
        );

        continue;
      }


      // --------------------------------------------------------
      // 혼잡한 관광지
      // --------------------------------------------------------

      final alternative =
          _findAlternativeSpot(
        candidate,
        candidates,
      );


      if (alternative != null) {

        result.add(
          alternative.copyWith(
            isAlternative: true,

            courseScore:
                _calculateCourseScore(
              alternative,
            ),
          ),
        );
      }
    }


    return result;
  }


  // ============================================================
  // 대체 관광지 탐색
  // ============================================================

  CourseCandidate? _findAlternativeSpot(
    CourseCandidate original,
    List<CourseCandidate> candidates,
  ) {

    final alternatives =
        candidates.where((candidate) {

      // 자기 자신 제외
      if (candidate.spotName ==
          original.spotName) {
        return false;
      }


      // 혼잡한 관광지는 대체 후보에서 제외
      final congestion =
          candidate.congestionScore ?? 0;

      if (congestion >=
          congestionThreshold) {
        return false;
      }


      // 원래 관광지와 성향이
      // 너무 다른 관광지는 제외
      final preferenceDifference =
          (candidate.preferenceScore -
                  original.preferenceScore)
              .abs();

      if (preferenceDifference >
          preferenceTolerance) {
        return false;
      }


      return true;

    }).toList();


    if (alternatives.isEmpty) {
      return null;
    }


    // 가장 적합한 관광지 선택
    alternatives.sort(
      (a, b) =>
          b.courseScore
              .compareTo(a.courseScore),
    );


    return alternatives.first;
  }


  // ============================================================
  // 최종 코스 점수
  // ============================================================

  double _calculateCourseScore(
    CourseCandidate candidate,
  ) {

    final double preference =
        candidate.preferenceScore;


    final double congestion =
        candidate.congestionScore ?? 50;


    // ----------------------------------------------------------
    // 핵심
    //
    // 성향 70%
    // 혼잡도 30%
    //
    // 혼잡도가 낮을수록 높은 점수
    // ----------------------------------------------------------

    final double congestionScore =
        100 - congestion;


    return (
      preference * 0.7
    ) + (
      congestionScore * 0.3
    );
  }


  // ============================================================
  // 중복 제거
  // ============================================================

  List<CourseCandidate> _removeDuplicates(
    List<CourseCandidate> candidates,
  ) {

    final Map<String, CourseCandidate>
        unique = {};


    for (final candidate in candidates) {

      final key =
          candidate.contentId ??
          candidate.spotName;


      if (!unique.containsKey(key)) {
        unique[key] = candidate;
      }
    }


    return unique.values.toList();
  }


  // ============================================================
  // 최종 코스 선정
  // ============================================================

  List<CourseCandidate> _selectCourse(
    List<CourseCandidate> candidates,
    int courseSize,
  ) {

    final sorted =
        List<CourseCandidate>.from(
      candidates,
    );


    sorted.sort(
      (a, b) =>
          b.courseScore
              .compareTo(a.courseScore),
    );


    if (sorted.length <= courseSize) {
      return sorted;
    }


    return sorted.sublist(
      0,
      courseSize,
    );
  }


  // ============================================================
  // CourseResult 생성
  // ============================================================

  CourseResult _buildCourseResult(
    List<CourseCandidate> candidates,
    String regionName,
  ) {

    final items =
        candidates.map((candidate) {

      return CourseItem(
        spotName:
            candidate.spotName,

        address:
            candidate.address,

        distanceKm:
            candidate.distanceKm,

        durationMin:
            candidate.durationMin,

        congestionScore:
            candidate.congestionScore,

        isAlternative:
            candidate.isAlternative,
      );

    }).toList();


    return CourseResult(
      regionName: regionName,
      items: items,
    );
  }
}