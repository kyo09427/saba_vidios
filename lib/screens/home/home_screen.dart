import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/video.dart';
import '../../services/supabase_service.dart';
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

  // デザイン用カラー定義 (HTMLに基づく)
  final Color _ytBackground = const Color(0xFF0F0F0F);
  final Color _ytSurface = const Color(0xFF272727);
  final Color _ytRed = const Color(0xFFF20D0D); // primary
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
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadVideos() async {
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

  void _setupRealtimeSubscription() {
    _realtimeChannel = _supabase
        .channel('videos')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'videos',
          callback: (payload) {
            if (mounted) {
              _loadVideos();
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
      await SupabaseService.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  Future<void> _navigateToPostScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PostVideoScreen()),
    );
    _loadVideos();
  }

  /// 相対時間を表示するヘルパー (例: 2時間前)
  String _formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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

  // --- UI Components ---

  /// カテゴリフィルター部分
  Widget _buildCategoryPills() {
    final categories = ['すべて', '新しい動画', 'ゲーム', '音楽', 'ライブ', 'ミックス', '料理', 'ペット'];
    return SliverToBoxAdapter(
      child: Container(
        height: 48,
        color: _ytBackground.withOpacity(0.95), // 背景透過
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
            // 最初の要素以外
            final category = categories[index - 1];
            final isSelected = index == 1; // "すべて"を選択状態に
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

  /// ショート動画セクション (HTMLのデザインを再現)
  Widget _buildShortsSection() {
    // ダミーデータ
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
                Icon(Icons.bolt, color: _ytRed, size: 24), // ショートアイコンの代用
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
                      // グラデーションオーバーレイ
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
                      // テキスト情報
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
                      // メニューアイコン
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
          // セクション区切り線
          Container(
            height: 6,
            margin: const EdgeInsets.only(top: 24),
            color: _ytSurface.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  /// 通常の動画カード
  Widget _buildVideoCard(Video video) {
    // モデルのプロパティへの安全なアクセス
    // (Videoモデルの実装に依存しますが、一般的なフィールド名を想定)
    final dynamic v = video; // 型キャスト回避用
    String title = '無題の動画';
    String thumbnailUrl = '';
    DateTime? createdAt;

    try {
      title = v.title ?? '無題の動画';
      thumbnailUrl = v.thumbnailUrl ?? '';
      createdAt = v.createdAt;
    } catch (_) {
      // フィールド名が異なる場合のフォールバック
    }

    return Column(
      children: [
        // サムネイル
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: thumbnailUrl.isNotEmpty
                  ? Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: _ytSurface),
                    )
                  : Container(
                      color: _ytSurface,
                      child: Center(
                        child: Icon(Icons.play_circle_outline,
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
              // アバターアイコン
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.purple,
                child: Text('サ', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              // テキスト情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
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
                      'サバ公式 • 1.2万回視聴 • ${_formatRelativeTime(createdAt)}',
                      style: TextStyle(color: _textGray, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // メニュー
              Icon(Icons.more_vert, color: _textWhite, size: 20),
            ],
          ),
        ),
        // 区切り線 (最後の要素以外に付けるロジックも可能だが、HTMLに合わせてシンプルに配置しないか、薄く配置)
        // HTMLでは border-bottom で区切っている
        // Container(height: 1, color: _ytSurface), 
      ],
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
                : CustomScrollView(
                    slivers: [
                      // --- ヘッダー (SliverAppBar) ---
                      SliverAppBar(
                        floating: true,
                        backgroundColor: _ytBackground.withOpacity(0.95),
                        elevation: 0,
                        titleSpacing: 0,
                        leadingWidth: 0,
                        leading: const SizedBox.shrink(),
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
                                  child: const Center(
                                    child: Text('9+',
                                        style: TextStyle(
                                            fontSize: 6, color: Colors.white)),
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

                      // --- カテゴリフィルター ---
                      _buildCategoryPills(),

                      // --- コンテンツ ---
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

                        // ショート動画セクション (HTMLのように途中に挟む)
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
                        
                        // 動画が少ない場合に下部に余白を持たせる
                         const SliverToBoxAdapter(child: SizedBox(height: 80)),
                      ],
                    ],
                  ),
      ),
      // --- ボトムナビゲーション ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _ytBackground,
          border: Border(top: BorderSide(color: _ytSurface, width: 0.5)),
        ),
        padding: EdgeInsets.only(
          top: 8,
          bottom: MediaQuery.of(context).padding.bottom + 8, // Safe Area考慮
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_filled, 'ホーム', isActive: true),
            _buildNavItem(Icons.bolt, 'ショート'),
            
            // 投稿ボタン (+)
            InkWell(
              onTap: _navigateToPostScreen,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1),
                  color: _ytSurface.withOpacity(0.5),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
            
            _buildNavItem(Icons.subscriptions_outlined, '登録チャンネル'),
            _buildNavItem(Icons.account_circle_outlined, 'マイページ'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool isActive = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? _textWhite : _textWhite,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? _textWhite : _textWhite,
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: _ytRed, size: 48),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: TextStyle(color: _textWhite)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadVideos,
            style: ElevatedButton.styleFrom(
              backgroundColor: _ytSurface,
              foregroundColor: _textWhite,
            ),
            child: const Text('再読み込み'),
          ),
        ],
      ),
    );
  }
}