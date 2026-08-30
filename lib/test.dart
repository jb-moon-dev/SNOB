import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  print('========================================');
  print('관광지 집중률 API 테스트');
  print('========================================');

  // --------------------------------------------------
  // 테스트 지역
  // --------------------------------------------------

  const areaCd = '26';
  const signguCd = '26110';

  print('지역');
  print('areaCd   : $areaCd');
  print('signguCd : $signguCd');

  // --------------------------------------------------
  // API
  // --------------------------------------------------

  const baseUrl =
      'https://apis.data.go.kr/B551011/LocgoHubTarService1';

  const serviceKey =
      'cbea666b85656aa336898b2d32bfee6f7d6fdad29e7c840109a41b9bf449c8a9';

  // --------------------------------------------------
  // 이전 달
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
  print('조회 기준월 : $baseYm');

  // --------------------------------------------------
  // API URL
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
      'areaCd': areaCd,
      'signguCd': signguCd,
      '_type': 'json',
    },
  );

  print('');
  print('========================================');
  print('API 호출');
  print(uri);
  print('========================================');

  try {
    final response = await http.get(uri);

    print('STATUS CODE : ${response.statusCode}');

    print('');
    print('========================================');
    print('원본 응답');
    print('========================================');

    print(response.body);

    // --------------------------------------------------
    // JSON 확인
    // --------------------------------------------------

    if (response.statusCode != 200) {
      return;
    }

    final decoded = jsonDecode(response.body);

    final responseData = decoded['response'];

    if (responseData is! Map) {
      print('response 형식 오류');
      return;
    }

    final body = responseData['body'];

    if (body is! Map) {
      print('body 형식 오류');
      return;
    }

    final items = body['items'];

    if (items == null || items == '') {
      print('');
      print('❌ 집중률 데이터가 없습니다.');
      return;
    }

    final itemData = items['item'];

    if (itemData == null || itemData == '') {
      print('');
      print('❌ 관광지 데이터가 없습니다.');
      return;
    }

    List<Map<String, dynamic>> data;

    if (itemData is List) {
      data = itemData
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();
    } else if (itemData is Map) {
      data = [
        Map<String, dynamic>.from(itemData),
      ];
    } else {
      print('❌ item 형식 오류');
      return;
    }

    // --------------------------------------------------
    // 결과
    // --------------------------------------------------

    print('');
    print('========================================');
    print('집중률 API 데이터');
    print('총 데이터 수 : ${data.length}');
    print('========================================');

    for (int i = 0; i < data.length; i++) {
      final item = data[i];

      print('');
      print('[${i + 1}]');

      print(
        '관광지명 : '
        '${item['hubTatsNm'] ?? item['tAtsNm'] ?? item['tatsNm']}',
      );

      print(
        '관광지 코드 : '
        '${item['hubTatsCd'] ?? item['tAtsCd'] ?? item['tatsCd']}',
      );

      print(
        '집중률 : '
        '${item['cnctrRate'] ?? item['concentrationRate']}',
      );

      print('전체 데이터 : $item');
    }

    // --------------------------------------------------
    // 특정 관광지 검색
    // --------------------------------------------------

    print('');
    print('========================================');
    print('닥터밸런스 검색');
    print('========================================');

    for (final item in data) {
      final name =
          item['hubTatsNm'] ??
          item['tAtsNm'] ??
          item['tatsNm'] ??
          '';

      if (name.toString().contains('닥터밸런스')) {
        print('✅ 발견!');
        print(item);
      }
    }

    print('');
    print('========================================');
    print('테스트 종료');
    print('========================================');
  } catch (e) {
    print('');
    print('❌ API 호출 오류');
    print(e);
  }
}