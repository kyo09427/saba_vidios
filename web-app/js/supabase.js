/**
 * Supabase Service - 初期化・認証・データアクセス
 *
 * NOTE: 実際の SUPABASE_URL と SUPABASE_ANON_KEY は
 * ビルド時に環境変数で差し替える or 手動で設定してください
 */

// ================================
// 設定 - ここを書き換えてください
// ================================
const SUPABASE_CONFIG = {
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
  sharedPassword: 'YOUR_SHARED_PASSWORD'
};

let supabase = null;

window.SupabaseService = {
  /**
   * Supabase初期化
   */
  init() {
    if (supabase) return;
    if (!SUPABASE_CONFIG.url || SUPABASE_CONFIG.url === 'YOUR_SUPABASE_URL') {
      console.warn('⚠️ Supabase is not configured. Please set SUPABASE_CONFIG in supabase.js');
      return;
    }
    supabase = window.supabase.createClient(SUPABASE_CONFIG.url, SUPABASE_CONFIG.anonKey);
    console.log('✅ Supabase initialized');
  },

  get client() {
    return supabase;
  },

  // ================== Auth ==================

  /**
   * 共有パスワード検証
   */
  validateSharedPassword(password) {
    return password.trim() === SUPABASE_CONFIG.sharedPassword.trim();
  },

  /**
   * 新規登録
   */
  async signUp(email, password) {
    const { data, error } = await supabase.auth.signUp({
      email: email.trim(),
      password
    });
    if (error) throw error;

    // プロフィール作成はログイン成功後に行う
    return data;
  },

  /**
   * ログイン
   */
  async signIn(email, password) {
    const { data, error } = await supabase.auth.signInWithPassword({
      email: email.trim(),
      password
    });
    if (error) throw error;

    // プロフィール存在確認
    if (data.user) {
      await this.ensureProfileExists(data.user);
    }
    return data;
  },

  /**
   * ログアウト
   */
  async signOut() {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
  },

  /**
   * 現在のユーザーを取得
   */
  async getCurrentUser() {
    const { data: { user } } = await supabase.auth.getUser();
    return user;
  },

  /**
   * セッション取得
   */
  async getSession() {
    const { data: { session } } = await supabase.auth.getSession();
    return session;
  },

  /**
   * 認証状態変更リスナー
   */
  onAuthStateChange(callback) {
    return supabase.auth.onAuthStateChange(callback);
  },

  /**
   * プロフィール確保
   */
  async ensureProfileExists(user) {
    try {
      const { data: existing } = await supabase
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

      if (existing) return;

      let username = user.email.split('@')[0];

      // 重複チェック
      const { data: dup } = await supabase
        .from('profiles')
        .select('username')
        .eq('username', username)
        .maybeSingle();

      if (dup) {
        username = `${username}_${user.id.substring(0, 8)}`;
      }

      await supabase.from('profiles').insert({
        id: user.id,
        username
      });
      console.log('✅ Profile created:', username);
    } catch (e) {
      console.warn('⚠️ Failed to ensure profile:', e);
    }
  },

  // ================== Videos ==================

  /**
   * 動画一覧取得（プロフィール含む）
   */
  async getVideos() {
    const { data: videos, error } = await supabase
      .from('videos')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;

    // プロフィール一括取得
    const userIds = [...new Set(videos.map(v => v.user_id).filter(Boolean))];
    let profilesMap = {};

    if (userIds.length > 0) {
      const { data: profiles } = await supabase
        .from('profiles')
        .select('*')
        .in('id', userIds);

      if (profiles) {
        profiles.forEach(p => { profilesMap[p.id] = p; });
      }
    }

    // タグ取得
    const videoIds = videos.map(v => v.id);
    let tagsMap = {};

    if (videoIds.length > 0) {
      const { data: tags } = await supabase
        .from('video_tags')
        .select('video_id, tags!inner(name)')
        .in('video_id', videoIds);

      if (tags) {
        tags.forEach(t => {
          if (!tagsMap[t.video_id]) tagsMap[t.video_id] = [];
          tagsMap[t.video_id].push(t.tags.name);
        });
      }
    }

    // マージ
    return videos.map(v => ({
      ...v,
      profile: profilesMap[v.user_id] || null,
      tags: tagsMap[v.id] || []
    }));
  },

  /**
   * 動画投稿
   */
  async postVideo(title, url, mainCategory) {
    const user = await this.getCurrentUser();
    if (!user) throw new Error('ログインが必要です');

    const { data, error } = await supabase
      .from('videos')
      .insert({
        title,
        url,
        user_id: user.id,
        main_category: mainCategory
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  // ================== Profiles ==================

  /**
   * プロフィール取得
   */
  async getProfile(userId) {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();

    if (error) throw error;
    return data;
  },

  /**
   * プロフィール更新
   */
  async updateProfile(userId, updates) {
    const { data, error } = await supabase
      .from('profiles')
      .update(updates)
      .eq('id', userId)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  /**
   * アバターアップロード
   */
  async uploadAvatar(userId, file) {
    const ext = file.name.split('.').pop();
    const filePath = `${userId}/avatar.${ext}`;

    const { error: uploadError } = await supabase.storage
      .from('avatars')
      .upload(filePath, file, { upsert: true });

    if (uploadError) throw uploadError;

    const { data: { publicUrl } } = supabase.storage
      .from('avatars')
      .getPublicUrl(filePath);

    // プロフィール更新
    await this.updateProfile(userId, { avatar_url: publicUrl });
    return publicUrl;
  },

  // ================== Channel / Subscriptions ==================

  /**
   * チャンネルの動画取得
   */
  async getChannelVideos(channelId) {
    const { data, error } = await supabase
      .from('videos')
      .select('*')
      .eq('user_id', channelId)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data;
  },

  /**
   * チャンネル登録
   */
  async subscribe(channelId) {
    const user = await this.getCurrentUser();
    if (!user) throw new Error('ログインが必要です');

    const { error } = await supabase
      .from('subscriptions')
      .insert({ subscriber_id: user.id, channel_id: channelId });

    if (error) throw error;
  },

  /**
   * チャンネル登録解除
   */
  async unsubscribe(channelId) {
    const user = await this.getCurrentUser();
    if (!user) throw new Error('ログインが必要です');

    const { error } = await supabase
      .from('subscriptions')
      .delete()
      .eq('subscriber_id', user.id)
      .eq('channel_id', channelId);

    if (error) throw error;
  },

  /**
   * 登録チェック
   */
  async isSubscribed(channelId) {
    const user = await this.getCurrentUser();
    if (!user) return false;

    const { data } = await supabase
      .from('subscriptions')
      .select()
      .eq('subscriber_id', user.id)
      .eq('channel_id', channelId)
      .maybeSingle();

    return !!data;
  },

  /**
   * 登録者数取得
   */
  async getSubscriberCount(channelId) {
    const { data } = await supabase
      .from('subscriptions')
      .select('id')
      .eq('channel_id', channelId);

    return data ? data.length : 0;
  },

  /**
   * 登録チャンネルIDリスト取得
   */
  async getSubscribedChannelIds() {
    const user = await this.getCurrentUser();
    if (!user) return [];

    const { data } = await supabase
      .from('subscriptions')
      .select('channel_id')
      .eq('subscriber_id', user.id);

    return data ? data.map(d => d.channel_id) : [];
  },

  /**
   * 登録チャンネルの動画取得
   */
  async getSubscriptionFeedVideos() {
    const channelIds = await this.getSubscribedChannelIds();
    if (channelIds.length === 0) return [];

    const { data: videos, error } = await supabase
      .from('videos')
      .select('*')
      .in('user_id', channelIds)
      .order('created_at', { ascending: false });

    if (error) throw error;

    // プロフィールをマージ
    const userIds = [...new Set(videos.map(v => v.user_id))];
    let profilesMap = {};
    if (userIds.length > 0) {
      const { data: profiles } = await supabase
        .from('profiles')
        .select('*')
        .in('id', userIds);
      if (profiles) profiles.forEach(p => { profilesMap[p.id] = p; });
    }

    return videos.map(v => ({
      ...v,
      profile: profilesMap[v.user_id] || null
    }));
  },

  /**
   * 動画の総件数
   */
  async getVideoCount(userId) {
    const { data } = await supabase
      .from('videos')
      .select('id')
      .eq('user_id', userId);
    return data ? data.length : 0;
  },

  // ================== Realtime ==================

  /**
   * 動画テーブルのリアルタイム購読
   */
  subscribeToVideos(callback) {
    return supabase
      .channel('videos_web_channel')
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'videos'
      }, callback)
      .subscribe();
  },

  /**
   * チャンネル購読解除
   */
  unsubscribeChannel(channel) {
    if (channel) {
      supabase.removeChannel(channel);
    }
  }
};
