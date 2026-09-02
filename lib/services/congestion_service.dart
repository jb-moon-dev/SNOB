import 'dart:convert';
import 'package:http/http.dart' as http;

class CongestionService {
  static const String baseUrl =
      'https://apis.data.go.kr/B551011/TatsCnctrRateService';

  static const String serviceKey =
      'cbea666b85656aa336898b2d32bfee6f7d6fdad29e7c840109a41b9bf449c8a9';

  // ================================================================
  // 관광지 집중률 API
  // ================================================================
  //
  // 기본적으로 전달받은 areaCd + signguCd로 조회한다.
  //
  // 만약 해당 지역에 데이터가 없다면
  // 하위 "구" 단위 지역을 찾아서 다시 조회한다.
  //
  // 예:
  //
  // 고양시 41280
  //   ↓ 데이터 없음
  //
  // 덕양구 41281
  // 일산동구 41285
  // 일산서구 41287
  //
  // 이렇게 하위 구의 데이터를 합친다.
  // ================================================================

  Future<List<Map<String, dynamic>>> getCongestion({
    required String areaCd,
    required String signguCd,
    int pageNo = 1,
    int numOfRows = 100,
  }) async {
    print('');
    print('============================================================');
    print('📡 CONGESTION SERVICE START');
    print('============================================================');
    print('[CONGESTION] 요청 areaCd   = "$areaCd"');
    print('[CONGESTION] 요청 signguCd = "$signguCd"');
    print('============================================================');

    // ------------------------------------------------------------
    // 1. 먼저 요청한 지역 그대로 조회
    // ------------------------------------------------------------

    final directResults = await _requestCongestion(
      areaCd: areaCd,
      signguCd: signguCd,
      pageNo: pageNo,
      numOfRows: numOfRows,
    );

    if (directResults.isNotEmpty) {
      print('');
      print('✅ 직접 지역에서 집중률 데이터를 찾았습니다.');
      print('데이터 수 : ${directResults.length}');
      print('============================================================');

      return directResults;
    }

    // ------------------------------------------------------------
    // 2. 직접 데이터가 없으면 하위 구 조회
    // ------------------------------------------------------------

    print('');
    print('⚠️ 직접 지역의 집중률 데이터가 없습니다.');
    print('하위 "구" 지역을 확인합니다.');
    print('============================================================');

    final childCodes = _getChildDistrictCodes(
      areaCd: areaCd,
      signguCd: signguCd,
    );

    if (childCodes.isEmpty) {
      print('');
      print('❌ 하위 구 지역도 찾을 수 없습니다.');
      print('============================================================');

      return [];
    }

    print('');
    print('🔎 하위 구 발견');
    print('하위 구 개수 : ${childCodes.length}');

    for (final code in childCodes) {
      print(
        '  - ${code['name']} '
        '(${code['signguCd']})',
      );
    }

    print('============================================================');

    // ------------------------------------------------------------
    // 3. 하위 구들의 집중률 데이터 합치기
    // ------------------------------------------------------------

    final List<Map<String, dynamic>> mergedResults = [];

    for (final child in childCodes) {
      final childSignguCd =
          child['signguCd'] as String;

      final childName =
          child['name'] as String;

      print('');
      print('----------------------------------------');
      print('📡 하위 구 조회');
      print('지역 : $childName');
      print('areaCd   : $areaCd');
      print('signguCd : $childSignguCd');
      print('----------------------------------------');

      try {
        final childResults =
            await _requestCongestion(
          areaCd: areaCd,
          signguCd: childSignguCd,
          pageNo: pageNo,
          numOfRows: numOfRows,
        );

        print(
          '→ $childName 데이터 수 : '
          '${childResults.length}',
        );

        mergedResults.addAll(childResults);
      } catch (e) {
        print('');
        print('❌ $childName 조회 실패');
        print(e);
      }
    }

    print('');
    print('============================================================');
    print('📊 CONGESTION SERVICE RESULT');
    print('============================================================');
    print('직접 지역 데이터 : ${directResults.length}');
    print('하위 구 데이터   : ${mergedResults.length}');
    print('최종 데이터      : ${mergedResults.length}');
    print('============================================================');

    return mergedResults;
  }

