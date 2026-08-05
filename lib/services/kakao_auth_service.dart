import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';



class KakaoAuthService {



  static Future<User?> login() async {


    try {


      print(
        "카카오 SDK 로그인 시작"
      );



      OAuthToken token;



      bool installed =
          await isKakaoTalkInstalled();



      print(
        "카카오톡 설치 여부: $installed"
      );




      if(installed) {


        print(
          "카카오톡 로그인 시도"
        );


        try {


          token =
              await UserApi.instance.loginWithKakaoTalk();



          print(
            "🔥 카카오톡 토큰 받아옴"
          );



        } catch(e) {


          print(
            "카카오톡 실패 -> 계정 로그인"
          );


          print(e);



          token =
              await UserApi.instance.loginWithKakaoAccount();



          print(
            "🔥 카카오 계정 토큰 받아옴"
          );


        }



      } else {



        print(
          "카카오 계정 로그인 시도"
        );



        token =
            await UserApi.instance.loginWithKakaoAccount();



        print(
          "🔥 카카오 계정 토큰 받아옴"
        );


      }





      print(
        "✅ 로그인 성공"
      );



      print(
        "ACCESS TOKEN : ${token.accessToken}"
      );




      // 토큰 확인
      try {


        AccessTokenInfo tokenInfo =
            await UserApi.instance.accessTokenInfo();



        print(
          "TOKEN INFO ID : ${tokenInfo.id}"
        );



      } catch(e) {


        print(
          "토큰 정보 확인 실패"
        );


        print(e);


      }






      // 사용자 정보 가져오기
      try {


        User user =
            await UserApi.instance.me();



        print(
          "🔥 사용자 정보 받아옴"
        );



        print(
          "USER ID : ${user.id}"
        );



        print(
          "닉네임 : ${user.kakaoAccount?.profile?.nickname}"
        );



        return user;



      } catch(e) {


        print(
          "❌ 사용자 정보 가져오기 실패"
        );


        print(e);



        return null;


      }




    } catch(e, stackTrace) {



      print(
        "❌ 카카오 로그인 실패"
      );


      print(e);


      print(stackTrace);



      return null;


    }


  }


}