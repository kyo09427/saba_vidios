-- ============================================
-- カテゴリ・タグ機能 マイグレーション
-- ============================================
-- このSQLをSupabaseダッシュボードのSQL Editorで実行してください

-- 1. videosテーブルにmain_categoryカラムを追加
ALTER TABLE videos
ADD COLUMN main_category TEXT CHECK (main_category IN ('雑談', 'ゲーム', '音楽', 'ネタ', 'その他'));

-- 既存データにデフォルト値を設定
UPDATE videos SET main_category = '雑談' WHERE main_category IS NULL;

-- NOT NULL制約を追加
ALTER TABLE videos ALTER COLUMN main_category SET NOT NULL;

-- インデックス追加（検索性能向上）
CREATE INDEX IF NOT EXISTS videos_main_category_idx ON videos(main_category);

-- 2. tagsテーブルを作成
CREATE TABLE IF NOT EXISTS tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  usage_count INTEGER DEFAULT 0  -- 使用回数（人気タグの表示用）
);

-- tagsテーブルのインデックス
CREATE INDEX IF NOT EXISTS tags_name_idx ON tags(name);
CREATE INDEX IF NOT EXISTS tags_usage_count_idx ON tags(usage_count DESC);

-- 3. video_tagsテーブルを作成（多対多リレーション）
CREATE TABLE IF NOT EXISTS video_tags (
  video_id UUID REFERENCES videos(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (video_id, tag_id)
);

-- video_tagsテーブルのインデックス
CREATE INDEX IF NOT EXISTS video_tags_video_id_idx ON video_tags(video_id);
CREATE INDEX IF NOT EXISTS video_tags_tag_id_idx ON video_tags(tag_id);

-- 4. tagsテーブルのRLSポリシー
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;

-- 認証済みユーザーは全タグを閲覧可能
DROP POLICY IF EXISTS "認証済みユーザーは全タグを閲覧可能" ON tags;
CREATE POLICY "認証済みユーザーは全タグを閲覧可能"
  ON tags FOR SELECT
  USING (auth.role() = 'authenticated');

-- 認証済みユーザーはタグを作成可能
DROP POLICY IF EXISTS "認証済みユーザーはタグを作成可能" ON tags;
CREATE POLICY "認証済みユーザーはタグを作成可能"
  ON tags FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- タグの使用回数を更新可能（誰でも）
DROP POLICY IF EXISTS "タグの使用回数を更新可能" ON tags;
CREATE POLICY "タグの使用回数を更新可能"
  ON tags FOR UPDATE
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- 5. video_tagsテーブルのRLSポリシー
ALTER TABLE video_tags ENABLE ROW LEVEL SECURITY;

-- 認証済みユーザーは全video_tagsを閲覧可能
DROP POLICY IF EXISTS "認証済みユーザーは全video_tagsを閲覧可能" ON video_tags;
CREATE POLICY "認証済みユーザーは全video_tagsを閲覧可能"
  ON video_tags FOR SELECT
  USING (auth.role() = 'authenticated');

-- 動画投稿者はvideo_tagsを作成可能
DROP POLICY IF EXISTS "動画投稿者はvideo_tagsを作成可能" ON video_tags;
CREATE POLICY "動画投稿者はvideo_tagsを作成可能"
  ON video_tags FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM videos
      WHERE videos.id = video_id AND videos.user_id = auth.uid()
    )
  );

-- 動画投稿者はvideo_tagsを削除可能
DROP POLICY IF EXISTS "動画投稿者はvideo_tagsを削除可能" ON video_tags;
CREATE POLICY "動画投稿者はvideo_tagsを削除可能"
  ON video_tags FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM videos
      WHERE videos.id = video_id AND videos.user_id = auth.uid()
    )
  );

-- 6. タグの使用回数を自動更新する関数
CREATE OR REPLACE FUNCTION increment_tag_usage_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE tags
  SET usage_count = usage_count + 1
  WHERE id = NEW.tag_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrement_tag_usage_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE tags
  SET usage_count = GREATEST(usage_count - 1, 0)
  WHERE id = OLD.tag_id;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- トリガーの作成
DROP TRIGGER IF EXISTS video_tags_increment_usage ON video_tags;
CREATE TRIGGER video_tags_increment_usage
  AFTER INSERT ON video_tags
  FOR EACH ROW
  EXECUTE FUNCTION increment_tag_usage_count();

DROP TRIGGER IF EXISTS video_tags_decrement_usage ON video_tags;
CREATE TRIGGER video_tags_decrement_usage
  AFTER DELETE ON video_tags
  FOR EACH ROW
  EXECUTE FUNCTION decrement_tag_usage_count();
