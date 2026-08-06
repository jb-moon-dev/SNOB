import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KakaoAuthService {
  static const storage = FlutterSecureStorage();

  // ==========================
  // 카카오 로그인
  // ==========================
  static Future<User?> login() async {
    try {
      OAuthToken token;

      // 1. 카카오톡 앱 설치 여부 확인
      if (await isKakaoTalkInstalled()) {
        try {
          print("카카오톡 앱으로 로그인 시도");
          token = await UserApi.instance.loginWithKakaoTalk();
        } catch (e) {
          print("카카오톡 로그인 실패, 계정 로그인으로 전환: $e");
          // 카카오톡 로그인 취소/실패 시 웹 계정 로그인 실행
          token = await UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        print("카카오 계정으로 로그인 (웹 브라우저)");
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      // 기기 보안 저장소에 액세스 토큰 저장
      await storage.write(
        key: "kakao_access_token",
        value: token.accessToken,
      );

      print("토큰 저장 완료");

      User user = await UserApi.instance.me();
      print("사용자 id : ${user.id}");

      return user;
    } catch (e) {
      print("카카오 로그인 실패 : $e");
      return null;
    }
  }

  // ==========================
  // 로그인 상태 확인 (앱 실행 시 호출)
  // ==========================
  static Future<bool> checkToken() async {
    try {
      String? token = await storage.read(
        key: "kakao_access_token",
      );

      if (token == null) {
        print("저장된 토큰 없음");
        return false;
      }

      // 카카오 서버에 토큰 유효성 검증
      try {
        await UserApi.instance.accessTokenInfo();
        print("로그인 상태 확인됨 (토큰 유효)");
        return true;
      } catch (e) {
        print("토큰 만료됨");
        await logout();
        return false;
      }
    } catch (e) {
      print("토큰 확인 오류 : $e");
      return false;
    }
  }

  // ==========================
  // 로그아웃
  // ==========================
  static Future<void> logout() async {
    try {
      await UserApi.instance.logout();
    } catch (e) {
      print("카카오 로그아웃 오류 : $e");
    }

    // 저장소의 토큰 삭제
    await storage.delete(
      key: "kakao_access_token",
    );
  }
}