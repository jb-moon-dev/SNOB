import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

class CongestionData {
  final String cd;
  final String nm;
  final double currentVisitor;
  final double normalVisitor;
  final double normalCompare;
  final double absoluteScore;
  final String levelStr;

  CongestionData({
    required this.cd,
    required this.nm,
    required this.currentVisitor,
    required this.normalVisitor,
    required this.normalCompare,
    required this.absoluteScore,
    required this.levelStr,
  });
}

class ParseParams {
  final String csvString;
  final String jsonString;
  final bool onlySeoul;

  ParseParams(this.csvString, this.jsonString, {this.onlySeoul = false});
}

class ParseResult {
  final Map<String, CongestionData> congestionMapByNm;
  final Map<String, List<List<LatLng>>> polygonPointsMapByNm;

  ParseResult(
    this.congestionMapByNm,
    this.polygonPointsMapByNm,
  );
}

// 지역명 매칭 정규화 함수
String _normalizeName(String name) {
  String clean = name.replaceAll(' ', '').trim();
  if (clean == '세종' || clean == '세종시' || clean == '세종특별자치시') {
    return '세종';
  }
  clean = clean
      .replaceAll('특별시', '')
      .replaceAll('광역시', '')
      .replaceAll('특별자치시', '')
      .replaceAll('특별자치도', '');
  return clean;
}

// 백그라운드 파싱 (MultiPolygon 전체 지원)
ParseResult _parseInBackground(ParseParams params) {
  List<String> lines = const LineSplitter().convert(params.csvString);
  Map<String, CongestionData> tempCsvMap = {};

  for (int i = 1; i < lines.length; i++) {
    if (lines[i].trim().isEmpty) continue;
    List<String> cols = lines[i].split(',');

    if (cols.length >= 8) {
      String cd = cols[0].trim();
      String rawNm = cols[1].trim();
      String normalizedNm = _normalizeName(rawNm);

      CongestionData data = CongestionData(
        cd: cd,
        nm: rawNm,
        currentVisitor: double.tryParse(cols[2]) ?? 0,
        normalVisitor: double.tryParse(cols[3]) ?? 0,
        normalCompare: double.tryParse(cols[4]) ?? 0,
        absoluteScore: double.tryParse(cols[6]) ?? 0,
        levelStr: cols[7].trim(),
      );

      tempCsvMap[normalizedNm] = data;
      tempCsvMap[rawNm] = data;
    }
  }

  Map<String, dynamic> geojson = jsonDecode(params.jsonString);
  List features = geojson['features'] ?? [];

  Map<String, List<List<LatLng>>> tempPolygonMap = {};

  for (var feature in features) {
    var geometry = feature['geometry'];
    var properties = feature['properties'];

    if (geometry == null || properties == null) continue;

    String cd = (properties['SIGUNGU_CD'] ?? '').toString().trim();
    String rawNm = (properties['SIGUNGU_NM'] ?? '').toString().trim();

    if (rawNm.isEmpty) continue;

    if (params.onlySeoul && !cd.startsWith('11')) {
      continue;
    }

    String type = geometry['type'] ?? '';
    List<List<LatLng>> multiPolygons = [];

    try {
      if (type == 'Polygon') {
        List rawRings = geometry['coordinates'];
        for (var ring in rawRings) {
          List<LatLng> points = _downsampleCoordinates(ring, params.onlySeoul);
          if (points.length >= 3) multiPolygons.add(points);
        }
      } else if (type == 'MultiPolygon') {
        List rawPolygons = geometry['coordinates'];
        for (var poly in rawPolygons) {
          if (poly.isNotEmpty) {
            List<LatLng> points = _downsampleCoordinates(poly[0], params.onlySeoul);
            if (points.length >= 3) multiPolygons.add(points);
          }
        }
      }
    } catch (e) {
      continue;
    }

    if (multiPolygons.isNotEmpty) {
      tempPolygonMap[rawNm] = multiPolygons;
    }
  }

  return ParseResult(
    tempCsvMap,
    tempPolygonMap,
  );
}

