import 'dart:convert';

import 'package:http/http.dart' as http;

/// ============================================================
/// Kakao 장소 검색 결과
/// ============================================================

class KakaoPlace {
  final String id;
  final String name;

  final String? categoryName;

  final String? addressName;
  final String? roadAddressName;

  final String? phone;
  final String? placeUrl;

  final double latitude;
  final double longitude;

  final String? distance;

  const KakaoPlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.categoryName,
    this.addressName,
    this.roadAddressName,
    this.phone,
    this.placeUrl,
    this.distance,
  });

  String get displayAddress {
    if (roadAddressName != null &&
        roadAddressName!.isNotEmpty) {
      return roadAddressName!;
    }

    return addressName ?? '';
  }

  factory KakaoPlace.fromJson(
    Map<String, dynamic> json,
  ) {
    return KakaoPlace(
      id: json['id']?.toString() ?? '',
      name:
          json['place_name']?.toString() ?? '',
      categoryName:
          json['category_name']?.toString(),
      addressName:
          json['address_name']?.toString(),
      roadAddressName:
          json['road_address_name']?.toString(),
      phone:
          json['phone']?.toString(),
      placeUrl:
          json['place_url']?.toString(),
      longitude:
          double.tryParse(
                json['x']?.toString() ?? '',
              ) ??
              0,
      latitude:
          double.tryParse(
                json['y']?.toString() ?? '',
              ) ??
              0,
      distance:
          json['distance']?.toString(),
    );
  }
}

/// ============================================================
/// Kakao Local Service
/// ============================================================

class KakaoLocalService {
  KakaoLocalService({
    String? restApiKey,
    http.Client? client,
  })  : _restApiKey =
            restApiKey ??
                const String.fromEnvironment(
                  'KAKAO_REST_API_KEY',
                ),
        _client = client ?? http.Client();

  final String _restApiKey;
  final http.Client _client;

  static const String _baseUrl =
      'https://dapi.kakao.com';

  /// ----------------------------------------------------------
  /// API Key 확인
  /// ----------------------------------------------------------

  void _validateKey() {
    if (_restApiKey.trim().isEmpty) {
      throw Exception(
        'Kakao REST API Key가 설정되지 않았습니다.\n'
        '--dart-define=KAKAO_REST_API_KEY=... '
        '형태로 실행해주세요.',
      );
    }
  }

  /// ----------------------------------------------------------
  /// 장소 키워드 검색
  /// ----------------------------------------------------------

  Future<List<KakaoPlace>> searchPlaces(
    String query, {
    int page = 1,
    int size = 15,
  }) async {
    _validateKey();

    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      return [];
    }

    final uri = Uri.parse(
      '$_baseUrl/v2/local/search/keyword.json',
    ).replace(
      queryParameters: {
        'query': trimmed,
        'page': '$page',
        'size': '$size',
        'sort': 'accuracy',
      },
    );

    final response = await _client.get(
      uri,
      headers: {
        'Authorization':
            'KakaoAK $_restApiKey',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        '장소 검색 실패 '
        '(${response.statusCode})',
      );
    }

    final data =
        jsonDecode(response.body)
            as Map<String, dynamic>;

    final documents =
        data['documents'] as List? ?? [];

    return documents
        .map(
          (item) => KakaoPlace.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where(
          (place) =>
              place.name.isNotEmpty &&
              place.latitude != 0 &&
              place.longitude != 0,
        )
        .toList();
  }

  void dispose() {
    _client.close();
  }
}