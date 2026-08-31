import 'dart:convert';
import 'package:http/http.dart' as http;

class CongestionService {
  static const String baseUrl =
      'https://apis.data.go.kr/B551011/TatsCnctrRateService';

  static const String serviceKey =
      'cbea666b85656aa336898b2d32bfee6f7d6fdad29e7c840109a41b9bf449c8a9';

  /// 관광지 집중률 API
  ///
  /// areaCd + signguCd를 기준으로 해당 지역의
  /// 관광지 집중률 데이터를 가져온다.
  Future<List<Map<String, dynamic>>> getCongestion({
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
    print('============================================================');
    print('📡 CONGESTION API START');
    print('============================================================');
    print('[CONGESTION] URL');
    print(uri.toString());
    print('');
    print('[CONGESTION] areaCd   = "$areaCd"');
    print('[CONGESTION] signguCd = "$signguCd"');
    print('[CONGESTION] pageNo   = $pageNo');
    print('[CONGESTION] numOfRows = $numOfRows');
    print('============================================================');

    final response = await http.get(uri);

    print('');
    print('============================================================');
    print('📡 CONGESTION API RESPONSE');
    print('============================================================');
    print('[CONGESTION] STATUS      = ${response.statusCode}');
    print('[CONGESTION] BODY LENGTH = ${response.body.length}');
    print('============================================================');

    if (response.statusCode != 200) {
      print('');
      print('❌ CONGESTION API HTTP ERROR');
      print('[CONGESTION] status = ${response.statusCode}');
      print('[CONGESTION] body = ${response.body}');

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
      print('[CONGESTION] $e');
      print('[CONGESTION] BODY');
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
      print('response type = ${responseData.runtimeType}');
      return [];
    }

    // ------------------------------------------------------------
    // Header
    // ------------------------------------------------------------

    final header = responseData['header'];

    print('');
    print('============================================================');
    print('📋 API HEADER');
    print('============================================================');

    if (header is Map) {
      print('[CONGESTION] resultCode = ${header['resultCode']}');
      print('[CONGESTION] resultMsg  = ${header['resultMsg']}');
    } else {
      print('[CONGESTION] header 없음');
    }

    print('============================================================');

    // ------------------------------------------------------------
    // Body
    // ------------------------------------------------------------

    final body = responseData['body'];

    if (body is! Map) {
      print('❌ body가 Map이 아닙니다.');
      print('body type = ${body.runtimeType}');
      return [];
    }

    final totalCount = body['totalCount'];

    print('');
    print('============================================================');
    print('📊 API DATA INFO');
    print('============================================================');
    print('[CONGESTION] totalCount = $totalCount');
    print('[CONGESTION] numOfRows  = ${body['numOfRows']}');
    print('[CONGESTION] pageNo     = ${body['pageNo']}');
    print('============================================================');

    // ------------------------------------------------------------
    // Items
    // ------------------------------------------------------------

    final items = body['items'];

    if (items == null || items == '') {
      print('');
      print('❌ API items가 없습니다.');
      return [];
    }

    if (items is! Map) {
      print('');
      print('❌ items가 Map이 아닙니다.');
      print('items type = ${items.runtimeType}');
      return [];
    }

    final itemData = items['item'];

    if (itemData == null || itemData == '') {
      print('');
      print('❌ API item이 없습니다.');
      return [];
    }

    List<Map<String, dynamic>> results = [];

    // ------------------------------------------------------------
    // 여러 관광지
    // ------------------------------------------------------------

    if (itemData is List) {
      results = itemData
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();
    }

    // ------------------------------------------------------------
    // 관광지 1개
    // ------------------------------------------------------------

    else if (itemData is Map) {
      results = [
        Map<String, dynamic>.from(itemData),
      ];
    }

    // ------------------------------------------------------------
    // 알 수 없는 형식
    // ------------------------------------------------------------

    else {
      print('');
      print('❌ 알 수 없는 item 형식');
      print('item type = ${itemData.runtimeType}');
      return [];
    }

    // ------------------------------------------------------------
    // RAW DATA 출력
    // ------------------------------------------------------------

    print('');
    print('============================================================');
    print('🔎 RAW API ITEM 확인');
    print('============================================================');
    print('[RAW] 전체 데이터 수 = ${results.length}');
    print('============================================================');

    for (int i = 0; i < results.length && i < 10; i++) {
      final item = results[i];

      print('');
      print('---------------- API ITEM $i ----------------');

      print('[RAW] 전체 데이터');
      print(item);

      print('');
      print('[RAW] 필드 목록');
      print(item.keys.toList());

      print('');
      print('[RAW] baseYmd     = ${item['baseYmd']}');
      print('[RAW] areaCd      = ${item['areaCd']}');
      print('[RAW] areaNm      = ${item['areaNm']}');
      print('[RAW] signguCd    = ${item['signguCd']}');
      print('[RAW] signguNm    = ${item['signguNm']}');
      print('[RAW] hubTatsNm   = ${item['hubTatsNm']}');
      print('[RAW] cnctrRate   = ${item['cnctrRate']}');

      // 코드가 실제 API에 존재하는지 확인
      print('');
      print('[RAW] 코드 관련 필드');

      for (final key in item.keys) {
        final keyString = key.toString().toLowerCase();

        if (keyString.contains('cd') ||
            keyString.contains('code') ||
            keyString.contains('id')) {
          print(
            '    $key = ${item[key]}',
          );
        }
      }

      print('-----------------------------------------------');
    }

    if (results.length > 10) {
      print('');
      print(
        '[RAW] 전체 ${results.length}개 중 10개만 출력했습니다.',
      );
    }

    print('');
    print('============================================================');
    print('✅ CONGESTION API 완료');
    print('관광지 집중률 데이터 수 = ${results.length}');
    print('============================================================');

    return results;
  }
}