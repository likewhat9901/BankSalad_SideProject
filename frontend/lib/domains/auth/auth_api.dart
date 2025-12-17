// frontend/lib/domains/auth/auth_api.dart
import '../../core/api/api_client.dart';

class AuthApi {
  /// 로그인
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    return await BaseApiClient.post(
      '/auth/login',
      {
        'username': username,
        'password': password,
      },
    );
  }

  /// 회원가입
  static Future<Map<String, dynamic>> signup({
    required String username,
    required String password,
    required String email,
  }) async {
    return await BaseApiClient.post(
      '/auth/signup',
      {
        'username': username,
        'password': password,
        'email': email,
      },
    );
  }

  /// 아이디 찾기
  static Future<Map<String, dynamic>> findUsername({
    required String email,
  }) async {
    return await BaseApiClient.post(
      '/auth/find-username',
      {'email': email},
    );
  }

  /// 비밀번호 찾기
  static Future<Map<String, dynamic>> findPassword({
    required String username,
    required String email,
  }) async {
    return await BaseApiClient.post(
      '/auth/find-password',
      {
        'username': username,
        'email': email,
      },
    );
  }
}