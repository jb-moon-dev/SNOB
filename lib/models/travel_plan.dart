import 'dart:convert';

/// 여행 일정에 들어가는 하나의 관광지.
class TravelSpot {
  // ============================================================
  // 관광지 기본 정보
  // ============================================================

  final String name;
  final String? category;
  final String? address;

  final double? latitude;
  final double? longitude;

  final double? congestion;
  final double? snobScore;

  final String? contentId;

  // ============================================================
  // 일정 정보
  // ============================================================

  /// 하루 중 방문 시작 시간.
  ///
  /// 자정부터 지난 분 단위로 저장한다.
  /// 예:
  /// 09:30 → 570
  /// 11:00 → 660
  ///
  /// 아직 일정 시간이 정해지지 않은 경우 null.
  final int? startMinute;

  /// 해당 관광지에서 머무르는 시간(분).
  ///
  /// 기본값은 60분.
  final int durationMinutes;

  /// 이전 관광지에서 현재 관광지까지 이동하는 시간(분).
  ///
  /// 첫 번째 관광지는 기본값 0.
  final int travelMinutesFromPrevious;

  TravelSpot({
    required this.name,
    this.category,
    this.address,
    this.latitude,
    this.longitude,
    this.congestion,
    this.snobScore,
    this.contentId,
    this.startMinute,
    this.durationMinutes = 60,
    this.travelMinutesFromPrevious = 0,
  });

  // ============================================================
  // 수정용 copyWith
  // ============================================================

  TravelSpot copyWith({
    String? name,
    String? category,
    String? address,
    double? latitude,
    double? longitude,
    double? congestion,
    double? snobScore,
    String? contentId,
    int? startMinute,
    int? durationMinutes,
    int? travelMinutesFromPrevious,
  }) {
    return TravelSpot(
      name: name ?? this.name,
      category: category ?? this.category,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      congestion: congestion ?? this.congestion,
      snobScore: snobScore ?? this.snobScore,
      contentId: contentId ?? this.contentId,
      startMinute: startMinute ?? this.startMinute,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      travelMinutesFromPrevious:
          travelMinutesFromPrevious ??
          this.travelMinutesFromPrevious,
    );
  }

  // ============================================================
  // CourseResultScreen의 Map 데이터에서 생성
  // ============================================================

  factory TravelSpot.fromMap({
    required Map<String, dynamic> spot,
    double? congestion,
    double? snobScore,
  }) {
    return TravelSpot(
      name: spot['hubTatsNm']?.toString() ?? '이름 없음',

      category: spot['hubCtgryMclsNm']?.toString(),

      address: spot['signguNm']?.toString(),

      latitude: _toDouble(
        spot['lat'] ??
            spot['latitude'] ??
            spot['mapY'],
      ),

      longitude: _toDouble(
        spot['lon'] ??
            spot['longitude'] ??
            spot['mapX'],
      ),

      congestion: congestion,

      snobScore: snobScore,

      contentId: spot['contentId']?.toString(),

      // 새로 추가된 일정 정보는
      // 처음 관광지를 생성할 때는 아직 정하지 않는다.
      startMinute: null,
      durationMinutes: 60,
      travelMinutesFromPrevious: 0,
    );
  }

  // ============================================================
  // 숫자 변환
  // ============================================================

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  // ============================================================
  // JSON 저장
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      // 관광지 기본 정보
      'name': name,
      'category': category,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'congestion': congestion,
      'snobScore': snobScore,
      'contentId': contentId,

      // 일정 정보
      'startMinute': startMinute,
      'durationMinutes': durationMinutes,
      'travelMinutesFromPrevious':
          travelMinutesFromPrevious,
    };
  }

  // ============================================================
  // JSON 불러오기
  // ============================================================

  factory TravelSpot.fromJson(
    Map<String, dynamic> json,
  ) {
    return TravelSpot(
      name: json['name']?.toString() ?? '이름 없음',

      category: json['category']?.toString(),

      address: json['address']?.toString(),

      latitude: _toDouble(
        json['latitude'],
      ),

      longitude: _toDouble(
        json['longitude'],
      ),

      congestion: _toDouble(
        json['congestion'],
      ),

      snobScore: _toDouble(
        json['snobScore'],
      ),

      contentId: json['contentId']?.toString(),

      // 일정 정보
      //
      // 기존에 저장되어 있던 데이터에는
      // 이 값들이 없을 수 있기 때문에 기본값을 사용한다.
      startMinute: _toInt(
        json['startMinute'],
      ),

      durationMinutes:
          _toInt(
            json['durationMinutes'],
          ) ??
          60,

      travelMinutesFromPrevious:
          _toInt(
            json['travelMinutesFromPrevious'],
          ) ??
          0,
    );
  }
}

/// 하루의 여행 일정.
class TravelDay {
  final int day;
  final List<TravelSpot> spots;

  TravelDay({
    required this.day,
    List<TravelSpot>? spots,
  }) : spots = spots ?? [];

