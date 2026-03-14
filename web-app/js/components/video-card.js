/**
 * Video Card Component
 */
const VideoCard = {
  /**
   * 動画カードHTMLを生成
   * @param {Object} video - 動画データ
   * @param {Object} options - オプション { layout: 'grid' | 'list' }
   */
  render(video, options = {}) {
    const layout = options.layout || 'grid';
    const thumb = YouTubeUtils.getThumbnailUrl(video.url);
    const profile = video.profile;
    const initials = profile ? this.getInitials(profile.username) : '?';
    const avatarHtml = profile?.avatar_url
      ? `<img src="${profile.avatar_url}" alt="${profile.username}">`
      : initials;

    if (layout === 'list') {
      return this.renderListItem(video, thumb, profile, avatarHtml);
    }

    return `
      <article class="video-card" data-video-id="${video.id}" data-url="${video.url}" onclick="window.open('${YouTubeUtils.getWatchUrl(video.url)}', '_blank')">
        <div class="video-thumb-wrapper">
          ${thumb
            ? `<img src="${thumb}" alt="${this.escapeHtml(video.title)}" loading="lazy">`
            : `<div style="width:100%;height:100%;display:flex;align-items:center;justify-content:center;"><svg width="48" height="48" style="opacity:0.3;fill:var(--text-tertiary)"><use href="#icon-video"></use></svg></div>`
          }
          <div class="video-thumb-overlay">
            <div class="play-btn-overlay">
              <svg><use href="#icon-play"></use></svg>
            </div>
          </div>
        </div>
        <div class="video-info">
          <div class="avatar" onclick="event.stopPropagation(); Router.navigate('/channel/${video.user_id}')" style="cursor:pointer; background: ${this.getAvatarColor(video.user_id)}">
            ${avatarHtml}
          </div>
          <div class="video-info-text">
            <div class="video-title">${this.escapeHtml(video.title)}</div>
            <div class="video-meta">
              <span>${profile?.username || '不明'}</span>
              <span class="dot"></span>
              <span>${DateUtils.relativeTime(video.created_at)}</span>
            </div>
            <div class="video-category">
              <span class="category-badge" data-cat="${video.main_category || '雑談'}">${video.main_category || '雑談'}</span>
            </div>
          </div>
        </div>
      </article>
    `;
  },

  /**
   * リスト表示アイテム
   */
  renderListItem(video, thumb, profile, avatarHtml) {
    return `
      <div class="channel-video-item" onclick="window.open('${YouTubeUtils.getWatchUrl(video.url)}', '_blank')">
        <div class="channel-video-thumb">
          ${thumb
            ? `<img src="${thumb}" alt="${this.escapeHtml(video.title)}" loading="lazy">`
            : `<div style="width:100%;height:100%;background:var(--bg-elevated);display:flex;align-items:center;justify-content:center;"><svg width="32" height="32" style="opacity:0.3;fill:var(--text-tertiary)"><use href="#icon-video"></use></svg></div>`
          }
        </div>
        <div class="channel-video-info">
          <div class="channel-video-title">${this.escapeHtml(video.title)}</div>
          <div class="channel-video-meta">
            ${profile?.username || '不明'} • ${DateUtils.relativeTime(video.created_at)}
          </div>
          <div style="margin-top:4px;">
            <span class="category-badge" data-cat="${video.main_category || '雑談'}">${video.main_category || '雑談'}</span>
          </div>
        </div>
      </div>
    `;
  },

  /**
   * スケルトンカード
   */
  renderSkeleton() {
    return `
      <div class="video-card">
        <div class="video-thumb-wrapper skeleton" style="aspect-ratio:16/9"></div>
        <div class="video-info" style="gap:var(--space-3)">
          <div class="skeleton" style="width:36px;height:36px;border-radius:var(--radius-full);flex-shrink:0"></div>
          <div style="flex:1;display:flex;flex-direction:column;gap:8px">
            <div class="skeleton" style="height:14px;width:90%"></div>
            <div class="skeleton" style="height:12px;width:60%"></div>
          </div>
        </div>
      </div>
    `;
  },

  /**
   * HTMLエスケープ
   */
  escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text || '';
    return div.innerHTML;
  },

  /**
   * イニシャル取得
   */
  getInitials(username) {
    if (!username) return '?';
    if (/[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]/.test(username)) {
      return username[0];
    }
    const parts = username.split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return username.substring(0, 2).toUpperCase();
  },

  /**
   * ユーザーIDからアバターの背景色を生成
   */
  getAvatarColor(userId) {
    if (!userId) return '#9C27B0';
    const colors = ['#9C27B0', '#2196F3', '#E91E63', '#FF9800', '#4CAF50', '#00BCD4', '#3F51B5', '#F44336'];
    let hash = 0;
    for (let i = 0; i < userId.length; i++) {
      hash = userId.charCodeAt(i) + ((hash << 5) - hash);
    }
    return colors[Math.abs(hash) % colors.length];
  }
};
