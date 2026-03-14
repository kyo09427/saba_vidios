/**
 * Navigation Bar Component (Header)
 */
const NavBar = {
  render(activePage = 'home') {
    return `
      <header class="app-header">
        <div class="header-left">
          <div class="header-logo-icon">
            <svg viewBox="0 0 24 24"><use href="#icon-play"></use></svg>
          </div>
          <span class="header-logo-text">サバの動画</span>
          <nav class="desktop-nav">
            <a href="#/" class="${activePage === 'home' ? 'active' : ''}">ホーム</a>
            <a href="#/timeline" class="${activePage === 'timeline' ? 'active' : ''}">タイムライン</a>
            <a href="#/subscriptions" class="${activePage === 'subscriptions' ? 'active' : ''}">登録チャンネル</a>
            <a href="#/profile" class="${activePage === 'profile' ? 'active' : ''}">マイページ</a>
          </nav>
        </div>
        <div class="header-right">
          <div class="header-search">
            <svg class="search-icon"><use href="#icon-search"></use></svg>
            <input type="text" placeholder="動画を検索..." id="header-search-input">
          </div>
          <button class="btn-icon" title="通知" style="position:relative">
            <svg width="22" height="22" fill="currentColor"><use href="#icon-notifications"></use></svg>
          </button>
          <div class="header-avatar" id="header-avatar" onclick="Router.navigate('/profile')" title="マイページ"></div>
        </div>
      </header>
    `;
  },

  /**
   * ヘッダーアバターを更新
   */
  async updateAvatar() {
    const el = document.getElementById('header-avatar');
    if (!el) return;

    try {
      const user = await SupabaseService.getCurrentUser();
      if (!user) return;

      const profile = await SupabaseService.getProfile(user.id);
      if (profile?.avatar_url) {
        el.innerHTML = `<img src="${profile.avatar_url}" alt="${profile.username}">`;
      } else {
        const initials = VideoCard.getInitials(profile?.username);
        el.style.backgroundColor = VideoCard.getAvatarColor(user.id);
        el.style.display = 'flex';
        el.style.alignItems = 'center';
        el.style.justifyContent = 'center';
        el.style.fontSize = '12px';
        el.style.fontWeight = '600';
        el.innerHTML = initials;
      }
    } catch (e) {
      // ignore
    }
  }
};
