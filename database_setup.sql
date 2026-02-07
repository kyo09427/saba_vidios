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
