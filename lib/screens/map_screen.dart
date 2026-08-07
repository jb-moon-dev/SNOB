import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  KakaoMapController? mapController;
  bool isMapReady = false;
  Set<Polygon> polygons = {};

  @override
  void initState() {
    super.initState();
    _initMapAndLoadData();
  }

  Future<void> _initMapAndLoadData() async {
    // 1. QGIS GeoJSON 데이터 불러오기
    await loadCongestionGeoJson();

    // 2. WebView JS SDK 안전 로딩을 위한 지연 처리
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        isMapReady = true;
      });
    }
  }

  // GeoJSON 파싱 함수
  Future<void> loadCongestionGeoJson() async {
    try {
      // assets 폴더의 geojson 읽기
      String jsonString = await rootBundle.loadString('assets/data/congestion.geojson');
      Map<String, dynamic> geojson = jsonDecode(jsonString);

      List features = geojson['features'];
      Set<Polygon> newPolygons = {};

      for (var feature in features) {
        var geometry = feature['geometry'];
        var properties = feature['properties'];

        // QGIS 속성값에 따라 색상 지정 (예: level이 3이면 빨강, 2면 노랑, 1이면 초록)
        int level = properties['level'] ?? 1; 
        Color fillColor = _getCongestionColor(level);

        if (geometry['type'] == 'Polygon') {
          List coordinates = geometry['coordinates'][0]; // 첫 번째 외곽선 좌표 배열
          List<LatLng> points = coordinates.map((coord) {
            // GeoJSON은 [경도(lng), 위도(lat)] 순서이므로 순서에 주의합니다.
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();

          newPolygons.add(
            Polygon(
              polygonId: 'polygon_${newPolygons.length}',
              points: points,
              strokeColor: Colors.black45,
              strokeWidth: 1,
              fillColor: fillColor,
              fillOpacity: 0.5, // 투명도 조절
            ),
          );
        }
      }

      setState(() {
        polygons = newPolygons;
      });
    } catch (e) {
      print("GeoJSON 로드 실패: $e");
    }
  }

  // 혼잡도 단계별 색상 지정
  Color _getCongestionColor(int level) {
    switch (level) {
      case 3:
        return Colors.red;    // 매우 혼잡
      case 2:
        return Colors.orange; // 보통
      case 1:
      default:
        return Colors.green;  // 여유
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("혼잡도 지도"),
      ),
      body: isMapReady
          ? KakaoMap(
              onMapCreated: (controller) {
                mapController = controller;
              },
              center: LatLng(37.5665, 126.9780),
              polygons: polygons.toList(), // 생성된 다각형 레이어 추가
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}