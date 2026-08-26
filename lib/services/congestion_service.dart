import 'dart:convert';
import 'package:http/http.dart' as http;

class CongestionService {
  static const String baseUrl =
      'https://apis.data.go.kr/B551011/TatsCnctrRateService';

  static const String serviceKey =
      'cbea666b85656aa336898b2d32bfee6f7d6fdad29e7c840109a41b9bf449c8a9';

  /// 관광지 집중률 조회
  ///
  /// 조회 기준:
  /// - 조회일 기준 한 달 전
  /// - areaCd
  /// - signguCd
  ///
  /// 반환:
  /// [
  ///   {
  ///     'hubCtgryMclsNm': ...,
  ///     'hubRank': ...,
  ///     'baseYm': ...,
  ///     'mapX': ...,
  ///     'mapY': ...,
  ///     'areaCd': ...,
  ///     'areaNm': ...,
  ///     'signguCd': ...,
  ///     'signguNm': ...,
  ///     'hubTatsCd': ...,
  ///     'hubTatsNm': ...,
  ///     'hubCtgryLclsNm': ...
  ///   }
  /// ]
  Future<List<Map<String, dynamic>>> getCongestion({
    required String areaCd,
    required String signguCd,
    int pageNo = 1,
    int numOfRows = 100,
  }) async {

    // ============================================================
    // 조회일 기준 한 달 전
    // ============================================================

    final now = DateTime.now();

    final baseDate = DateTime(
      now.year,
      now.month - 1,
    );

    final baseYm =
        '${baseDate.year}${baseDate.month.toString().padLeft(2, '0')}';

    // ============================================================
    // API 요청
    // ============================================================

    final queryParameters = <String, String>{
      'serviceKey': serviceKey,
      'pageNo': pageNo.toString(),
      'numOfRows': numOfRows.toString(),
      'MobileOS': 'ETC',
      'MobileApp': 'SNOB',
      'baseYm': baseYm,
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
    print('========================================');
    print('CONGESTION API');
    print('기준월: $baseYm');
    print('지역코드: $areaCd');
    print('시군구코드: $signguCd');
    print(uri);
    print('========================================');

    final response = await http.get(uri);

    print('STATUS CODE: ${response.statusCode}');
    print('RESPONSE:');
    print(response.body);
    print('========================================');

    // ============================================================
    // HTTP 오류
    // ============================================================

    if (response.statusCode != 200) {
      throw Exception(
        '관광지 집중률 API 호출 실패: ${response.statusCode}',
      );
    }

    // ============================================================
    // JSON 파싱
    // ============================================================

    final decoded = jsonDecode(response.body);

    final responseData = decoded['response'];

    if (responseData is! Map) {
      print('response가 Map이 아닙니다.');
      return [];
    }

    final body = responseData['body'];

    if (body is! Map) {
      print('body가 Map이 아닙니다.');
      return [];
    }

    final itemsData = body['items'];

    print('items type: ${itemsData.runtimeType}');
    print('items: $itemsData');

    // ============================================================
    // 데이터 없음
    // ============================================================

    if (itemsData == null || itemsData == '') {
      print('관광지 집중률 데이터 없음');
      return [];
    }

    if (itemsData is! Map) {
      print('items가 Map이 아닙니다.');
      return [];
    }

    final itemData = itemsData['item'];

    if (itemData == null || itemData == '') {
      print('관광지 집중률 item 없음');
      return [];
    }

    // ============================================================
    // 여러 관광지
    // ============================================================

    if (itemData is List) {
      final results = itemData
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();

      print(
        '집중률 관광지 수: ${results.length}',
      );

      return results;
    }

    // ============================================================
    // 관광지 1개
    // ============================================================

    if (itemData is Map) {
      final result = [
        Map<String, dynamic>.from(itemData),
      ];

      print('집중률 관광지 수: 1');

      return result;
    }

    return [];
  }
}