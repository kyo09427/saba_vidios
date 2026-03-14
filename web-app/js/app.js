/**
 * サバの動画 Web App - Main Entry Point
 */
const App = {
  /**
   * アプリケーション初期化
   */
  async init() {
    console.log('🐟 サバの動画 Web版 initializing...');

    try {
      // Supabase初期化
      SupabaseService.init();

      // ルーティング設定
      this.setupRoutes();

      // Supabase未設定 → ログイン画面を直接表示
      if (!SupabaseService.client) {
        console.log('⚠️ Supabase not configured - showing login page');
        await AuthPage.renderLogin();
        // ルーターを開始（ログイン後のナビゲーション用）
        Router.start();
        return;
      }

      // 認証状態の監視
      SupabaseService.onAuthStateChange((event, session) => {
        console.log('Auth state changed:', event);
        if (event === 'SIGNED_OUT') {
          Router.navigate('/login');
        }
      });

      // ルーターを開始
      Router.start();

      // 認証チェック
      const session = await SupabaseService.getSession();
      const initialPath = Router.getCurrentPath();

      if (session) {
        // ログイン済み: リクエストされたパスまたはホーム
        const path = (initialPath && initialPath !== '/' && !initialPath.startsWith('/login') && !initialPath.startsWith('/register'))
          ? initialPath : '/';
        await Router.navigate(path);
      } else {
        // 未ログイン
        if (initialPath === '/register' || initialPath === '/verify-email') {
          await Router.navigate(initialPath);
        } else {
          await Router.navigate('/login');
        }
      }
    } catch (e) {
      console.error('❌ App init error:', e);
      // フォールバック: ログイン画面を表示
      await AuthPage.renderLogin();
    }
  },

  /**
   * ルート登録
   */
  setupRoutes() {
    // Auth routes (public)
    Router.register('/login', () => AuthPage.renderLogin());
    Router.register('/register', () => AuthPage.renderRegister());
    Router.register('/verify-email', () => AuthPage.renderVerifyEmail());

    // Protected routes
    Router.register('/', () => this.requireAuth(() => HomePage.render()));
    Router.register('/post', () => this.requireAuth(() => PostPage.render()));
    Router.register('/channel/:id', (params) => this.requireAuth(() => ChannelPage.render(params)));
    Router.register('/subscriptions', () => this.requireAuth(() => SubscriptionsPage.render()));
    Router.register('/timeline', () => this.requireAuth(() => TimelinePage.render()));
    Router.register('/profile', () => this.requireAuth(() => ProfilePage.render()));
  },

  /**
   * 認証ガード
   */
  async requireAuth(renderFn) {
    if (!SupabaseService.client) {
      // Supabase未設定の場合はデモモードで表示
      return renderFn();
    }

    try {
      const session = await SupabaseService.getSession();
      if (!session) {
        Router.navigate('/login');
        return;
      }
      return renderFn();
    } catch (e) {
      console.error('Auth check failed:', e);
      Router.navigate('/login');
    }
  },

  /**
   * トースト表示
   */
  showToast(message, type = 'info') {
    const container = document.getElementById('toast-container');
    if (!container) return;

    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.textContent = message;
    container.appendChild(toast);

    setTimeout(() => {
      toast.style.opacity = '0';
      toast.style.transform = 'translateY(10px)';
      toast.style.transition = 'all 0.3s ease';
      setTimeout(() => toast.remove(), 300);
    }, 3000);
  }
};

// DOM Ready → 初期化
document.addEventListener('DOMContentLoaded', () => {
  App.init().catch(e => {
    console.error('❌ Fatal init error:', e);
    document.getElementById('app').innerHTML = `
      <div style="color:white;padding:40px;text-align:center;">
        <h2>初期化エラー</h2>
        <p>${e.message || e}</p>
      </div>
    `;
  });
});
