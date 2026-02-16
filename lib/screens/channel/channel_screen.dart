import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../models/video.dart';
import '../../models/channel_stats.dart';
import '../../services/supabase_service.dart';
import '../../services/youtube_service.dart';

/// チャンネル画面
/// 
/// 特定のユーザーのチャンネル情報と動画一覧を表示します。
class ChannelScreen extends StatefulWidget {
  final String channelId;

  const ChannelScreen({
    super.key,
    required this.channelId,
  });

  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {
  final _supabase = SupabaseService.instance.client;
  UserProfile? _channelProfile;
  List<Video> _videos = [];
  ChannelStats? _stats;
  bool _isLoading = true;
  bool _isSubscribed = false;
  String? _errorMessage;

  // デザイン用カラー定義
  final Color _ytBackground = const Color(0xFF0F0F0F);
  final Color _ytSurface = const Color(0xFF272727);
  final Color _ytRed = const Color(0xFFF20D0D);
  final Color _textWhite = Colors.white;
  final Color _textGray = const Color(0xFFAAAAAA);

  @override
  void initState() {
    super.initState();
    _loadChannelData();
  }

  /// チャンネルデータを読み込む
  Future<void> _loadChannelData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // プロフィール情報を取得
      final profileResponse = await _supabase
          .from('profiles')
          .select()
          .eq('id', widget.channelId)
          .single();

      final profile = UserProfile.fromJson(profileResponse);

      // 動画一覧を取得
      final videosResponse = await _supabase
          .from('videos')
          .select()
          .eq('user_id', widget.channelId)
          .order('created_at', ascending: false);

      final videos = (videosResponse as List)
          .map((v) => Video.fromJson(v as Map<String, dynamic>).copyWith(
                userProfile: profile,
              ))
          .where((v) => v.id.isNotEmpty)
          .toList();

      // 統計情報を取得
      final subscriberCount =
          await SupabaseService.instance.getSubscriberCount(widget.channelId);
      final videoCount = videos.length;

      final stats = ChannelStats(
        channelId: widget.channelId,
        subscriberCount: subscriberCount,
        videoCount: videoCount,
      );

      // 登録状態を確認
      final isSubscribed =
          await SupabaseService.instance.isSubscribed(widget.channelId);

      if (mounted) {
        setState(() {
          _channelProfile = profile;
          _videos = videos;
          _stats = stats;
          _isSubscribed = isSubscribed;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading channel data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'チャンネル情報の読み込みに失敗しました';
          _isLoading = false;
        });
      }
    }
  }

  /// 登録/登録解除を処理
  Future<void> _toggleSubscription() async {
    try {
      if (_isSubscribed) {
        await SupabaseService.instance.unsubscribeFromChannel(widget.channelId);
      } else {
        await SupabaseService.instance.subscribeToChannel(widget.channelId);
      }

      // 登録状態を更新
      await _loadChannelData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isSubscribed ? 'チャンネル登録を解除しました' : 'チャンネル登録しました！'),
            backgroundColor: _isSubscribed ? Colors.grey : Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 動画をタップしたときの処理
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

  /// 動画カードを構築
  Widget _buildVideoCard(Video video) {
    return InkWell(
      onTap: () => _handleVideoTap(video),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // サムネイル
            SizedBox(
              width: 160,
              height: 90,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: video.thumbnailUrl != null
                        ? Image.network(
                            video.thumbnailUrl!,
                            width: 160,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 160,
                                  height: 90,
                                  color: _ytSurface,
                                  child: Icon(Icons.play_circle_outline,
                                      color: _textGray, size: 36),
                                ),
                          )
                        : Container(
                            width: 160,
                            height: 90,
                            color: _ytSurface,
                            child: Icon(Icons.video_library_outlined,
                                color: _textGray, size: 36),
                          ),
                  ),
                  // 時間表示（ダミー）
                  Positioned(
                    bottom: 4,
                    right: 4,
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
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 動画情報
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
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.relativeTime,
                    style: TextStyle(
                      color: _textGray,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = SupabaseService.instance.currentUser?.id;
    final isOwnChannel = currentUserId == widget.channelId;

    return Scaffold(
      backgroundColor: _ytBackground,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: _ytRed))
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: _ytRed, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: _textWhite),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadChannelData,
                          child: const Text('再読み込み'),
                        ),
                      ],
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      // ヘッダー
                      SliverAppBar(
                        floating: true,
                        backgroundColor: _ytBackground,
                        elevation: 0,
                        leading: IconButton(
                          icon: Icon(Icons.arrow_back, color: _textWhite),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        actions: [
                          IconButton(
                            icon: Icon(Icons.cast, color: _textWhite),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: Icon(Icons.search, color: _textWhite),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: Icon(Icons.more_vert, color: _textWhite),
                            onPressed: () {},
                          ),
                        ],
                      ),

                      // プロフィールセクション
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // アバターとチャンネル情報
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: Colors.purple,
                                    backgroundImage: _channelProfile?.avatarUrl != null
                                        ? NetworkImage(_channelProfile!.avatarUrl!)
                                        : null,
                                    child: _channelProfile?.avatarUrl == null
                                        ? Text(
                                            _channelProfile?.initials ?? '?',
                                            style: const TextStyle(
                                                color: Colors.white, fontSize: 28),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _channelProfile?.username ?? '不明',
                                          style: TextStyle(
                                            color: _textWhite,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '登録者 ${_stats?.subscriberCount ?? 0}人 • 動画 ${_stats?.videoCount ?? 0}本',
                                          style: TextStyle(
                                            color: _textGray,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (_channelProfile?.bio != null &&
                                            _channelProfile!.bio!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            _channelProfile!.bio!,
                                            style: TextStyle(
                                              color: _textGray,
                                              fontSize: 11,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              // 登録ボタン（自分のチャンネルの場合は非表示）
                              if (!isOwnChannel) ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _toggleSubscription,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isSubscribed
                                          ? _ytSurface
                                          : _textWhite,
                                      foregroundColor: _isSubscribed
                                          ? _textWhite
                                          : Colors.black,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    child: Text(
                                      _isSubscribed ? '登録済み' : '登録',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // タブバー
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverAppBarDelegate(
                          minHeight: 48,
                          maxHeight: 48,
                          child: Container(
                            color: _ytBackground,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: _textWhite,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      '動画',
                                      style: TextStyle(
                                        color: _textWhite,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Text(
                                      'ショート',
                                      style: TextStyle(
                                        color: _textGray,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Text(
                                      'プレイリスト',
                                      style: TextStyle(
                                        color: _textGray,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 動画一覧
                      if (_videos.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.video_library_outlined,
                                    size: 80, color: _ytSurface),
                                const SizedBox(height: 16),
                                Text('動画がありません', style: TextStyle(color: _textGray)),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return _buildVideoCard(_videos[index]);
                            },
                            childCount: _videos.length,
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),
      ),
    );
  }
}

/// SliverPersistentHeader用のデリゲート
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
