import 'package:url_launcher/url_launcher.dart';

/// YouTube関連の機能を提供するサービスクラス
class YouTubeService {
  /// YouTube URLからビデオIDを抽出
  static String? extractVideoId(String url) {
    if (url.isEmpty) return null;
    
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // youtu.be形式: https://youtu.be/VIDEO_ID
    if (uri.host == 'youtu.be' || uri.host == 'www.youtu.be') {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments[0].split('?')[0] : null;
    }

    // youtube.com形式: https://www.youtube.com/watch?v=VIDEO_ID
    // m.youtube.com形式にも対応
    if (uri.host.contains('youtube.com')) {
      final videoId = uri.queryParameters['v'];
      if (videoId != null && videoId.isNotEmpty) {
        return videoId;
      }
      
      // /embed/VIDEO_ID 形式
      if (uri.pathSegments.contains('embed') && uri.pathSegments.length > 1) {
        final index = uri.pathSegments.indexOf('embed');
        if (index + 1 < uri.pathSegments.length) {
          return uri.pathSegments[index + 1].split('?')[0];
        }
      }
      
      // /v/VIDEO_ID 形式
      if (uri.pathSegments.contains('v') && uri.pathSegments.length > 1) {
        final index = uri.pathSegments.indexOf('v');
        if (index + 1 < uri.pathSegments.length) {
          return uri.pathSegments[index + 1].split('?')[0];
        }
      }
    }

    return null;
  }

  /// YouTube URLが有効かをチェック
  static bool isValidYouTubeUrl(String url) {
    if (url.isEmpty) return false;
    final videoId = extractVideoId(url);
    return videoId != null && videoId.isNotEmpty && videoId.length == 11;
  }

  /// サムネイルURLを生成
  static String? getThumbnailUrl(String videoId) {
    if (videoId.isEmpty || videoId.length != 11) return null;
    // 高画質サムネイル (480x360)
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }

  /// 複数の画質のサムネイルURLを取得
  static Map<String, String> getThumbnailUrls(String videoId) {
    if (videoId.isEmpty || videoId.length != 11) return {};
    
    return {
      'default': 'https://img.youtube.com/vi/$videoId/default.jpg', // 120x90
      'medium': 'https://img.youtube.com/vi/$videoId/mqdefault.jpg', // 320x180
      'high': 'https://img.youtube.com/vi/$videoId/hqdefault.jpg', // 480x360
      'standard': 'https://img.youtube.com/vi/$videoId/sddefault.jpg', // 640x480
      'maxres': 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg', // 1280x720
    };
  }

  /// YouTube動画を外部アプリ/ブラウザで開く
  static Future<bool> launchVideo(String url) async {
    if (url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      
      if (!await canLaunchUrl(uri)) {
        return false;
      }

      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // YouTubeアプリで開く
      );
    } catch (e) {
      return false;
    }
  }

  /// YouTube動画のURLを正規化（標準形式に変換）
  static String? normalizeUrl(String url) {
    final videoId = extractVideoId(url);
    if (videoId == null || videoId.isEmpty) return null;
    
    return 'https://www.youtube.com/watch?v=$videoId';
  }
}