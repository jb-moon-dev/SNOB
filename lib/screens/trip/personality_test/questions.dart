import 'question_model.dart';

final List<Question> questions = [

  // 1. 관광 성향
  Question(
    question: "여행지를 고를 때 가장 먼저 보는 것은?",
    answers: [
      Answer(text: "많은 사람이 방문한 유명 명소", famous: 2),
      Answer(text: "SNS에서 인기 있는 장소", famous: 1),
      Answer(text: "현지인이 추천하는 장소", hidden: 1),
      Answer(text: "잘 알려지지 않은 나만의 장소", hidden: 2),
    ],
  ),

  Question(
    question: "처음 방문하는 지역이라면?",
    answers: [
      Answer(text: "대표 관광지는 꼭 방문한다", famous: 2),
      Answer(text: "유명 장소 몇 곳은 포함한다", famous: 1),
      Answer(text: "관광객보다 현지 분위기를 보고 싶다", hidden: 1),
      Answer(text: "사람들이 잘 모르는 곳을 찾는다", hidden: 2),
    ],
  ),

  Question(
    question: "여행 사진첩을 보면?",
    answers: [
      Answer(text: "유명 랜드마크 사진이 많다", famous: 2),
      Answer(text: "인증샷 명소 사진이 있다", famous: 1),
      Answer(text: "골목이나 지역 풍경 사진이 많다", hidden: 1),
      Answer(text: "나만 아는 장소 사진이 많다", hidden: 2),
    ],
  ),


  // 2. 이동 성향
  Question(
    question: "여행 전 준비 방식은?",
    answers: [
      Answer(text: "시간별 일정표를 만든다", planner: 2),
      Answer(text: "방문 장소 리스트를 정리한다", planner: 1),
      Answer(text: "가고 싶은 곳만 저장한다", spontaneous: 1),
      Answer(text: "현장에서 결정한다", spontaneous: 2),
    ],
  ),

  Question(
    question: "갑자기 일정이 변경된다면?",
    answers: [
      Answer(text: "새로운 일정으로 다시 계획한다", planner: 2),
      Answer(text: "가능한 대안을 찾는다", planner: 1),
      Answer(text: "상황에 맞춰 움직인다", spontaneous: 1),
      Answer(text: "마음 가는 곳으로 간다", spontaneous: 2),
    ],
  ),

  Question(
    question: "여행 중 이동 방식은?",
    answers: [
      Answer(text: "최적의 이동 경로를 미리 찾는다", planner: 2),
      Answer(text: "주요 이동지만 정한다", planner: 1),
      Answer(text: "그날 기분에 따라 이동한다", spontaneous: 1),
      Answer(text: "발길 닿는 곳으로 간다", spontaneous: 2),
    ],
  ),


  // 3. 분위기
  Question(
    question: "선호하는 여행 분위기는?",
    answers: [
      Answer(text: "축제와 사람이 많은 곳", lively: 2),
      Answer(text: "도시의 활기찬 분위기", lively: 1),
      Answer(text: "조용한 자연 공간", quiet: 1),
      Answer(text: "사람이 적은 힐링 장소", quiet: 2),
    ],
  ),

  Question(
    question: "여행에서 가장 만족하는 순간은?",
    answers: [
      Answer(text: "새로운 사람들과 즐기는 순간", lively: 2),
      Answer(text: "인기 장소의 분위기를 느낄 때", lively: 1),
      Answer(text: "혼자 여유롭게 쉬는 순간", quiet: 1),
      Answer(text: "평화로운 풍경을 볼 때", quiet: 2),
    ],
  ),


  Question(
    question: "숙소를 선택한다면?",
    answers: [
      Answer(text: "번화가 중심 숙소", lively: 2),
      Answer(text: "접근성 좋은 도시 숙소", lively: 1),
      Answer(text: "자연 가까운 숙소", quiet: 1),
      Answer(text: "조용한 독채 숙소", quiet: 2),
    ],
  ),


  // 4. 여행 목적
  Question(
    question: "여행에서 가장 중요하게 생각하는 것은?",
    answers: [
      Answer(text: "인생 사진 남기기", photo: 2),
      Answer(text: "예쁜 장소 방문하기", photo: 1),
      Answer(text: "새로운 경험하기", experience: 1),
      Answer(text: "현지 문화를 체험하기", experience: 2),
    ],
  ),

  Question(
    question: "여행 후 가장 기억나는 것은?",
    answers: [
      Answer(text: "멋진 사진", photo: 2),
      Answer(text: "방문했던 유명 장소", photo: 1),
      Answer(text: "특별했던 경험", experience: 1),
      Answer(text: "현지에서의 이야기", experience: 2),
    ],
  ),


  // 5. 동행
  Question(
    question: "가장 선호하는 여행 방식은?",
    answers: [
      Answer(text: "혼자만의 시간을 보내는 여행", solo: 2),
      Answer(text: "내 페이스대로 움직이는 여행", solo: 1),
      Answer(text: "친구와 추억 만드는 여행", group: 1),
      Answer(text: "여러 사람과 즐기는 여행", group: 2),
    ],
  ),

  Question(
    question: "여행 계획을 세울 때?",
    answers: [
      Answer(text: "내가 원하는 대로 결정한다", solo: 2),
      Answer(text: "내 관심사를 우선한다", solo: 1),
      Answer(text: "함께 갈 사람 의견을 듣는다", group: 1),
      Answer(text: "모두가 즐길 계획을 만든다", group: 2),
    ],
  ),


  // 6. 소비
  Question(
    question: "여행 비용을 사용할 때?",
    answers: [
      Answer(text: "최대한 절약한다", budget: 2),
      Answer(text: "가격 대비 좋은 선택을 한다", budget: 1),
      Answer(text: "좋은 경험이면 투자한다", premium: 1),
      Answer(text: "특별한 경험에는 아끼지 않는다", premium: 2),
    ],
  ),

  Question(
    question: "숙소 선택 기준은?",
    answers: [
      Answer(text: "저렴하고 깔끔하면 충분하다", budget: 2),
      Answer(text: "합리적인 가격이 중요하다", budget: 1),
      Answer(text: "분위기와 서비스가 중요하다", premium: 1),
      Answer(text: "특별한 숙소 경험이 중요하다", premium: 2),
    ],
  ),

  Question(
    question: "여행에서 돈을 쓴다면?",
    answers: [
      Answer(text: "비용을 최대한 아낀다", budget: 2),
      Answer(text: "할인과 혜택을 활용한다", budget: 1),
      Answer(text: "특별한 체험에 투자한다", premium: 1),
      Answer(text: "기억에 남는 경험에 투자한다", premium: 2),
    ],
  ),
  Question(
    question: "여행 중 가장 하고 싶은 활동은?",
    answers: [
      Answer(
        text: "멋진 장소에서 사진을 남긴다",
        photo: 2,
      ),
      Answer(
        text: "예쁜 카페와 풍경을 찾아간다",
        photo: 1,
      ),
      Answer(
        text: "직접 참여하는 체험을 한다",
        experience: 1,
      ),
      Answer(
        text: "지역 사람들과 교류한다",
        experience: 2,
      ),
    ],
  ),
  Question(
    question: "여행 중 문제가 생겼을 때?",
    answers: [
      Answer(
        text: "혼자 해결 방법을 찾는다",
        solo: 2,
      ),
      Answer(
        text: "내 판단으로 먼저 움직인다",
        solo: 1,
      ),
      Answer(
        text: "같이 온 사람과 의논한다",
        group: 1,
      ),
      Answer(
        text: "함께 해결하며 추억으로 만든다",
        group: 2,
      ),
    ],
  ),
];