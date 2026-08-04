class UserVector {


  // 🌿 도시 ↔ 자연
  final double nature;


  // 🔍 유명 ↔ 숨은
  final double hidden;


  // 🌙 활동 ↔ 힐링
  final double healing;




  const UserVector({

    required this.nature,

    required this.hidden,

    required this.healing,

  });





  // =================================
  // ScoreManager 점수 → UserVector 변환
  // =================================


  factory UserVector.fromScore({


    required int cityScore,

    required int natureScore,


    required int famousScore,

    required int hiddenScore,


    required int activeScore,

    required int healingScore,


  }){


    int natureTotal =

        cityScore + natureScore;



    int hiddenTotal =

        famousScore + hiddenScore;



    int healingTotal =

        activeScore + healingScore;





    return UserVector(


      // 자연 비율

      nature:

      natureTotal == 0

          ? 50

          :

      (natureScore / natureTotal * 100),





      // 숨은 비율

      hidden:

      hiddenTotal == 0

          ? 50

          :

      (hiddenScore / hiddenTotal * 100),





      // 힐링 비율

      healing:

      healingTotal == 0

          ? 50

          :

      (healingScore / healingTotal * 100),


    );


  }




  @override
  String toString(){


    return """

===== User Vector =====

🌿 자연 : ${nature.toStringAsFixed(1)}

🔍 숨은 : ${hidden.toStringAsFixed(1)}

🌙 힐링 : ${healing.toStringAsFixed(1)}

""";


  }


}