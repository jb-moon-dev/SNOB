import 'question_model.dart';


final List<Question> questions = [


Question(

question: "여행지를 고를 때 가장 끌리는 곳은?",

answers: [

Answer(
text: "유명한 랜드마크",
famous:2,
),

Answer(
text: "SNS에서 핫한 장소",
famous:1,
),

Answer(
text: "현지인이 추천하는 숨은 장소",
hidden:1,
),

Answer(
text: "사람이 잘 모르는 나만의 장소",
hidden:2,
),

],

),



Question(

question:"여행 전에 계획을 얼마나 세우나요?",

answers:[

Answer(
text:"시간 단위로 계획한다",
planner:2,
),

Answer(
text:"큰 일정만 정한다",
planner:1,
),

Answer(
text:"가고 싶은 곳만 저장한다",
spontaneous:1,
),

Answer(
text:"현장에서 결정한다",
spontaneous:2,
),

],

),



Question(

question:"여행에서 더 중요하게 생각하는 것은?",

answers:[

Answer(
text:"멋진 사진 남기기",
photo:2,
),

Answer(
text:"인생 사진 명소 방문",
photo:1,
),

Answer(
text:"새로운 경험 하기",
experience:1,
),

Answer(
text:"현지 문화 체험",
experience:2,
),

],

),



Question(

question:"여행 분위기는 어떤 것을 선호하나요?",

answers:[

Answer(
text:"축제와 사람이 많은 곳",
lively:2,
),

Answer(
text:"활기찬 도시 여행",
lively:1,
),

Answer(
text:"조용한 자연 속 여행",
quiet:1,
),

Answer(
text:"혼자 쉬는 힐링 여행",
quiet:2,
),

],

),



Question(

question:"여행 비용을 사용할 때 어떤 편인가요?",

answers:[

Answer(
text:"최대한 아끼는 여행",
budget:2,
),

Answer(
text:"가격 대비 좋은 선택",
budget:1,
),

Answer(
text:"좋은 경험에는 투자",
premium:1,
),

Answer(
text:"특별한 숙소와 경험",
premium:2,
),

],

),


];