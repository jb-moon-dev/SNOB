import 'tourism_spot.dart';
import 'spot_vector.dart';


class SpotVectorGenerator {


  static SpotVector generate(
    TourismSpot spot,
  ) {


    double nature = 50;
    double hidden = 50;
    double healing = 50;



    // ==========================
    // 🌿 자연 점수
    // ==========================

    if(spot.cat1 == "A01") {

      // 자연 관광
      nature += 30;

    }


    if(spot.cat2.startsWith("A0101")) {

      // 자연 명소
      nature += 20;

    }


    if(spot.cat2.startsWith("A0201")) {

      // 역사/문화
      nature -= 10;

    }



    // ==========================
    // 🔍 숨은 점수
    // ==========================

    if(spot.cat3.contains("00")) {

      hidden += 10;

    }


    // 이름 기반 간단 보정
    final title = spot.title;


    if(
      title.contains("공원") ||
      title.contains("산") ||
      title.contains("숲") ||
      title.contains("계곡")
    ){

      hidden += 10;

    }



    // ==========================
    // 🌙 힐링 점수
    // ==========================

    if(
      title.contains("온천") ||
      title.contains("휴양") ||
      title.contains("힐링") ||
      title.contains("치유")
    ){

      healing += 30;

    }


    if(
      spot.cat2.startsWith("A0202")
    ){

      // 체험/레포츠
      healing -= 20;

    }



    // 범위 제한
    nature =
        nature.clamp(0,100);

    hidden =
        hidden.clamp(0,100);

    healing =
        healing.clamp(0,100);



    return SpotVector(

      spotName: spot.title,

      regionName: spot.areaName,

      nature: nature,

      hidden: hidden,

      healing: healing,

      // 아직 혼잡도 API 연결 전
      congestion: 50,

    );


  }


}