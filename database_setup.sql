-- サバの動画アプリ用データベース設定
-- SupabaseダッシュボードのSQL Editorで実行してください

-- videosテーブルの作成
CREATE TABLE videos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  title TEXT NOT NULL,
  url TEXT NOT NULL,
  user_id UUID REFERENCES auth.users(id) NOT NULL
);

-- RLSの有効化
ALTER TABLE videos ENABLE ROW LEVEL SECURITY;

-- 認証済みユーザーは全ての動画を閲覧可能
CREATE POLICY "認証済みユーザーは全動画を閲覧可能"
  ON videos FOR SELECT
  USING (auth.role() = 'authenticated');

-- 認証済みユーザーは動画を投稿可能
CREATE POLICY "認証済みユーザーは動画を投稿可能"
  ON videos FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 投稿者本人のみ削除可能（将来的な拡張用）
CREATE POLICY "投稿者のみ削除可能"
  ON videos FOR DELETE
  USING (auth.uid() = user_id);

-- インデックスの作成（パフォーマンス向上）
CREATE INDEX videos_created_at_idx ON videos(created_at DESC);
CREATE INDEX videos_user_id_idx ON videos(user_id);

-- ============================================
-- プロフィール機能追加（v1.2.0）
-- ============================================

-- profilesテーブルの作成
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  bio TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- profilesテーブルのRLS有効化
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 全ユーザーが全プロフィールを閲覧可能
CREATE POLICY "全ユーザーが全プロフィールを閲覧可能"
  ON profiles FOR SELECT
  USING (true);  -- 認証不要で閲覧可能（動画カードでの表示用）

-- 本人のみ自分のプロフィールを更新可能
CREATE POLICY "本人のみプロフィールを更新可能"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- 認証済みユーザーが自分のプロフィールを作成可能
CREATE POLICY "認証済みユーザーが自分のプロフィールを作成可能"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- インデックスの作成
CREATE INDEX profiles_username_idx ON profiles(username);

-- updated_atを自動更新する関数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- updated_at自動更新トリガー
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 注意: auth.usersへのトリガーについて
-- ============================================
-- Supabaseのauth.usersテーブルは保護されたスキーマにあり、
-- 直接トリガーを設定するとユーザー登録時にエラーが発生します。
-- 
-- 代わりに、アプリケーション側（lib/services/supabase_service.dart）で
-- ユーザー登録成功後に自動的にprofilesレコードを作成しています。
--
-- 以下のトリガーは使用しないでください：
-- CREATE TRIGGER on_auth_user_created
--   AFTER INSERT ON auth.users
--   FOR EACH ROW
--   EXECUTE FUNCTION create_profile_for_new_user();

-- ============================================
-- Supabase Storage設定
-- ============================================
-- 以下はSupabaseダッシュボードのStorage > Create a new bucketから手動で作成してください
-- または、Supabase CLIを使用して作成できます
--
-- バケット名: avatars
-- Public bucket: はい（チェックを入れる）
-- File size limit: 5MB
-- Allowed MIME types: image/webp, image/jpeg, image/png
--
-- RLS Policy (avatars bucket):
-- - Policy name: "Anyone can view avatars"
--   Operation: SELECT
--   Policy definition: true
--
-- - Policy name: "Users can upload their own avatar"
--   Operation: INSERT
--   Policy definition: bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text
--
-- - Policy name: "Users can update their own avatar"
--   Operation: UPDATE
--   Policy definition: bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text
--
-- - Policy name: "Users can delete their own avatar"
--   Operation: DELETE
--   Policy definition: bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text
