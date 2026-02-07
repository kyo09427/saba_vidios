/// アプリユーザーモデル
class AppUser {
  final String id;
  final String email;

  AppUser({
    required this.id,
    required this.email,
  });

  /// Supabase Authから取得したユーザー情報をもとに生成
  factory AppUser.fromAuthUser(dynamic user) {
    return AppUser(
      id: user.id as String,
      email: user.email as String,
    );
  }
}
