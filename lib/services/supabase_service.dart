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
    await dotenv.load(fileName: '.env');

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be defined in .env file',
      );
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    _client = Supabase.instance.client;
  }

  /// 共有パスワードを検証
  bool validateSharedPassword(String password) {
    final sharedPassword = dotenv.env['SHARED_PASSWORD'];
    if (sharedPassword == null || sharedPassword.isEmpty) {
      throw Exception('SHARED_PASSWORD is not defined in .env file');
    }
    return password == sharedPassword;
  }

  /// 現在のユーザーを取得
  User? get currentUser => client.auth.currentUser;

  /// 認証状態の変更を監視
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// メールアドレスとパスワードで新規登録
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// メールアドレスとパスワードでログイン
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// ログアウト
  Future<void> signOut() async {
    await client.auth.signOut();
  }
}
