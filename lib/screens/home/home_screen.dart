import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/video.dart';
import '../../services/supabase_service.dart';
import '../../widgets/video_card.dart';
import '../auth/login_screen.dart';
import '../post/post_video_screen.dart';

/// ホーム画面（動画一覧）
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = SupabaseService.instance.client;
  List<Video> _videos = [];
  bool _isLoading = true;
  String? _errorMessage;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    // リアルタイムチャンネルのクリーンアップ
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  /// 動画一覧を読み込む
  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _supabase
          .from('videos')
          .select()
          .order('created_at', ascending: false);

      final videos = (response as List)
          .map((json) => Video.fromJson(json as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _videos = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '動画の読み込みに失敗しました: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  /// リアルタイム更新を設定
  void _setupRealtimeSubscription() {
    _realtimeChannel = _supabase
        .channel('videos')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'videos',
          callback: (payload) {
            // データに変更があったら再読み込み（mountedチェック済み）
            if (mounted) {
              _loadVideos();
            }
          },
        )
        .subscribe();
  }

  /// ログアウト処理
  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await SupabaseService.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  /// 投稿画面へ遷移
  Future<void> _navigateToPostScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PostVideoScreen()),
    );
    // 投稿画面から戻ってきたら再読み込み
    _loadVideos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('サバの動画'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'ログアウト',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadVideos,
                        child: const Text('再読み込み'),
                      ),
                    ],
                  ),
                )
              : _videos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.video_library_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'まだ動画が投稿されていません',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '右下のボタンから動画を投稿しましょう！',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadVideos,
                      child: ListView.builder(
                        itemCount: _videos.length,
                        itemBuilder: (context, index) {
                          return VideoCard(video: _videos[index]);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToPostScreen,
        tooltip: '動画を投稿',
        child: const Icon(Icons.add),
      ),
    );
  }
}
