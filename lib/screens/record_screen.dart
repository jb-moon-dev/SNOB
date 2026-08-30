import 'package:flutter/material.dart';


// ================================================================
// 여행 기록 데이터
// ================================================================

class TravelRecord {
  final String region;
  final String title;
  final String startDate;
  final String endDate;
  final int placeCount;

  final String typeName;
  final int natureScore;
  final int cityScore;
  final int peopleScore;

  final String recommendedRegion;
  final String recommendedDescription;

  final List<String> courses;

  String? diary;
  int mood;

  TravelRecord({
    required this.region,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.placeCount,
    required this.typeName,
    required this.natureScore,
    required this.cityScore,
    required this.peopleScore,
    required this.recommendedRegion,
    required this.recommendedDescription,
    required this.courses,
    this.diary,
    this.mood = 3,
  });
}


// ================================================================
// 기록 화면
// ================================================================

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}


class _RecordScreenState extends State<RecordScreen> {

  // --------------------------------------------------------------
  // 임시 여행 기록
  // --------------------------------------------------------------

  final List<TravelRecord> _records = [

    TravelRecord(
      region: '제주',
      title: '제주, 자연 속으로',
      startDate: '2026.08.18',
      endDate: '2026.08.22',
      placeCount: 8,
      typeName: '자연형 여행자',
      natureScore: 86,
      cityScore: 38,
      peopleScore: 61,
      recommendedRegion: '제주특별자치도',
      recommendedDescription:
          '자연과 여유를 중심으로 여행하기 좋은 지역',
      courses: [
        'DAY 1  제주공항 → 동문시장 → 용두암',
        'DAY 2  성산일출봉 → 섭지코지 → 우도',
        'DAY 3  애월 → 한담해안산책로',
      ],
      diary:
          '제주에서 보낸 5일은 생각보다 훨씬 여유로웠다.\n\n'
          '사람이 많은 곳보다 한적한 바닷길을 걸었던 순간이 가장 기억에 남는다.',
      mood: 4,
    ),

    TravelRecord(
      region: '강릉',
      title: '강릉, 바다를 따라',
      startDate: '2026.07.12',
      endDate: '2026.07.14',
      placeCount: 5,
      typeName: '힐링형 여행자',
      natureScore: 72,
      cityScore: 45,
      peopleScore: 34,
      recommendedRegion: '강원특별자치도',
      recommendedDescription:
          '조용한 자연과 여유로운 시간을 보내기 좋은 지역',
      courses: [
        'DAY 1  강릉역 → 안목해변 → 경포호',
        'DAY 2  정동진 → 하슬라아트월드',
        'DAY 3  주문진 → 영진해변',
      ],
      diary: '',
      mood: 3,
    ),
  ];


  // ==============================================================
  // 기록 추가
  // ==============================================================

  void _addRecord() {

    final newRecord = TravelRecord(
      region: '새로운 여행',
      title: '새로운 여행 기록',
      startDate: '2026.08.30',
      endDate: '2026.08.30',
      placeCount: 0,

      // 나중에 테스트 결과와 연결
      typeName: '여행자 유형',
      natureScore: 50,
      cityScore: 50,
      peopleScore: 50,

      // 나중에 추천 시스템과 연결
      recommendedRegion: '추천 지역',
      recommendedDescription:
          '여행 성향을 바탕으로 추천된 지역입니다.',

      // 나중에 실제 여행 코스와 연결
      courses: [],
    );

    setState(() {
      _records.insert(0, newRecord);
    });

    // 새로 만든 여행 기록으로 바로 이동
    _openRecord(newRecord);
  }


  // ==============================================================
  // 여행 기록 상세 화면
  // ==============================================================

