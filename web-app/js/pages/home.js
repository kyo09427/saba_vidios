/**
 * Home Page - 動画一覧
 */
const HomePage = {
  videos: [],
  filteredVideos: [],
  selectedFilter: 'すべて',
  realtimeChannel: null,

  async render() {
    const app = document.getElementById('app');

    app.innerHTML = `
      ${NavBar.render('home')}
      ${CategoryPills.renderHTML(this.selectedFilter)}
      <main class="main-content">
        <div class="video-grid" id="video-grid">
          ${Array(6).fill(VideoCard.renderSkeleton()).join('')}
        </div>
      </main>
      ${BottomNav.render(0)}
    `;

    // カテゴリフィルターのイベントリスナー
    document.getElementById('category-filter')?.addEventListener('click', (e) => {
      const pill = e.target.closest('.category-pill');
      if (!pill) return;
      const category = pill.dataset.category;
      this.selectedFilter = category;
      // アクティブ状態更新
      document.querySelectorAll('.category-pill').forEach(p => p.classList.remove('active'));
      pill.classList.add('active');
      this.applyFilter();
      this.renderVideos();
    });

    // アバター更新
    NavBar.updateAvatar();

    // データ取得
    await this.loadVideos();

    // リアルタイム購読
    this.realtimeChannel = SupabaseService.subscribeToVideos(() => {
      this.loadVideos();
    });

    // クリーンアップ関数を返す
    return () => {
      SupabaseService.unsubscribeChannel(this.realtimeChannel);
      this.realtimeChannel = null;
    };
  },

  async loadVideos() {
    try {
      this.videos = await SupabaseService.getVideos();
      this.applyFilter();
      this.renderVideos();
    } catch (e) {
      console.error('Failed to load videos:', e);
      const grid = document.getElementById('video-grid');
      if (grid) {
        grid.innerHTML = `
          <div class="empty-state" style="grid-column: 1/-1">
            <div class="empty-state-icon">⚠️</div>
            <div class="empty-state-title">動画の読み込みに失敗しました</div>
            <button class="btn btn-primary" onclick="HomePage.loadVideos()">再読み込み</button>
          </div>
        `;
      }
    }
  },

  applyFilter() {
    if (this.selectedFilter === 'すべて') {
      this.filteredVideos = this.videos;
    } else if (this.selectedFilter === '新しい動画') {
      const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
      this.filteredVideos = this.videos.filter(v => new Date(v.created_at) > yesterday);
    } else {
      this.filteredVideos = this.videos.filter(v => v.main_category === this.selectedFilter);
    }
  },

  renderVideos() {
    const grid = document.getElementById('video-grid');
    if (!grid) return;

    if (this.filteredVideos.length === 0) {
      grid.innerHTML = `
        <div class="empty-state" style="grid-column: 1/-1">
          <div class="empty-state-icon">📹</div>
          <div class="empty-state-title">動画がありません</div>
          <div class="empty-state-desc">最初の動画を投稿してみましょう</div>
          <button class="btn btn-primary" onclick="Router.navigate('/post')">
            <svg width="18" height="18" fill="currentColor"><use href="#icon-add"></use></svg>
            動画を投稿
          </button>
        </div>
      `;
      return;
    }

    grid.innerHTML = this.filteredVideos.map(v => VideoCard.render(v)).join('');
  }
};
