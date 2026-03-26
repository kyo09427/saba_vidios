-- ============================================
-- Discord ギルド検証フラグ追加マイグレーション
-- ============================================
-- SupabaseダッシュボードのSQL Editorで実行してください
--
-- 目的:
-- Discord OAuthログイン時のギルドメンバーシップ検証結果をDBに保存し、
-- セッション復帰時にproviderTokenなしでも検証状態を確認可能にする

-- profilesテーブルにギルド検証カラムを追加
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS discord_guild_verified BOOLEAN DEFAULT FALSE;

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS discord_guild_verified_at TIMESTAMPTZ;

-- コメント追加
COMMENT ON COLUMN profiles.discord_guild_verified IS 'Discord OAuth: 指定ギルドのメンバーシップが検証済みかどうか';
COMMENT ON COLUMN profiles.discord_guild_verified_at IS 'Discord OAuth: ギルドメンバーシップが最後に検証された日時';
