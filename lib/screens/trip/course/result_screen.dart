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
  bool isLoading = true;

  String? errorMessage;

  List<SnobCongestionResult> results = [];

  // ============================================================
  // 여행 일정
  // ============================================================

  late TravelPlan travelPlan;

  @override
  void initState() {
    super.initState();

    // 일단 기본 여행 일정 생성
    travelPlan = TravelPlan.create(
      regionName: widget.regionName,
      dayCount: 1,
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

        print(
          '저장된 여행 일정 불러오기 완료: '
          '${savedPlan.regionName}',
        );

        print(
          '저장된 관광지 수: '
          '${savedPlan.totalSpotCount}',
        );
      } else {
        print('현재 지역에 해당하는 저장된 일정이 없습니다.');
      }
    } catch (e) {
      print('여행 일정 불러오기 오류: $e');
    }
  }

  // ============================================================
  // center50 관광지 50개
  //       ↓
  // SnobCongestion
  //       ↓
  // 30일 평균 혼잡도
  //       ↓
  // SNOB 점수
  //       ↓
  // 높은 점수 순 정렬
  // ============================================================

  Future<void> _calculateSnob() async {
    try {
      print('');
      print('========================================');
      print('COURSE RESULT 시작');
      print('추천 지역: ${widget.regionName}');
      print('관광지 수: ${widget.spots.length}');
      print('========================================');

      // 이미 만들어둔 SnobCongestion 사용
      final calculator = SnobCongestion();

      // center50.dart에서 받은 50개 관광지를 전달
      final calculatedResults =
          await calculator.calculate(widget.spots);

      if (!mounted) return;

      setState(() {
        results = calculatedResults;
        isLoading = false;
      });

      print('');
      print('========================================');
      print('SNOB 계산 완료');
      print('결과 수: ${calculatedResults.length}');
      print('========================================');

      for (int i = 0;
          i < calculatedResults.length;
          i++) {
        final result = calculatedResults[i];

        print('');
        print(
          '[${i + 1}] ${result.spot['hubTatsNm']}',
        );

        print(
          '30일 평균 혼잡도: '
          '${result.averageCongestion.toStringAsFixed(2)}',
        );

        print(
          'SNOB 점수: '
          '${result.snobScore.toStringAsFixed(2)}',
        );
      }

      print('');
      print('========================================');
      print('COURSE RESULT 종료');
      print('========================================');
    } catch (e) {
      print('');
      print('========================================');
      print('COURSE RESULT 오류');
      print(e);
      print('========================================');

      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  // ============================================================
  // 일정에 관광지 추가 + 저장
  // ============================================================

  Future<void> _addToPlan(
    SnobCongestionResult result,
  ) async {
    final spot = TravelSpot.fromMap(
      spot: result.spot,
      congestion: result.averageCongestion,
      snobScore: result.snobScore,
    );

    travelPlan.addSpot(
      day: 1,
      spot: spot,
    );

    // SharedPreferences에 저장
    await TravelPlanStorage.saveTravelPlan(
      travelPlan,
    );

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${spot.name}이(가) 일정에 추가됐어요.',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ============================================================
  // 이미 일정에 추가됐는지 확인
  // ============================================================

  bool _isAdded(String spotName) {
    return travelPlan.days
        .expand((day) => day.spots)
        .any(
          (spot) => spot.name == spotName,
        );
  }

  // ============================================================
  // 현재 일정 보기
  // ============================================================

  void _showPlan() {
    final spots = travelPlan.days.isNotEmpty
        ? travelPlan.days.first.spots
        : <TravelSpot>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.regionName} 일정',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${spots.length}곳',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                if (spots.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 25,
                    ),
                    child: Center(
                      child: Text(
                        '아직 추가한 관광지가 없어요.',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  ...spots.asMap().entries.map(
                    (entry) {
                      final index = entry.key;
                      final spot = entry.value;

                      return ListTile(
                        contentPadding:
                            EdgeInsets.zero,

                        leading: CircleAvatar(
                          child: Text(
                            '${index + 1}',
                          ),
                        ),

                        title: Text(spot.name),

                        subtitle:
                            spot.category != null
                                ? Text(spot.category!)
                                : null,

                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                          ),
                          onPressed: () async {
                            travelPlan.removeSpot(
                              day: 1,
                              spotName: spot.name,
                            );

                            await TravelPlanStorage
                                .saveTravelPlan(
                              travelPlan,
                            );

                            if (!mounted) return;

                            Navigator.pop(context);

                            setState(() {});

                            // 다시 일정창 열기
                            _showPlan();
                          },
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 10),
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

  Widget _buildBody() {
    // ------------------------------------------------------------
    // 로딩
    // ------------------------------------------------------------

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
            ),

            SizedBox(height: 8),

            Text(
              '잠시만 기다려주세요.',
            ),
          ],
        ),
      );
    }

    // ------------------------------------------------------------
    // 오류
    // ------------------------------------------------------------

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            '코스 추천 중 오류가 발생했습니다.\n\n'
            '$errorMessage',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // ------------------------------------------------------------
    // 결과 없음
    // ------------------------------------------------------------

    if (results.isEmpty) {
      return const Center(
        child: Text(
          '혼잡도 데이터를 조회할 수 있는 관광지가 없습니다.',
          textAlign: TextAlign.center,
        ),
      );
    }

    // ------------------------------------------------------------
    // 결과 화면
    // ------------------------------------------------------------

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        // ----------------------------------------------------------
        // 추천 지역
        // ----------------------------------------------------------

        Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            12,
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
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                '혼잡도가 낮은 관광지부터 추천해드려요.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

        const Divider(),

        // ----------------------------------------------------------
        // 관광지 목록
        // ----------------------------------------------------------

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];

              final spot = result.spot;

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

              // 일정에 이미 추가됐는지 확인
              final isAdded =
                  _isAdded(spotName);

              return Card(
                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),

                child: Padding(
                  padding:
                      const EdgeInsets.all(16),

                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      // ------------------------------------------------
                      // 순위
                      // ------------------------------------------------

                      CircleAvatar(
                        child: Text(
                          '${index + 1}',
                        ),
                      ),

                      const SizedBox(
                        width: 15,
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
                                ),
                              ),

                            const SizedBox(
                              height: 12,
                            ),

                            // ------------------------------------------------
                            // 혼잡도
                            // ------------------------------------------------

                            Text(
                              '30일 평균 혼잡도 '
                              '${result.averageCongestion.toStringAsFixed(2)}',
                              style:
                                  const TextStyle(
                                fontSize: 13,
                              ),
                            ),

                            const SizedBox(
                              height: 5,
                            ),

                            // ------------------------------------------------
                            // SNOB 점수
                            // ------------------------------------------------

                            Text(
                              'SNOB '
                              '${result.snobScore.toStringAsFixed(2)}',
                              style:
                                  const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),

                            const SizedBox(
                              height: 10,
                            ),

                            // ------------------------------------------------
                            // 일정 추가
                            // ------------------------------------------------

                            Align(
                              alignment:
                                  Alignment
                                      .centerRight,

                              child:
                                  TextButton.icon(
                                onPressed:
                                    isAdded
                                        ? null
                                        : () {
                                            _addToPlan(
                                              result,
                                            );
                                          },

                                icon: Icon(
                                  isAdded
                                      ? Icons.check
                                      : Icons.add,
                                  size: 18,
                                ),

                                label: Text(
                                  isAdded
                                      ? '추가됨'
                                      : '일정에 추가',
                                ),
                              ),
                            ),
                          ],
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