// 정점 다운샘플링 최적화
List<LatLng> _downsampleCoordinates(List rawCoordinates, bool onlySeoul) {
  List<LatLng> points = [];
  int totalPoints = rawCoordinates.length;

  int step = 1;
  if (onlySeoul) {
    if (totalPoints > 50) step = 10;
    else if (totalPoints > 20) step = 5;
  } else {
    if (totalPoints > 100) step = 35;
    else if (totalPoints > 50) step = 20;
    else if (totalPoints > 20) step = 10;
    else if (totalPoints > 8) step = 5;
  }

  for (int i = 0; i < totalPoints; i += step) {
    var c = rawCoordinates[i];
    points.add(
      LatLng(
        (c[1] as num).toDouble(),
        (c[0] as num).toDouble(),
      ),
    );
  }
  return points;
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  KakaoMapController? mapController;
  bool isDataLoaded = false;
  bool isMapReady = false;
  bool isAbsoluteMode = true;

  Map<String, CongestionData> congestionMapByNm = {};
  Map<String, List<List<LatLng>>> polygonPointsMapByNm = {};

  List<Polygon> renderedPolygons = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      String csvString = await rootBundle.loadString('congestion_final.csv');
      String jsonString =
          await rootBundle.loadString('assets/map/sigungu_congestion.geojson');

      ParseResult result = await compute(
        _parseInBackground,
        ParseParams(csvString, jsonString, onlySeoul: false),
      );

      congestionMapByNm = result.congestionMapByNm;
      polygonPointsMapByNm = result.polygonPointsMapByNm;

      if (mounted) {
        setState(() {
          isDataLoaded = true;
        });
      }
    } catch (e) {
      debugPrint("데이터 로드 오류: $e");
    }
  }

  CongestionData? _getCongestionData(String regionName) {
    if (congestionMapByNm.containsKey(regionName)) {
      return congestionMapByNm[regionName];
    }
    String normalized = _normalizeName(regionName);
    return congestionMapByNm[normalized];
  }

  // 색상 반환 (매우 여유 = 더 진한 초록, 여유 = 밝은 초록)
  Color _getStageColor(CongestionData data) {
    if (isAbsoluteMode) {
      double score = data.absoluteScore;
      if (score < 20) return const Color(0x8827AE60); // 매우 여유 (진한 초록)
      if (score < 40) return const Color(0x882ECC71); // 여유 (연한 초록)
      if (score < 60) return const Color(0x88F1C40F); // 보통 (노랑)
      if (score < 80) return const Color(0x88E67E22); // 주의 (주황)
      return const Color(0x88E74C3C); // 혼잡 (빨강)
    } else {
      double compare = data.normalCompare;
      if (compare <= -30) return const Color(0x8827AE60);
      if (compare <= -10) return const Color(0x882ECC71);
      if (compare <= 10) return const Color(0x88F1C40F);
      if (compare <= 40) return const Color(0x88E67E22);
      return const Color(0x88E74C3C);
    }
  }

  // 공식 보도/뉴스 스타일 혼잡도 표현
  String _getStageText(CongestionData data) {
    if (isAbsoluteMode) {
      double score = data.absoluteScore;
      if (score < 20) return "매우 여유";
      if (score < 40) return "여유";
      if (score < 60) return "보통";
      if (score < 80) return "혼잡";
      return "매우 혼잡";
    } else {
      double compare = data.normalCompare;
      if (compare <= -30) return "대폭 감소";
      if (compare <= -10) return "소폭 감소";
      if (compare <= 10) return "평년 수준";
      if (compare <= 40) return "소폭 증가";
      return "대폭 증가";
    }
  }

  Future<void> _renderPolygonsInChunks() async {
    renderedPolygons.clear();
    List<MapEntry<String, List<List<LatLng>>>> entries =
        polygonPointsMapByNm.entries.toList();

    int chunkSize = 20;
    for (int i = 0; i < entries.length; i += chunkSize) {
      if (!mounted) return;

      int end = (i + chunkSize < entries.length) ? i + chunkSize : entries.length;
      List<MapEntry<String, List<List<LatLng>>>> chunk = entries.sublist(i, end);

      List<Polygon> newChunkPolygons = [];
      for (var entry in chunk) {
        String nm = entry.key;
        List<List<LatLng>> multiPolygonPoints = entry.value;

        CongestionData? data = _getCongestionData(nm);
        Color fillColor =
            data != null ? _getStageColor(data) : const Color(0x449E9E9E);

        int polyIndex = 0;
        for (var points in multiPolygonPoints) {
          newChunkPolygons.add(
            Polygon(
              polygonId: "${nm}_$polyIndex",
              points: points,
              strokeColor: Colors.black38,
              strokeWidth: 1,
              fillColor: fillColor,
              fillOpacity: 0.55,
            ),
          );
          polyIndex++;
        }
      }

      setState(() {
        renderedPolygons.addAll(newChunkPolygons);
      });

      await Future.delayed(const Duration(milliseconds: 35));
    }
  }

  bool _isPointInSinglePolygon(LatLng point, List<LatLng> polygon) {
    bool isInside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].longitude > point.longitude) !=
              (polygon[j].longitude > point.longitude) &&
          (point.latitude <
              (polygon[j].latitude - polygon[i].latitude) *
                      (point.longitude - polygon[i].longitude) /
                      (polygon[j].longitude - polygon[i].longitude) +
                  polygon[i].latitude)) {
        isInside = !isInside;
      }
      j = i;
    }
    return isInside;
  }

  void _handleMapTap(LatLng latLng) {
    for (var entry in polygonPointsMapByNm.entries) {
      for (var polygon in entry.value) {
        if (_isPointInSinglePolygon(latLng, polygon)) {
          _showRegionDetailCard(entry.key);
          return;
        }
      }
    }
  }

  void _showRegionDetailCard(String regionName) {
    CongestionData? data = _getCongestionData(regionName);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        if (data == null) {
          return Container(
            padding: const EdgeInsets.all(24),
            height: 150,
            child: Center(
              child: Text(
                "$regionName\n혼잡도 데이터가 존재하지 않습니다.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }

        Color statusColor = _getStageColor(data).withOpacity(1.0);
        String statusText = _getStageText(data);

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    data.nm,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn("현재 방문자", "${data.currentVisitor.toInt()}명"),
                  _buildStatColumn("평소 방문자", "${data.normalVisitor.toInt()}명"),
                  _buildStatColumn(
                    "평소 대비",
                    "${data.normalCompare > 0 ? '+' : ''}${data.normalCompare.toStringAsFixed(1)}%",
                    isHighlight: true,
                  ),
                ],
              ),
              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String label, String value,
      {bool isHighlight = false}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: isHighlight ? Colors.blueAccent : Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "전국 혼잡도 지도",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (isDataLoaded)
            KakaoMap(
              onMapCreated: (controller) async {
                mapController = controller;
                await Future.delayed(const Duration(milliseconds: 500));
                if (mounted) {
                  setState(() {
                    isMapReady = true;
                  });
                  _renderPolygonsInChunks();
                }
              },
              onMapTap: (latLng) {
                _handleMapTap(latLng);
              },
              center: LatLng(36.3, 127.8),
              currentLevel: 12,
              polygons: isMapReady ? List.from(renderedPolygons) : [],
            )
          else
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("데이터를 불러오는 중입니다..."),
                ],
              ),
            ),

          if (isDataLoaded && isMapReady)
            Positioned(
              top: 16,
              left: 20,
              right: 20,
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!isAbsoluteMode) {
                            isAbsoluteMode = true;
                            _renderPolygonsInChunks();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isAbsoluteMode
                                ? Colors.blueAccent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "절대 혼잡도",
                            style: TextStyle(
                              color: isAbsoluteMode
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (isAbsoluteMode) {
                            isAbsoluteMode = false;
                            _renderPolygonsInChunks();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: !isAbsoluteMode
                                ? Colors.blueAccent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "평소 대비",
                            style: TextStyle(
                              color: !isAbsoluteMode
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}