/**
 * Profile / My Page
 */
const ProfilePage = {
  async render() {
    const app = document.getElementById('app');

    app.innerHTML = `
      ${NavBar.render('profile')}
      <main class="main-content">
        <div class="loading-view">
          <div class="spinner"></div>
          <span class="loading-text">読み込み中...</span>
        </div>
      </main>
      ${BottomNav.render(4)}
    `;

    try {
      const user = await SupabaseService.getCurrentUser();
      if (!user) {
        Router.navigate('/login');
        return;
      }

      const [profile, videoCount, subscriberCount] = await Promise.all([
        SupabaseService.getProfile(user.id),
        SupabaseService.getVideoCount(user.id),
        SupabaseService.getSubscriberCount(user.id)
      ]);

      const avatarHtml = profile?.avatar_url
        ? `<img src="${profile.avatar_url}" alt="${profile.username}">`
        : VideoCard.getInitials(profile?.username);

      const main = app.querySelector('main');
      main.innerHTML = `
        <div class="profile-screen">
          <div class="profile-header">
            <div class="profile-avatar-wrapper">
              <div class="profile-avatar" style="background:${VideoCard.getAvatarColor(user.id)}">
                ${avatarHtml}
              </div>
            </div>
            <div class="profile-username">${VideoCard.escapeHtml(profile?.username || '名無し')}</div>
            <div class="profile-email">${user.email}</div>
            ${profile?.bio ? `<div class="profile-bio">${VideoCard.escapeHtml(profile.bio)}</div>` : ''}

            <div class="profile-stats-row">
              <div class="profile-stat">
                <span class="profile-stat-value">${videoCount}</span>
                <span class="profile-stat-label">投稿動画</span>
              </div>
              <div class="profile-stat">
                <span class="profile-stat-value">${subscriberCount}</span>
                <span class="profile-stat-label">登録者</span>
              </div>
            </div>
          </div>

          <div class="profile-menu">
            <div class="profile-menu-item" onclick="ProfilePage.showEditModal()">
              <svg fill="currentColor"><use href="#icon-edit"></use></svg>
              <span>プロフィールを編集</span>
              <svg class="menu-chevron" fill="currentColor"><use href="#icon-chevron-right"></use></svg>
            </div>
            <div class="profile-menu-item" onclick="Router.navigate('/channel/${user.id}')">
              <svg fill="currentColor"><use href="#icon-person"></use></svg>
              <span>自分のチャンネル</span>
              <svg class="menu-chevron" fill="currentColor"><use href="#icon-chevron-right"></use></svg>
            </div>
            <div class="profile-menu-item" onclick="Router.navigate('/subscriptions')">
              <svg fill="currentColor"><use href="#icon-subscriptions"></use></svg>
              <span>登録チャンネル</span>
              <svg class="menu-chevron" fill="currentColor"><use href="#icon-chevron-right"></use></svg>
            </div>
            <div class="profile-menu-item" onclick="ProfilePage.showHelp()">
              <svg fill="currentColor"><use href="#icon-help"></use></svg>
              <span>ヘルプ・使い方</span>
              <svg class="menu-chevron" fill="currentColor"><use href="#icon-chevron-right"></use></svg>
            </div>
            <div class="profile-menu-item danger" onclick="ProfilePage.handleLogout()">
              <svg fill="currentColor"><use href="#icon-logout"></use></svg>
              <span>ログアウト</span>
            </div>
          </div>
        </div>
      `;

      NavBar.updateAvatar();
    } catch (e) {
      console.error('Profile load error:', e);
    }
  },

  async handleLogout() {
    const overlay = document.createElement('div');
    overlay.className = 'modal-overlay';
    overlay.innerHTML = `
      <div class="modal-content">
        <div class="modal-title">ログアウト</div>
        <p style="color:var(--text-secondary);font-size:var(--text-sm)">ログアウトしますか？</p>
        <div class="modal-actions">
          <button class="btn btn-ghost" id="logout-cancel">キャンセル</button>
          <button class="btn btn-danger" id="logout-confirm">ログアウト</button>
        </div>
      </div>
    `;
    document.body.appendChild(overlay);

    overlay.querySelector('#logout-cancel').onclick = () => overlay.remove();
    overlay.querySelector('#logout-confirm').onclick = async () => {
      try {
        await SupabaseService.signOut();
        overlay.remove();
        Router.navigate('/login');
      } catch (e) {
        App.showToast('ログアウトに失敗しました', 'error');
      }
    };
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) overlay.remove();
    });
  },

  async showEditModal() {
    const user = await SupabaseService.getCurrentUser();
    if (!user) return;

    const profile = await SupabaseService.getProfile(user.id);

    const overlay = document.createElement('div');
    overlay.className = 'modal-overlay';
    overlay.innerHTML = `
      <div class="modal-content" style="max-width:500px">
        <div class="modal-title">プロフィールを編集</div>
        <form class="edit-profile-form" id="edit-profile-form">
          <div class="edit-avatar-section">
            <div class="edit-avatar-preview" id="edit-avatar-preview" style="background:${VideoCard.getAvatarColor(user.id)}">
              ${profile?.avatar_url
                ? `<img src="${profile.avatar_url}" alt="">`
                : VideoCard.getInitials(profile?.username)
              }
            </div>
            <label class="btn btn-outline btn-sm" style="cursor:pointer">
              アバターを変更
              <input type="file" accept="image/*" id="edit-avatar-input" style="display:none">
            </label>
          </div>
          <div class="input-group">
            <label for="edit-username">ユーザー名</label>
            <input type="text" id="edit-username" class="input-field" value="${VideoCard.escapeHtml(profile?.username || '')}" required>
          </div>
          <div class="input-group">
            <label for="edit-bio">自己紹介</label>
            <textarea id="edit-bio" class="input-field" placeholder="自己紹介を入力...">${VideoCard.escapeHtml(profile?.bio || '')}</textarea>
          </div>
          <div id="edit-error" class="input-error-msg"></div>
          <div class="modal-actions">
            <button type="button" class="btn btn-ghost" id="edit-cancel">キャンセル</button>
            <button type="submit" class="btn btn-primary" id="edit-save">保存</button>
          </div>
        </form>
      </div>
    `;
    document.body.appendChild(overlay);

    let avatarFile = null;

    // アバター変更
    overlay.querySelector('#edit-avatar-input').addEventListener('change', (e) => {
      const file = e.target.files[0];
      if (!file) return;
      avatarFile = file;
      const reader = new FileReader();
      reader.onload = (ev) => {
        overlay.querySelector('#edit-avatar-preview').innerHTML = `<img src="${ev.target.result}" alt="preview">`;
      };
      reader.readAsDataURL(file);
    });

    overlay.querySelector('#edit-cancel').onclick = () => overlay.remove();
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) overlay.remove();
    });

    overlay.querySelector('#edit-profile-form').addEventListener('submit', async (e) => {
      e.preventDefault();
      const username = overlay.querySelector('#edit-username').value.trim();
      const bio = overlay.querySelector('#edit-bio').value.trim();
      const errorEl = overlay.querySelector('#edit-error');
      const saveBtn = overlay.querySelector('#edit-save');

      errorEl.textContent = '';

      if (!username) {
        errorEl.textContent = 'ユーザー名を入力してください';
        return;
      }

      saveBtn.disabled = true;
      saveBtn.textContent = '保存中...';

      try {
        // アバターアップロード
        if (avatarFile) {
          await SupabaseService.uploadAvatar(user.id, avatarFile);
        }

        // プロフィール更新
        await SupabaseService.updateProfile(user.id, { username, bio: bio || null });

        App.showToast('プロフィールを更新しました', 'success');
        overlay.remove();
        ProfilePage.render(); // 画面を再描画
      } catch (err) {
        errorEl.textContent = '更新に失敗しました: ' + (err.message || err);
      } finally {
        saveBtn.disabled = false;
        saveBtn.textContent = '保存';
      }
    });
  },

  showHelp() {
    const overlay = document.createElement('div');
    overlay.className = 'modal-overlay';
    overlay.innerHTML = `
      <div class="modal-content" style="max-width:500px">
        <div class="modal-title">ヘルプ・使い方</div>
        <div style="color:var(--text-secondary);font-size:var(--text-sm);line-height:1.8">
          <h3 style="color:var(--text-primary);font-size:var(--text-base);margin-bottom:8px">🏠 ホーム</h3>
          <p>投稿された動画が一覧表示されます。カードをクリックするとYouTubeで動画が開きます。</p>
          <br>
          <h3 style="color:var(--text-primary);font-size:var(--text-base);margin-bottom:8px">📹 動画の投稿</h3>
          <p>中央の「+」ボタンからYouTube URLを入力して動画を投稿できます。</p>
          <br>
          <h3 style="color:var(--text-primary);font-size:var(--text-base);margin-bottom:8px">👤 チャンネル</h3>
          <p>動画カードのアバターをクリックすると、そのユーザーのチャンネルページへ移動できます。</p>
          <br>
          <h3 style="color:var(--text-primary);font-size:var(--text-base);margin-bottom:8px">📅 タイムライン</h3>
          <p>すべての動画を年月別に閲覧できます。</p>
        </div>
        <div class="modal-actions">
          <button class="btn btn-primary" onclick="this.closest('.modal-overlay').remove()">閉じる</button>
        </div>
      </div>
    `;
    document.body.appendChild(overlay);
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) overlay.remove();
    });
  }
};
