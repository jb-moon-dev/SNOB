import 'dart:convert';

/// 여행 일정에 들어가는 하나의 관광지.
class TravelSpot {
  final String name;
  final String? category;
  final String? address;

  final double? latitude;
  final double? longitude;

  final double? congestion;
  final double? snobScore;

  final String? contentId;

  TravelSpot({
    required this.name,
    this.category,
    this.address,
    this.latitude,
    this.longitude,
    this.congestion,
    this.snobScore,
    this.contentId,
  });

  /// CourseResultScreen의 Map 데이터에서 생성
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
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'congestion': congestion,
      'snobScore': snobScore,
      'contentId': contentId,
    };
  }

  factory TravelSpot.fromJson(
    Map<String, dynamic> json,
  ) {
    return TravelSpot(
      name: json['name']?.toString() ?? '이름 없음',
      category: json['category']?.toString(),
      address: json['address']?.toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      congestion: _toDouble(json['congestion']),
      snobScore: _toDouble(json['snobScore']),
      contentId: json['contentId']?.toString(),
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

  TravelDay copyWith({
    int? day,
    List<TravelSpot>? spots,
  }) {
    return TravelDay(
      day: day ?? this.day,
      spots: spots ?? List<TravelSpot>.from(this.spots),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'spots': spots
          .map((spot) => spot.toJson())
          .toList(),
    };
  }

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
                  Map<String, dynamic>.from(spot),
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

  /// 새 여행 생성
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

  /// 관광지를 특정 날짜에 추가
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

    if (targetDay == null) {
      targetDay = TravelDay(day: day);
      days.add(targetDay);

      days.sort(
        (a, b) => a.day.compareTo(b.day),
      );
    }

    final alreadyExists = targetDay.spots.any(
      (item) => item.name == spot.name,
    );

    if (!alreadyExists) {
      targetDay.spots.add(spot);
    }

    updatedAt = DateTime.now();
  }

  /// 관광지 제거
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

  /// 전체 관광지 수
  int get totalSpotCount {
    int count = 0;

    for (final day in days) {
      count += day.spots.length;
    }

    return count;
  }

  /// JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'regionName': regionName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'days': days
          .map((day) => day.toJson())
          .toList(),
    };
  }

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
                  Map<String, dynamic>.from(day),
                ),
              )
              .toList()
          : [],
    );
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory TravelPlan.fromJsonString(
    String source,
  ) {
    return TravelPlan.fromJson(
      jsonDecode(source)
          as Map<String, dynamic>,
    );
  }
}
