# データベースセットアップ手順

## 重要: トリガーとRLSポリシーに関する問題

新規ユーザー登録時に「Database error saving new user」や「row-level security policy」エラーが発生する場合、以下の手順を実行してください。

## 手順

### 1. 既存のトリガーとRLSポリシーを削除

Supabase ダッシュボード > SQL Editor で以下を実行:

```sql
-- 既存のトリガーとトリガー関数を削除
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS create_profile_for_new_user();

-- 既存のRLSポリシーを削除
DROP POLICY IF EXISTS "全ユーザーが全プロフィールを閲覧可能" ON profiles;
DROP POLICY IF EXISTS "本人のみプロフィールを更新可能" ON profiles;
DROP POLICY IF EXISTS "本人のみプロフィールを挿入可能" ON profiles;
DROP POLICY IF EXISTS "認証済みユーザーが自分のプロフィールを作成可能" ON profiles;
```

### 2. データベースセットアップSQLを実行

Supabase ダッシュボード > SQL Editor で `database_setup.sql` の内容を実行してください。

**注意**: 
- `auth.users`へのトリガーは含まれていません
- プロフィール作成はアプリケーション側で自動的に行われます

### 3. Storageバケットの作成

1. Supabaseダッシュボード > Storage > Create a new bucket
2. バケット名: `avatars`
3. Public bucket: ✅ はい
4. File size limit: 5MB
5. Create bucket をクリック

### 4. Storageポリシーの設定

`avatars` バケットの Policies タブで以下を追加:

```sql
-- Anyone can view avatars
CREATE POLICY "Anyone can view avatars"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'avatars');

-- Users can upload their own avatar
CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars' AND 
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can update their own avatar  
CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars' AND 
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can delete their own avatar
CREATE POLICY "Users can delete their own avatar"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars' AND 
  (storage.foldername(name))[1] = auth.uid()::text
);
```

### 5. 新規登録をテスト

これで新規ユーザー登録が正常に動作するはずです。

## トラブルシューティング

### それでもエラーが出る場合

ブラウザのコンソール（F12 > Console）で詳細なエラーメッセージを確認してください。
