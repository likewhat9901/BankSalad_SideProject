import 'package:firebase_auth/firebase_auth.dart';          // 로그인, 회원가입, 로그아웃, 비밀번호 재설정 기능 제공
import 'package:cloud_firestore/cloud_firestore.dart';      // 사용자 정보 저장 기능 제공
import '../logger/logger_service.dart';

/// TODO: rethrow를 커스텀 AuthException으로 변경 권장

/// Firebase 인증 서비스
/// 회원가입, 로그인, 로그아웃, 비밀번호 재설정 기능 제공
class AuthService {
  // ========== Firebase 인스턴스 ==========
  
  /// Firebase Auth 인스턴스 (싱글톤 패턴)
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // TODO : mock 주입 가능한 타협안
  // final FirebaseAuth _auth;
  // AuthRepository({FirebaseAuth? auth})
  //     : _auth = auth ?? FirebaseAuth.instance;
  
  /// Firestore 인스턴스 (싱글톤 패턴)
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== 현재 사용자 정보 ==========
  
  /// 현재 로그인되어 있으면 User 객체를 반환, 로그인되어 있지 않으면 null을 반환
  User? get currentUser => _auth.currentUser;
  
  /// 인증 상태 변경 스트림 (로그인/로그아웃 실시간 감지)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ========== 인증 메서드 ==========

  /// 회원가입
  Future<UserCredential> signUp({
    required String email,        // 이메일
    required String password,      // 비밀번호
    required String username,      // 사용자명
  }) async {
    // 처리 흐름: Firebase Auth 계정 생성 → Firestore 사용자 정보 저장 → 실패 시 Auth 계정 삭제 및 롤백
    // 에러: 모든 예외는 로깅 후 rethrow

    LoggerService.debug('Auth', '회원가입 시도: $email');
    
    try {
      // Firebase Auth 계정 생성 (이메일/비밀번호 인증만 생성)
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      LoggerService.info('Auth', 'Firebase Auth 회원가입 성공: ${credential.user?.uid}');
      
      // Firestore에 사용자 정보 저장
      try {
        // uid를 문서 ID로 사용하여 사용자 정보 저장 (중복 방지)
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'username': username,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        LoggerService.info('Auth', 'Firestore 사용자 정보 저장 성공');
      } catch (e) {
        LoggerService.error('Auth', 'Firestore 저장 실패', e);
        // Firestore 저장 실패 시 Auth 계정 삭제 및 롤백
        await credential.user?.delete();    // 유령 계정 방지
        rethrow;
      }
      
      LoggerService.info('Auth', '회원가입 완료: $email');
      return credential;
    } catch (e, stackTrace) {
      LoggerService.error('Auth', '회원가입 실패: $email', e, stackTrace);
      rethrow;
    }
  }

  /// 로그인
  Future<UserCredential> signIn({
    required String email,        // 이메일
    required String password,      // 비밀번호
  }) async {
    // 처리 흐름: Firebase Auth로 이메일/비밀번호 인증 (FireStore 접근 없음)
    // 에러: 모든 예외는 로깅 후 rethrow

    LoggerService.info('Auth', '로그인 시도: $email');
    
    try {
      // Firebase Auth로 이메일/비밀번호 인증
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      LoggerService.info('Auth', '로그인 성공: ${credential.user?.uid}');
      return credential;
    } catch (e, stackTrace) {
      LoggerService.error('Auth', '로그인 실패: $email', e, stackTrace);
      rethrow;
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    // 처리 흐름: Firebase Auth에서 현재 사용자 로그아웃 (FireStore 접근 없음)
    // 에러: 모든 예외는 로깅 후 rethrow

    LoggerService.info('Auth', '로그아웃 시도');
    try {
      // Firebase Auth에서 현재 사용자 로그아웃 (현재 세션만 종료)
      await _auth.signOut();
      LoggerService.info('Auth', '로그아웃 성공');
    } catch (e, stackTrace) {
      LoggerService.error('Auth', '로그아웃 실패', e, stackTrace);
      rethrow;
    }
  }

  /// 비밀번호 재설정 이메일 발송
  Future<void> resetPassword(String email) async {
    // 처리 흐름: Firebase Auth로 비밀번호 재설정 이메일 전송
    // 에러: 모든 예외는 로깅 후 rethrow

    LoggerService.info('Auth', '비밀번호 재설정 이메일 발송 시도: $email');
    try {
      // Firebase Auth로 비밀번호 재설정 이메일 전송
      await _auth.sendPasswordResetEmail(email: email);
      LoggerService.info('Auth', '비밀번호 재설정 이메일 발송 성공: $email');
    } catch (e, stackTrace) {
      LoggerService.error('Auth', '비밀번호 재설정 이메일 발송 실패: $email', e, stackTrace);
      rethrow;
    }
  }
}