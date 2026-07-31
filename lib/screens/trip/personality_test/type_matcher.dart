class TypeMatcher {


  static String match(Map<String, String> profile) {


    String tourism = profile["tourism"]!;
    String movement = profile["movement"]!;
    String mood = profile["mood"]!;
    String purpose = profile["purpose"]!;
    String companion = profile["companion"]!;
    String cost = profile["cost"]!;



    // 1. 로컬 큐레이터
    if(
    tourism == "숨은 명소" &&
        mood == "조용함" &&
        purpose == "경험"
    ){
      return "local_curator";
    }



    // 2. 힐링 노마드
    if(
    tourism == "숨은 명소" &&
        mood == "조용함"
    ){
      return "healing_nomad";
    }



    // 3. 트렌드 헌터
    if(
    tourism == "유명 관광" &&
        purpose == "사진" &&
        mood == "활기"
    ){
      return "trend_hunter";
    }



    // 4. 스마트 플래너
    if(
    movement == "계획형" &&
        tourism == "유명 관광"
    ){
      return "smart_planner";
    }



    // 5. 골목 탐험가
    if(
    tourism == "숨은 명소" &&
        movement == "즉흥형"
    ){
      return "alley_explorer";
    }



    // 6. 감성 기록가
    if(
    purpose == "사진" &&
        mood == "조용함"
    ){
      return "emotion_recorder";
    }



    // 7. 문화 발견가
    if(
    purpose == "경험" &&
        movement == "계획형"
    ){
      return "culture_finder";
    }



    // 8. 액티브 플레이어
    if(
    mood == "활기" &&
        companion == "함께"
    ){
      return "active_player";
    }



    // 9. 미식 탐험가
    if(
    purpose == "경험" &&
        companion == "함께"
    ){
      return "food_explorer";
    }



    // 10. 도시 컬렉터
    if(
    tourism == "유명 관광" &&
        movement == "계획형"
    ){
      return "city_collector";
    }



    // 11. 자유 여행자
    if(
    movement == "즉흥형" &&
        companion == "혼자"
    ){
      return "free_traveler";
    }



    // 12. 백팩커
    if(
    companion == "혼자" &&
        cost == "가성비"
    ){
      return "backpacker";
    }



    // 13. 프리미엄 탐방가
    if(
    cost == "프리미엄" &&
        movement == "계획형"
    ){
      return "premium_traveler";
    }



    // 14. 가성비 여행러
    if(
    cost == "가성비"
    ){
      return "budget_traveler";
    }



    // 15. 야간 탐험가
    if(
    mood == "활기" &&
        purpose == "사진"
    ){
      return "night_explorer";
    }



    // 16. 여유로운 여행자
    if(
    mood == "조용함" &&
        cost == "가성비"
    ){
      return "slow_traveler";
    }



    // 17. 지역 연결자
    if(
    purpose == "경험" &&
        companion == "함께"
    ){
      return "local_connector";
    }



    // 18. 추억 설계자
    if(
    companion == "함께" &&
        movement == "계획형"
    ){
      return "memory_builder";
    }



    // 19. 숨은 보석 수집가
    if(
    tourism == "숨은 명소" &&
        purpose == "사진"
    ){
      return "hidden_collector";
    }



    // 20. 기본값
    return "balanced_traveler";

  }

}