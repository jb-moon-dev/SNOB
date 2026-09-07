import 'package:flutter/material.dart';

import '../../../models/travel_plan.dart';
import '../../../services/travel_plan_storage.dart';
import '../../../services/tourism_api_service.dart';
import '../../../services/congestion_service.dart';
import '../../../region_mapping/region_mapping_service.dart';
import '../../../region_mapping/spot_mapping_service.dart';
import '../../../region_mapping/snob_spot.dart';
import 'snob_final.dart';


// ================================================================
// Course Result Screen
// ================================================================

class CourseResultScreen extends StatefulWidget {
  // ============================================================
  // 추천 지역명
  // ============================================================

  final String regionName;

  const CourseResultScreen({
    super.key,
    required this.regionName,
  });

  @override
  State<CourseResultScreen> createState() =>
      _CourseResultScreenState();
}


// ================================================================
// 관광지 결과
// ================================================================

class CourseResultData {
  final Map<String, dynamic> spot;
  final double averageConcentration;
  final double snobScore;

  const CourseResultData({
    required this.spot,
    required this.averageConcentration,
    required this.snobScore,
  });
}


// ================================================================
// State
// ================================================================

class _CourseResultScreenState
    extends State<CourseResultScreen> {
  // ============================================================
  // 상태
  // ============================================================

  bool isLoading = true;
  bool isSaving = false;

  String? errorMessage;

  List<CourseResultData> results = [];

  // ============================================================
  // 여행 일정
  // ============================================================

  late TravelPlan travelPlan;


  // ============================================================
  // initState
  // ============================================================

  @override
  void initState() {
    super.initState();

    // 기본 여행 일정 생성
    travelPlan = TravelPlan.create(
      regionName: widget.regionName,
    );

    // 저장된 일정 불러오기
    _initializeTravelPlan();

    // 관광지 조회 → 집중률 매핑 → SNOB 계산
    _calculateSnob();
  }


  // ============================================================
  // 저장된 여행 일정 불러오기
  // ============================================================

  Future<void> _initializeTravelPlan() async {
    try {
      final savedPlan =
          await TravelPlanStorage.loadTravelPlan();

      if (!mounted) {
        return;
      }

      if (savedPlan != null &&
          savedPlan.regionName ==
              widget.regionName) {
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
  // 전체 SNOB 계산
  // ============================================================
  //
  // 지역명
  // ↓
  // TourAPI 현재 지역 코드 찾기
  // ↓
  // 해당 지역 관광지 전체 조회
  // ↓
  // 집중률 API 지역 코드 매핑
  // ↓
  // 집중률 데이터 조회
  // ↓
  // 관광지명 매칭
  // ↓
  // SnobFinal
  // ↓
  // 최종 SNOB 점수
  //
  // 중요:
  // 집중률 매칭에 실패한 관광지도 삭제하지 않는다.
  // ============================================================

  Future<void> _calculateSnob() async {
    try {
      debugPrint('');
      debugPrint(
        '========================================',
      );
      debugPrint(
        'COURSE RESULT 시작',
      );
      debugPrint(
        '추천 지역: ${widget.regionName}',
      );
      debugPrint(
        '========================================',
      );


      // ==========================================================
      // 1. TourAPI 시도 코드 조회
      // ==========================================================

      final List<Map<String, String>> regions =
          await TourismApiService.getRegions();

      Map<String, String>? selectedRegion;
      String? selectedSigunguCode;
      String? selectedSigunguName;


      // ==========================================================
      // 2. 추천 지역 찾기
      // ==========================================================

      for (final region in regions) {
        final String regionCode =
            region['code'] ?? '';

        final String regionName =
            region['name'] ?? '';


        // --------------------------------------------------------
        // 시도 자체인 경우
        // --------------------------------------------------------

        if (widget.regionName ==
            regionName) {
          selectedRegion = region;
          break;
        }


        // --------------------------------------------------------
        // 시도 + 시군구인 경우
        //
        // 예:
        // 서울특별시 성동구
        // --------------------------------------------------------

        if (!widget.regionName
            .startsWith('$regionName ')) {
          continue;
        }

        final String sigunguName =
            widget.regionName
                .substring(
                  regionName.length,
                )
                .trim();


        final List<Map<String, String>>
            sigungus =
            await TourismApiService
                .getSigungus(
          regionCode,
        );


        for (final sigungu in sigungus) {
          final String currentName =
              sigungu['name'] ?? '';

          if (currentName ==
              sigunguName) {
            selectedRegion = region;

            selectedSigunguCode =
                sigungu['code'];

            selectedSigunguName =
                sigungu['name'];

            break;
          }
        }


        if (selectedRegion != null) {
          break;
        }
      }


      // ==========================================================
      // 지역을 찾지 못한 경우
      // ==========================================================

      if (selectedRegion == null) {
        throw Exception(
          '추천 지역의 TourAPI 지역 코드를 '
          '찾을 수 없습니다.\n'
          '지역: ${widget.regionName}',
        );
      }


      final String regionCode =
          selectedRegion['code']!;


      // ==========================================================
      // 세종특별자치시 예외
      // ==========================================================

      if (selectedSigunguCode == null) {
        final List<Map<String, String>>
            sigungus =
            await TourismApiService
                .getSigungus(
          regionCode,
        );


        if (sigungus.isNotEmpty) {
          selectedSigunguCode =
              sigungus.first['code'];

          selectedSigunguName =
              sigungus.first['name'];
        }
      }


      if (selectedSigunguCode == null) {
        throw Exception(
          '추천 지역의 시군구 코드를 '
          '찾을 수 없습니다.\n'
          '지역: ${widget.regionName}',
        );
      }


      debugPrint('');
      debugPrint(
        '========================================',
      );
      debugPrint(
        '현재 TourAPI 지역',
      );
      debugPrint(
        '========================================',
      );
      debugPrint(
        '지역 코드: $regionCode',
      );
      debugPrint(
        '시군구 코드: $selectedSigunguCode',
      );
      debugPrint(
        '시군구 이름: $selectedSigunguName',
      );


      // ==========================================================
      // 3. 관광지 전체 조회
      // ==========================================================
      //
      // CENTER50 사용하지 않음
      // ==========================================================

      final List<TourismSpot> tourismSpots =
          await TourismApiService
              .getTourismSpotsByLegalDong(
        regionCode,
        selectedSigunguCode!,
        widget.regionName,
      );


      debugPrint('');
      debugPrint(
        '========================================',
      );
      debugPrint(
        'TourAPI 관광지 조회 완료',
      );
      debugPrint(
        '관광지 수: ${tourismSpots.length}',
      );
      debugPrint(
        '========================================',
      );


      if (tourismSpots.isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          results = [];
          isLoading = false;
        });

        return;
      }


      // ==========================================================
      // 4. 집중률 API 지역 매핑
      // ==========================================================

      final List<RegionQuery> regionQueries =
          RegionMappingService
              .getQueryRegions(
        regionCode: regionCode,
        sigunguCode: selectedSigunguCode!,
        regionName: widget.regionName,
      );


      if (regionQueries.isEmpty) {
        throw Exception(
          '집중률 API 지역 매핑 결과가 없습니다.\n'
          '지역: ${widget.regionName}',
        );
      }


      debugPrint('');
      debugPrint(
        '========================================',
      );
      debugPrint(
        '집중률 API 지역 매핑',
      );
      debugPrint(
        '========================================',
      );


      for (final query
          in regionQueries) {
        debugPrint(
          'areaCd: ${query.areaCd} '
          '| signguCd: ${query.signguCd}',
        );

        debugPrint(
          '이유: ${query.reason}',
        );
      }


      // ==========================================================
      // 5. 집중률 API 조회
      // ==========================================================

      final CongestionService
          congestionService =
          CongestionService();

      final List<Map<String, dynamic>>
          allCongestionData = [];

      final Set<String>
          queriedRegions = {};


      for (final query
          in regionQueries) {
        final String key =
            '${query.areaCd}|'
            '${query.signguCd}';


        // 같은 집중률 API 지역은
        // 한 번만 조회
        if (queriedRegions
            .contains(key)) {
          continue;
        }


        queriedRegions.add(key);


        final List<Map<String, dynamic>>
            data =
            await congestionService
                .getAllCongestion(
          areaCd:
              query.areaCd,
          signguCd:
              query.signguCd,
        );


        allCongestionData
            .addAll(data);


        debugPrint(
          '집중률 데이터 추가: '
          '$key → ${data.length}개',
        );
      }


      debugPrint('');
      debugPrint(
        '========================================',
      );
      debugPrint(
        '집중률 API 조회 완료',
      );
      debugPrint(
        '전체 집중률 데이터: '
        '${allCongestionData.length}개',
      );
      debugPrint(
        '========================================',
      );


      // ==========================================================
      // 6. 관광지 ↔ 집중률 매핑
      // ==========================================================
      //
      // 여기서 핵심:
      //
      // 매칭 성공 → 실제 집중률 사용
      //
      // 매칭 실패 → 관광지 유지
      //             concentrationRate = null
      //
      // 즉 관광지를 삭제하지 않는다.
      // ==========================================================

      final List<SnobSpot>
          mappedSpots =
          SpotMappingService.mapSpots(
        tourismSpots:
            tourismSpots,
        congestionData:
            allCongestionData,
      );


      debugPrint('');
      debugPrint(
        '========================================',
      );
      debugPrint(
        '관광지 매핑 완료',
      );
      debugPrint(
        '전체 관광지: '
        '${mappedSpots.length}개',
      );


      final int matchedCount =
          mappedSpots
              .where(
                (spot) =>
                    spot.concentrationRate !=
                    null,
              )
              .length;


      final int unmatchedCount =
          mappedSpots.length -
              matchedCount;


      debugPrint(
        '집중률 매칭 성공: '
        '$matchedCount개',
      );

      debugPrint(
        '집중률 매칭 실패: '
        '$unmatchedCount개',
      );

      debugPrint(
        '========================================',
      );


      // ==========================================================
      // 7. SnobSpot → Map 변환
      // ==========================================================
      //
      // Sensitivity / Substitutability가
      // 기존 파일 기반이므로 기존 필드명도
      // 함께 전달한다.
      // ==========================================================

      final List<Map<String, dynamic>>
          spotMaps =
          mappedSpots.map(
        (SnobSpot spot) {
          return {
            // ----------------------------------------------------
            // 새 구조
            // ----------------------------------------------------

            'contentId':
                spot.contentId,

            'title':
                spot.title,

            'address':
                spot.address,

            'contentTypeId':
                spot.contentTypeId,

            'lDongRegnCd':
                spot.lDongRegnCd,

            'lDongSignguCd':
                spot.lDongSignguCd,

            'regionName':
                spot.regionName,

            'lclsSystm1':
                spot.lclsSystm1,

            'lclsSystm2':
                spot.lclsSystm2,

            'lclsSystm3':
                spot.lclsSystm3,

            'modifiedTime':
                spot.modifiedTime,

            'latitude':
                spot.latitude,

            'longitude':
                spot.longitude,

            'concentrationRate':
                spot.concentrationRate,

            'concentrationBaseYmd':
                spot.concentrationBaseYmd,

            'concentrationAreaCd':
                spot.concentrationAreaCd,

            'concentrationAreaNm':
                spot.concentrationAreaNm,

            'concentrationSignguCd':
                spot.concentrationSignguCd,

            'concentrationSignguNm':
                spot.concentrationSignguNm,

            'snobScore':
                spot.snobScore,

            // ----------------------------------------------------
            // 기존 파일 호환
            // ----------------------------------------------------

            'hubTatsNm':
                spot.title,

            'hubCtgryMclsNm':
                spot.lclsSystm2,

            'signguCd':
                spot.lDongSignguCd,

            'sigunguCd':
                spot.lDongSignguCd,

            'signguNm':
                spot.concentrationSignguNm,
          };
        },
      ).toList();


      // ==========================================================
      // 8. 최종 SNOB 계산
      // ==========================================================

      final SnobFinal calculator =
          SnobFinal();


      final List<SnobFinalResult>
          calculatedResults =
          await calculator.calculate(
        spotMaps,
      );


      if (!mounted) {
        return;
      }


      // ==========================================================
      // 9. 화면 결과로 변환
      // ==========================================================

      final List<CourseResultData>
          finalResults =
          calculatedResults.map(
        (result) {
          return CourseResultData(
            spot: result.spot,
            averageConcentration:
                result.averageConcentration,
            snobScore:
                result.totalScore,
          );
        },
      ).toList();


      setState(() {
        results = finalResults;
        isLoading = false;
      });


      // ==========================================================
      // 10. 최종 로그
      // ==========================================================

      debugPrint('');
      debugPrint(
        '========================================',
      );
      debugPrint(
        'SNOB 계산 완료',
      );
      debugPrint(
        '최종 관광지 수: '
        '${finalResults.length}',
      );
      debugPrint(
        '========================================',
      );


      for (int i = 0;
          i < finalResults.length;
          i++) {
        final CourseResultData result =
            finalResults[i];


        debugPrint(
          '[${i + 1}] '
          '${_getSpotName(result.spot)} '
          '| SNOB: '
          '${result.snobScore.toStringAsFixed(2)}',
        );
      }
    } catch (e) {
      debugPrint('');
      debugPrint(
        '========================================',
      );
      debugPrint(
        'COURSE RESULT 오류',
      );
      debugPrint(
        e.toString(),
      );
      debugPrint(
        '========================================',
      );


      if (!mounted) {
        return;
      }


      setState(() {
        errorMessage =
            e.toString();

        isLoading = false;
      });
    }
  }


  // ============================================================
  // 관광지 이름
  // ============================================================

  String _getSpotName(
    Map<String, dynamic> spot,
  ) {
    final List<dynamic> candidates = [
      spot['title'],
      spot['name'],
      spot['tAtsNm'],
      spot['hubTatsNm'],
    ];


    for (final value in candidates) {
      if (value != null &&
          value
              .toString()
              .trim()
              .isNotEmpty) {
        return value
            .toString()
            .trim();
      }
    }


    return '이름 없음';
  }


  // ============================================================
  // 카테고리
  // ============================================================

  String _getCategory(
    Map<String, dynamic> spot,
  ) {
    final List<dynamic> candidates = [
      spot['lclsSystm2'],
      spot['lclsSystm3'],
      spot['category'],
      spot['contentTypeId'],
      spot['hubCtgryMclsNm'],
    ];


    for (final value in candidates) {
      if (value != null &&
          value
              .toString()
              .trim()
              .isNotEmpty) {
        return value
            .toString()
            .trim();
      }
    }


    return '';
  }


  // ============================================================
  // 주소
  // ============================================================

  String _getAddress(
    Map<String, dynamic> spot,
  ) {
    final List<dynamic> candidates = [
      spot['address'],
      spot['addr1'],
      spot['addr2'],
      spot['signguNm'],
    ];


    for (final value in candidates) {
      if (value != null &&
          value
              .toString()
              .trim()
              .isNotEmpty) {
        return value
            .toString()
            .trim();
      }
    }


    return '';
  }


  // ============================================================
  // 숫자 변환
  // ============================================================

  double? _toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }


    if (value is num) {
      return value.toDouble();
    }


    final String text =
        value.toString().trim();


    if (text.isEmpty) {
      return null;
    }


    return double.tryParse(text);
  }


  // ============================================================
  // Map → TravelSpot
  // ============================================================

  TravelSpot _createTravelSpot(
    CourseResultData result,
  ) {
    final Map<String, dynamic>
        spot = result.spot;


    final String name =
        _getSpotName(spot);


    final String category =
        _getCategory(spot);


    final String address =
        _getAddress(spot);


    final double? latitude =
        _toDouble(
      spot['latitude'] ??
          spot['lat'] ??
          spot['y'] ??
          spot['mapy'],
    );


    final double? longitude =
        _toDouble(
      spot['longitude'] ??
          spot['lng'] ??
          spot['lon'] ??
          spot['x'] ??
          spot['mapx'],
    );


    final String? contentId =
        spot['contentId']
            ?.toString();


    final String? kakaoPlaceId =
        spot['kakaoPlaceId']
            ?.toString();


    final String? kakaoPlaceUrl =
        spot['kakaoPlaceUrl']
            ?.toString();


    return TravelSpot(
      name: name,

      category:
          category.isEmpty
              ? null
              : category,

      address:
          address.isEmpty
              ? null
              : address,

      latitude: latitude,

      longitude: longitude,

      congestion:
          result.averageConcentration,

      snobScore:
          result.snobScore,

      contentId:
          contentId,

      kakaoPlaceId:
          kakaoPlaceId,

      kakaoPlaceUrl:
          kakaoPlaceUrl,

      startMinute: null,

      durationMinutes:
          60,

      travelMinutesFromPrevious:
          0,
    );
  }


  // ============================================================
  // 특정 Day 찾기
  // ============================================================

  TravelDay? _findDay(
    int dayNumber,
  ) {
    for (final day
        in travelPlan.days) {
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
    CourseResultData result,
    int dayNumber,
  ) async {
    if (isSaving) {
      return;
    }


    final TravelDay? day =
        _findDay(dayNumber);


    if (day == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            '해당 여행 일정을 찾을 수 없습니다.',
          ),
        ),
      );


      return;
    }


    final TravelSpot spot =
        _createTravelSpot(result);


    // ----------------------------------------------------------
    // 중복 체크
    // ----------------------------------------------------------

    final bool alreadyExists =
        day.spots.any(
      (existingSpot) =>
          existingSpot.name ==
          spot.name,
    );


    if (alreadyExists) {
      Navigator.pop(context);


      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '${spot.name}은(는) '
            '이미 Day $dayNumber에 '
            '추가되어 있어요.',
          ),
        ),
      );


      return;
    }


    // ----------------------------------------------------------
    // 일정 추가
    // ----------------------------------------------------------

    setState(() {
      isSaving = true;
    });


    day.spots.add(spot);

    travelPlan.updatedAt =
        DateTime.now();


    try {
      await TravelPlanStorage
          .saveTravelPlan(
        travelPlan,
      );


      if (!mounted) {
        return;
      }


      setState(() {
        isSaving = false;
      });


      Navigator.pop(context);


      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '${spot.name}이(가) '
            'Day $dayNumber 일정에 '
            '추가됐어요.',
          ),
          duration:
              const Duration(
            seconds: 1,
          ),
        ),
      );
    } catch (e) {
      day.spots.remove(spot);


      if (!mounted) {
        return;
      }


      setState(() {
        isSaving = false;
      });


      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '일정 저장 중 오류가 발생했습니다.\n'
            '$e',
          ),
        ),
      );
    }
  }


  // ============================================================
  // 일정에 이미 추가됐는지 확인
  // ============================================================

  bool _isAdded(
    String spotName,
  ) {
    return travelPlan.days
        .expand(
          (day) => day.spots,
        )
        .any(
          (spot) =>
              spot.name ==
              spotName,
        );
  }


  // ============================================================
  // 관광지가 몇 일차에 있는지
  // ============================================================

  int? _getAddedDay(
    String spotName,
  ) {
    for (final day
        in travelPlan.days) {
      final bool exists =
          day.spots.any(
        (spot) =>
            spot.name ==
            spotName,
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
    final int nextDay =
        travelPlan.days.isEmpty
            ? 1
            : travelPlan.days
                    .map(
                      (day) => day.day,
                    )
                    .reduce(
                      (a, b) =>
                          a > b ? a : b,
                    ) +
                1;


    travelPlan.days.add(
      TravelDay(
        day: nextDay,
      ),
    );


    travelPlan.days.sort(
      (a, b) =>
          a.day.compareTo(
        b.day,
      ),
    );


    travelPlan.updatedAt =
        DateTime.now();


    await TravelPlanStorage
        .saveTravelPlan(
      travelPlan,
    );


    if (!mounted) {
      return;
    }


    setState(() {});


    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Day $nextDay이 추가됐어요.',
        ),
        duration:
            const Duration(
          seconds: 1,
        ),
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
      backgroundColor:
          Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (
            context,
            setModalState,
          ) {
            return SafeArea(
              child: Container(
                constraints:
                    BoxConstraints(
                  maxHeight:
                      MediaQuery.of(context)
                              .size
                              .height *
                          0.8,
                ),
                decoration:
                    const BoxDecoration(
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
                                  travelPlan
                                      .regionName,
                                  style:
                                      const TextStyle(
                                    fontSize: 22,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  '${travelPlan.totalSpotCount}곳의 관광지가 추가됨',
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.grey,
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

                      const SizedBox(
                        height: 15,
                      ),

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

                            const SizedBox(
                              height: 10,
                            ),

                            OutlinedButton.icon(
                              onPressed:
                                  () async {
                                await _addDay();

                                if (mounted) {
                                  setModalState(
                                    () {},
                                  );
                                }
                              },
                              icon:
                                  const Icon(
                                Icons.add,
                              ),
                              label:
                                  const Text(
                                '여행 일정 추가',
                              ),
                            ),

                            const SizedBox(
                              height: 10,
                            ),
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
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      decoration:
          BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
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
                  decoration:
                      BoxDecoration(
                    color: Colors.black,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    'DAY ${day.day}',
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Text(
                  '${day.spots.length}곳',
                  style:
                      const TextStyle(
                    color:
                        Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

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
                  style:
                      TextStyle(
                    color:
                        Colors.grey,
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
                  final int index =
                      entry.key;

                  final TravelSpot spot =
                      entry.value;

                  return ListTile(
                    contentPadding:
                        EdgeInsets.zero,

                    leading:
                        CircleAvatar(
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
                        spot.category !=
                                null
                            ? Text(
                                spot.category!,
                              )
                            : null,

                    trailing:
                        IconButton(
                      icon:
                          const Icon(
                        Icons
                            .delete_outline,
                      ),
                      onPressed:
                          () async {
                        day.spots
                            .removeWhere(
                          (item) =>
                              item.name ==
                              spot.name,
                        );


                        travelPlan
                                .updatedAt =
                            DateTime.now();


                        await TravelPlanStorage
                            .saveTravelPlan(
                          travelPlan,
                        );


                        if (!mounted) {
                          return;
                        }


                        setState(
                          () {},
                        );


                        setModalState(
                          () {},
                        );
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
  // 일정 추가 Day 선택
  // ============================================================

  void _showDaySelector(
    CourseResultData result,
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
                const EdgeInsets.all(
              20,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  '어느 날에 추가할까요?',
                  style:
                      TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  _getSpotName(
                    result.spot,
                  ),
                  style:
                      const TextStyle(
                    color:
                        Colors.grey,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                ...travelPlan.days.map(
                  (day) {
                    return ListTile(
                      leading:
                          CircleAvatar(
                        child:
                            Text(
                          '${day.day}',
                        ),
                      ),

                      title:
                          Text(
                        'Day ${day.day}',
                      ),

                      subtitle:
                          Text(
                        '${day.spots.length}곳',
                      ),

                      trailing:
                          const Icon(
                        Icons.chevron_right,
                      ),

                      onTap:
                          isSaving
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

                const SizedBox(
                  height: 8,
                ),

                OutlinedButton.icon(
                  onPressed:
                      isSaving
                          ? null
                          : () async {
                              Navigator.pop(
                                context,
                              );

                              await _addDay();

                              if (!mounted) {
                                return;
                              }

                              _showDaySelector(
                                result,
                              );
                            },
                  icon:
                      const Icon(
                    Icons.add,
                  ),
                  label:
                      const Text(
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
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          '코스 추천',
        ),
        actions: [
          if (travelPlan
                  .totalSpotCount >
              0)
            IconButton(
              icon:
                  const Icon(
                Icons
                    .calendar_today_outlined,
              ),
              onPressed:
                  _showPlan,
            ),
        ],
      ),
      body:
          _buildBody(),
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

            SizedBox(
              height: 20,
            ),

            Text(
              '관광지와 SNOB 점수를 분석하고 있어요.',
              style:
                  TextStyle(
                fontSize: 15,
              ),
            ),

            SizedBox(
              height: 8,
            ),

            Text(
              '잠시만 기다려주세요.',
              style:
                  TextStyle(
                color:
                    Colors.grey,
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
              const EdgeInsets.all(
            20,
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.grey,
              ),

              const SizedBox(
                height: 15,
              ),

              const Text(
                '코스 추천 중 오류가 발생했습니다.',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                errorMessage!,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color:
                      Colors.grey,
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
          '추천할 관광지가 없습니다.',
          textAlign:
              TextAlign.center,
        ),
      );
    }


    // ----------------------------------------------------------
    // 결과
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
                style:
                    TextStyle(
                  fontSize: 14,
                  color:
                      Colors.grey,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                widget.regionName,
                style:
                    const TextStyle(
                  fontSize: 27,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              const Text(
                'SNOB 점수가 높은 관광지부터 추천해드려요.',
                style:
                    TextStyle(
                  fontSize: 14,
                  color:
                      Colors.grey,
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
          child:
              ListView.builder(
            padding:
                const EdgeInsets.all(
              16,
            ),
            itemCount:
                results.length,
            itemBuilder:
                (context, index) {
              final CourseResultData
                  result =
                  results[index];


              final Map<String, dynamic>
                  spot =
                  result.spot;


              final String spotName =
                  _getSpotName(
                spot,
              );


              final String category =
                  _getCategory(
                spot,
              );


              final String address =
                  _getAddress(
                spot,
              );


              final bool isAdded =
                  _isAdded(
                spotName,
              );


              final int? addedDay =
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
                          // ------------------------------------------
                          // 순위
                          // ------------------------------------------

                          CircleAvatar(
                            radius: 20,
                            child:
                                Text(
                              '${index + 1}',
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 14,
                          ),

                          // ------------------------------------------
                          // 관광지 정보
                          // ------------------------------------------

                          Expanded(
                            child:
                                Column(
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
                                        FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 5,
                                ),

                                if (category
                                    .isNotEmpty)
                                  Text(
                                    category,
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.grey,
                                      fontSize:
                                          13,
                                    ),
                                  ),

                                if (address
                                    .isNotEmpty)
                                  Text(
                                    address,
                                    maxLines:
                                        2,
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
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
                      // SNOB 점수
                      // ====================================================

                      _ScoreBox(
                        title:
                            'SNOB',
                        value:
                            result.snobScore
                                .toStringAsFixed(
                          1,
                        ),
                        icon:
                            Icons
                                .travel_explore,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      // ====================================================
                      // 일정 추가
                      // ====================================================

                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            FilledButton
                                .icon(
                          onPressed:
                              isAdded ||
                                      isSaving
                                  ? null
                                  : () {
                                      _showDaySelector(
                                        result,
                                      );
                                    },

                          icon:
                              Icon(
                            isAdded
                                ? Icons.check
                                : Icons.add,
                          ),

                          label:
                              Text(
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

class _ScoreBox
    extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ScoreBox({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),

      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color:
                Colors.grey.shade700,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      TextStyle(
                    fontSize: 11,
                    color:
                        Colors.grey.shade600,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 19,
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