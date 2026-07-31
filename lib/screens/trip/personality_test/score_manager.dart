import 'question_model.dart';


class ScoreManager {


  // 관광 성향
  int famous = 0;
  int hidden = 0;


  // 이동 성향
  int planner = 0;
  int spontaneous = 0;


  // 분위기
  int lively = 0;
  int quiet = 0;


  // 여행 목적
  int photo = 0;
  int experience = 0;


  // 동행
  int solo = 0;
  int group = 0;


  // 소비
  int budget = 0;
  int premium = 0;



  // 답변 선택 시 점수 추가
  void addScore(Answer answer) {


    famous += answer.famous;
    hidden += answer.hidden;


    planner += answer.planner;
    spontaneous += answer.spontaneous;


    lively += answer.lively;
    quiet += answer.quiet;


    photo += answer.photo;
    experience += answer.experience;


    solo += answer.solo;
    group += answer.group;


    budget += answer.budget;
    premium += answer.premium;

  }



  // 최종 성향 반환
  Map<String, String> getProfile(){


    return {


      "tourism":
      hidden > famous
          ? "숨은 명소"
          : "유명 관광",



      "movement":
      planner > spontaneous
          ? "계획형"
          : "즉흥형",



      "mood":
      quiet > lively
          ? "조용함"
          : "활기",



      "purpose":
      experience > photo
          ? "경험"
          : "사진",



      "companion":
      solo > group
          ? "혼자"
          : "함께",



      "cost":
      budget > premium
          ? "가성비"
          : "프리미엄",


    };

  }


}