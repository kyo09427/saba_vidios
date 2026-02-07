import 'package:url_launcher/url_launcher.dart';

/// YouTube関連の機能を提供するサービスクラス
class YouTubeService {
  /// YouTube URLからビデオIDを抽出
  static String? extractVideoId(String url) {
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

  /// YouTube URLが有効かをチェック
  static bool isValidYouTubeUrl(String url) {
    return extractVideoId(url) != null;
  }

  /// サムネイルURLを生成
  static String? getThumbnailUrl(String videoId) {
    if (videoId.isEmpty) return null;
    // 高画質サムネイル (480x360)
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }

  /// YouTube動画を外部アプリ/ブラウザで開く
  static Future<void> launchVideo(String url) async {
    final uri = Uri.parse(url);
    
    if (!await canLaunchUrl(uri)) {
      throw Exception('Could not launch $url');
    }

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication, // YouTubeアプリで開く
    );
  }
}
