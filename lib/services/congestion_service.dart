import 'dart:convert';
import 'package:http/http.dart' as http;

class CongestionService {
  static const String baseUrl =
      'https://apis.data.go.kr/B551011/TatsCnctrRateService';

  static const String serviceKey =
      'cbea666b85656aa336898b2d32bfee6f7d6fdad29e7c840109a41b9bf449c8a9';

  /// 관광지 집중률 조회
  ///
  /// 반환:
  /// [
  ///   {
  ///     'tAtsNm': '해운대해수욕장',
  ///     'congestion': 82.4,
  ///     ...
  ///   }
  /// ]
  Future<List<Map<String, dynamic>>> getCongestion({
    required String areaCd,
    required String signguCd,
    String? touristSpotName,
    int pageNo = 1,
    int numOfRows = 30,
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

    // 특정 관광지만 조회할 경우
    if (touristSpotName != null && touristSpotName.isNotEmpty) {
      queryParameters['tAtsNm'] = touristSpotName;
    }

    final uri = Uri.parse(
      '$baseUrl/tatsCnctrRatedList',
    ).replace(
      queryParameters: queryParameters,
    );

    print('');
    print('========================================');
    print('CONGESTION API');
    print(uri);
    print('========================================');

    final response = await http.get(uri);

    print('STATUS CODE: ${response.statusCode}');
    print('RESPONSE:');
    print(response.body);
    print('========================================');

    if (response.statusCode != 200) {
      throw Exception(
        '관광지 집중률 API 호출 실패: ${response.statusCode}',
      );
    }

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

    // 데이터가 없는 경우
    if (itemsData == null || itemsData == '') {
      return [];
    }

    if (itemsData is! Map) {
      print('items가 Map이 아닙니다.');
      return [];
    }

    final itemData = itemsData['item'];

    if (itemData == null || itemData == '') {
      return [];
    }

    if (itemData is List) {
      return itemData
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();
    }

    if (itemData is Map) {
      return [
        Map<String, dynamic>.from(itemData),
      ];
    }

    return [];
  }
}