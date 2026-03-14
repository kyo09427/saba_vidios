/**
 * Timeline Page - 年月別アーカイブ
 */
const TimelinePage = {
  async render() {
    const app = document.getElementById('app');

    app.innerHTML = `
      ${NavBar.render('timeline')}
      <main class="main-content">
        <div class="loading-view">
          <div class="spinner"></div>
          <span class="loading-text">タイムラインを読み込み中...</span>
        </div>
      </main>
      ${BottomNav.render(1)}
    `;

    try {
      const videos = await SupabaseService.getVideos();
      const groups = DateUtils.groupByYearMonth(videos);
      const main = app.querySelector('main');

      if (groups.length === 0) {
        main.innerHTML = `
          <div class="empty-state">
            <div class="empty-state-icon">📅</div>
            <div class="empty-state-title">まだ動画がありません</div>
            <button class="btn btn-primary" onclick="Router.navigate('/post')">最初の動画を投稿</button>
          </div>
        `;
        return;
      }

      // 年でグループ化（サイドバー用）
      const years = {};
      groups.forEach(g => {
        if (!years[g.year]) years[g.year] = [];
        years[g.year].push(g);
      });

      main.innerHTML = `
        <div class="timeline-chips" id="timeline-chips">
          ${groups.map((g, i) => `
            <button class="timeline-chip ${i === 0 ? 'active' : ''}" data-key="${g.year}-${g.month}">
              ${g.year}年${g.month}月 (${g.videos.length})
            </button>
          `).join('')}
        </div>
        <div class="timeline-layout">
          <aside class="timeline-sidebar">
            <div class="timeline-sidebar-title">タイムライン</div>
            <div class="timeline-sidebar-sub">投稿アーカイブ</div>
            <div class="timeline-nav">
              ${Object.entries(years).sort((a, b) => b[0] - a[0]).map(([year, months], yi) => `
                <div class="timeline-nav-year ${yi === 0 ? '' : 'inactive'}">
                  <div class="timeline-nav-year-label">${year}</div>
                  ${months.map((m, mi) => `
                    <div class="timeline-nav-month ${yi === 0 && mi === 0 ? 'active' : ''}" data-key="${m.year}-${m.month}">
                      ${m.month}月 <span style="color:var(--text-tertiary);font-size:var(--text-xs)">(${m.videos.length})</span>
                    </div>
                  `).join('')}
                </div>
              `).join('')}
            </div>
          </aside>
          <div class="timeline-content" id="timeline-content">
            ${groups.map(g => `
              <section class="timeline-month-section" id="section-${g.year}-${g.month}">
                <div class="timeline-month-header">
                  <h2 class="timeline-month-name">${g.month}月</h2>
                  <span class="timeline-month-year">${g.year}</span>
                  <span class="timeline-month-count">${g.videos.length}本</span>
                </div>
                <div class="video-grid">
                  ${g.videos.map(v => VideoCard.render(v)).join('')}
                </div>
              </section>
            `).join('')}
          </div>
        </div>
      `;

      // サイドバーナビゲーション
      document.querySelectorAll('.timeline-nav-month').forEach(el => {
        el.addEventListener('click', () => {
          const key = el.dataset.key;
          const [year, month] = key.split('-');
          const section = document.getElementById(`section-${year}-${month}`);
          if (section) {
            section.scrollIntoView({ behavior: 'smooth', block: 'start' });
            document.querySelectorAll('.timeline-nav-month').forEach(m => m.classList.remove('active'));
            el.classList.add('active');
          }
        });
      });

      // モバイル月チップ
      document.getElementById('timeline-chips')?.addEventListener('click', (e) => {
        const chip = e.target.closest('.timeline-chip');
        if (!chip) return;
        const key = chip.dataset.key;
        const [year, month] = key.split('-');
        const section = document.getElementById(`section-${year}-${month}`);
        if (section) {
          section.scrollIntoView({ behavior: 'smooth', block: 'start' });
          document.querySelectorAll('.timeline-chip').forEach(c => c.classList.remove('active'));
          chip.classList.add('active');
        }
      });

      NavBar.updateAvatar();
    } catch (e) {
      console.error('Timeline load error:', e);
      const main = app.querySelector('main');
      main.innerHTML = `
        <div class="empty-state">
          <div class="empty-state-icon">⚠️</div>
          <div class="empty-state-title">タイムラインの読み込みに失敗しました</div>
          <button class="btn btn-primary" onclick="TimelinePage.render()">再読み込み</button>
        </div>
      `;
    }
  }
};