  // ============================================================
  // 복사
  // ============================================================

  TravelDay copyWith({
    int? day,
    List<TravelSpot>? spots,
  }) {
    return TravelDay(
      day: day ?? this.day,
      spots: spots ??
          List<TravelSpot>.from(
            this.spots,
          ),
    );
  }

  // ============================================================
  // JSON 저장
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'spots': spots
          .map(
            (spot) => spot.toJson(),
          )
          .toList(),
    };
  }

  // ============================================================
  // JSON 불러오기
  // ============================================================

  factory TravelDay.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawSpots = json['spots'];

    return TravelDay(
      day: (json['day'] as num?)?.toInt() ?? 1,

      spots: rawSpots is List
          ? rawSpots
              .whereType<Map>()
              .map(
                (spot) => TravelSpot.fromJson(
                  Map<String, dynamic>.from(
                    spot,
                  ),
                ),
              )
              .toList()
          : [],
    );
  }
}

/// 사용자가 만들고 있는 하나의 여행.
class TravelPlan {
  final String id;

  final String regionName;

  final DateTime createdAt;

  DateTime updatedAt;

  final List<TravelDay> days;

  TravelPlan({
    required this.id,
    required this.regionName,
    required this.createdAt,
    required this.updatedAt,
    List<TravelDay>? days,
  }) : days = days ?? [];

  // ============================================================
  // 새 여행 생성
  // ============================================================

  factory TravelPlan.create({
    required String regionName,
    int dayCount = 1,
  }) {
    final now = DateTime.now();

    return TravelPlan(
      id: now.microsecondsSinceEpoch.toString(),

      regionName: regionName,

      createdAt: now,

      updatedAt: now,

      days: List.generate(
        dayCount,
        (index) => TravelDay(
          day: index + 1,
        ),
      ),
    );
  }

  // ============================================================
  // 관광지를 특정 날짜에 추가
  // ============================================================

  void addSpot({
    required int day,
    required TravelSpot spot,
  }) {
    TravelDay? targetDay;

    for (final travelDay in days) {
      if (travelDay.day == day) {
        targetDay = travelDay;
        break;
      }
    }

    // 해당 날짜가 없으면 새로 생성
    if (targetDay == null) {
      targetDay = TravelDay(
        day: day,
      );

      days.add(targetDay);

      days.sort(
        (a, b) => a.day.compareTo(b.day),
      );
    }

    // 같은 장소 중복 추가 방지
    final alreadyExists = targetDay.spots.any(
      (item) => item.name == spot.name,
    );

    if (!alreadyExists) {
      targetDay.spots.add(spot);
    }

    updatedAt = DateTime.now();
  }

  // ============================================================
  // 관광지 제거
  // ============================================================

  void removeSpot({
    required int day,
    required String spotName,
  }) {
    for (final travelDay in days) {
      if (travelDay.day == day) {
        travelDay.spots.removeWhere(
          (spot) => spot.name == spotName,
        );

        break;
      }
    }

    updatedAt = DateTime.now();
  }

  // ============================================================
  // 특정 Day 가져오기
  // ============================================================

  TravelDay? getDay(int day) {
    for (final travelDay in days) {
      if (travelDay.day == day) {
        return travelDay;
      }
    }

    return null;
  }

  // ============================================================
  // 전체 관광지 수
  // ============================================================

  int get totalSpotCount {
    int count = 0;

    for (final day in days) {
      count += day.spots.length;
    }

    return count;
  }

  // ============================================================
  // JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,

      'regionName': regionName,

      'createdAt':
          createdAt.toIso8601String(),

      'updatedAt':
          updatedAt.toIso8601String(),

      'days': days
          .map(
            (day) => day.toJson(),
          )
          .toList(),
    };
  }

  // ============================================================
  // JSON에서 TravelPlan 생성
  // ============================================================

  factory TravelPlan.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawDays = json['days'];

    return TravelPlan(
      id: json['id']?.toString() ??
          DateTime.now()
              .microsecondsSinceEpoch
              .toString(),

      regionName:
          json['regionName']?.toString() ?? '',

      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),

      updatedAt: DateTime.tryParse(
            json['updatedAt']?.toString() ?? '',
          ) ??
          DateTime.now(),

      days: rawDays is List
          ? rawDays
              .whereType<Map>()
              .map(
                (day) => TravelDay.fromJson(
                  Map<String, dynamic>.from(
                    day,
                  ),
                ),
              )
              .toList()
          : [],
    );
  }

  // ============================================================
  // JSON String
  // ============================================================

  String toJsonString() {
    return jsonEncode(
      toJson(),
    );
  }

  // ============================================================
  // JSON String에서 TravelPlan 생성
  // ============================================================

  factory TravelPlan.fromJsonString(
    String source,
  ) {
    return TravelPlan.fromJson(
      jsonDecode(source)
          as Map<String, dynamic>,
    );
  }
}