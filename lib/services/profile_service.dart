import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';

/// プロフィール管理サービス
/// 
/// ユーザープロフィールの取得、更新、アバター画像のアップロードを担当します。
class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  final _supabase = SupabaseService.instance.client;

  /// 指定されたユーザーIDのプロフィールを取得
  /// 
  /// [userId] ユーザーID
  /// 
  /// Returns: プロフィール情報、存在しない場合null
  Future<UserProfile?> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return UserProfile.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching profile: $e');
      }
      return null;
    }
  }

  /// プロフィール情報を更新
  /// 
  /// [profile] 更新するプロフィール情報
  /// 
  /// Throws: データベース更新エラー、権限エラーなど
  Future<void> updateProfile(UserProfile profile) async {
    try {
      await _supabase
          .from('profiles')
          .update(profile.toJson())
          .eq('id', profile.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating profile: $e');
      }
      rethrow;
    }
  }

  /// アバター画像をアップロード
  /// 
  /// 画像を圧縮し、Supabase Storageにアップロードします。
  /// - 最大サイズ: 512x512px（アスペクト比維持）
  /// - JPEG品質: 85%
  /// - ファイル名: {userId}_{timestamp}.jpg
  /// 
  /// [userId] ユーザーID
  /// [imageData] 元の画像データ
  /// 
  /// Returns: アップロードされた画像の公開URL
  /// 
  /// Throws: 画像処理エラー、アップロードエラーなど
  Future<String> uploadAvatar(String userId, Uint8List imageData) async {
    try {
      // 1. 画像をデコード
      img.Image? image = img.decodeImage(imageData);
      if (image == null) {
        throw Exception('画像のデコードに失敗しました');
      }

      // 2. アスペクト比を維持しながら最大512x512pxにリサイズ
      const maxSize = 512;
      if (image.width > maxSize || image.height > maxSize) {
        // リサイズ後のサイズを計算
        int targetWidth;
        int targetHeight;
        
        if (image.width > image.height) {
          targetWidth = maxSize;
          targetHeight = (maxSize * image.height / image.width).round();
        } else {
          targetHeight = maxSize;
          targetWidth = (maxSize * image.width / image.height).round();
        }
        
        // サイズが1以上であることを保証
        targetWidth = targetWidth > 0 ? targetWidth : 1;
        targetHeight = targetHeight > 0 ? targetHeight : 1;
        
        image = img.copyResize(
          image,
          width: targetWidth,
          height: targetHeight,
          interpolation: img.Interpolation.average,
        );
      }

      // 3. JPEG形式に変換（品質85%）
      //    注: imageパッケージのWebPエンコーディングがバージョンによって利用できない場合があるため、
      //    JPEGを使用します。JPEGも十分に圧縮効率が高く、実用的です。
      final compressedData = Uint8List.fromList(img.encodeJpg(image, quality: 85));

      // 4. ファイル名を生成（既存のファイルを上書き）
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$userId/${userId}_$timestamp.jpg';

      // 5. Supabase Storageにアップロード
      try {
        await _supabase.storage.from('avatars').uploadBinary(
              fileName,
              compressedData,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true, // 同名ファイルがあれば上書き
              ),
            );
      } on StorageException catch (e) {
        if (e.statusCode == '404') {
          throw Exception(
            'Supabaseの「avatars」バケットが存在しません。\n'
            'Supabaseダッシュボードで以下の手順を実行してください：\n'
            '1. Storage > Create a new bucketをクリック\n'
            '2. バケット名: avatars\n'
            '3. Public bucket: はい（チェックを入れる）'
          );
        }
        rethrow;
      }

      // 6. 公開URLを取得
      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

      if (kDebugMode) {
        debugPrint('✅ Avatar uploaded successfully: $publicUrl');
        debugPrint('   Original size: ${imageData.length} bytes');
        debugPrint('   Compressed size: ${compressedData.length} bytes');
        debugPrint('   Compression: ${((1 - compressedData.length / imageData.length) * 100).toStringAsFixed(1)}%');
      }

      return publicUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error uploading avatar: $e');
      }
      rethrow;
    }
  }

  /// ユーザー名の重複チェック
  /// 
  /// [username] チェックするユーザー名
  /// [excludeUserId] 除外するユーザーID（自分自身のIDを指定）
  /// 
  /// Returns: 重複している場合true
  Future<bool> isUsernameTaken(String username, {String? excludeUserId}) async {
    try {
      var query = _supabase.from('profiles').select('id').eq('username', username);

      if (excludeUserId != null) {
        query = query.neq('id', excludeUserId);
      }

      final response = await query.maybeSingle();
      return response != null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking username: $e');
      }
      return false;
    }
  }

  /// 古いアバター画像を削除
  /// 
  /// [userId] ユーザーID
  /// [currentAvatarUrl] 現在のアバターURL（削除しない）
  Future<void> deleteOldAvatars(String userId, String? currentAvatarUrl) async {
    try {
      // ユーザーフォルダ内のすべてのファイルを取得
      final files = await _supabase.storage.from('avatars').list(path: userId);

      // 現在のアバター以外を削除
      for (final file in files) {
        final fullPath = '$userId/${file.name}';
        final fileUrl = _supabase.storage.from('avatars').getPublicUrl(fullPath);

        if (currentAvatarUrl == null || fileUrl != currentAvatarUrl) {
          await _supabase.storage.from('avatars').remove([fullPath]);
          if (kDebugMode) {
            debugPrint('🗑️ Deleted old avatar: $fullPath');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error deleting old avatars: $e');
      }
      // 古いファイルの削除エラーは無視（重要ではない）
    }
  }
}
