import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'converter.dart';
import 'result_screen.dart';

class Center50Screen extends StatefulWidget {
  // RegionVector에서 넘어온 추천 지역명
  final String regionName;

  const Center50Screen({
    super.key,
    required this.regionName,
  });

  @override
  State<Center50Screen> createState() => _Center50ScreenState();
}

class _Center50ScreenState extends State<Center50Screen> {
  static const String baseUrl =
      'https://apis.data.go.kr/B551011/LocgoHubTarService1';

  static const String serviceKey =
      'cbea666b85656aa336898b2d32bfee6f7d6fdad29e7c840109a41b9bf449c8a9';

  bool isLoading = true;

  String? errorMessage;

  @override
  void initState() {
    super.initState();

    _loadCenter50();
  }

  Future<void> _loadCenter50() async {
    try {
      print('');
      print('========================================');
      print('CENTER 50 시작');
      print('추천 지역명: ${widget.regionName}');
      print('======================ㄹ==================');

      // --------------------------------------------------
      // 1. 추천 지역명 → 지역 코드
      // --------------------------------------------------

      final regionCode =
          await RegionCodeConverter.getRegionCode(
        widget.regionName,
      );

      if (regionCode == null) {
        throw Exception(
          '지역 코드를 찾을 수 없습니다: ${widget.regionName}',
        );
      }

      print('');
      print('변환 결과');
      print('areaCd: ${regionCode.areaCd}');
      print('sigunguCd: ${regionCode.sigunguCd}');

      // --------------------------------------------------
      // 2. 조회 기준월 결정
      //
      // 현재 달이 아니라 이전 달 사용
      //
      // 예:
      // 2026년 8월 → 202607
      // 2026년 1월 → 202512
      // --------------------------------------------------

      final now = DateTime.now();

      late DateTime targetDate;

      if (now.month == 1) {
        targetDate = DateTime(
          now.year - 1,
          12,
        );
      } else {
        targetDate = DateTime(
          now.year,
          now.month - 1,
        );
      }

      final baseYm =
          '${targetDate.year}'
          '${targetDate.month.toString().padLeft(2, '0')}';

      print('');
      print('조회 기준월: $baseYm');

      // --------------------------------------------------
      // 3. 관광지 API 호출
      // --------------------------------------------------

      final uri = Uri.parse(
        '$baseUrl/areaBasedList1',
      ).replace(
        queryParameters: {
          'serviceKey': serviceKey,
          'pageNo': '1',
          'numOfRows': '100',
          'MobileOS': 'ETC',
          'MobileApp': 'SNOB',
          'baseYm': baseYm,
          'areaCd': regionCode.areaCd.toString(),
          'signguCd': regionCode.sigunguCd.toString(),
          '_type': 'json',
        },
      );

      print('');
      print('========================================');
      print('CENTER SPOT API');
      print(uri);
      print('========================================');

      final response = await http.get(uri);

      print('STATUS CODE: ${response.statusCode}');
      print('RESPONSE:');
      print(response.body);
      print('========================================');

      if (response.statusCode != 200) {
        throw Exception(
          '관광지 API 호출 실패: ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);

      final responseData = decoded['response'];

      if (responseData is! Map) {
        throw Exception(
          'API response 형식이 올바르지 않습니다.',
        );
      }

      final body = responseData['body'];

      if (body is! Map) {
        throw Exception(
          'API body 형식이 올바르지 않습니다.',
        );
      }

      final itemsData = body['items'];

      // --------------------------------------------------
      // 4. 데이터 없음
      // --------------------------------------------------

      if (itemsData == null || itemsData == '') {
        throw Exception(
          '조회된 관광지가 없습니다.',
        );
      }

      if (itemsData is! Map) {
        throw Exception(
          'items 형식이 올바르지 않습니다.',
        );
      }

      final itemData = itemsData['item'];

      if (itemData == null || itemData == '') {
        throw Exception(
          '조회된 관광지가 없습니다.',
        );
      }

      // --------------------------------------------------
      // 5. 관광지 데이터 List 변환
      // --------------------------------------------------

      List<Map<String, dynamic>> allSpots;

      if (itemData is List) {
        allSpots = itemData
            .map(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();
      } else if (itemData is Map) {
        allSpots = [
          Map<String, dynamic>.from(itemData),
        ];
      } else {
        throw Exception(
          '관광지 데이터 형식이 올바르지 않습니다.',
        );
      }

      print('');
      print('========================================');
      print('API 원본 데이터');
      print('총 데이터 수: ${allSpots.length}');
      print('========================================');

      // --------------------------------------------------
      // 6. 숙박 제거 → 최대 50개
      // --------------------------------------------------

      final filteredSpots = allSpots
          .where(
            (spot) =>
                spot['hubCtgryLclsNm']?.toString() != '숙박',
          )
          .take(50)
          .toList();

      print('');
      print('========================================');
      print('숙박 제거 후');
      print('총 관광지 수: ${filteredSpots.length}');
      print('========================================');

      // --------------------------------------------------
      // 7. 관광지 데이터 확인
      // --------------------------------------------------

      for (int i = 0; i < filteredSpots.length; i++) {
        final spot = filteredSpots[i];

        print('');
        print('[${i + 1}] ${spot['hubTatsNm']}');
        print('관광지 코드 : ${spot['hubTatsCd']}');
        print(
          '지역        : '
          '${spot['areaNm']} (${spot['areaCd']})',
        );
        print(
          '시군구      : '
          '${spot['signguNm']} (${spot['signguCd']})',
        );
        print(
          '대분류      : '
          '${spot['hubCtgryLclsNm']}',
        );
        print(
          '중분류      : '
          '${spot['hubCtgryMclsNm']}',
        );
        print(
          '순위        : '
          '${spot['hubRank']}',
        );
        print(
          '좌표        : '
          '${spot['mapX']}, ${spot['mapY']}',
        );
      }

      // --------------------------------------------------
      // 8. CourseResultScreen으로 이동
      // --------------------------------------------------

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CourseResultScreen(
            regionName: widget.regionName,
            spots: filteredSpots,
          ),
        ),
      );

      print('');
      print('========================================');
      print('CENTER 50 종료');
      print('========================================');
    } catch (e) {
      print('');
      print('========================================');
      print('CENTER 50 오류');
      print(e);
      print('========================================');

      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // --------------------------------------------------
    // 로딩
    // --------------------------------------------------

    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '추천 관광지를 찾고 있어요...',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // --------------------------------------------------
    // 오류
    // --------------------------------------------------

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '관광지를 불러오지 못했어요.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                errorMessage!,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });

                  _loadCenter50();
                },
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    // 정상적으로 처리된 경우에는
    // Navigator.pushReplacement가 실행되므로
    // 이 화면이 계속 표시될 일은 없다.
    return const SizedBox.shrink();
  }
}