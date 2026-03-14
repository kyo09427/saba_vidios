/**
 * Post Page - 動画投稿
 */
const PostPage = {
  async render() {
    const app = document.getElementById('app');

    app.innerHTML = `
      ${NavBar.render('')}
      <div class="post-screen main-content">
        <div class="post-header">
          <button class="btn-icon" onclick="history.back()" title="戻る">
            <svg width="22" height="22" fill="currentColor"><use href="#icon-back"></use></svg>
          </button>
          <h2>動画を投稿</h2>
        </div>
        <form class="post-form" id="post-form">
          <div class="input-group">
            <label for="post-url">YouTube URL</label>
            <input type="url" id="post-url" class="input-field" placeholder="https://www.youtube.com/watch?v=..." required>
          </div>

          <div class="post-preview" id="post-preview">
            <div class="post-preview-placeholder">
              <svg fill="currentColor"><use href="#icon-video"></use></svg>
              <span style="font-size:var(--text-sm)">URLを入力するとプレビューが表示されます</span>
            </div>
          </div>

          <div class="input-group">
            <label for="post-title">動画タイトル</label>
            <input type="text" id="post-title" class="input-field" placeholder="動画のタイトルを入力" required>
          </div>

          <div class="input-group">
            <label>カテゴリ</label>
            <div class="post-category-select" id="post-category-select">
              ${['雑談', 'ゲーム', '音楽', 'ネタ', 'その他'].map(cat => `
                <button type="button" class="post-category-option ${cat === '雑談' ? 'selected' : ''}" data-cat="${cat}">${cat}</button>
              `).join('')}
            </div>
          </div>

          <div id="post-error" class="input-error-msg"></div>

          <button type="submit" class="btn btn-primary btn-lg" id="post-btn">
            投稿する
          </button>
        </form>
      </div>
      ${BottomNav.render(-1)}
    `;

    let selectedCategory = '雑談';

    // URL入力でプレビュー更新
    document.getElementById('post-url').addEventListener('input', (e) => {
      const url = e.target.value;
      const preview = document.getElementById('post-preview');
      const thumb = YouTubeUtils.getThumbnailUrl(url);

      if (thumb) {
        preview.innerHTML = `<img src="${thumb}" alt="プレビュー">`;
      } else {
        preview.innerHTML = `
          <div class="post-preview-placeholder">
            <svg fill="currentColor"><use href="#icon-video"></use></svg>
            <span style="font-size:var(--text-sm)">URLを入力するとプレビューが表示されます</span>
          </div>
        `;
      }
    });

    // カテゴリ選択
    document.getElementById('post-category-select').addEventListener('click', (e) => {
      const btn = e.target.closest('.post-category-option');
      if (!btn) return;
      document.querySelectorAll('.post-category-option').forEach(b => b.classList.remove('selected'));
      btn.classList.add('selected');
      selectedCategory = btn.dataset.cat;
    });

    // フォーム送信
    document.getElementById('post-form').addEventListener('submit', async (e) => {
      e.preventDefault();
      const url = document.getElementById('post-url').value;
      const title = document.getElementById('post-title').value;
      const errorEl = document.getElementById('post-error');
      const btn = document.getElementById('post-btn');

      errorEl.textContent = '';

      if (!YouTubeUtils.extractVideoId(url)) {
        errorEl.textContent = '有効なYouTube URLを入力してください';
        return;
      }

      btn.disabled = true;
      btn.textContent = '投稿中...';

      try {
        await SupabaseService.postVideo(title, url, selectedCategory);
        App.showToast('動画を投稿しました！', 'success');
        Router.navigate('/');
      } catch (err) {
        errorEl.textContent = '投稿に失敗しました: ' + (err.message || err);
      } finally {
        btn.disabled = false;
        btn.textContent = '投稿する';
      }
    });

    NavBar.updateAvatar();
  }
};
