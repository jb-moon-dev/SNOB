import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

/// ============================================================
/// 경로 결과
/// ============================================================

class RouteResult {
  final int durationMinutes;
  final int durationSeconds;

  final int distanceMeters;

  final bool fromApi;

  const RouteResult({
    required this.durationMinutes,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.fromApi,
  });
}

/// ============================================================
/// Kakao 실제 도보 경로 Service
/// ============================================================

class RouteService {
  RouteService({
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

  void _validateKey() {
    if (_restApiKey.trim().isEmpty) {
      throw Exception(
        'Kakao REST API Key가 설정되지 않았습니다.',
      );
    }
  }

  /// ----------------------------------------------------------
  /// 실제 도보 경로 조회
  /// ----------------------------------------------------------

  Future<RouteResult> getWalkingRoute({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) async {
    _validateKey();

    final uri = Uri.parse(
      '$_baseUrl/v2/routing/walk',
    ).replace(
      queryParameters: {
        'start_x':
            startLongitude.toString(),
        'start_y':
            startLatitude.toString(),
        'end_x':
            endLongitude.toString(),
        'end_y':
            endLatitude.toString(),
        'route_mode': 'BROAD_FIRST',
      },
    );

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Authorization':
              'KakaoAK $_restApiKey',
        },
      );

      if (response.statusCode != 200) {
        return _fallback(
          startLatitude,
          startLongitude,
          endLatitude,
          endLongitude,
        );
      }

      final data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      final status =
          data['status']?.toString();

      if (status != 'OK') {
        return _fallback(
          startLatitude,
          startLongitude,
          endLatitude,
          endLongitude,
        );
      }

      final route =
          data['route']
              as Map<String, dynamic>?;

      final properties =
          route?['properties']
              as Map<String, dynamic>?;

      final totalDistance =
          (properties?['totalDistance']
                      as num?)
                  ?.toInt();

      final totalTime =
          (properties?['totalTime']
                      as num?)
                  ?.toInt();

      if (totalDistance == null ||
          totalTime == null) {
        return _fallback(
          startLatitude,
          startLongitude,
          endLatitude,
          endLongitude,
        );
      }

      return RouteResult(
        durationSeconds: totalTime,
        durationMinutes:
            math.max(
              1,
              (totalTime / 60).ceil(),
            ),
        distanceMeters:
            totalDistance,
        fromApi: true,
      );
    } catch (_) {
      return _fallback(
        startLatitude,
        startLongitude,
        endLatitude,
        endLongitude,
      );
    }
  }

  /// ----------------------------------------------------------
  /// fallback
  ///
  /// API가 실패했을 때만 사용.
  ///
  /// 실제 도로 이동시간이 아니라
  /// 좌표 기반 직선거리 예상치.
  /// ----------------------------------------------------------

  RouteResult _fallback(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    final distanceMeters =
        _haversineDistance(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );

    // 평균 도보속도 약 4.5 km/h
    const walkingMetersPerSecond =
        4500 / 3600;

    final seconds =
        (distanceMeters /
                walkingMetersPerSecond)
            .round();

    return RouteResult(
      durationSeconds: seconds,
      durationMinutes:
          math.max(
            1,
            (seconds / 60).ceil(),
          ),
      distanceMeters:
          distanceMeters.round(),
      fromApi: false,
    );
  }

  /// ----------------------------------------------------------
  /// Haversine 거리
  /// ----------------------------------------------------------

  double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0;

    final dLat =
        _degreesToRadians(lat2 - lat1);

    final dLon =
        _degreesToRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) *
                math.sin(dLat / 2) +
            math.cos(
                  _degreesToRadians(lat1),
                ) *
                math.cos(
                  _degreesToRadians(lat2),
                ) *
                math.sin(dLon / 2) *
                math.sin(dLon / 2);

    final c =
        2 *
            math.atan2(
              math.sqrt(a),
              math.sqrt(1 - a),
            );

    return earthRadius * c;
  }

  double _degreesToRadians(
    double degrees,
  ) {
    return degrees *
        math.pi /
        180;
  }

  void dispose() {
    _client.close();
  }
}