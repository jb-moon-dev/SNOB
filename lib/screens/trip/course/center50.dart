import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'converter.dart';

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

  List<Map<String, dynamic>> spots = [];

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
      print('========================================');

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

      print('변환 결과');
      print('areaCd: ${regionCode.areaCd}');
      print('sigunguCd: ${regionCode.sigunguCd}');

      // --------------------------------------------------
      // 2. 조회할 날짜 결정
      //
      // 현재 달이 아니라 "이전 달" 사용
      // 예:
      // 2026년 8월 → 202607
      // 2026년 1월 → 202512
      // --------------------------------------------------

      final now = DateTime.now();

      DateTime targetDate;

      if (now.month == 1) {
        targetDate = DateTime(now.year - 1, 12);
      } else {
        targetDate = DateTime(now.year, now.month - 1);
      }

      final baseYm =
          '${targetDate.year}${targetDate.month.toString().padLeft(2, '0')}';

      print('조회 기준월: $baseYm');

      // --------------------------------------------------
      // 3. API 직접 호출
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
        throw Exception('API response 형식이 올바르지 않습니다.');
      }

      final body = responseData['body'];

      if (body is! Map) {
        throw Exception('API body 형식이 올바르지 않습니다.');
      }

      final itemsData = body['items'];

      // 관광지가 없는 경우
      if (itemsData == null || itemsData == '') {
        setState(() {
          spots = [];
          isLoading = false;
        });

        print('조회된 데이터가 없습니다.');
        return;
      }

      if (itemsData is! Map) {
        throw Exception('items 형식이 올바르지 않습니다.');
      }

      final itemData = itemsData['item'];

      if (itemData == null || itemData == '') {
        setState(() {
          spots = [];
          isLoading = false;
        });

        print('조회된 관광지가 없습니다.');
        return;
      }

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
        throw Exception('관광지 데이터 형식이 올바르지 않습니다.');
      }

      print('');
      print('========================================');
      print('API 원본 데이터');
      print('총 데이터 수: ${allSpots.length}');
      print('========================================');

      // --------------------------------------------------
      // 4. 숙박 제거
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
      // 5. 화면에 저장
      // --------------------------------------------------

      if (!mounted) return;

      setState(() {
        spots = filteredSpots;
        isLoading = false;
      });

      // --------------------------------------------------
      // 6. 확인용 출력
      // --------------------------------------------------

      for (int i = 0; i < filteredSpots.length; i++) {
        final spot = filteredSpots[i];

        print('');
        print('[${i + 1}] ${spot['hubTatsNm']}');
        print('관광지 코드 : ${spot['hubTatsCd']}');
        print('지역        : ${spot['areaNm']} (${spot['areaCd']})');
        print('시군구      : ${spot['signguNm']} (${spot['signguCd']})');
        print('대분류      : ${spot['hubCtgryLclsNm']}');
        print('중분류      : ${spot['hubCtgryMclsNm']}');
        print('순위        : ${spot['hubRank']}');
        print('좌표        : ${spot['mapX']}, ${spot['mapY']}');
      }

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
      appBar: AppBar(
        title: const Text('추천 관광지'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            errorMessage!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (spots.isEmpty) {
      return const Center(
        child: Text('조회된 관광지가 없습니다.'),
      );
    }

    return ListView.builder(
      itemCount: spots.length,
      itemBuilder: (context, index) {
        final spot = spots[index];

        return ListTile(
          leading: CircleAvatar(
            child: Text('${index + 1}'),
          ),
          title: Text(
            spot['hubTatsNm']?.toString() ?? '이름 없음',
          ),
          subtitle: Text(
            '${spot['hubCtgryMclsNm'] ?? ''}\n'
            '${spot['signguNm'] ?? ''}',
          ),
        );
      },
    );
  }
}