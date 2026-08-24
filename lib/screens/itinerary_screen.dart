import 'package:flutter/material.dart';

import '../models/travel_plan.dart';
import '../services/travel_plan_storage.dart';

class ItineraryScreen extends StatefulWidget {
  final TravelPlan travelPlan;

  const ItineraryScreen({
    super.key,
    required this.travelPlan,
  });

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  late TravelPlan travelPlan;

  int selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();

    travelPlan = widget.travelPlan;

    if (travelPlan.days.isEmpty) {
      travelPlan.days.add(
        TravelDay(day: 1),
      );
    }
  }

  // ============================================================
  // 현재 Day
  // ============================================================

  TravelDay get currentDay {
    if (selectedDayIndex >= travelPlan.days.length) {
      selectedDayIndex = 0;
    }

    return travelPlan.days[selectedDayIndex];
  }

  // ============================================================
  // 일정 저장
  // ============================================================

  Future<void> _savePlan() async {
    travelPlan.updatedAt = DateTime.now();

    await TravelPlanStorage.saveTravelPlan(
      travelPlan,
    );
  }

  // ============================================================
  // 시간 포맷
  // ============================================================

  String _formatMinute(int? minute) {
    if (minute == null) {
      return '--:--';
    }

    final hour = minute ~/ 60;
    final min = minute % 60;

    return '${hour.toString().padLeft(2, '0')}:'
        '${min.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // 관광지 추가
  // ============================================================

  void _showAddPlaceDialog() {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            '장소 추가',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ------------------------------------------------
                // 장소명
                // ------------------------------------------------

                TextField(
                  controller: nameController,

                  // 한글 / 일반 텍스트 입력
                  keyboardType: TextInputType.text,

                  // 다음 입력칸으로 이동
                  textInputAction: TextInputAction.next,

                  // 한글 입력 시 자동 추천 허용
                  enableSuggestions: true,

                  // 장소명은 자동 수정하지 않음
                  autocorrect: false,

                  decoration: const InputDecoration(
                    labelText: '장소명',
                    hintText: '예: 죽녹원',
                    prefixIcon: Icon(
                      Icons.place_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                // ------------------------------------------------
                // 카테고리
                // ------------------------------------------------

                TextField(
                  controller: categoryController,

                  keyboardType: TextInputType.text,

                  textInputAction: TextInputAction.done,

                  enableSuggestions: true,

                  autocorrect: false,

                  decoration: const InputDecoration(
                    labelText: '카테고리',
                    hintText: '예: 자연',
                    prefixIcon: Icon(
                      Icons.category_outlined,
                    ),
                    border: OutlineInputBorder(),
                  ),

                  onSubmitted: (_) {
                    _addPlaceFromDialog(
                      dialogContext,
                      nameController,
                      categoryController,
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                _addPlaceFromDialog(
                  dialogContext,
                  nameController,
                  categoryController,
                );
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    ).then((_) {
      // 다이얼로그가 완전히 닫힌 뒤 컨트롤러 정리
      nameController.dispose();
      categoryController.dispose();
    });
  }

  // ============================================================
  // 직접 장소 추가 처리
  // ============================================================

  Future<void> _addPlaceFromDialog(
    BuildContext dialogContext,
    TextEditingController nameController,
    TextEditingController categoryController,
  ) async {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '장소명을 입력해주세요.',
          ),
        ),
      );
      return;
    }

    final categoryText =
        categoryController.text.trim();

    // ----------------------------------------------------------
    // 중복 확인
    // ----------------------------------------------------------

    final alreadyExists = currentDay.spots.any(
      (item) => item.name == name,
    );

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '이미 같은 장소가 일정에 있어요.',
          ),
        ),
      );
      return;
    }

    // ----------------------------------------------------------
    // 장소 생성
    // ----------------------------------------------------------

    final spot = TravelSpot(
      name: name,
      category:
          categoryText.isEmpty
              ? null
              : categoryText,
      startMinute: null,
      durationMinutes: 60,
      travelMinutesFromPrevious: 0,
    );

    // ----------------------------------------------------------
    // 일정에 추가
    // ----------------------------------------------------------

    setState(() {
      currentDay.spots.add(spot);
    });

    // ----------------------------------------------------------
    // 저장
    // ----------------------------------------------------------

    await _savePlan();

    if (!mounted) return;

    Navigator.pop(dialogContext);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$name이(가) 일정에 추가됐어요.',
        ),
      ),
    );
  }

  // ============================================================
  // 관광지 삭제
  // ============================================================

  Future<void> _removeSpot(
    TravelSpot spot,
  ) async {
    setState(() {
      currentDay.spots.remove(spot);
    });

    await _savePlan();
  }

  // ============================================================
  // 체류시간 변경
  // ============================================================

  Future<void> _changeDuration(
    TravelSpot spot,
  ) async {
    final options = <int>[
      30,
      60,
      90,
      120,
      150,
      180,
    ];

    final selected =
        await showModalBottomSheet<int>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Align(
                  alignment:
                      Alignment.centerLeft,
                  child: Text(
                    '머무르는 시간',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              ...options.map(
                (minutes) {
                  final isSelected =
                      spot.durationMinutes ==
                          minutes;

                  return ListTile(
                    title: Text(
                      _durationText(minutes),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(
                        context,
                        minutes,
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    setState(() {
      final index =
          currentDay.spots.indexOf(spot);

      if (index != -1) {
        currentDay.spots[index] =
            spot.copyWith(
          durationMinutes: selected,
        );
      }
    });

    await _savePlan();
  }

  // ============================================================
  // 체류시간 텍스트
  // ============================================================

  String _durationText(int minutes) {
    if (minutes < 60) {
      return '$minutes분';
    }

    final hour = minutes ~/ 60;
    final remain = minutes % 60;

    if (remain == 0) {
      return '$hour시간';
    }

    return '$hour시간 $remain분';
  }

  // ============================================================
  // 일정 카드
  // ============================================================

  Widget _buildSpotCard(
    TravelSpot spot,
    int index,
  ) {
    return Dismissible(
      key: ValueKey(
        '${currentDay.day}_${spot.name}_$index',
      ),
      direction:
          DismissDirection.endToStart,

      background: Container(
        margin: const EdgeInsets.only(
          bottom: 12,
        ),
        alignment:
            Alignment.centerRight,
        padding:
            const EdgeInsets.only(
          right: 20,
        ),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.red,
        ),
      ),

      onDismissed: (_) {
        _removeSpot(spot);
      },

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // 시간
          // ------------------------------------------------------

          SizedBox(
            width: 52,
            child: Column(
              children: [
                Text(
                  _formatMinute(
                    spot.startMinute,
                  ),
                  style:
                      const TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Container(
                  width: 10,
                  height: 10,
                  decoration:
                      const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),

          // ------------------------------------------------------
          // Timeline
          // ------------------------------------------------------

          Column(
            children: [
              Container(
                width: 2,
                height: 24,
                color:
                    Colors.grey.shade300,
              ),

              Container(
                width: 12,
                height: 12,
                decoration:
                    BoxDecoration(
                  shape:
                      BoxShape.circle,
                  border: Border.all(
                    width: 3,
                    color:
                        Theme.of(context)
                            .colorScheme
                            .primary,
                  ),
                ),
              ),

              if (index <
                  currentDay.spots.length -
                      1)
                Container(
                  width: 2,
                  height: 150,
                  color:
                      Colors.grey.shade300,
                ),
            ],
          ),

          const SizedBox(width: 12),

          // ------------------------------------------------------
          // 카드
          // ------------------------------------------------------

          Expanded(
            child: Card(
              elevation: 0,
              margin:
                  const EdgeInsets.only(
                bottom: 12,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  18,
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
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    // ------------------------------------------------
                    // 장소명 + 메뉴
                    // ------------------------------------------------

                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Expanded(
                          child: Text(
                            spot.name,
                            style:
                                const TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ),

                        PopupMenuButton<
                            String>(
                          onSelected:
                              (value) {
                            if (value ==
                                'duration') {
                              _changeDuration(
                                spot,
                              );
                            }

                            if (value ==
                                'delete') {
                              _removeSpot(
                                spot,
                              );
                            }
                          },
                          itemBuilder:
                              (context) =>
                                  const [
                            PopupMenuItem(
                              value:
                                  'duration',
                              child: Text(
                                '체류시간 변경',
                              ),
                            ),
                            PopupMenuItem(
                              value:
                                  'delete',
                              child: Text(
                                '삭제',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // ------------------------------------------------
                    // 카테고리
                    // ------------------------------------------------

                    if (spot.category !=
                        null) ...[
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        spot.category!,
                        style: TextStyle(
                          color:
                              Colors.grey
                                  .shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],

                    // ------------------------------------------------
                    // 주소
                    // ------------------------------------------------

                    if (spot.address !=
                        null) ...[
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        spot.address!,
                        style: TextStyle(
                          color:
                              Colors.grey
                                  .shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],

                    const SizedBox(
                      height: 14,
                    ),

                    // ------------------------------------------------
                    // 정보
                    // ------------------------------------------------

                    Row(
                      children: [
                        _InfoChip(
                          icon:
                              Icons.schedule,
                          text:
                              _durationText(
                            spot.durationMinutes,
                          ),
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        if (spot.snobScore !=
                            null)
                          _InfoChip(
                            icon:
                                Icons
                                    .eco_outlined,
                            text:
                                'SNOB ${spot.snobScore!.toStringAsFixed(0)}',
                          ),
                      ],
                    ),

                    // ------------------------------------------------
                    // 혼잡도
                    // ------------------------------------------------

                    if (spot.congestion !=
                        null) ...[
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        '평균 혼잡도 '
                        '${spot.congestion!.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Colors.grey
                                  .shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 일정 요약
  // ============================================================

  Widget _buildDaySummary() {
    final spots = currentDay.spots;

    int totalDuration = 0;
    int totalTravel = 0;

    for (final spot in spots) {
      totalDuration +=
          spot.durationMinutes;

      totalTravel +=
          spot.travelMinutesFromPrevious;
    }

    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        12,
      ),
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              title: '방문 장소',
              value:
                  '${spots.length}곳',
            ),
          ),

          Expanded(
            child: _SummaryItem(
              title: '예상 체류',
              value:
                  _durationText(
                totalDuration,
              ),
            ),
          ),

          Expanded(
            child: _SummaryItem(
              title: '이동',
              value:
                  _durationText(
                totalTravel,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Day 선택
  // ============================================================

  Widget _buildDaySelector() {
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection:
            Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        itemCount:
            travelPlan.days.length,
        itemBuilder:
            (context, index) {
          final day =
              travelPlan.days[index];

          final selected =
              index ==
                  selectedDayIndex;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDayIndex =
                    index;
              });
            },
            child:
                AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 200,
              ),
              width: 76,
              margin:
                  const EdgeInsets.only(
                right: 10,
              ),
              decoration:
                  BoxDecoration(
                color: selected
                    ? Theme.of(
                        context,
                      )
                        .colorScheme
                        .primary
                    : Colors.white,
                borderRadius:
                    BorderRadius
                        .circular(16),
                border:
                    Border.all(
                  color: selected
                      ? Theme.of(
                          context,
                        )
                          .colorScheme
                          .primary
                      : Colors.grey
                          .shade200,
                ),
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  Text(
                    'DAY ${day.day}',
                    style: TextStyle(
                      fontSize: 12,
                      color: selected
                          ? Colors.white
                          : Colors.grey,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    '${day.spots.length}곳',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                      color: selected
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${travelPlan.regionName} 여행',
        ),
        actions: [
          IconButton(
            icon:
                const Icon(
              Icons.more_vert,
            ),
            onPressed: () {},
          ),
        ],
      ),

      body: Column(
        children: [
          const SizedBox(
            height: 8,
          ),

          _buildDaySelector(),

          _buildDaySummary(),

          const Divider(
            height: 1,
          ),

          Expanded(
            child: currentDay
                    .spots
                    .isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      16,
                      20,
                      16,
                      100,
                    ),
                    itemCount:
                        currentDay
                            .spots
                            .length,
                    itemBuilder:
                        (context, index) {
                      return _buildSpotCard(
                        currentDay
                            .spots[index],
                        index,
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            _showAddPlaceDialog,
        icon:
            const Icon(
          Icons.add,
        ),
        label:
            const Text(
          '장소 추가',
        ),
      ),
    );
  }

  // ============================================================
  // 빈 일정
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route_outlined,
              size: 64,
              color:
                  Colors.grey.shade400,
            ),

            const SizedBox(
              height: 20,
            ),

            const Text(
              '아직 일정이 없어요.',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              '추천 관광지를 추가하거나\n'
              '직접 장소를 추가해보세요.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            FilledButton.icon(
              onPressed:
                  _showAddPlaceDialog,
              icon:
                  const Icon(
                Icons.add,
              ),
              label:
                  const Text(
                '장소 추가',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 작은 정보 Chip
// ============================================================

class _InfoChip
    extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color:
                Colors.grey.shade700,
          ),

          const SizedBox(
            width: 4,
          ),

          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color:
                  Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 일정 요약 Item
// ============================================================

class _SummaryItem
    extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryItem({
    required this.title,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color:
                Colors.grey.shade600,
          ),
        ),

        const SizedBox(
          height: 5,
        ),

        Text(
          value,
          style:
              const TextStyle(
            fontSize: 15,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    );
  }
}