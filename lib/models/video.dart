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
    return Video(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      title: json['title'] as String,
      url: json['url'] as String,
      userId: json['user_id'] as String,
    );
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

    return null;
  }

  /// YouTubeサムネイルURLを取得
  String? get thumbnailUrl {
    final id = videoId;
    if (id == null) return null;
    // 高画質サムネイル
    return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }

  /// 投稿日時を日本語形式で表示（JST）
  String get formattedDate {
    final jst = createdAt.toLocal();
    return DateFormat('yyyy年MM月dd日 HH:mm', 'ja_JP').format(jst);
  }
}
