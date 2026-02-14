import 'package:flutter/foundation.dart';

/// タグデータモデル
/// 
/// サブカテゴリタグの情報を保持するモデルクラス。
/// Supabaseのtagsテーブルとマッピングされます。
@immutable
class Tag {
  /// タグの一意識別子（UUID）
  final String id;

  /// タグ名
  final String name;

  /// 作成日時
  final DateTime createdAt;

  /// 使用回数（人気タグ表示用）
  final int usageCount;

  const Tag({
    required this.id,
    required this.name,
    required this.createdAt,
    this.usageCount = 0,
  });

  /// Supabaseから取得したJSONデータからTagオブジェクトを生成
  factory Tag.fromJson(Map<String, dynamic> json) {
    try {
      return Tag(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        usageCount: json['usage_count'] as int? ?? 0,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error parsing Tag from JSON: $e');
        debugPrint('   JSON data: $json');
      }

      return Tag(
        id: '',
        name: '',
        createdAt: DateTime.now(),
        usageCount: 0,
      );
    }
  }

  /// SupabaseへinsertするためのJSONデータに変換
  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }

  @override
  String toString() => 'Tag(id: $id, name: $name, usageCount: $usageCount)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
