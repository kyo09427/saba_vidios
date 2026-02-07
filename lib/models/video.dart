import 'package:intl/intl.dart';

/// 動画データモデル
class Video {
  final String id;
  final DateTime createdAt;
  final String title;
  final String url;
  final String userId;

  Video({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.url,
    required this.userId,
  });

  /// Supabaseから取得したJSONデータからVideoオブジェクトを生成
  factory Video.fromJson(Map<String, dynamic> json) {
    try {
      return Video(
        id: json['id'] as String? ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        title: json['title'] as String? ?? '無題の動画',
        url: json['url'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
      );
    } catch (e) {
      // パースエラー時のフォールバック
      return Video(
        id: '',
        createdAt: DateTime.now(),
        title: '読み込みエラー',
        url: '',
        userId: '',
      );
    }
  }

  /// SupabaseへinsertするためのJSONデータに変換
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'user_id': userId,
    };
  }

  /// YouTube動画IDを抽出（URLから）
  String? get videoId {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // youtu.be形式: https://youtu.be/VIDEO_ID
    if (uri.host == 'youtu.be') {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
    }

    // youtube.com形式: https://www.youtube.com/watch?v=VIDEO_ID
    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    }

    // m.youtube.com形式にも対応
    if (uri.host.contains('m.youtube.com')) {
      return uri.queryParameters['v'];
    }

    return null;
  }

  /// YouTubeサムネイルURLを取得
  String? get thumbnailUrl {
    final id = videoId;
    if (id == null || id.isEmpty) return null;
    // 高画質サムネイル
    return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }

  /// 投稿日時を日本語形式で表示（JST）
  String get formattedDate {
    final jst = createdAt.toLocal();
    return DateFormat('yyyy年MM月dd日 HH:mm', 'ja_JP').format(jst);
  }

  /// 相対時間を表示するヘルパー (例: 2時間前)
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}年前';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}ヶ月前';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}日前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}時間前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }
}