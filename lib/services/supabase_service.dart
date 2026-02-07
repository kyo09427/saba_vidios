import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase接続を管理するサービスクラス
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  SupabaseService._();

  /// シングルトンインスタンスを取得
  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  /// Supabaseクライアントを取得
  SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase is not initialized. Call initialize() first.');
    }
    return _client!;
  }

  /// Supabaseの初期化
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');

      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (supabaseUrl == null || supabaseUrl.isEmpty) {
        throw Exception('SUPABASE_URL is not defined in .env file');
      }

      if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
        throw Exception('SUPABASE_ANON_KEY is not defined in .env file');
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: kDebugMode, // デバッグモードでのみログを出力
      );

      _client = Supabase.instance.client;
      
      if (kDebugMode) {
        debugPrint('✅ Supabase initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Supabase initialization failed: $e');
      }
      rethrow;
    }
  }

  /// 共有パスワードを検証
  bool validateSharedPassword(String password) {
    try {
      final sharedPassword = dotenv.env['SHARED_PASSWORD'];
      if (sharedPassword == null || sharedPassword.isEmpty) {
        throw Exception('SHARED_PASSWORD is not defined in .env file');
      }
      return password == sharedPassword;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Shared password validation failed: $e');
      }
      rethrow;
    }
  }

  /// 現在のユーザーを取得
  User? get currentUser => client.auth.currentUser;

  /// 現在のセッションを取得
  Session? get currentSession => client.auth.currentSession;

  /// 認証状態の変更を監視
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// メールアドレスとパスワードで新規登録
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🔐 Attempting sign up for: $email');
      }

      final response = await client.auth.signUp(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        debugPrint('✅ Sign up successful for: $email');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Sign up failed: $e');
      }
      rethrow;
    }
  }

  /// メールアドレスとパスワードでログイン
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🔐 Attempting sign in for: $email');
      }

      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        debugPrint('✅ Sign in successful for: $email');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Sign in failed: $e');
      }
      rethrow;
    }
  }

  /// ログアウト
  Future<void> signOut() async {
    try {
      if (kDebugMode) {
        debugPrint('🔐 Attempting sign out');
      }

      await client.auth.signOut();

      if (kDebugMode) {
        debugPrint('✅ Sign out successful');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Sign out failed: $e');
      }
      rethrow;
    }
  }

  /// パスワードリセットメールを送信
  Future<void> resetPasswordForEmail(String email) async {
    try {
      if (kDebugMode) {
        debugPrint('📧 Sending password reset email to: $email');
      }

      await client.auth.resetPasswordForEmail(email);

      if (kDebugMode) {
        debugPrint('✅ Password reset email sent');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Password reset failed: $e');
      }
      rethrow;
    }
  }

  /// 認証状態を確認
  bool get isAuthenticated => currentUser != null && currentSession != null;
}