/**
 * Bottom Navigation Component
 */
const BottomNav = {
  render(activeIndex = 0) {
    const items = [
      { icon: 'icon-home', label: 'ホーム', path: '/' },
      { icon: 'icon-timeline', label: 'タイムライン', path: '/timeline' },
      { type: 'post' },
      { icon: 'icon-subscriptions', label: '登録チャンネル', path: '/subscriptions' },
      { icon: 'icon-person', label: 'マイページ', path: '/profile' }
    ];

    return `
      <nav class="bottom-nav">
        ${items.map((item, i) => {
          if (item.type === 'post') {
            return `
              <div class="nav-post-btn" onclick="Router.navigate('/post')" title="動画を投稿">
                <svg><use href="#icon-add"></use></svg>
              </div>
            `;
          }
          const isActive = i === activeIndex;
          return `
            <a class="nav-item ${isActive ? 'active' : ''}" href="#${item.path}">
              <svg fill="currentColor"><use href="#${item.icon}"></use></svg>
              <span class="nav-item-label">${item.label}</span>
            </a>
          `;
        }).join('')}
      </nav>
    `;
  }
};
