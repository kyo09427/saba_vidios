-- ============================================
-- チャンネル登録機能 マイグレーション
-- ============================================
-- このSQLをSupabaseダッシュボードのSQL Editorで実行してください

-- 1. subscriptionsテーブルを作成
CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscriber_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  channel_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(subscriber_id, channel_id), -- 同じチャンネルを重複登録できないようにする
  CHECK (subscriber_id != channel_id) -- 自分自身を登録できないようにする
);

-- 2. インデックスを作成（パフォーマンス向上）
CREATE INDEX IF NOT EXISTS subscriptions_subscriber_id_idx ON subscriptions(subscriber_id);
CREATE INDEX IF NOT EXISTS subscriptions_channel_id_idx ON subscriptions(channel_id);

-- 3. subscriptionsテーブルのRLSポリシー
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- 認証済みユーザーは全登録を閲覧可能
DROP POLICY IF EXISTS "認証済みユーザーは全登録を閲覧可能" ON subscriptions;
CREATE POLICY "認証済みユーザーは全登録を閲覧可能"
  ON subscriptions FOR SELECT
  USING (auth.role() = 'authenticated');

-- 本人のみ登録可能
DROP POLICY IF EXISTS "本人のみ登録可能" ON subscriptions;
CREATE POLICY "本人のみ登録可能"
  ON subscriptions FOR INSERT
  WITH CHECK (auth.uid() = subscriber_id);

-- 本人のみ登録解除可能
DROP POLICY IF EXISTS "本人のみ登録解除可能" ON subscriptions;
CREATE POLICY "本人のみ登録解除可能"
  ON subscriptions FOR DELETE
  USING (auth.uid() = subscriber_id);
