/**
 * Auth Page - Login / Register / Email Verification
 */
const AuthPage = {
  /**
   * ログイン画面を表示
   */
  async renderLogin() {
    const app = document.getElementById('app');
    app.innerHTML = `
      <div class="auth-screen">
        <div class="auth-container">
          <div class="auth-logo">
            <div class="auth-logo-icon">
              <svg viewBox="0 0 24 24"><use href="#icon-play"></use></svg>
            </div>
            <span class="auth-logo-text">サバの動画</span>
          </div>
          <div class="auth-card">
            <h2>ログイン</h2>
            <p class="subtitle">仲間だけの秘密基地へようこそ</p>
            <form class="auth-form" id="login-form">
              <div class="input-group">
                <label for="login-email">メールアドレス</label>
                <input type="email" id="login-email" class="input-field" placeholder="example@email.com" required autocomplete="email">
              </div>
              <div class="input-group">
                <label for="login-password">パスワード</label>
                <input type="password" id="login-password" class="input-field" placeholder="パスワードを入力" required autocomplete="current-password">
              </div>
              <div id="login-error" class="input-error-msg"></div>
              <button type="submit" class="btn btn-primary btn-lg auth-submit" id="login-btn">
                ログイン
              </button>
            </form>
            <div class="auth-footer">
              アカウントをお持ちでない方は
              <a href="#/register" onclick="event.preventDefault(); Router.navigate('/register')">新規登録はこちら</a>
            </div>
          </div>
        </div>
      </div>
    `;

    // フォーム送信
    document.getElementById('login-form').addEventListener('submit', async (e) => {
      e.preventDefault();
      const email = document.getElementById('login-email').value;
      const password = document.getElementById('login-password').value;
      const errorEl = document.getElementById('login-error');
      const btn = document.getElementById('login-btn');

      errorEl.textContent = '';
      btn.disabled = true;
      btn.textContent = 'ログイン中...';

      try {
        await SupabaseService.signIn(email, password);
        Router.navigate('/');
      } catch (err) {
        let msg = 'ログインに失敗しました';
        if (err.message?.includes('Invalid login credentials')) {
          msg = 'メールアドレスまたはパスワードが正しくありません';
        } else if (err.message?.includes('Email not confirmed')) {
          msg = 'メールアドレスが確認されていません。確認メールをご確認ください';
        }
        errorEl.textContent = msg;
      } finally {
        btn.disabled = false;
        btn.textContent = 'ログイン';
      }
    });
  },

  /**
   * 新規登録画面を表示
   */
  async renderRegister() {
    const app = document.getElementById('app');
    app.innerHTML = `
      <div class="auth-screen">
        <div class="auth-container">
          <div class="auth-logo">
            <div class="auth-logo-icon">
              <svg viewBox="0 0 24 24"><use href="#icon-play"></use></svg>
            </div>
            <span class="auth-logo-text">サバの動画</span>
          </div>
          <div class="auth-card">
            <h2>新規登録</h2>
            <p class="subtitle">仲間の招待で参加しましょう</p>
            <form class="auth-form" id="register-form">
              <div class="input-group">
                <label for="reg-email">メールアドレス</label>
                <input type="email" id="reg-email" class="input-field" placeholder="example@email.com" required autocomplete="email">
              </div>
              <div class="input-group">
                <label for="reg-password">パスワード</label>
                <input type="password" id="reg-password" class="input-field" placeholder="6文字以上のパスワード" required minlength="6" autocomplete="new-password">
              </div>
              <div class="input-group">
                <label for="reg-password-confirm">パスワード確認</label>
                <input type="password" id="reg-password-confirm" class="input-field" placeholder="パスワードを再入力" required autocomplete="new-password">
              </div>
              <div class="auth-divider">招待確認</div>
              <div class="input-group">
                <label for="reg-shared">共有パスワード</label>
                <input type="password" id="reg-shared" class="input-field" placeholder="仲間から共有されたパスワード" required>
              </div>
              <div id="register-error" class="input-error-msg"></div>
              <button type="submit" class="btn btn-primary btn-lg auth-submit" id="register-btn">
                登録する
              </button>
            </form>
            <div class="auth-footer">
              アカウントをお持ちの方は
              <a href="#/login" onclick="event.preventDefault(); Router.navigate('/login')">ログインはこちら</a>
            </div>
          </div>
        </div>
      </div>
    `;

    document.getElementById('register-form').addEventListener('submit', async (e) => {
      e.preventDefault();
      const email = document.getElementById('reg-email').value;
      const password = document.getElementById('reg-password').value;
      const passwordConfirm = document.getElementById('reg-password-confirm').value;
      const shared = document.getElementById('reg-shared').value;
      const errorEl = document.getElementById('register-error');
      const btn = document.getElementById('register-btn');

      errorEl.textContent = '';

      // バリデーション
      if (password !== passwordConfirm) {
        errorEl.textContent = 'パスワードが一致しません';
        return;
      }

      if (password.length < 6) {
        errorEl.textContent = 'パスワードは6文字以上で入力してください';
        return;
      }

      if (!SupabaseService.validateSharedPassword(shared)) {
        errorEl.textContent = '共有パスワードが正しくありません';
        return;
      }

      btn.disabled = true;
      btn.textContent = '登録中...';

      try {
        await SupabaseService.signUp(email, password);
        Router.navigate('/verify-email');
      } catch (err) {
        let msg = '登録に失敗しました';
        if (err.message?.includes('already registered')) {
          msg = 'このメールアドレスは既に登録されています';
        }
        errorEl.textContent = msg;
      } finally {
        btn.disabled = false;
        btn.textContent = '登録する';
      }
    });
  },

  /**
   * メール確認画面
   */
  async renderVerifyEmail() {
    const app = document.getElementById('app');
    app.innerHTML = `
      <div class="auth-screen">
        <div class="auth-container">
          <div class="auth-card verification-card">
            <div class="icon-wrapper">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <use href="#icon-mail"></use>
              </svg>
            </div>
            <h2>メールを確認してください</h2>
            <p class="subtitle" style="margin-bottom: var(--space-4)">
              登録したメールアドレスに確認メールを送信しました。<br>
              メール内のリンクをクリックして認証を完了してください。
            </p>
            <button class="btn btn-primary btn-lg" style="width:100%" onclick="Router.navigate('/login')">
              ログイン画面へ
            </button>
          </div>
        </div>
      </div>
    `;
  }
};
