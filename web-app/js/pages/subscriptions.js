/**
 * Subscriptions Page - 登録チャンネル
 */
const SubscriptionsPage = {
  async render() {
    const app = document.getElementById('app');

    app.innerHTML = `
      ${NavBar.render('subscriptions')}
      <main class="main-content subs-screen">
        <div class="loading-view">
          <div class="spinner"></div>
          <span class="loading-text">読み込み中...</span>
        </div>
      </main>
      ${BottomNav.render(3)}
    `;

    try {
      const videos = await SupabaseService.getSubscriptionFeedVideos();
      const main = app.querySelector('main');

      if (videos.length === 0) {
        main.innerHTML = `
          <div class="empty-state">
            <div class="empty-state-icon">📡</div>
            <div class="empty-state-title">登録チャンネルがありません</div>
            <div class="empty-state-desc">動画カードのアバターをタップして、チャンネルを登録してみましょう</div>
            <button class="btn btn-primary" onclick="Router.navigate('/')">ホームで探す</button>
          </div>
        `;
      } else {
        // チャンネルでグループ化
        const channels = {};
        videos.forEach(v => {
          if (!channels[v.user_id]) {
            channels[v.user_id] = {
              profile: v.profile,
              count: 0
            };
          }
          channels[v.user_id].count++;
        });

        main.innerHTML = `
          <div class="subs-channel-filter" id="subs-filter">
            <button class="subs-channel-chip active" data-channel="all">
              すべて
            </button>
            ${Object.entries(channels).map(([id, ch]) => `
              <button class="subs-channel-chip" data-channel="${id}">
                <div class="avatar" style="background:${VideoCard.getAvatarColor(id)}">
                  ${ch.profile?.avatar_url
                    ? `<img src="${ch.profile.avatar_url}" alt="">`
                    : VideoCard.getInitials(ch.profile?.username)
                  }
                </div>
                ${ch.profile?.username || '不明'}
              </button>
            `).join('')}
          </div>
          ${CategoryPills.renderHTML('すべて')}
          <div class="video-grid" id="subs-video-grid">
            ${videos.map(v => VideoCard.render(v)).join('')}
          </div>
        `;

        let selectedChannel = 'all';
        let selectedCategory = 'すべて';

        const renderFiltered = () => {
          let filtered = videos;
          if (selectedChannel !== 'all') {
            filtered = filtered.filter(v => v.user_id === selectedChannel);
          }
          if (selectedCategory !== 'すべて' && selectedCategory !== '新しい動画') {
            filtered = filtered.filter(v => v.main_category === selectedCategory);
          } else if (selectedCategory === '新しい動画') {
            const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
            filtered = filtered.filter(v => new Date(v.created_at) > yesterday);
          }

          const grid = document.getElementById('subs-video-grid');
          if (grid) {
            grid.innerHTML = filtered.length > 0
              ? filtered.map(v => VideoCard.render(v)).join('')
              : `<div class="empty-state" style="grid-column:1/-1"><div class="empty-state-title">動画がありません</div></div>`;
          }
        };

        // チャンネルフィルター
        document.getElementById('subs-filter')?.addEventListener('click', (e) => {
          const chip = e.target.closest('.subs-channel-chip');
          if (!chip) return;
          document.querySelectorAll('.subs-channel-chip').forEach(c => c.classList.remove('active'));
          chip.classList.add('active');
          selectedChannel = chip.dataset.channel;
          renderFiltered();
        });

        // カテゴリフィルター
        document.getElementById('category-filter')?.addEventListener('click', (e) => {
          const pill = e.target.closest('.category-pill');
          if (!pill) return;
          document.querySelectorAll('.category-pill').forEach(p => p.classList.remove('active'));
          pill.classList.add('active');
          selectedCategory = pill.dataset.category;
          renderFiltered();
        });
      }

      NavBar.updateAvatar();
    } catch (e) {
      console.error('Subscriptions load error:', e);
      const main = app.querySelector('main');
      main.innerHTML = `
        <div class="empty-state">
          <div class="empty-state-icon">⚠️</div>
          <div class="empty-state-title">読み込みに失敗しました</div>
          <button class="btn btn-primary" onclick="SubscriptionsPage.render()">再読み込み</button>
        </div>
      `;
    }
  }
};
