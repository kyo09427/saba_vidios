import 'package:flutter/material.dart';
import '../../models/video.dart';
import '../../services/supabase_service.dart';
import '../../services/youtube_service.dart';

/// 動画投稿画面
class PostVideoScreen extends StatefulWidget {
  const PostVideoScreen({super.key});

  @override
  State<PostVideoScreen> createState() => _PostVideoScreenState();
}

class _PostVideoScreenState extends State<PostVideoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _tagInputController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _previewThumbnail;
  String? _videoId;
  
  // カテゴリとタグの状態
  String _selectedCategory = '雑談';
  final List<String> _categories = ['雑談', 'ゲーム', '音楽', 'ネタ', 'その他'];
  List<String> _tags = [];

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  /// タグを追加
  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isEmpty) return;
    if (_tags.contains(trimmedTag)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('このタグは既に追加されています'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    setState(() {
      _tags.add(trimmedTag);
      _tagInputController.clear();
    });
  }

  /// タグを削除
  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  /// URLからサムネイルをプレビュー
  void _updatePreview(String url) {
    setState(() {
      _videoId = YouTubeService.extractVideoId(url);
      _previewThumbnail = _videoId != null
          ? YouTubeService.getThumbnailUrl(_videoId!)
          : null;
    });
  }

  Future<void> _handlePost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = SupabaseService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('ログインしていません');
      }

      // URLを正規化
      final normalizedUrl = YouTubeService.normalizeUrl(_urlController.text.trim());
      if (normalizedUrl == null) {
        throw Exception('無効なYouTube URLです');
      }

      final video = Video(
        id: '',
        createdAt: DateTime.now(),
        title: _titleController.text.trim(),
        url: normalizedUrl,
        userId: currentUser.id,
        mainCategory: _selectedCategory,
        tags: _tags,
      );

      // 動画を挿入して、挿入されたデータを取得
      final insertedData = await SupabaseService.instance.client
          .from('videos')
          .insert(video.toJson())
          .select()
          .single();
      
      final videoId = insertedData['id'] as String;

      // タグの処理
      if (_tags.isNotEmpty) {
        for (final tagName in _tags) {
          // タグが存在するか確認
          final existingTag = await SupabaseService.instance.client
              .from('tags')
              .select('id')
              .eq('name', tagName)
              .maybeSingle();

          String tagId;
          if (existingTag != null) {
            tagId = existingTag['id'] as String;
          } else {
            // 新しいタグを作成
            final newTag = await SupabaseService.instance.client
                .from('tags')
                .insert({'name': tagName})
                .select('id')
                .single();
            tagId = newTag['id'] as String;
          }

          // video_tagsテーブルに関連付けを追加
          await SupabaseService.instance.client
              .from('video_tags')
              .insert({
            'video_id': videoId,
            'tag_id': tagId,
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('動画を投稿しました！'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // trueを返して、ホーム画面でリフレッシュを促す
        Navigator.of(context).pop(true);
      }
    } on Exception catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } catch (e) {
      setState(() {
        _errorMessage = '投稿に失敗しました。もう一度お試しください。\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('動画を投稿'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 説明
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'YouTube動画を投稿',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'YouTubeの動画URLを入力してください。\n一覧にサムネイルとタイトルが表示されます。',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // YouTube URL入力
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'YouTube URL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                  helperText: '例: https://www.youtube.com/watch?v=...',
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                onChanged: _updatePreview,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'URLを入力してください';
                  }
                  if (!YouTubeService.isValidYouTubeUrl(value)) {
                    return '有効なYouTube URLを入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // サムネイルプレビュー
              if (_previewThumbnail != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'プレビュー',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          _previewThumbnail!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.error,
                                color: Colors.red,
                                size: 48,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              // タイトル入力
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '動画タイトル',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                  helperText: '動画の説明やメモを入力',
                ),
                maxLength: 100,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (_formKey.currentState!.validate()) {
                    _handlePost();
                  }
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'タイトルを入力してください';
                  }
                  if (value.trim().length < 3) {
                    return 'タイトルは3文字以上で入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // メインカテゴリ選択
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'メインカテゴリ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                  helperText: 'カテゴリを選択（必須）',
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              // サブカテゴリタグ入力
              TextFormField(
                controller: _tagInputController,
                decoration: InputDecoration(
                  labelText: 'タグ',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.tag),
                  helperText: '複数入力可能（Enterで追加）',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      _addTag(_tagInputController.text);
                    },
                  ),
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: _addTag,
              ),
              const SizedBox(height: 8),

              // タグのチップ表示
              if (_tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      onDeleted: () => _removeTag(tag),
                      deleteIcon: const Icon(Icons.close, size: 18),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),

              // エラーメッセージ
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[900]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[900]),
                        ),
                      ),
                    ],
                  ),
                ),

              // 投稿ボタン
              ElevatedButton(
                onPressed: _isLoading ? null : _handlePost,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send),
                          SizedBox(width: 8),
                          Text('投稿する', style: TextStyle(fontSize: 16)),
                        ],
                      ),
              ),
              const SizedBox(height: 16),

              // キャンセルボタン
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}