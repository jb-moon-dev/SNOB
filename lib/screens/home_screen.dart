import 'package:flutter/material.dart';

import 'trip/personality_test/personality_test_screen.dart';
import '../models/travel_plan.dart';
import '../services/travel_plan_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TravelPlan? savedPlan;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadTravelPlan();
  }

  // ============================================================
  // 저장된 여행 일정 불러오기
  // ============================================================

  Future<void> _loadTravelPlan() async {
    final plan =
        await TravelPlanStorage.loadTravelPlan();

    if (!mounted) return;

    setState(() {
      savedPlan = plan;
      isLoading = false;
    });
  }

  // ============================================================
  // 저장된 여행 일정 보기
  // ============================================================

  void _showSavedPlan() {
    if (savedPlan == null) return;

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
                // ------------------------------------------------
                // 제목
                // ------------------------------------------------

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${savedPlan!.regionName} 여행',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    Text(
                      '${savedPlan!.totalSpotCount}곳',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ------------------------------------------------
                // 일정
                // ------------------------------------------------

                if (savedPlan!.totalSpotCount == 0)
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(
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
                  ...savedPlan!.days.map(
                    (day) {
                      return Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            '${day.day}일차',
                            style:
                                const TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          ...day.spots
                              .asMap()
                              .entries
                              .map(
                            (entry) {
                              final index =
                                  entry.key;

                              final spot =
                                  entry.value;

                              return ListTile(
                                contentPadding:
                                    EdgeInsets
                                        .zero,

                                leading:
                                    CircleAvatar(
                                  child: Text(
                                    '${index + 1}',
                                  ),
                                ),

                                title:
                                    Text(
                                  spot.name,
                                ),

                                subtitle:
                                    spot.category !=
                                            null
                                        ? Text(
                                            spot.category!,
                                          )
                                        : null,
                              );
                            },
                          ),

                          const SizedBox(
                            height: 10,
                          ),
                        ],
                      );
                    },
                  ),

                // ------------------------------------------------
                // 삭제 버튼
                // ------------------------------------------------

                if (savedPlan!.totalSpotCount > 0)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await TravelPlanStorage
                            .deleteTravelPlan();

                        if (!mounted) return;

                        Navigator.pop(context);

                        setState(() {
                          savedPlan = null;
                        });

                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '여행 일정이 삭제됐어요.',
                            ),
                          ),
                        );
                      },

                      icon: const Icon(
                        Icons.delete_outline,
                      ),

                      label: const Text(
                        '여행 일정 삭제',
                      ),
                    ),
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
  // 화면
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Text(
              '홈 화면',
              style: TextStyle(
                fontSize: 24,
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            // ------------------------------------------------
            // 여행 성향 테스트
            // ------------------------------------------------

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const PersonalityTestScreen(),
                  ),
                ).then((_) {
                  // 돌아왔을 때 저장된 일정 다시 확인
                  _loadTravelPlan();
                });
              },

              child: const Text(
                '여행 성향 테스트 시작',
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            // ------------------------------------------------
            // 저장된 여행 일정
            // ------------------------------------------------

            if (!isLoading &&
                savedPlan != null &&
                savedPlan!.totalSpotCount > 0)
              ElevatedButton.icon(
                onPressed: _showSavedPlan,

                icon: const Icon(
                  Icons.calendar_today_outlined,
                ),

                label: Text(
                  '내 여행 일정 '
                  '(${savedPlan!.totalSpotCount}곳)',
                ),
              ),
          ],
        ),
      ),
    );
  }
}