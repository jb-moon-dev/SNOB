import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';


class KakaoAuthService {


  static Future<User?> login() async {


    try {


      print("카카오 SDK 로그인 시작");


      OAuthToken token;



      // 카카오톡 설치 여부 확인
      bool installed = await isKakaoTalkInstalled();


      if (installed) {


        print("카카오톡 로그인 시도");


        try {


          token =
              await UserApi.instance.loginWithKakaoTalk();


        } catch (error) {


          print("카카오톡 로그인 실패 -> 카카오 계정 로그인 전환");


          token =
              await UserApi.instance.loginWithKakaoAccount();


        }



      } else {


        print("카카오 계정 로그인 시도");


        token =
            await UserApi.instance.loginWithKakaoAccount();


      }




      print("로그인 성공");

      print(
        "Access Token: ${token.accessToken}"
      );




      User user =
          await UserApi.instance.me();




      print(
        "카카오 닉네임: ${user.kakaoAccount?.profile?.nickname}"
      );


      return user;




    } catch (e, stackTrace) {


      print(
        "카카오 로그인 실패: $e"
      );


      print(stackTrace);


      return null;


    }


  }


}