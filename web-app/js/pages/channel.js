/**
 * Channel Page - チャンネル表示
 */
const ChannelPage = {
  async render(params = {}) {
    const app = document.getElementById('app');
    const channelId = params.id;

    if (!channelId) {
      Router.navigate('/');
      return;
    }

    // ローディング表示
    app.innerHTML = `
      ${NavBar.render('')}
      <main class="main-content">
        <div class="loading-view">
          <div class="spinner"></div>
          <span class="loading-text">チャンネルを読み込み中...</span>
        </div>
      </main>
      ${BottomNav.render(-1)}
    `;

    try {
      const [profile, videos, subscriberCount, currentUser] = await Promise.all([
        SupabaseService.getProfile(channelId),
        SupabaseService.getChannelVideos(channelId),
        SupabaseService.getSubscriberCount(channelId),
        SupabaseService.getCurrentUser()
      ]);

      const isOwnChannel = currentUser?.id === channelId;
      let isSubscribed = false;
      if (!isOwnChannel && currentUser) {
        isSubscribed = await SupabaseService.isSubscribed(channelId);
      }

      const avatarHtml = profile?.avatar_url
        ? `<img src="${profile.avatar_url}" alt="${profile.username}">`
        : VideoCard.getInitials(profile?.username);

      app.innerHTML = `
        ${NavBar.render('')}
        <main class="main-content">
          <div class="channel-header">
            <div class="avatar avatar-xl" style="background:${VideoCard.getAvatarColor(channelId)}">
              ${avatarHtml}
            </div>
            <div class="channel-info">
              <h1 class="channel-name">${VideoCard.escapeHtml(profile?.username || '不明')}</h1>
              <div class="channel-stats">
                <span>登録者 ${subscriberCount}人</span>
                <span>•</span>
                <span>動画 ${videos.length}本</span>
              </div>
              ${profile?.bio ? `<div class="channel-bio">${VideoCard.escapeHtml(profile.bio)}</div>` : ''}
            </div>
          </div>
          ${!isOwnChannel ? `
            <div class="channel-actions">
              <button class="btn ${isSubscribed ? 'btn-subscribe subscribed' : 'btn-subscribe'}" id="subscribe-btn" style="width:100%">
                ${isSubscribed ? '登録済み' : '登録'}
              </button>
            </div>
          ` : ''}
          <div class="channel-tabs">
            <div class="channel-tab active">動画</div>
          </div>
          <div id="channel-videos">
            ${videos.length === 0 ? `
              <div class="empty-state">
                <div class="empty-state-icon">📹</div>
                <div class="empty-state-title">まだ動画がありません</div>
              </div>
            ` : `
              <div class="channel-video-list">
                ${videos.map(v => VideoCard.render({ ...v, profile }, { layout: 'list' })).join('')}
              </div>
            `}
          </div>
        </main>
        ${BottomNav.render(-1)}
      `;

      // 登録ボタン
      const subBtn = document.getElementById('subscribe-btn');
      if (subBtn) {
        subBtn.addEventListener('click', async () => {
          subBtn.disabled = true;
          try {
            if (isSubscribed) {
              await SupabaseService.unsubscribe(channelId);
              isSubscribed = false;
              subBtn.textContent = '登録';
              subBtn.classList.remove('subscribed');
            } else {
              await SupabaseService.subscribe(channelId);
              isSubscribed = true;
              subBtn.textContent = '登録済み';
              subBtn.classList.add('subscribed');
            }
          } catch (err) {
            App.showToast('操作に失敗しました', 'error');
          } finally {
            subBtn.disabled = false;
          }
        });
      }

      NavBar.updateAvatar();
    } catch (e) {
      console.error('Channel load error:', e);
      app.innerHTML = `
        ${NavBar.render('')}
        <main class="main-content">
          <div class="empty-state">
            <div class="empty-state-icon">⚠️</div>
            <div class="empty-state-title">チャンネルの読み込みに失敗しました</div>
            <button class="btn btn-primary" onclick="Router.navigate('/')">ホームに戻る</button>
          </div>
        </main>
        ${BottomNav.render(-1)}
      `;
    }
  }
};
