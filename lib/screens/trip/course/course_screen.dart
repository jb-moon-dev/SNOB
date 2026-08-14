import 'package:flutter/material.dart';

import 'models/course_item.dart';
import 'package:snob/snob/user_vector.dart';

class CourseScreen extends StatefulWidget {
  // 사용자의 여행 성향
  final UserVector userVector;

  // 현재 추천된 지역 이름
  final String regionName;

  // 중심 관광지 목록
  final List<CourseItem> centerSpots;

  const CourseScreen({
    super.key,
    required this.userVector,
    required this.regionName,
    required this.centerSpots,
  });

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  late List<CourseItem> sortedSpots;

  CourseItem? selectedSpot;

  @override
  void initState() {
    super.initState();

    // 중심 관광지 최대 50개
    sortedSpots =
        List<CourseItem>.from(widget.centerSpots.take(50));

    // SNOB 지수가 낮은 순서
    sortedSpots.sort(
      (a, b) => a.snobIndex.compareTo(b.snobIndex),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '추천 여행지',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: sortedSpots.isEmpty
          ? _buildEmpty()
          : _buildSpotList(),
    );
  }

  // ============================================================
  // 관광지 목록
  // ============================================================

  Widget _buildSpotList() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // --------------------------------------------------------
        // 지역
        // --------------------------------------------------------

        Text(
          widget.regionName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          '당신의 여행 성향과 SNOB 지수를 기준으로\n'
          '상대적으로 여유로운 관광지를 추천해요.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 24),

        // --------------------------------------------------------
        // 안내
        // --------------------------------------------------------

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
                  'SNOB 지수가 낮을수록 관광객이 몰리는 정도가 낮고,\n'
                  '여행 성향에 더 적합한 관광지예요.',
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

        Text(
          '추천 관광지 ${sortedSpots.length}곳',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        // --------------------------------------------------------
        // 관광지 카드
        // --------------------------------------------------------

        ...List.generate(
          sortedSpots.length,
          (index) {
            final spot = sortedSpots[index];

            return _buildSpotCard(
              spot: spot,
              rank: index + 1,
            );
          },
        ),

        // --------------------------------------------------------
        // 선택한 관광지
        // --------------------------------------------------------

        if (selectedSpot != null) ...[
          const SizedBox(height: 24),

          _buildSelectedSpot(),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              // TODO:
              // 선택한 관광지를 기준으로
              // 대체 관광지 API 연결
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(
                double.infinity,
                52,
              ),
            ),
            child: const Text(
              '대체 관광지 보기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],

        const SizedBox(height: 30),
      ],
    );
  }

  // ============================================================
  // 관광지 카드
  // ============================================================

  Widget _buildSpotCard({
    required CourseItem spot,
    required int rank,
  }) {
    final bool isSelected =
        selectedSpot?.contentId == spot.contentId;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSpot = spot;
        });
      },

      child: Container(
        margin: const EdgeInsets.only(
          bottom: 14,
        ),

        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.withOpacity(0.08)
              : Colors.white,

          borderRadius:
              BorderRadius.circular(18),

          border: Border.all(
            color: isSelected
                ? Colors.green
                : Colors.grey.shade200,

            width: isSelected ? 2 : 1,
          ),

          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),

        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ----------------------------------------------------
            // 순위
            // ----------------------------------------------------

            Container(
              width: 38,
              height: 38,

              decoration: BoxDecoration(
                color: rank <= 3
                    ? Colors.green
                    : Colors.grey.shade200,

                shape: BoxShape.circle,
              ),

              alignment: Alignment.center,

              child: Text(
                '$rank',

                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,

                  color: rank <= 3
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ),

            const SizedBox(width: 14),

            // ----------------------------------------------------
            // 관광지 정보
            // ----------------------------------------------------

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    spot.title.isEmpty
                        ? '관광지 정보 없음'
                        : spot.title,

                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    spot.address.isEmpty
                        ? '주소 정보 없음'
                        : spot.address,

                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ------------------------------------------------
                  // SNOB 지수
                  // ------------------------------------------------

                  Row(
                    children: [
                      const Text(
                        'SNOB 지수 ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      Text(
                        spot.snobIndex
                            .toStringAsFixed(1),

                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 선택된 관광지
  // ============================================================

  Widget _buildSelectedSpot() {
    final spot = selectedSpot!;

    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.grey.shade50,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            '선택한 관광지',

            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            spot.title,

            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            spot.address,

            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'SNOB 지수 ${spot.snobIndex.toStringAsFixed(1)}',

            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 관광지가 없을 때
  // ============================================================

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.travel_explore,
              size: 60,
              color: Colors.grey,
            ),

            const SizedBox(height: 18),

            const Text(
              '추천할 관광지를 찾지 못했어요.',

              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              '잠시 후 다시 시도해주세요.',

              textAlign:
                  TextAlign.center,

              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}