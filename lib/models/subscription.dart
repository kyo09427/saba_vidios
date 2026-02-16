import 'package:flutter/foundation.dart';

/// チャンネル登録モデル
/// 
/// Supabaseのsubscriptionsテーブルとマッピングされます。
@immutable
class Subscription {
  /// 登録の一意識別子（UUID）
  final String id;

  /// 登録者のユーザーID
  final String subscriberId;

  /// チャンネル（登録先）のユーザーID
  final String channelId;

  /// 登録日時
  final DateTime createdAt;

  const Subscription({
    required this.id,
    required this.subscriberId,
    required this.channelId,
    required this.createdAt,
  });

  /// Supabaseから取得したJSONデータからSubscriptionオブジェクトを生成
  factory Subscription.fromJson(Map<String, dynamic> json) {
    try {
      return Subscription(
        id: json['id'] as String? ?? '',
        subscriberId: json['subscriber_id'] as String? ?? '',
        channelId: json['channel_id'] as String? ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error parsing Subscription from JSON: $e');
        debugPrint('   JSON data: $json');
      }

      // エラー時のフォールバック
      return Subscription(
        id: '',
        subscriberId: '',
        channelId: '',
        createdAt: DateTime.now(),
      );
    }
  }

  /// Supabaseへinsertするための JSONデータに変換
  Map<String, dynamic> toJson() {
    return {
      'subscriber_id': subscriberId,
      'channel_id': channelId,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Subscription &&
        other.id == id &&
        other.subscriberId == subscriberId &&
        other.channelId == channelId &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      subscriberId,
      channelId,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'Subscription(id: $id, subscriberId: $subscriberId, channelId: $channelId, createdAt: $createdAt)';
  }
}
