import 'package:flutter/foundation.dart';

/// ユーザープロフィールモデル
/// 
/// Supabaseのprofilesテーブルとマッピングされます。
@immutable
class UserProfile {
  /// ユーザーの一意識別子（auth.users.idと同じ）
  final String id;

  /// ユーザー名（表示名）
  final String username;

  /// アバター画像のURL（Supabase Storage）
  final String? avatarUrl;

  /// 自己紹介文
  final String? bio;

  /// プロフィール作成日時
  final DateTime createdAt;

  /// プロフィール更新日時
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Supabaseから取得したJSONデータからUserProfileオブジェクトを生成
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    try {
      return UserProfile(
        id: json['id'] as String? ?? '',
        username: json['username'] as String? ?? '名無し',
        avatarUrl: json['avatar_url'] as String?,
        bio: json['bio'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error parsing UserProfile from JSON: $e');
        debugPrint('   JSON data: $json');
      }

      // エラー時のフォールバック
      return UserProfile(
        id: '',
        username: '名無し',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Supabaseへ更新するためのJSONデータに変換
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'avatar_url': avatarUrl,
      'bio': bio,
    };
  }

  /// イニシャルを取得（アバター表示用）
  String get initials {
    if (username.isEmpty) return '?';
    
    // 日本語の場合は最初の1文字
    if (RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]').hasMatch(username)) {
      return username[0];
    }
    
    // 英語の場合は最初の2文字（スペース区切りなら各単語の頭文字）
    final parts = username.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    
    return username.substring(0, username.length > 2 ? 2 : username.length).toUpperCase();
  }

  /// プロフィールのコピーを作成（一部のフィールドを変更可能）
  UserProfile copyWith({
    String? id,
    String? username,
    String? avatarUrl,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserProfile &&
        other.id == id &&
        other.username == username &&
        other.avatarUrl == avatarUrl &&
        other.bio == bio &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      username,
      avatarUrl,
      bio,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, username: $username, avatarUrl: $avatarUrl, bio: $bio)';
  }
}
