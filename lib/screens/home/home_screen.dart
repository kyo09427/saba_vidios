import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/video.dart';
import '../../services/supabase_service.dart';
import '../../services/youtube_service.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../auth/login_screen.dart';
import '../post/post_video_screen.dart';

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

  // デザイン用カラー定義
  final Color _ytBackground = const Color(0xFF0F0F0F);
  final Color _ytSurface = const Color(0xFF272727);
  final Color _ytRed = const Color(0xFFF20D0D);
  final Color _textWhite = Colors.white;
  final Color _textGray = const Color(0xFFAAAAAA);

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _cleanupRealtimeSubscription();
    super.dispose();
  }

  /// リアルタイム購読のクリーンアップ
  void _cleanupRealtimeSubscription() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }

  Future<void> _loadVideos({bool isRefresh = false}) async {
    if (!mounted) return;
    
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
          .where((video) => video.id.isNotEmpty) // 無効なデータを除外
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
          _errorMessage = '動画の読み込みに失敗しました';
          _isLoading = false;
        });
      }
    }
  }

  void _setupRealtimeSubscription() {
    _realtimeChannel = _supabase
        .channel('videos_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'videos',
          callback: (payload) {
            if (mounted) {
              _loadVideos(isRefresh: true);
            }
          },
        )
        .subscribe();
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _ytSurface,
        title: Text('ログアウト', style: TextStyle(color: _textWhite)),
        content: Text('ログアウトしますか?', style: TextStyle(color: _textWhite)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('ログアウト', style: TextStyle(color: _ytRed)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        // リアルタイム購読をクリーンアップ
        _cleanupRealtimeSubscription();
        
        await SupabaseService.instance.signOut();
        
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ログアウトに失敗しました: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _navigateToPostScreen() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PostVideoScreen()),
    );
    
    // 投稿画面から戻ってきた場合、明示的にリフレッシュ
    if (result == true && mounted) {
      await _loadVideos(isRefresh: true);
    }
  }

  Future<void> _handleVideoTap(Video video) async {
    if (video.url.isEmpty) {
      _showErrorSnackBar('無効な動画URLです');
      return;
    }

    final success = await YouTubeService.launchVideo(video.url);
    
    if (!success && mounted) {
      _showErrorSnackBar('動画を開けませんでした');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// カテゴリフィルター部分
  Widget _buildCategoryPills() {
    final categories = ['すべて', '新しい動画', 'ゲーム', '音楽', 'ライブ', 'ミックス', '料理', 'ペット'];
    return SliverToBoxAdapter(
      child: Container(
        height: 48,
        color: _ytBackground.withOpacity(0.95),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: categories.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _ytSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.explore_outlined, color: _textWhite, size: 20),
              );
            }
            
            final category = categories[index - 1];
            final isSelected = index == 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? _textWhite : _ytSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.black : _textWhite,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// ショート動画セクション
  Widget _buildShortsSection() {
    final shortsData = [
      {'title': 'すごいドラムソロ！🥁', 'views': '150万回視聴', 'color': Colors.blue},
      {'title': '完璧な盛り付けのコツ 👨‍🍳', 'views': '89万回視聴', 'color': Colors.orange},
      {'title': '子犬の朝のルーティン 🐶', 'views': '210万回視聴', 'color': Colors.green},
    ];

    return SliverToBoxAdapter(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
            child: Row(
              children: [
                Icon(Icons.bolt, color: _ytRed, size: 24),
                const SizedBox(width: 8),
                Text(
                  'ショート',
                  style: TextStyle(
                    color: _textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 260,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: shortsData.length,
              itemBuilder: (context, index) {
                final item = shortsData[index];
                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: item['color'] as Color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 8,
                        right: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['views'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Positioned(
                        top: 4,
                        right: 4,
                        child: Icon(Icons.more_vert, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            height: 6,
            margin: const EdgeInsets.only(top: 24),
            color: _ytSurface.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  /// 動画カード
  Widget _buildVideoCard(Video video) {
    return InkWell(
      onTap: () => _handleVideoTap(video),
      child: Column(
        children: [
          // サムネイル
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: video.thumbnailUrl != null && video.thumbnailUrl!.isNotEmpty
                    ? Image.network(
                        video.thumbnailUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: _ytSurface,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: _ytRed,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              color: _ytSurface,
                              child: Center(
                                child: Icon(Icons.play_circle_outline,
                                    color: _textGray, size: 48),
                              ),
                            ),
                      )
                    : Container(
                        color: _ytSurface,
                        child: Center(
                          child: Icon(Icons.video_library_outlined,
                              color: _textGray, size: 48),
                        ),
                      ),
              ),
              // 時間表示バッジ (ダミー)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '12:45',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
          // 動画詳細情報
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.purple,
                  child: Text('サ', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _textWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.normal,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'サバ公式 • 1.2万回視聴 • ${video.relativeTime}',
                        style: TextStyle(color: _textGray, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.more_vert, color: _textWhite, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: _ytRed, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'エラーが発生しました',
              style: TextStyle(color: _textWhite),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadVideos(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _ytSurface,
                foregroundColor: _textWhite,
              ),
              child: const Text('再読み込み'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ytBackground,
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: _ytRed))
            : _errorMessage != null
                ? _buildErrorView()
                : RefreshIndicator(
                    onRefresh: () => _loadVideos(isRefresh: true),
                    color: _ytRed,
                    backgroundColor: _ytSurface,
                    child: CustomScrollView(
                      slivers: [
                        // ヘッダー
                        SliverAppBar(
                          floating: true,
                          backgroundColor: _ytBackground.withOpacity(0.95),
                          elevation: 0,
                          titleSpacing: 0,
                          leadingWidth: 0,
                          leading: const SizedBox.shrink(),
                          automaticallyImplyLeading: false,
                          title: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Row(
                              children: [
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.play_circle_filled,
                                      color: _ytRed, size: 30),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'サバの動画',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.cast),
                              onPressed: () {},
                              color: _textWhite,
                            ),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications_outlined),
                                  onPressed: () {},
                                  color: _textWhite,
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: _ytRed,
                                      border: Border.all(
                                          color: _ytBackground, width: 1.5),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () {},
                              color: _textWhite,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 12, left: 4),
                              child: GestureDetector(
                                onTap: _handleLogout,
                                child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.purple,
                                  child: Text('S',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.white)),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // カテゴリフィルター
                        _buildCategoryPills(),

                        // コンテンツ
                        if (_videos.isEmpty)
                          SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.video_library_outlined,
                                      size: 80, color: _ytSurface),
                                  const SizedBox(height: 16),
                                  Text('動画がありません',
                                      style: TextStyle(color: _textGray)),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: _navigateToPostScreen,
                                    icon: const Icon(Icons.add),
                                    label: const Text('最初の動画を投稿'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _ytRed,
                                      foregroundColor: _textWhite,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else ...[
                          // 1つ目の動画
                          if (_videos.isNotEmpty)
                            SliverToBoxAdapter(
                              child: _buildVideoCard(_videos.first),
                            ),

                          // ショート動画セクション
                          _buildShortsSection(),

                          // 2つ目以降の動画
                          if (_videos.length > 1)
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return _buildVideoCard(_videos[index + 1]);
                                },
                                childCount: _videos.length - 1,
                              ),
                            ),
                          
                          const SliverToBoxAdapter(child: SizedBox(height: 80)),
                        ],
                      ],
                    ),
                  ),
      ),
      // ボトムナビゲーション
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 0),
    );
  }
}