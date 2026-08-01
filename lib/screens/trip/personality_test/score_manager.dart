import 'question_model.dart';

class ScoreManager {
  // =========================
  // 축1 : 도시 ↔ 자연
  // =========================
  int city = 0;
  int nature = 0;

  // =========================
  // 축2 : 유명 ↔ 숨은
  // =========================
  int famous = 0;
  int hidden = 0;

  // =========================
  // 축3 : 활동 ↔ 힐링
  // =========================
  int active = 0;
  int healing = 0;


  // 점수 추가
  void addScore(Answer answer) {
    city += answer.city;
    nature += answer.nature;

    famous += answer.famous;
    hidden += answer.hidden;

    active += answer.active;
    healing += answer.healing;
  }


  // =========================
  // 축 판별 함수
  // =========================

  // 도시 ↔ 자연
  String getLocationType() {
    int total = city + nature;

    if (total == 0) {
      return "balance";
    }

    double natureRatio = nature / total;

    if (natureRatio < 0.333) {
      return "city";
    } 
    else if (natureRatio < 0.666) {
      return "balance";
    } 
    else {
      return "nature";
    }
  }


  // 유명 ↔ 숨은
  String getPlaceType() {
    int total = famous + hidden;

    if (total == 0) {
      return "normal";
    }

    double hiddenRatio = hidden / total;

    if (hiddenRatio < 0.333) {
      return "famous";
    } 
    else if (hiddenRatio < 0.666) {
      return "normal";
    } 
    else {
      return "hidden";
    }
  }


  // 활동 ↔ 힐링
  String getStyleType() {
    int total = active + healing;

    if (total == 0) {
      return "balance";
    }

    double healingRatio = healing / total;

    if (healingRatio < 0.333) {
      return "active";
    } 
    else if (healingRatio < 0.666) {
      return "balance";
    } 
    else {
      return "healing";
    }
  }


  // =========================
  // 최종 유형 Key 생성
  // =========================

  String getResultType() {
    return "${getLocationType()}_${getPlaceType()}_${getStyleType()}";
  }


  // 초기화
  void reset() {
    city = 0;
    nature = 0;

    famous = 0;
    hidden = 0;

    active = 0;
    healing = 0;
  }
}