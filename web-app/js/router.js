/**
 * SPA Router
 */
const Router = {
  routes: {},
  currentPage: null,
  currentCleanup: null,

  /**
   * ルート登録
   */
  register(path, handler) {
    this.routes[path] = handler;
  },

  /**
   * ナビゲート
   */
  async navigate(path, params = {}) {
    // クリーンアップ
    if (this.currentCleanup && typeof this.currentCleanup === 'function') {
      this.currentCleanup();
      this.currentCleanup = null;
    }

    // ルートを解決
    let handler = this.routes[path];
    let routeParams = params;

    // パラメータ付きルートの解決 (/channel/:id など)
    if (!handler) {
      for (const [routePath, routeHandler] of Object.entries(this.routes)) {
        if (routePath.includes(':')) {
          const routeParts = routePath.split('/');
          const pathParts = path.split('/');
          if (routeParts.length === pathParts.length) {
            let match = true;
            const extractedParams = {};
            for (let i = 0; i < routeParts.length; i++) {
              if (routeParts[i].startsWith(':')) {
                extractedParams[routeParts[i].slice(1)] = pathParts[i];
              } else if (routeParts[i] !== pathParts[i]) {
                match = false;
                break;
              }
            }
            if (match) {
              handler = routeHandler;
              routeParams = { ...extractedParams, ...params };
              break;
            }
          }
        }
      }
    }

    if (!handler) {
      console.warn(`Route not found: ${path}`);
      handler = this.routes['/'] || this.routes['/login'];
      if (!handler) return;
    }

    // 記録
    const fullPath = path === '/' ? '/' : path;
    if (window.location.hash !== '#' + fullPath) {
      window.history.pushState(null, '', '#' + fullPath);
    }

    const app = document.getElementById('app');

    // 初回以外はexitアニメーション
    if (this.currentPage !== null) {
      app.style.opacity = '0';
      await new Promise(r => setTimeout(r, 100));
    }

    this.currentPage = path;

    // ページをレンダリング
    try {
      const cleanup = await handler(routeParams);
      this.currentCleanup = cleanup;
    } catch (e) {
      console.error('Page render error:', e);
      app.innerHTML = `
        <div class="empty-state">
          <div class="empty-state-icon">⚠️</div>
          <div class="empty-state-title">ページの表示に失敗しました</div>
          <button class="btn btn-primary" onclick="Router.navigate('/')">ホームに戻る</button>
        </div>
      `;
    }

    // Enter アニメーション
    app.style.opacity = '0';
    app.style.transform = 'translateY(8px)';
    requestAnimationFrame(() => {
      app.style.transition = 'opacity 0.25s ease, transform 0.25s ease';
      app.style.opacity = '1';
      app.style.transform = 'translateY(0)';
      setTimeout(() => {
        app.style.transition = '';
      }, 250);
    });
  },

  /**
   * 初期ルーティング
   */
  start() {
    window.addEventListener('hashchange', () => {
      const path = window.location.hash.slice(1) || '/';
      this.navigate(path);
    });

    window.addEventListener('popstate', () => {
      const path = window.location.hash.slice(1) || '/';
      this.navigate(path);
    });
  },

  /**
   * 現在のパスを取得
   */
  getCurrentPath() {
    return window.location.hash.slice(1) || '/';
  }
};
