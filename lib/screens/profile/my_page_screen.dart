import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../auth/login_screen.dart';

/// マイページ画面
class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final _supabase = SupabaseService.instance.client;
  
  // ユーザー情報
  String? _userEmail;
  DateTime? _createdAt;
  
  // 統計情報（ダミーデータ）
  int _totalVideos = 0;
  int _totalViews = 0;
  int _totalLikes = 0;
  
  // 設定
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _autoPlayEnabled = true;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = SupabaseService.instance.currentUser;
      
      if (user != null) {
        // 投稿数を取得
        final videoCount = await _supabase
            .from('videos')
            .select()
            .eq('user_id', user.id)
            .count();

        setState(() {
          _userEmail = user.email;
          _createdAt = user.createdAt != null 
              ? DateTime.parse(user.createdAt) 
              : null;
          _totalVideos = videoCount.count;
          // ダミーデータ
          _totalViews = _totalVideos * 120;
          _totalLikes = _totalVideos * 15;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
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

  String _getInitials(String? email) {
    if (email == null || email.isEmpty) return '?';
    return email[0].toUpperCase();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '不明';
    return '${date.year}年${date.month}月${date.day}日';
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.blue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.blue,
          size: 24,
        ),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.blue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.blue,
          size: 24,
        ),
      ),
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('マイページ'),
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false, // 戻るボタンを非表示
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // プロフィールヘッダー
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        // アバター
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue,
                          child: Text(
                            _getInitials(_userEmail),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // メールアドレス
                        Text(
                          _userEmail ?? '未設定',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        // 登録日
                        Text(
                          '登録日: ${_formatDate(_createdAt)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // プロフィール編集ボタン
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('プロフィール編集機能は準備中です'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('プロフィール編集'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 統計情報
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '統計情報',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.video_library,
                                label: '投稿動画',
                                value: '$_totalVideos',
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.visibility,
                                label: '総再生数',
                                value: '$_totalViews',
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.favorite,
                                label: 'いいね',
                                value: '$_totalLikes',
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 設定セクション
                  Container(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '設定',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        _buildSwitchTile(
                          icon: Icons.notifications,
                          title: '通知を受け取る',
                          value: _notificationsEnabled,
                          onChanged: (value) {
                            setState(() {
                              _notificationsEnabled = value;
                            });
                          },
                          iconColor: Colors.orange,
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          icon: Icons.dark_mode,
                          title: 'ダークモード',
                          value: _darkModeEnabled,
                          onChanged: (value) {
                            setState(() {
                              _darkModeEnabled = value;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ダークモード機能は準備中です'),
                              ),
                            );
                          },
                          iconColor: Colors.purple,
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          icon: Icons.play_circle,
                          title: '自動再生',
                          value: _autoPlayEnabled,
                          onChanged: (value) {
                            setState(() {
                              _autoPlayEnabled = value;
                            });
                          },
                          iconColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // その他のメニュー
                  Container(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'その他',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        _buildMenuTile(
                          icon: Icons.video_collection,
                          title: '投稿した動画',
                          subtitle: '$_totalVideos件',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('投稿動画一覧機能は準備中です'),
                              ),
                            );
                          },
                          iconColor: Colors.blue,
                        ),
                        const Divider(height: 1),
                        _buildMenuTile(
                          icon: Icons.favorite,
                          title: 'いいねした動画',
                          subtitle: '機能準備中',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('いいね機能は準備中です'),
                              ),
                            );
                          },
                          iconColor: Colors.red,
                        ),
                        const Divider(height: 1),
                        _buildMenuTile(
                          icon: Icons.history,
                          title: '視聴履歴',
                          subtitle: '機能準備中',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('視聴履歴機能は準備中です'),
                              ),
                            );
                          },
                          iconColor: Colors.purple,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // サポート・情報
                  Container(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'サポート・情報',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        _buildMenuTile(
                          icon: Icons.help_outline,
                          title: 'ヘルプ・使い方',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('使い方'),
                                content: const SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '📹 動画の投稿',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 4),
                                      Text('ホーム画面の「+」ボタンから投稿できます。'),
                                      SizedBox(height: 12),
                                      Text(
                                        '👀 動画の視聴',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 4),
                                      Text('動画カードをタップするとYouTubeアプリで開きます。'),
                                      SizedBox(height: 12),
                                      Text(
                                        '🔄 最新情報に更新',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 4),
                                      Text('画面を下にスワイプすると最新情報に更新されます。'),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('閉じる'),
                                  ),
                                ],
                              ),
                            );
                          },
                          iconColor: Colors.green,
                        ),
                        const Divider(height: 1),
                        _buildMenuTile(
                          icon: Icons.info_outline,
                          title: 'アプリについて',
                          subtitle: 'バージョン 1.1.0',
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: 'サバの動画',
                              applicationVersion: '1.1.0',
                              applicationIcon: const Icon(
                                Icons.video_library,
                                size: 48,
                                color: Colors.blue,
                              ),
                              children: const [
                                Text('仲間内でYouTube動画を共有するアプリ'),
                                SizedBox(height: 8),
                                Text('© 2026 サバの仲間たち'),
                              ],
                            );
                          },
                          iconColor: Colors.blue,
                        ),
                        const Divider(height: 1),
                        _buildMenuTile(
                          icon: Icons.privacy_tip_outlined,
                          title: 'プライバシーポリシー',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('プライバシーポリシーは準備中です'),
                              ),
                            );
                          },
                          iconColor: Colors.grey,
                        ),
                        const Divider(height: 1),
                        _buildMenuTile(
                          icon: Icons.description_outlined,
                          title: '利用規約',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('利用規約は準備中です'),
                              ),
                            );
                          },
                          iconColor: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ログアウトボタン
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout),
                        label: const Text('ログアウト'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
      // ボトムナビゲーション
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 4),
    );
  }
}