import 'question_model.dart';
import '../../../snob/user_vector.dart';

class ScoreManager {

  // 도시 ↔ 자연
  int city = 0;
  int nature = 0;

  // 유명 ↔ 숨은
  int famous = 0;
  int hidden = 0;

  // 활동 ↔ 힐링
  int active = 0;
  int healing = 0;


  /// 답변 선택 시 점수 추가
  void addScore(Answer answer) {
    city += answer.city;
    nature += answer.nature;

    famous += answer.famous;
    hidden += answer.hidden;

    active += answer.active;
    healing += answer.healing;
  }


  /// 다시 테스트할 때 초기화
  void reset() {
    city = 0;
    nature = 0;

    famous = 0;
    hidden = 0;

    active = 0;
    healing = 0;
  }


  // ⭐ 여기 추가
  UserVector getUserVector() {

    return UserVector.fromScore(

      cityScore: city,
      natureScore: nature,

      famousScore: famous,
      hiddenScore: hidden,

      activeScore: active,
      healingScore: healing,

    );

  }

}