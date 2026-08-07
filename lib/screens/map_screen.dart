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

  ParseParams(this.csvString, this.jsonString);
}

class ParseResult {
  final Map<String, CongestionData> congestionMap;
  final Map<String, List<LatLng>> polygonPointsMap;
  final Map<String, String> cdToNameMap;

  ParseResult(
    this.congestionMap,
    this.polygonPointsMap,
    this.cdToNameMap,
  );
}

// ============================================================
// 백그라운드 파싱 및 정점 극단적 축소
// ============================================================
ParseResult _parseInBackground(ParseParams params) {
  List<String> lines = const LineSplitter().convert(params.csvString);
  Map<String, CongestionData> tempCsvMap = {};

  for (int i = 1; i < lines.length; i++) {
    if (lines[i].trim().isEmpty) continue;
    List<String> cols = lines[i].split(',');

    if (cols.length >= 8) {
      String cd = cols[0].trim();
      String nm = cols[1].trim();

      tempCsvMap[cd] = CongestionData(
        cd: cd,
        nm: nm,
        currentVisitor: double.tryParse(cols[2]) ?? 0,
        normalVisitor: double.tryParse(cols[3]) ?? 0,
        normalCompare: double.tryParse(cols[4]) ?? 0,
        absoluteScore: double.tryParse(cols[6]) ?? 0,
        levelStr: cols[7].trim(),
      );
    }
  }

  Map<String, dynamic> geojson = jsonDecode(params.jsonString);
  List features = geojson['features'] ?? [];

  Map<String, List<LatLng>> tempPolygonMap = {};
  Map<String, String> tempCdToNameMap = {};

  for (var feature in features) {
    var geometry = feature['geometry'];
    var properties = feature['properties'];

    if (geometry == null || properties == null) continue;

    String cd = (properties['SIGUNGU_CD'] ?? '').toString().trim();
    String nm = (properties['SIGUNGU_NM'] ?? '').toString().trim();

    if (cd.isEmpty) continue;

    tempCdToNameMap[cd] = nm;
    List<LatLng> points = [];
    String type = geometry['type'] ?? '';

    try {
      List rawCoordinates = [];
      if (type == 'Polygon') {
        rawCoordinates = geometry['coordinates'][0];
      } else if (type == 'MultiPolygon') {
        rawCoordinates = geometry['coordinates'][0][0];
      }

      int totalPoints = rawCoordinates.length;

      // 정점 수를 극단적으로 축소 (UI 스레드 멈춤 방지)
      int step = 1;
      if (totalPoints > 150) {
        step = 20;
      } else if (totalPoints > 60) {
        step = 10;
      } else if (totalPoints > 20) {
        step = 5;
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
    } catch (e) {
      continue;
    }

    if (points.length >= 3) {
      tempPolygonMap[cd] = points;
    }
  }

  return ParseResult(
    tempCsvMap,
    tempPolygonMap,
    tempCdToNameMap,
  );
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  KakaoMapController? mapController;
  bool isDataLoaded = false;
  bool isAbsoluteMode = true;

  Map<String, CongestionData> congestionMap = {};
  Map<String, List<LatLng>> polygonPointsMap = {};
  Map<String, String> cdToNameMap = {};

  List<Polygon> displayedPolygons = [];
  Timer? _renderTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _renderTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      String csvString = await rootBundle.loadString('congestion_final.csv');
      String jsonString = await rootBundle.loadString('assets/map/sigungu_congestion.geojson');

      ParseResult result = await compute(
        _parseInBackground,
        ParseParams(csvString, jsonString),
      );

      congestionMap = result.congestionMap;
      polygonPointsMap = result.polygonPointsMap;
      cdToNameMap = result.cdToNameMap;

      if (mounted) {
        setState(() {
          isDataLoaded = true;
        });
      }
    } catch (e) {
      debugPrint("데이터 로드 오류: $e");
    }
  }

  Color _getStageColor(CongestionData data) {
    if (isAbsoluteMode) {
      double score = data.absoluteScore;
      if (score < 20) return const Color(0x992ECC71);
      if (score < 40) return const Color(0x9927AE60);
      if (score < 60) return const Color(0x99F1C40F);
      if (score < 80) return const Color(0x99E67E22);
      return const Color(0x99E74C3C);
    } else {
      double compare = data.normalCompare;
      if (compare <= -30) return const Color(0x992ECC71);
      if (compare <= -10) return const Color(0x9927AE60);
      if (compare <= 10) return const Color(0x99F1C40F);
      if (compare <= 40) return const Color(0x99E67E22);
      return const Color(0x99E74C3C);
    }
  }

  // 10개 단위로 500ms 간격 분할 주입
  void _startSafeBatchRendering() {
    _renderTimer?.cancel();

    List<Polygon> allPolygons = [];
    polygonPointsMap.forEach((cd, points) {
      CongestionData? data = congestionMap[cd];
      Color fillColor = data != null ? _getStageColor(data) : const Color(0x559E9E9E);

      allPolygons.add(
        Polygon(
          polygonId: cd,
          points: points,
          strokeColor: Colors.black26,
          strokeWidth: 1,
          fillColor: fillColor,
          fillOpacity: 0.5,
        ),
      );
    });

    displayedPolygons.clear();
    int batchSize = 10;
    int currentIndex = 0;

    _renderTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      int nextIndex = currentIndex + batchSize;
      if (nextIndex > allPolygons.length) {
        nextIndex = allPolygons.length;
      }

      setState(() {
        displayedPolygons.addAll(allPolygons.sublist(currentIndex, nextIndex));
      });

      currentIndex = nextIndex;

      if (currentIndex >= allPolygons.length) {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "혼잡도 지도",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          KakaoMap(
            onMapCreated: (controller) async {
              mapController = controller;
              // 지도가 안착될 수 있도록 1.5초 대기 후 분할 주입
              await Future.delayed(const Duration(milliseconds: 1500));
              _startSafeBatchRendering();
            },
            center: LatLng(36.5, 127.8),
            currentLevel: 13,
            polygons: displayedPolygons,
          ),

          if (!isDataLoaded)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text("혼잡도 지도를 준비하고 있습니다..."),
                ],
              ),
            ),

          if (isDataLoaded)
            Positioned(
              top: 16,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!isAbsoluteMode) {
                            setState(() {
                              isAbsoluteMode = true;
                            });
                            _startSafeBatchRendering();
                          }
                        },
                        child: Text(
                          "절대 혼잡도",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: isAbsoluteMode ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (isAbsoluteMode) {
                            setState(() {
                              isAbsoluteMode = false;
                            });
                            _startSafeBatchRendering();
                          }
                        },
                        child: Text(
                          "평소 대비",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: !isAbsoluteMode ? FontWeight.bold : FontWeight.normal,
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