class Question {
  final String question;
  final List<Answer> answers;

  Question({
    required this.question,
    required this.answers,
  });
}

class Answer {
  final String text;

  // 관광 성향
  final int famous;
  final int hidden;

  // 이동 성향
  final int planner;
  final int spontaneous;

  // 분위기
  final int lively;
  final int quiet;

  // 여행 목적
  final int photo;
  final int experience;

  // 동행
  final int solo;
  final int group;

  // 소비
  final int budget;
  final int premium;

  const Answer({
    required this.text,

    this.famous = 0,
    this.hidden = 0,

    this.planner = 0,
    this.spontaneous = 0,

    this.lively = 0,
    this.quiet = 0,

    this.photo = 0,
    this.experience = 0,

    this.solo = 0,
    this.group = 0,

    this.budget = 0,
    this.premium = 0,
  });
}