import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_profile.dart';
import '../../services/profile_service.dart';
import '../../services/supabase_service.dart';

/// プロフィール編集画面
class EditProfileScreen extends StatefulWidget {
  final UserProfile profile;

  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _profileService = ProfileService.instance;
  final _imagePicker = ImagePicker();

  String? _avatarUrl;
  Uint8List? _newAvatarData;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.profile.username;
    _bioController.text = widget.profile.bio ?? '';
    _avatarUrl = widget.profile.avatarUrl;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  /// アバター画像を選択
  Future<void> _pickAvatar() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _newAvatarData = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('画像の選択に失敗しました: ${e.toString()}');
      }
    }
  }

  /// プロフィールを保存
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final currentUser = SupabaseService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('ログインしていません');
      }

      // ユーザー名の重複チェック
      final username = _usernameController.text.trim();
      if (username != widget.profile.username) {
        final isTaken = await _profileService.isUsernameTaken(
          username,
          excludeUserId: currentUser.id,
        );

        if (isTaken) {
          if (mounted) {
            _showErrorSnackBar('このユーザー名は既に使用されています');
          }
          return;
        }
      }

      // アバター画像のアップロード
      String? newAvatarUrl = _avatarUrl;
      if (_newAvatarData != null) {
        newAvatarUrl = await _profileService.uploadAvatar(
          currentUser.id,
          _newAvatarData!,
        );
        
        // 古いアバターを削除
        await _profileService.deleteOldAvatars(currentUser.id, newAvatarUrl);
      }

      // プロフィール更新
      final updatedProfile = widget.profile.copyWith(
        username: username,
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        avatarUrl: newAvatarUrl,
        updatedAt: DateTime.now(),
      );

      await _profileService.updateProfile(updatedProfile);

      if (mounted) {
        // 成功メッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プロフィールを更新しました'),
            backgroundColor: Colors.green,
          ),
        );

        // 前の画面に戻る（更新されたプロフィールを渡す）
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('保存に失敗しました: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('プロフィール編集'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                '保存',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // アバター画像
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blue,
                    backgroundImage: _newAvatarData != null
                        ? MemoryImage(_newAvatarData!)
                        : (_avatarUrl != null
                            ? NetworkImage(_avatarUrl!)
                            : null) as ImageProvider?,
                    child: _newAvatarData == null && _avatarUrl == null
                        ? Text(
                            widget.profile.initials,
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _pickAvatar,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ユーザー名
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ユーザー名',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'ユーザー名を入力',
                      contentPadding: EdgeInsets.zero,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'ユーザー名を入力してください';
                      }
                      if (value.trim().length < 3) {
                        return 'ユーザー名は3文字以上で入力してください';
                      }
                      if (value.trim().length > 30) {
                        return 'ユーザー名は30文字以内で入力してください';
                      }
                      // 英数字、日本語、アンダースコア、ハイフンのみ許可
                      if (!RegExp(r'^[\w\-ぁ-んァ-ヶー一-龥々]+$').hasMatch(value.trim())) {
                        return 'ユーザー名に使用できない文字が含まれています';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 自己紹介
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '自己紹介',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '自己紹介を入力（任意）',
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: 4,
                    maxLength: 200,
                    validator: (value) {
                      if (value != null && value.trim().length > 200) {
                        return '自己紹介は200文字以内で入力してください';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 注意事項
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'アバター画像は自動で圧縮されます（JPEG形式）。\n最大サイズ: 512×512px',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                        height: 1.5,
                      ),
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
}