  void _openRecord(TravelRecord record) {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TravelRecordDetailScreen(
          record: record,
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }


  // ==============================================================
  // Build
  // ==============================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF7F8FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '기록',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),


      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            // ======================================================
            // 제목
            // ======================================================

            const Text(
              '나의 여행을 다시 만나보세요',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),


            // ======================================================
            // 나의 여행 요약 카드
            // ======================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Row(
                    children: [

                      Container(
                        width: 48,
                        height: 48,

                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),

                        child: const Center(
                          child: Text(
                            '✈️',
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      const Text(
                        '나의 여행',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Text(
                    '지금까지 ${_records.length}개의 여행을 기록했어요',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _records.isNotEmpty
                        ? '최근 여행  ${_records.first.region} · '
                          '${_records.first.startDate}'
                        : '아직 기록된 여행이 없어요',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),


            const SizedBox(height: 32),


            // ======================================================
            // 여행 기록
            // ======================================================

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [

                const Text(
                  '여행 기록',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                TextButton(
                  onPressed: _addRecord,

                  child: const Text(
                    '+ 여행 기록 만들기',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),


            // ======================================================
            // 여행 카드
            // ======================================================

            ..._records.map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: 16),

                child: GestureDetector(
                  onTap: () => _openRecord(record),

                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        // ------------------------------------------
                        // 여행 사진
                        // ------------------------------------------

                        Container(
                          height: 150,
                          width: double.infinity,

                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius:
                                BorderRadius.circular(15),
                          ),

                          child: const Center(
                            child: Text(
                              '📸 여행 사진',
                              style: TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        Text(
                          record.region,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 7),

                        Text(
                          '${record.startDate} - ${record.endDate}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [

                            Icon(
                              Icons.location_on_outlined,
                              size: 17,
                              color: Colors.grey.shade600,
                            ),

                            const SizedBox(width: 4),

                            Text(
                              '${record.placeCount}곳 방문',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),


            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}


// ==================================================================
// 여행 기록 상세 화면
// ==================================================================

class TravelRecordDetailScreen extends StatefulWidget {

  final TravelRecord record;

  const TravelRecordDetailScreen({
    super.key,
    required this.record,
  });

  @override
  State<TravelRecordDetailScreen> createState() =>
      _TravelRecordDetailScreenState();
}


class _TravelRecordDetailScreenState
    extends State<TravelRecordDetailScreen> {

  late TextEditingController _diaryController;

  late int _mood;


  @override
  void initState() {
    super.initState();

    _diaryController = TextEditingController(
      text: widget.record.diary ?? '',
    );

    _mood = widget.record.mood;
  }


  @override
  void dispose() {
    _diaryController.dispose();
    super.dispose();
  }


  // ==============================================================
  // 기록 저장
  // ==============================================================

  void _saveRecord() {

    widget.record.diary =
        _diaryController.text.trim();

    widget.record.mood = _mood;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('여행 기록이 저장되었습니다.'),
      ),
    );

    setState(() {});
  }


  // ==============================================================
  // Build
  // ==============================================================

  @override
  Widget build(BuildContext context) {

    final record = widget.record;

    return Scaffold(

      backgroundColor: const Color(0xFFF7F8FA),


      // ============================================================
      // 상단
      // ============================================================

      appBar: AppBar(

        backgroundColor: Colors.white,

        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Text(
          record.region,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),


      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            // ======================================================
            // 대표 사진
            // ======================================================

            Container(
              width: double.infinity,
              height: 220,

              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),

              child: Stack(

                children: [

                  const Center(
                    child: Text(
                      '🌊 여행 대표사진',
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ),


                  Positioned(
                    bottom: 15,
                    right: 15,

                    child: ElevatedButton.icon(
                      onPressed: () {

                        // TODO:
                        // image_picker 연결
                      },

                      icon: const Icon(
                        Icons.add_a_photo,
                      ),

                      label: const Text(
                        '사진 추가',
                      ),
                    ),
                  ),
                ],
              ),
            ),


            const SizedBox(height: 25),


            // ======================================================
            // 여행 기본 정보
            // ======================================================

            Text(
              record.title,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              '${record.startDate} — ${record.endDate}',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 12),


            Row(
              children: [

                const Text(
                  '🌿 ',
                  style: TextStyle(fontSize: 18),
                ),

                Text(
                  record.typeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [

                const Text(
                  '📍 ',
                  style: TextStyle(fontSize: 18),
                ),

                Text(
                  record.region,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),


            const SizedBox(height: 30),

            const Divider(),

            const SizedBox(height: 25),


            // ======================================================
            // 여행 성향
            // ======================================================

            const Text(
              '🧠 나의 여행 성향',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),


            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    record.typeName,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  _ScoreBar(
                    title: '자연',
                    score: record.natureScore,
                  ),

                  const SizedBox(height: 12),

                  _ScoreBar(
                    title: '도시',
                    score: record.cityScore,
                  ),

                  const SizedBox(height: 12),

                  _ScoreBar(
                    title: '사람',
                    score: record.peopleScore,
                  ),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () {

                      // TODO:
                      // 테스트 결과 화면으로 이동

                    },

                    child: const Text(
                      '테스트 결과 다시 보기 ›',
                    ),
                  ),
                ],
              ),
            ),


            const SizedBox(height: 30),


            // ======================================================
            // 추천 지역
            // ======================================================

            const Text(
              '📍 추천 지역',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    record.recommendedRegion,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '"${record.recommendedDescription}"',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),


            const SizedBox(height: 30),


            // ======================================================
            // 여행 코스
            // ======================================================

            const Text(
              '🗺️ 나의 여행 코스',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),

              child: record.courses.isEmpty

                  ? const Text(
                      '아직 기록된 여행 코스가 없습니다.',
                    )

                  : Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        for (final course
                            in record.courses) ...[

                          Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 15,
                            ),

                            child: Text(
                              course,
                              style: const TextStyle(
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],

                        TextButton(
                          onPressed: () {

                            // TODO:
                            // 전체 일정 화면

                          },

                          child: const Text(
                            '전체 일정 보기 ›',
                          ),
                        ),
                      ],
                    ),
            ),


            const SizedBox(height: 30),


            // ======================================================
            // 여행 일기
            // ======================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(
                    '✍️ 여행 일기',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    '이번 여행은 어땠나요?',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 15),


                  // ------------------------------------------------
                  // 일기 입력
                  // ------------------------------------------------

                  TextField(
                    controller: _diaryController,

                    maxLines: 8,

                    decoration: InputDecoration(

                      hintText:
                          '여행에서 느낀 점을 자유롭게 기록해보세요.',

                      filled: true,

                      fillColor:
                          const Color(0xFFF7F8FA),

                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(15),

                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),


                  const SizedBox(height: 25),


                  // ------------------------------------------------
                  // 기분
                  // ------------------------------------------------

                  const Text(
                    '😊 이번 여행의 기분',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),


                  Row(

                    mainAxisAlignment:
                        MainAxisAlignment.spaceAround,

                    children: [

                      _MoodButton(
                        emoji: '😫',
                        index: 1,
                        selected: _mood,
                        onTap: () {
                          setState(() {
                            _mood = 1;
                          });
                        },
                      ),

                      _MoodButton(
                        emoji: '😐',
                        index: 2,
                        selected: _mood,
                        onTap: () {
                          setState(() {
                            _mood = 2;
                          });
                        },
                      ),

                      _MoodButton(
                        emoji: '🙂',
                        index: 3,
                        selected: _mood,
                        onTap: () {
                          setState(() {
                            _mood = 3;
                          });
                        },
                      ),

                      _MoodButton(
                        emoji: '😊',
                        index: 4,
                        selected: _mood,
                        onTap: () {
                          setState(() {
                            _mood = 4;
                          });
                        },
                      ),

                      _MoodButton(
                        emoji: '🤩',
                        index: 5,
                        selected: _mood,
                        onTap: () {
                          setState(() {
                            _mood = 5;
                          });
                        },
                      ),
                    ],
                  ),


                  const SizedBox(height: 25),


                  // ------------------------------------------------
                  // 저장
                  // ------------------------------------------------

                  SizedBox(
                    width: double.infinity,
                    height: 52,

                    child: ElevatedButton(

                      onPressed: _saveRecord,

                      child: const Text(
                        '기록 저장',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),


            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}


// ==================================================================
// 점수 바
// ==================================================================

class _ScoreBar extends StatelessWidget {

  final String title;
  final int score;

  const _ScoreBar({
    required this.title,
    required this.score,
  });


  @override
  Widget build(BuildContext context) {

    return Row(

      children: [

        SizedBox(
          width: 45,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),

        Expanded(
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(10),

            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 9,
              backgroundColor:
                  Colors.grey.shade200,
            ),
          ),
        ),

        const SizedBox(width: 10),

        SizedBox(
          width: 30,

          child: Text(
            '$score',
            textAlign: TextAlign.right,

            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}


// ==================================================================
// 기분 버튼
// ==================================================================

class _MoodButton extends StatelessWidget {

  final String emoji;
  final int index;
  final int selected;
  final VoidCallback onTap;

  const _MoodButton({
    required this.emoji,
    required this.index,
    required this.selected,
    required this.onTap,
  });


  @override
  Widget build(BuildContext context) {

    final isSelected = index == selected;

    return GestureDetector(

      onTap: onTap,

      child: AnimatedContainer(

        duration:
            const Duration(milliseconds: 200),

        width: 48,
        height: 48,

        decoration: BoxDecoration(

          color: isSelected
              ? Colors.blue.shade50
              : Colors.transparent,

          shape: BoxShape.circle,

          border: Border.all(
            color: isSelected
                ? Colors.blue
                : Colors.transparent,
            width: 2,
          ),
        ),

        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(
              fontSize: 25,
            ),
          ),
        ),
      ),
    );
  }
}