  // ================================================================
  // 실제 집중률 API 호출
  // ================================================================

  Future<List<Map<String, dynamic>>> _requestCongestion({
    required String areaCd,
    required String signguCd,
    int pageNo = 1,
    int numOfRows = 100,
  }) async {
    final queryParameters = <String, String>{
      'serviceKey': serviceKey,
      'pageNo': pageNo.toString(),
      'numOfRows': numOfRows.toString(),
      'MobileOS': 'ETC',
      'MobileApp': 'SNOB',
      'areaCd': areaCd,
      'signguCd': signguCd,
      '_type': 'json',
    };

    final uri = Uri.parse(
      '$baseUrl/tatsCnctrRatedList',
    ).replace(
      queryParameters: queryParameters,
    );

    print('');
    print('[CONGESTION REQUEST]');
    print('areaCd   = "$areaCd"');
    print('signguCd = "$signguCd"');
    print('URL      = $uri');

    final response = await http.get(uri);

    print('');
    print('[CONGESTION RESPONSE]');
    print('STATUS      = ${response.statusCode}');
    print('BODY LENGTH = ${response.body.length}');

    if (response.statusCode != 200) {
      print('');
      print('❌ HTTP ERROR');
      print(response.body);

      throw Exception(
        '관광지 집중률 API 호출 실패: ${response.statusCode}',
      );
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (e) {
      print('');
      print('❌ JSON PARSE ERROR');
      print(e);
      print(response.body);

      throw Exception(
        '관광지 집중률 API JSON 파싱 실패: $e',
      );
    }

    if (decoded is! Map) {
      print('❌ API 응답이 Map 형식이 아닙니다.');
      return [];
    }

    final responseData = decoded['response'];

    if (responseData is! Map) {
      print('❌ response가 Map이 아닙니다.');
      return [];
    }

    // ------------------------------------------------------------
    // Header
    // ------------------------------------------------------------

    final header = responseData['header'];

    if (header is Map) {
      print(
        '[HEADER] resultCode = '
        '${header['resultCode']}',
      );

      print(
        '[HEADER] resultMsg  = '
        '${header['resultMsg']}',
      );

      final resultCode =
          header['resultCode']?.toString();

      if (resultCode != null &&
          resultCode != '0000') {
        print('');
        print('❌ API ERROR');
        print(
          'resultCode = $resultCode',
        );
        print(
          'resultMsg = '
          '${header['resultMsg']}',
        );

        return [];
      }
    }

    // ------------------------------------------------------------
    // Body
    // ------------------------------------------------------------

    final body = responseData['body'];

    if (body is! Map) {
      print('❌ body가 Map이 아닙니다.');
      return [];
    }

    final totalCount = body['totalCount'];

    print(
      '[BODY] totalCount = $totalCount',
    );

    // ------------------------------------------------------------
    // Items
    // ------------------------------------------------------------

    final items = body['items'];

    if (items == null || items == '') {
      print('❌ API items가 없습니다.');
      return [];
    }

    if (items is! Map) {
      print('❌ items가 Map이 아닙니다.');
      return [];
    }

    final itemData = items['item'];

    if (itemData == null || itemData == '') {
      print('❌ API item이 없습니다.');
      return [];
    }

    final List<Map<String, dynamic>> results = [];

    // 여러 관광지
    if (itemData is List) {
      for (final item in itemData) {
        if (item is Map) {
          results.add(
            Map<String, dynamic>.from(item),
          );
        }
      }
    }

    // 관광지 1개
    else if (itemData is Map) {
      results.add(
        Map<String, dynamic>.from(itemData),
      );
    }

    else {
      print('❌ 알 수 없는 item 형식');
      print(
        'item type = '
        '${itemData.runtimeType}',
      );

      return [];
    }

    print(
      '✅ 조회 성공 '
      '($areaCd / $signguCd) '
      ': ${results.length}개',
    );

    // ------------------------------------------------------------
    // 집중률 데이터 확인
    // ------------------------------------------------------------

    for (int i = 0;
        i < results.length && i < 5;
        i++) {
      final item = results[i];

      print('');
      print(
        '[DATA ${i + 1}] '
        '${item['tAtsNm']}',
      );

      print(
        '  baseYmd   : '
        '${item['baseYmd']}',
      );

      print(
        '  areaCd    : '
        '${item['areaCd']}',
      );

      print(
        '  signguCd  : '
        '${item['signguCd']}',
      );

      print(
        '  집중률     : '
        '${item['cnctrRate']}',
      );
    }

    if (results.length > 5) {
      print('');
      print(
        '... 전체 ${results.length}개 중 '
        '5개만 출력',
      );
    }

    return results;
  }

  // ================================================================
  // 하위 "구" 코드 찾기
  // ================================================================
  //
  // signguCd가 5자리라고 가정한다.
  //
  // 예:
  //
  // 고양시     41280
  // 덕양구     41281
  // 일산동구   41285
  // 일산서구   41287
  //
  // 따라서 부모 코드의 앞 4자리 + 마지막 숫자 패턴을
  // 이용해서 하위 구를 찾는다.
  //
  // 주의:
  // 이 함수는 실제 전국 행정구역 데이터를 API에서 가져오는 것이 아니라
  // SNOB에서 사용하는 행정구역 코드 체계를 기준으로 찾는다.
  // ================================================================

  List<Map<String, String>> _getChildDistrictCodes({
    required String areaCd,
    required String signguCd,
  }) {
    // ------------------------------------------------------------
    // 부모 시/군 코드 → 하위 구 코드
    // ------------------------------------------------------------
    //
    // 전국적으로 "구"가 존재하는 지역만 등록한다.
    //
    // 지역명이 아니라 코드 기준이므로
    // 이름 변경에도 영향을 덜 받는다.
    // ------------------------------------------------------------

    const Map<String, List<String>> districtMap = {
      // 경기도
      '41270': [
        '41271',
        '41273',
      ], // 안산시
      '41280': [
        '41281',
        '41285',
        '41287',
      ], // 고양시
      '41460': [
        '41461',
        '41463',
        '41465',
      ], // 용인시
      '41110': [
        '41111',
        '41113',
        '41115',
        '41117',
        '41119',
      ], // 수원시

      // 충청북도
      '43110': [
        '43111',
        '43112',
        '43113',
        '43114',
      ], // 청주시

      // 충청남도
      '44130': [
        '44131',
        '44133',
      ], // 천안시

      // 경상북도
      '47110': [
        '47111',
        '47113',
      ], // 포항시

      // 경상남도
      '48120': [
        '48121',
        '48123',
        '48125',
        '48127',
        '48129',
      ], // 창원시
    };

    final childCodes =
        districtMap[signguCd];

    if (childCodes == null ||
        childCodes.isEmpty) {
      return [];
    }

    return childCodes
        .map(
          (code) => {
            'name': _districtName(code),
            'signguCd': code,
          },
        )
        .toList();
  }

  // ================================================================
  // 하위 구 이름
  // ================================================================

  String _districtName(String signguCd) {
    const Map<String, String> names = {
      // 수원
      '41111': '장안구',
      '41113': '권선구',
      '41115': '팔달구',
      '41117': '영통구',

      // 안산
      '41271': '상록구',
      '41273': '단원구',

      // 고양
      '41281': '덕양구',
      '41285': '일산동구',
      '41287': '일산서구',

      // 용인
      '41461': '처인구',
      '41463': '기흥구',
      '41465': '수지구',

      // 청주
      '43111': '상당구',
      '43112': '서원구',
      '43113': '흥덕구',
      '43114': '청원구',

      // 천안
      '44131': '동남구',
      '44133': '서북구',

      // 포항
      '47111': '남구',
      '47113': '북구',

      // 창원
      '48121': '의창구',
      '48123': '성산구',
      '48125': '마산합포구',
      '48127': '마산회원구',
      '48129': '진해구',
    };

    return names[signguCd] ?? signguCd;
  }
}