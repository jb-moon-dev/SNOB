import 'models/course_item.dart';
import 'models/course_result.dart';

import 'package:snob/services/center_spot_service.dart';
import 'package:snob/services/related_spot_service.dart';

import 'congestion_service.dart';

import 'package:snob/snob/user_vector.dart';


class CourseRecommender {
  final CenterSpotService centerSpotService;
  final RelatedSpotService relatedSpotService;
  final CongestionService congestionService;

  CourseRecommender({
    required this.centerSpotService,
    required this.relatedSpotService,
    required this.congestionService,
  });


  // ============================================================
  // 코스 추천
  // ============================================================

  Future<CourseResult?> recommendCourse({
    required UserVector userVector,
    required String areaCd,
    required String sigunguCd,
    required String baseYm,
  }) async {

    // ----------------------------------------------------------
    // 1. 중심 관광지 조회
    // ----------------------------------------------------------

    final centerSpots =
        await centerSpotService.getCenterSpots(
      pageNo: 1,
      numOfRows: 20,
      mobileOS: 'AND',
      mobileApp: 'SNOB',
      baseYm: baseYm,
      areaCd: areaCd,
      signguCd: sigunguCd,
    );


    // 중심 관광지가 없으면 추천 불가
    if (centerSpots.isEmpty) {
      return null;
    }


    // ----------------------------------------------------------
    // 2. 중심 관광지 중 하나를 시작점으로 선정
    //
    // 현재는 첫 번째 관광지를 사용
    // ----------------------------------------------------------

    final startSpot = centerSpots.first;


    // ----------------------------------------------------------
    // 3. CourseItem으로 변환
    // ----------------------------------------------------------

    final startCourseItem =
        CourseItem.fromJson(startSpot);


    // ----------------------------------------------------------
    // 4. 임시 결과
    //
    // 아직 연관 관광지 + 혼잡도 로직은 붙이지 않음
    // ----------------------------------------------------------

    return CourseResult(
      regionName:
          startCourseItem.address,
      course: [
        startCourseItem,
      ],
    );
  }
}