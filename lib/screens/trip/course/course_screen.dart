import 'package:snob/services/center_spot_service.dart';
import 'package:snob/services/related_spot_service.dart';

import 'congestion_service.dart';

import 'package:flutter/material.dart';

import 'course_recommender.dart';
import 'models/course_result.dart';

// 기존 SNOB 성향 벡터
import 'package:snob/snob/user_vector.dart';

class CourseScreen extends StatefulWidget {
  final UserVector userVector;
  final String areaCd;
  final String sigunguCd;
  final String baseYm;

  const CourseScreen({
    super.key,
    required this.userVector,
    required this.areaCd,
    required this.sigunguCd,
    required this.baseYm,
  });

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  CourseResult? courseResult;

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCourse();
  }

  // ============================================================
  // 코스 추천 실행
  // ============================================================

  Future<void> _loadCourse() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // --------------------------------------------------------
      // 서비스 생성
      // --------------------------------------------------------

      final recommender = CourseRecommender(
        centerSpotService: CenterSpotService(),
        relatedSpotService: RelatedSpotService(),
        congestionService: CongestionService(),
      );

      // --------------------------------------------------------
      // 코스 추천
      // --------------------------------------------------------

      final result = await recommender.recommendCourse(
        userVector: widget.userVector,
        areaCd: widget.areaCd,
        sigunguCd: widget.sigunguCd,
        baseYm: widget.baseYm,
      );

      if (!mounted) return;

      setState(() {
        courseResult = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '추천 여행 코스',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    // ----------------------------------------------------------
    // 로딩
    // ----------------------------------------------------------

    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '여행 코스를 찾고 있어요...',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '혼잡도와 여행 성향을 분석하고 있습니다.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    // ----------------------------------------------------------
    // 오류
    // ----------------------------------------------------------

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.redAccent,
              ),

              const SizedBox(height: 16),

              const Text(
                '코스를 불러오지 못했어요.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _loadCourse,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // 추천 결과 없음
    // ----------------------------------------------------------

    if (courseResult == null ||
        courseResult!.course.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.travel_explore,
                size: 60,
                color: Colors.grey,
              ),

              const SizedBox(height: 16),

              const Text(
                '추천할 수 있는 코스를 찾지 못했어요.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                '다른 지역을 선택하거나\n잠시 후 다시 시도해주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _loadCourse,
                child: const Text('다시 추천받기'),
              ),
            ],
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // 정상 결과
    // ----------------------------------------------------------

    return _buildCourseResult();
  }

  // ============================================================
  // 추천 코스 결과
  // ============================================================

  Widget _buildCourseResult() {
    final result = courseResult!;

    return RefreshIndicator(
      onRefresh: _loadCourse,

      child: ListView(
        padding: const EdgeInsets.all(20),

        children: [
          // ----------------------------------------------------
          // 지역
          // ----------------------------------------------------

          Text(
            result.regionName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            '당신의 여행 성향에 맞춰 구성한 코스예요.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 24),

          // ----------------------------------------------------
          // 분산 여행 안내
          // ----------------------------------------------------

          Container(
            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.green.withOpacity(0.2),
              ),
            ),

            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.eco_outlined,
                  color: Colors.green,
                ),

                SizedBox(width: 12),

                Expanded(
                  child: Text(
                    '혼잡도가 높은 관광지는 피하고,\n'
                    '비슷한 여행 만족도를 제공하면서 '
                    '상대적으로 여유로운 관광지를 중심으로 코스를 구성했어요.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ----------------------------------------------------
          // 코스
          // ----------------------------------------------------

          ...List.generate(
            result.course.length,
            (index) {
              final spot = result.course[index];

              return _buildCourseItem(
                index: index,
                title: spot.title,
                address: spot.address,
                isLast:
                    index == result.course.length - 1,
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 코스 아이템
  // ============================================================

  Widget _buildCourseItem({
    required int index,
    required String title,
    required String address,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ------------------------------------------------------
        // 번호
        // ------------------------------------------------------

        Column(
          children: [
            Container(
              width: 40,
              height: 40,

              decoration: BoxDecoration(
                color: index == 0
                    ? Colors.blueAccent
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),

              alignment: Alignment.center,

              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: index == 0
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ),

            if (!isLast)
              Container(
                width: 2,
                height: 70,
                color: Colors.grey.shade300,
              ),
          ],
        ),

        const SizedBox(width: 16),

        // ------------------------------------------------------
        // 관광지 정보
        // ------------------------------------------------------

        Expanded(
          child: Container(
            margin: const EdgeInsets.only(
              bottom: 18,
            ),

            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius:
                  BorderRadius.circular(16),

              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  title.isEmpty
                      ? '관광지 정보 없음'
                      : title,

                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  address.isEmpty
                      ? '주소 정보 없음'
                      : address,

                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}