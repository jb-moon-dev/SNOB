import 'package:flutter/material.dart';

import 'snob_congestion.dart';
import '../../../models/travel_plan.dart';
import '../../../services/travel_plan_storage.dart';

class CourseResultScreen extends StatefulWidget {
  // 추천 지역명
  final String regionName;

  // center50.dart에서 가져온 관광지 50개
  final List<Map<String, dynamic>> spots;

  const CourseResultScreen({
    super.key,
    required this.regionName,
    required this.spots,
  });

  @override
  State<CourseResultScreen> createState() =>
      _CourseResultScreenState();
}

class _CourseResultScreenState
    extends State<CourseResultScreen> {
  // ============================================================
  // 상태
  // ============================================================

  bool isLoading = true;
  bool isSaving = false;

  String? errorMessage;

  List<SnobCongestionResult> results = [];

  // ============================================================
  // 여행 일정
  // ============================================================

  late TravelPlan travelPlan;

  @override
  void initState() {
    super.initState();

    // 기본 여행 일정 생성
    //
    // 현재 TravelPlan.create()는 dayCount를 받지 않으므로
    // regionName만 전달한다.
    travelPlan = TravelPlan.create(
      regionName: widget.regionName,
    );

    // 저장된 일정 불러오기
    _initializeTravelPlan();

    // SNOB 계산
    _calculateSnob();
  }

  // ============================================================
  // 저장된 여행 일정 불러오기
  // ============================================================

  Future<void> _initializeTravelPlan() async {
    try {
      final savedPlan =
          await TravelPlanStorage.loadTravelPlan();

      if (!mounted) return;

      if (savedPlan != null &&
          savedPlan.regionName == widget.regionName) {
        setState(() {
          travelPlan = savedPlan;
        });

        debugPrint(
          '저장된 여행 일정 불러오기 완료: '
          '${savedPlan.regionName}',
        );

        debugPrint(
          '저장된 관광지 수: '
          '${savedPlan.totalSpotCount}',
        );
      } else {
        debugPrint(
          '현재 지역에 해당하는 저장된 일정이 없습니다.',
        );
      }
    } catch (e) {
      debugPrint(
        '여행 일정 불러오기 오류: $e',
      );
    }
  }

  // ============================================================
  // SNOB 계산
  //
  // center50
  //     ↓
  // SnobCongestion
  //     ↓
  // 30일 평균 혼잡도
  //     ↓
  // SNOB 점수
  //     ↓
  // 높은 SNOB 점수 순
  // ============================================================

  Future<void> _calculateSnob() async {
    try {
      debugPrint('');
      debugPrint('========================================');
      debugPrint('COURSE RESULT 시작');
      debugPrint('추천 지역: ${widget.regionName}');
      debugPrint('관광지 수: ${widget.spots.length}');
      debugPrint('========================================');

      final calculator = SnobCongestion();

      final calculatedResults =
          await calculator.calculate(widget.spots);

      if (!mounted) return;

      setState(() {
        results = calculatedResults;
        isLoading = false;
      });

      debugPrint('');
      debugPrint('========================================');
      debugPrint('SNOB 계산 완료');
      debugPrint(
        '결과 수: ${calculatedResults.length}',
      );
      debugPrint('========================================');

      for (int i = 0;
          i < calculatedResults.length;
          i++) {
        final result = calculatedResults[i];

        debugPrint('');
        debugPrint(
          '[${i + 1}] '
          '${result.spot['hubTatsNm']}',
        );

        debugPrint(
          '30일 평균 혼잡도: '
          '${result.averageCongestion.toStringAsFixed(2)}',
        );

        debugPrint(
          'SNOB 점수: '
          '${result.snobScore.toStringAsFixed(2)}',
        );
      }

      debugPrint('');
      debugPrint('========================================');
      debugPrint('COURSE RESULT 종료');
      debugPrint('========================================');
    } catch (e) {
      debugPrint('');
      debugPrint('========================================');
      debugPrint('COURSE RESULT 오류');
      debugPrint(e.toString());
      debugPrint('========================================');

      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  // ============================================================
  // Map → TravelSpot 변환
  //
  // TravelSpot.fromMap()에 의존하지 않고
  // 현재 TravelSpot 모델의 생성자를 직접 사용한다.
  // ============================================================

  TravelSpot _createTravelSpot(
    SnobCongestionResult result,
  ) {
    final spot = result.spot;

    final name =
        spot['hubTatsNm']?.toString() ?? '이름 없음';

    final category =
        spot['hubCtgryMclsNm']?.toString();

    final address =
        spot['signguNm']?.toString();

    // ------------------------------------------------------------
    // 좌표 처리
    //
    // 데이터에 따라 lat/lng, latitude/longitude,
    // x/y 등의 이름이 다를 수 있으므로 여러 형태 지원
    // ------------------------------------------------------------

    double? latitude = _toDouble(
      spot['latitude'] ??
          spot['lat'] ??
          spot['y'],
    );

    double? longitude = _toDouble(
      spot['longitude'] ??
          spot['lng'] ??
          spot['lon'] ??
          spot['x'],
    );

    // ------------------------------------------------------------
    // contentId
    // ------------------------------------------------------------

    final contentId =
        spot['contentId']?.toString();

    // ------------------------------------------------------------
    // Kakao 관련 정보
    // ------------------------------------------------------------

    final kakaoPlaceId =
        spot['kakaoPlaceId']?.toString();

    final kakaoPlaceUrl =
        spot['kakaoPlaceUrl']?.toString();

    return TravelSpot(
      name: name,
      category: category,
      address: address,
      latitude: latitude,
      longitude: longitude,
      congestion: result.averageCongestion,
      snobScore: result.snobScore,
      contentId: contentId,
      kakaoPlaceId: kakaoPlaceId,
      kakaoPlaceUrl: kakaoPlaceUrl,
      startMinute: null,
      durationMinutes: 60,
      travelMinutesFromPrevious: 0,
    );
  }

  // ============================================================
  // 숫자 변환
  // ============================================================

  double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  // ============================================================
  // 특정 Day 찾기
  // ============================================================

  TravelDay? _findDay(int dayNumber) {
    for (final day in travelPlan.days) {
      if (day.day == dayNumber) {
        return day;
      }
    }

    return null;
  }

  // ============================================================
  // 관광지를 일정에 추가
  // ============================================================

  Future<void> _addToPlan(
    SnobCongestionResult result,
    int dayNumber,
  ) async {
    if (isSaving) return;

    final day = _findDay(dayNumber);

    if (day == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '해당 여행 일정을 찾을 수 없습니다.',
          ),
        ),
      );
      return;
    }

    final spot = _createTravelSpot(result);

    // ------------------------------------------------------------
    // 중복 체크
    // ------------------------------------------------------------

    final alreadyExists = day.spots.any(
      (existingSpot) =>
          existingSpot.name == spot.name,
    );

    if (alreadyExists) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${spot.name}은(는) 이미 Day $dayNumber에 추가되어 있어요.',
          ),
        ),
      );

      return;
    }

    // ------------------------------------------------------------
    // 일정에 직접 추가
    // ------------------------------------------------------------

    setState(() {
      isSaving = true;
    });

    day.spots.add(spot);
    travelPlan.updatedAt = DateTime.now();

    try {
      await TravelPlanStorage.saveTravelPlan(
        travelPlan,
      );

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${spot.name}이(가) Day $dayNumber 일정에 추가됐어요.',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      // 저장 실패 시 방금 추가한 관광지를 되돌린다.
      day.spots.remove(spot);

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '일정 저장 중 오류가 발생했습니다.\n$e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // 일정에 이미 추가됐는지 확인
  // ============================================================

  bool _isAdded(String spotName) {
    return travelPlan.days
        .expand((day) => day.spots)
        .any(
          (spot) => spot.name == spotName,
        );
  }

  // ============================================================
  // 해당 관광지가 몇 일차에 있는지
  // ============================================================

  int? _getAddedDay(String spotName) {
    for (final day in travelPlan.days) {
      final exists = day.spots.any(
        (spot) => spot.name == spotName,
      );

      if (exists) {
        return day.day;
      }
    }

    return null;
  }

  // ============================================================
  // Day 추가
  // ============================================================

  Future<void> _addDay() async {
    final nextDay = travelPlan.days.isEmpty
        ? 1
        : travelPlan.days
                .map((day) => day.day)
                .reduce(
                  (a, b) => a > b ? a : b,
                ) +
            1;

    travelPlan.days.add(
      TravelDay(
        day: nextDay,
      ),
    );

    travelPlan.days.sort(
      (a, b) => a.day.compareTo(b.day),
    );

    travelPlan.updatedAt = DateTime.now();

    await TravelPlanStorage.saveTravelPlan(
      travelPlan,
    );

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Day $nextDay이 추가됐어요.',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ============================================================
  // 현재 일정 보기
  // ============================================================

  void _showPlan() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (
            context,
            setModalState,
          ) {
            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.of(context).size.height *
                          0.8,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    10,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // ------------------------------------------------
                      // 제목
                      // ------------------------------------------------

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  travelPlan.regionName,
                                  style:
                                      const TextStyle(
                                    fontSize: 22,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${travelPlan.totalSpotCount}곳의 관광지가 추가됨',
                                  style:
                                      const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                              );
                            },
                            icon: const Icon(
                              Icons.close,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // ------------------------------------------------
                      // Day 목록
                      // ------------------------------------------------

                      Expanded(
                        child: ListView(
                          children: [
                            ...travelPlan.days.map(
                              (day) {
                                return _buildDaySection(
                                  day,
                                  setModalState,
                                );
                              },
                            ),

                            const SizedBox(height: 10),

                            // ------------------------------------------------
                            // Day 추가
                            // ------------------------------------------------

                            OutlinedButton.icon(
                              onPressed: () async {
                                await _addDay();

                                if (mounted) {
                                  setModalState(() {});
                                }
                              },
                              icon: const Icon(
                                Icons.add,
                              ),
                              label: const Text(
                                '여행 일정 추가',
                              ),
                            ),

                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // Day 하나 표시
  // ============================================================

  Widget _buildDaySection(
    TravelDay day,
    StateSetter setModalState,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------
            // Day 제목
            // ------------------------------------------------

            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    'DAY ${day.day}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${day.spots.length}곳',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ------------------------------------------------
            // 관광지 없음
            // ------------------------------------------------

            if (day.spots.isEmpty)
              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 12,
                ),
                child: Text(
                  '아직 추가한 관광지가 없어요.',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              )

            // ------------------------------------------------
            // 관광지 목록
            // ------------------------------------------------

            else
              ...day.spots
                  .asMap()
                  .entries
                  .map(
                (entry) {
                  final index = entry.key;
                  final spot = entry.value;

                  return ListTile(
                    contentPadding:
                        EdgeInsets.zero,

                    leading: CircleAvatar(
                      radius: 17,
                      child: Text(
                        '${index + 1}',
                        style:
                            const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ),

                    title: Text(
                      spot.name,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    subtitle:
                        spot.category != null
                            ? Text(
                                spot.category!,
                              )
                            : null,

                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                      ),
                      onPressed: () async {
                        // ------------------------------------------------
                        // 직접 삭제
                        // ------------------------------------------------

                        day.spots.removeWhere(
                          (item) =>
                              item.name ==
                              spot.name,
                        );

                        travelPlan.updatedAt =
                            DateTime.now();

                        await TravelPlanStorage
                            .saveTravelPlan(
                          travelPlan,
                        );

                        if (!mounted) return;

                        setState(() {});
                        setModalState(() {});
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 일정 추가할 Day 선택
  // ============================================================

  void _showDaySelector(
    SnobCongestionResult result,
  ) {
    showModalBottomSheet(
      context: context,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(20),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  '어느 날에 추가할까요?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  result.spot['hubTatsNm']
                          ?.toString() ??
                      '관광지',
                  style:
                      const TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 20),

                ...travelPlan.days.map(
                  (day) {
                    return ListTile(
                      leading:
                          CircleAvatar(
                        child: Text(
                          '${day.day}',
                        ),
                      ),

                      title: Text(
                        'Day ${day.day}',
                      ),

                      subtitle: Text(
                        '${day.spots.length}곳',
                      ),

                      trailing:
                          const Icon(
                        Icons.chevron_right,
                      ),

                      onTap: isSaving
                          ? null
                          : () {
                              _addToPlan(
                                result,
                                day.day,
                              );
                            },
                    );
                  },
                ),

                const SizedBox(height: 8),

                OutlinedButton.icon(
                  onPressed: isSaving
                      ? null
                      : () async {
                          Navigator.pop(
                            context,
                          );

                          await _addDay();

                          if (!mounted) return;

                          _showDaySelector(
                            result,
                          );
                        },
                  icon: const Icon(
                    Icons.add,
                  ),
                  label: const Text(
                    '새로운 Day 추가',
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    minimumSize:
                        const Size(
                      double.infinity,
                      48,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('코스 추천'),
        actions: [
          if (travelPlan.totalSpotCount > 0)
            IconButton(
              icon: const Icon(
                Icons.calendar_today_outlined,
              ),
              onPressed: _showPlan,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  // ============================================================
  // Body
  // ============================================================

  Widget _buildBody() {
    // ----------------------------------------------------------
    // 로딩
    // ----------------------------------------------------------

    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),

            SizedBox(height: 20),

            Text(
              '관광지 혼잡도를 분석하고 있어요.',
              style: TextStyle(
                fontSize: 15,
              ),
            ),

            SizedBox(height: 8),

            Text(
              '잠시만 기다려주세요.',
              style: TextStyle(
                color: Colors.grey,
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
          padding:
              const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.grey,
              ),

              const SizedBox(height: 15),

              const Text(
                '코스 추천 중 오류가 발생했습니다.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                errorMessage!,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // 결과 없음
    // ----------------------------------------------------------

    if (results.isEmpty) {
      return const Center(
        child: Text(
          '혼잡도 데이터를 조회할 수 있는\n관광지가 없습니다.',
          textAlign:
              TextAlign.center,
        ),
      );
    }

    // ----------------------------------------------------------
    // 결과 화면
    // ----------------------------------------------------------

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        // ========================================================
        // 추천 지역
        // ========================================================

        Padding(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            14,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                '추천 지역',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                widget.regionName,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                '혼잡도가 낮고 SNOB 점수가 높은 관광지부터 추천해드려요.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

        const Divider(
          height: 1,
        ),

        // ========================================================
        // 관광지 목록
        // ========================================================

        Expanded(
          child: ListView.builder(
            padding:
                const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder:
                (context, index) {
              final result =
                  results[index];

              final spot =
                  result.spot;

              final spotName =
                  spot['hubTatsNm']
                          ?.toString() ??
                      '이름 없음';

              final middleCategory =
                  spot['hubCtgryMclsNm']
                          ?.toString() ??
                      '';

              final signguName =
                  spot['signguNm']
                          ?.toString() ??
                      '';

              final isAdded =
                  _isAdded(spotName);

              final addedDay =
                  _getAddedDay(
                spotName,
              );

              return Card(
                elevation: 0,
                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  side: BorderSide(
                    color:
                        Colors.grey.shade200,
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          // ------------------------------------------------
                          // 순위
                          // ------------------------------------------------

                          CircleAvatar(
                            radius: 20,
                            child: Text(
                              '${index + 1}',
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 14,
                          ),

                          // ------------------------------------------------
                          // 관광지 정보
                          // ------------------------------------------------

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  spotName,
                                  style:
                                      const TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 5,
                                ),

                                if (middleCategory
                                    .isNotEmpty)
                                  Text(
                                    middleCategory,
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.grey,
                                      fontSize:
                                          13,
                                    ),
                                  ),

                                if (signguName
                                    .isNotEmpty)
                                  Text(
                                    signguName,
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.grey,
                                      fontSize:
                                          13,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      // ====================================================
                      // 점수 영역
                      // ====================================================

                      Row(
                        children: [
                          Expanded(
                            child:
                                _ScoreBox(
                              title: 'SNOB',
                              value: result
                                  .snobScore
                                  .toStringAsFixed(
                                1,
                              ),
                              icon: Icons
                                  .travel_explore,
                            ),
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          Expanded(
                            child:
                                _ScoreBox(
                              title:
                                  '30일 평균 혼잡도',
                              value: result
                                  .averageCongestion
                                  .toStringAsFixed(
                                1,
                              ),
                              icon: Icons
                                  .people_outline,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      // ====================================================
                      // 일정 추가 버튼
                      // ====================================================

                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            FilledButton.icon(
                          onPressed:
                              isAdded ||
                                      isSaving
                                  ? null
                                  : () {
                                      _showDaySelector(
                                        result,
                                      );
                                    },
                          icon: Icon(
                            isAdded
                                ? Icons.check
                                : Icons.add,
                          ),
                          label: Text(
                            isAdded
                                ? 'Day $addedDay 일정에 추가됨'
                                : '일정에 추가',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ================================================================
// 점수 박스
// ================================================================

class _ScoreBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ScoreBox({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey.shade700,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}