import 'package:flutter/foundation.dart';

/// チャンネル統計情報
/// 
/// チャンネルの登録者数や動画数などの統計情報を保持します。
@immutable
class ChannelStats {
  /// チャンネルID（user_id）
  final String channelId;

  /// 登録者数
  final int subscriberCount;

  /// 動画数
  final int videoCount;

  const ChannelStats({
    required this.channelId,
    required this.subscriberCount,
    required this.videoCount,
  });

  /// 空のインスタンスを作成
  factory ChannelStats.empty(String channelId) {
    return ChannelStats(
      channelId: channelId,
      subscriberCount: 0,
      videoCount: 0,
    );
  }

  /// コピーを作成（一部のフィールドを変更可能）
  ChannelStats copyWith({
    String? channelId,
    int? subscriberCount,
    int? videoCount,
  }) {
    return ChannelStats(
      channelId: channelId ?? this.channelId,
      subscriberCount: subscriberCount ?? this.subscriberCount,
      videoCount: videoCount ?? this.videoCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChannelStats &&
        other.channelId == channelId &&
        other.subscriberCount == subscriberCount &&
        other.videoCount == videoCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      channelId,
      subscriberCount,
      videoCount,
    );
  }

  @override
  String toString() {
    return 'ChannelStats(channelId: $channelId, subscriberCount: $subscriberCount, videoCount: $videoCount)';
  }
}
