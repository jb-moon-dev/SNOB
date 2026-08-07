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


  List<Polygon> polygons = [];



  @override
  void initState() {

    super.initState();

    loadMapData();

  }



  Future<void> loadMapData() async {


    // GeoJSON 불러오기

    final String data =
        await rootBundle.loadString(
          "assets/map/korea_sigungu.geojson"
        );


    final jsonData = jsonDecode(data);



    List<Polygon> temp = [];



    for(var feature in jsonData["features"]) {


      // 시군구 이름

      String name =
          feature["properties"]["SIGUNGU_NM"];



      // 임시 혼잡도
      // 나중에 csv 연결

      double score =
          generateScore(name);



      Color color =
          getColor(score);



      var coordinates =
          feature["geometry"]["coordinates"][0];



      List<LatLng> points = [];



      for(var point in coordinates) {


        points.add(

          LatLng(

            point[1],

            point[0],

          )

        );


      }



      temp.add(

        Polygon(

          polygonId: name,

          points: points,

          strokeColor: Colors.white,

          strokeWidth: 1,

          fillColor: color,

          fillOpacity: 0.5,

        )

      );


    }



    setState(() {

      polygons = temp;

    });


  }






  // ---------------------------------
  // 임시 점수 생성
  // 나중에 congestion_final.csv 연결
  // ---------------------------------

  double generateScore(String name) {


    return
        (name.hashCode % 100) / 100;


  }





  Color getColor(double score) {


    if(score < 0.33) {


      return Colors.green;


    }

    else if(score < 0.66) {


      return Colors.orange;


    }

    else {


      return Colors.red;


    }


  }





  @override
  Widget build(BuildContext context) {


    return Scaffold(


      appBar: AppBar(

        title:
        const Text(
          "혼잡도 지도"
        ),

      ),



      body: KakaoMap(


        onMapCreated: (controller) {


          mapController = controller;


        },


        center:

        LatLng(

          36.5,

          127.8,

        ),



        polygons: polygons,


      ),


    );


  }


}