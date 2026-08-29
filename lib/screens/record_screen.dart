import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/travel_plan.dart';
import '../services/trip_record_storage.dart';

class RecordScreen extends StatefulWidget {
  final TravelPlan? travelPlan;

  const RecordScreen({
    super.key,
    this.travelPlan,
  });

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  List<TripRecord> _records = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  // ============================================================
  // 기록 불러오기
  // ============================================================

  Future<void> _loadRecords() async {
    try {
      final records = await TripRecordStorage.loadRecords();

      if (!mounted) return;

      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('여행 기록 불러오기 실패: $e');

      if (!mounted) return;

      setState(() {
        _records = [];
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // 새 기록 작성
  // ============================================================

  Future<void> _openCreateRecord() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordEditorScreen(
          travelPlan: widget.travelPlan,
        ),
      ),
    );

    await _loadRecords();
  }

  // ============================================================
  // 기록 상세
  // ============================================================

  Future<void> _openRecordDetail(
    TripRecord record,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordDetailScreen(
          record: record,
        ),
      ),
    );

    await _loadRecords();
  }

  // ============================================================
  // 기록 삭제
  // ============================================================

  Future<void> _deleteRecord(int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '여행 기록을 삭제할까요?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '삭제한 기록은 다시 복구할 수 없어요.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                '삭제',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await TripRecordStorage.deleteRecord(index);

    await _loadRecords();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('여행 기록을 삭제했어요.'),
      ),
    );
  }

  // ============================================================
  // 날짜
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // 화면
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: const Text(
          '기록',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateRecord,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add),
        label: const Text(
          '기록 추가',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadRecords,
              child: _records.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        8,
                        20,
                        110,
                      ),
                      children: [
                        _buildHeader(),

                        const SizedBox(height: 24),

                        ...List.generate(
                          _records.length,
                          (index) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: 14,
                              ),
                              child: _buildRecordCard(
                                _records[index],
                                index,
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
  // 상단 설명
  // ============================================================

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '나의 여행 기록',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '떠났던 여행의 순간들을 다시 만나보세요.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 기록 카드
  // ============================================================

  Widget _buildRecordCard(
    TripRecord record,
    int index,
  ) {
    final hasPhotos = record.photoPaths.isNotEmpty;

    return GestureDetector(
      onTap: () => _openRecordDetail(record),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(22),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------
            // 대표 사진
            // ----------------------------------------------------

            if (hasPhotos)
              SizedBox(
                height: 190,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(record.photoPaths.first),
                      fit: BoxFit.cover,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return _buildPhotoPlaceholder();
                      },
                    ),

                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.photo_library_outlined,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${record.photoPaths.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              _buildPhotoPlaceholder(),

            // ----------------------------------------------------
            // 내용
            // ----------------------------------------------------

            Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                17,
                12,
                17,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 17,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                record.regionName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        Text(
                          _formatDate(record.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            _buildSmallInfo(
                              Icons.place_outlined,
                              '${record.visitedPlaces.length}곳',
                            ),
                            const SizedBox(width: 12),
                            _buildSmallInfo(
                              Icons.photo_outlined,
                              '${record.photoPaths.length}장',
                            ),
                          ],
                        ),

                        if (record.diary.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            record.diary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteRecord(index);
                      }
                    },
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('삭제'),
                        ),
                      ];
                    },
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.grey,
                    ),
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
  // 작은 정보
  // ============================================================

  Widget _buildSmallInfo(
    IconData icon,
    String text,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 사진 없음
  // ============================================================

  Widget _buildPhotoPlaceholder() {
    return Container(
      height: 150,
      width: double.infinity,
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(
          Icons.landscape_outlined,
          size: 45,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  // ============================================================
  // 빈 상태
  // ============================================================

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '📖',
                        style: TextStyle(
                          fontSize: 35,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    '아직 여행 기록이 없어요',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '여행을 다녀온 뒤 사진과 일기를 남겨보세요.\n'
                    '나만의 여행 이야기가 차곡차곡 쌓여요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 25),

                  ElevatedButton.icon(
                    onPressed: _openCreateRecord,
                    icon: const Icon(Icons.add),
                    label: const Text(
                      '첫 여행 기록 남기기',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ================================================================
// 기록 작성 화면
// ================================================================

class RecordEditorScreen extends StatefulWidget {
  final TravelPlan? travelPlan;

  const RecordEditorScreen({
    super.key,
    this.travelPlan,
  });

  @override
  State<RecordEditorScreen> createState() =>
      _RecordEditorScreenState();
}

class _RecordEditorScreenState
    extends State<RecordEditorScreen> {
  final TextEditingController _diaryController =
      TextEditingController();

  final ImagePicker _picker = ImagePicker();

  List<String> _photoPaths = [];

  bool _isSaving = false;

  @override
  void dispose() {
    _diaryController.dispose();
    super.dispose();
  }

  // ============================================================
  // 사진 추가
  // ============================================================

  Future<void> _pickPhoto() async {
    try {
      final XFile? image =
          await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) {
        return;
      }

      setState(() {
        _photoPaths.add(image.path);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            '사진을 불러오지 못했어요.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // 사진 삭제
  // ============================================================

  void _removePhoto(int index) {
    setState(() {
      _photoPaths.removeAt(index);
    });
  }

  // ============================================================
  // 기록 저장
  // ============================================================

  Future<void> _saveRecord() async {
    if (widget.travelPlan == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            '먼저 여행 일정을 만들어주세요.',
          ),
        ),
      );
      return;
    }

    final plan = widget.travelPlan!;

    final visitedPlaces = <String>[];

    for (final day in plan.days) {
      for (final spot in day.spots) {
        visitedPlaces.add(spot.name);
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final record = TripRecord(
        regionName: plan.regionName,
        diary: _diaryController.text.trim(),
        photoPaths:
            List<String>.from(_photoPaths),
        visitedPlaces: visitedPlaces,
      );

      await TripRecordStorage.saveRecord(
        record,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            '여행 기록을 저장했어요 ✨',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint('기록 저장 실패: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            '기록 저장 중 문제가 발생했어요.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // 전체 방문 장소
  // ============================================================

  List<TravelSpot> _allSpots() {
    if (widget.travelPlan == null) {
      return [];
    }

    final result = <TravelSpot>[];

    for (final day in widget.travelPlan!.days) {
      result.addAll(day.spots);
    }

    return result;
  }

  // ============================================================
  // 화면
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final plan = widget.travelPlan;
    final spots = _allSpots();

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '새 여행 기록',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: plan == null
          ? _buildEmptyState()
          : SafeArea(
              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  40,
                ),
                children: [
                  _buildTripHeader(plan),

                  const SizedBox(height: 28),

                  _buildSectionTitle(
                    '이번 여행에서 방문한 곳',
                  ),

                  const SizedBox(height: 12),

                  _buildVisitedPlaces(spots),

                  const SizedBox(height: 28),

                  _buildSectionTitle(
                    '여행 사진',
                  ),

                  const SizedBox(height: 12),

                  _buildPhotoSection(),

                  const SizedBox(height: 28),

                  _buildSectionTitle(
                    '여행 일기',
                  ),

                  const SizedBox(height: 12),

                  _buildDiaryField(),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed:
                          _isSaving
                              ? null
                              : _saveRecord,
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.black,
                        foregroundColor:
                            Colors.white,
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : const Text(
                              '여행 기록 저장하기',
                              style:
                                  TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // 여행 헤더
  // ============================================================

  Widget _buildTripHeader(
    TravelPlan plan,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: const Center(
                  child: Text(
                    '🧳',
                    style: TextStyle(
                      fontSize: 23,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.regionName,
                      style:
                          const TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${plan.days.length}일 · '
                      '${plan.totalSpotCount}곳',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors
                            .grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            '여행을 떠났던 날의 기억을 남겨보세요.',
            style: TextStyle(
              fontSize: 13,
              color:
                  Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 방문 장소
  // ============================================================

  Widget _buildVisitedPlaces(
    List<TravelSpot> spots,
  ) {
    if (spots.isEmpty) {
      return Container(
        padding:
            const EdgeInsets.all(20),
        decoration:
            BoxDecoration(
          color:
              Colors.grey.shade50,
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: Text(
          '아직 일정에 등록된 장소가 없어요.',
          style: TextStyle(
            color:
                Colors.grey.shade600,
          ),
        ),
      );
    }

    return Container(
      decoration:
          BoxDecoration(
        color:
            Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (int i = 0;
              i < spots.length;
              i++)
            Column(
              children: [
                ListTile(
                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 16,
                  ),
                  leading:
                      Container(
                    width: 36,
                    height: 36,
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white,
                      borderRadius:
                          BorderRadius
                              .circular(
                        11,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    spots[i].name,
                    style:
                        const TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  subtitle:
                      spots[i].address !=
                              null
                          ? Text(
                              spots[i]
                                  .address!,
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                            )
                          : null,
                ),
                if (i != spots.length - 1)
                  Divider(
                    height: 1,
                    indent: 68,
                    color:
                        Colors.grey.shade200,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // ============================================================
  // 사진
  // ============================================================

  Widget _buildPhotoSection() {
    return SizedBox(
      height: 105,
      child: ListView.separated(
        scrollDirection:
            Axis.horizontal,
        itemCount:
            _photoPaths.length + 1,
        separatorBuilder:
            (_, __) =>
                const SizedBox(width: 10),
        itemBuilder:
            (context, index) {
          if (index ==
              _photoPaths.length) {
            return GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: 105,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.grey.shade50,
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  border: Border.all(
                    color:
                        Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    Icon(
                      Icons
                          .add_photo_alternate_outlined,
                      size: 27,
                      color: Colors
                          .grey.shade500,
                    ),
                    const SizedBox(
                        height: 7),
                    Text(
                      '사진 추가',
                      style:
                          TextStyle(
                        fontSize: 12,
                        color: Colors
                            .grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final path =
              _photoPaths[index];

          return Stack(
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                child: Image.file(
                  File(path),
                  width: 105,
                  height: 105,
                  fit: BoxFit.cover,
                ),
              ),

              Positioned(
                right: 6,
                top: 6,
                child:
                    GestureDetector(
                  onTap: () =>
                      _removePhoto(index),
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration:
                        const BoxDecoration(
                      color:
                          Colors.black54,
                      shape:
                          BoxShape.circle,
                    ),
                    child:
                        const Icon(
                      Icons.close,
                      color:
                          Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // 일기
  // ============================================================

  Widget _buildDiaryField() {
    return TextField(
      controller:
          _diaryController,
      maxLines: 7,
      maxLength: 1000,
      decoration:
          InputDecoration(
        hintText:
            '이번 여행에서 기억에 남았던 순간을 기록해보세요.\n\n'
            '어떤 장소가 좋았는지,\n'
            '어떤 기분이었는지 자유롭게 적어보세요.',
        hintStyle:
            TextStyle(
          fontSize: 13,
          color:
              Colors.grey.shade400,
          height: 1.5,
        ),
        filled: true,
        fillColor:
            Colors.grey.shade50,
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          borderSide:
              BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.all(
          18,
        ),
      ),
    );
  }

  // ============================================================
  // 빈 상태
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
            const Text(
              '🧳',
              style: TextStyle(
                fontSize: 50,
              ),
            ),
            const SizedBox(
                height: 20),
            const Text(
              '기록할 여행이 없어요',
              style:
                  TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
                height: 8),
            Text(
              '먼저 여행 일정을 만들어주세요.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Section title
  // ============================================================

  Widget _buildSectionTitle(
    String title,
  ) {
    return Text(
      title,
      style:
          const TextStyle(
        fontSize: 17,
        fontWeight:
            FontWeight.bold,
      ),
    );
  }
}

// ================================================================
// 기록 상세 화면
// ================================================================

class RecordDetailScreen extends StatelessWidget {
  final TripRecord record;

  const RecordDetailScreen({
    super.key,
    required this.record,
  });

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '여행 기록',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          40,
        ),
        children: [
          // ------------------------------------------------------
          // 제목
          // ------------------------------------------------------

          Text(
            record.regionName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            _formatDate(record.createdAt),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),

          // ------------------------------------------------------
          // 성향
          // ------------------------------------------------------

          if (record.personalityType != null ||
              record.recommendedRegion != null) ...[
            const SizedBox(height: 22),
            _buildPersonalityCard(),
          ],

          // ------------------------------------------------------
          // 사진
          // ------------------------------------------------------

          if (record.photoPaths.isNotEmpty) ...[
            const SizedBox(height: 28),

            const Text(
              '여행 사진',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 230,
              child: ListView.separated(
                scrollDirection:
                    Axis.horizontal,
                itemCount:
                    record.photoPaths.length,
                separatorBuilder:
                    (_, __) =>
                        const SizedBox(width: 10),
                itemBuilder:
                    (context, index) {
                  return ClipRRect(
                    borderRadius:
                        BorderRadius.circular(18),
                    child: Image.file(
                      File(
                        record.photoPaths[index],
                      ),
                      width: 230,
                      height: 230,
                      fit: BoxFit.cover,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return Container(
                          width: 230,
                          height: 230,
                          color:
                              Colors.grey.shade100,
                          child: const Icon(
                            Icons
                                .broken_image_outlined,
                            size: 40,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],

          // ------------------------------------------------------
          // 방문 장소
          // ------------------------------------------------------

          const SizedBox(height: 28),

          const Text(
            '방문한 곳',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          if (record.visitedPlaces.isEmpty)
            Text(
              '기록된 방문 장소가 없어요.',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  for (
                    int i = 0;
                    i < record.visitedPlaces.length;
                    i++
                  )
                    ListTile(
                      leading: Container(
                        width: 34,
                        height: 34,
                        alignment:
                            Alignment.center,
                        decoration:
                            const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        record.visitedPlaces[i],
                        style:
                            const TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // ------------------------------------------------------
          // 일기
          // ------------------------------------------------------

          if (record.diary.isNotEmpty) ...[
            const SizedBox(height: 28),

            const Text(
              '여행 일기',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: Text(
                record.diary,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.7,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // 성향 카드
  // ============================================================

  Widget _buildPersonalityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology_outlined,
              size: 21,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                if (record.personalityType != null)
                  Text(
                    record.personalityType!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                if (record.recommendedRegion != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '추천 지역 · ${record.recommendedRegion!}',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}