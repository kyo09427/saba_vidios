/**
 * Category Filter Pills Component
 */
const CategoryPills = {
  categories: ['すべて', '新しい動画', '雑談', 'ゲーム', '音楽', 'ネタ', 'その他'],

  render(selected = 'すべて', onSelect) {
    const container = document.createElement('div');
    container.className = 'category-filter';

    this.categories.forEach(cat => {
      const pill = document.createElement('button');
      pill.className = `category-pill ${cat === selected ? 'active' : ''}`;
      pill.textContent = cat;
      pill.onclick = () => {
        container.querySelectorAll('.category-pill').forEach(p => p.classList.remove('active'));
        pill.classList.add('active');
        if (onSelect) onSelect(cat);
      };
      container.appendChild(pill);
    });

    return container;
  },

  renderHTML(selected = 'すべて') {
    return `
      <div class="category-filter" id="category-filter">
        ${this.categories.map(cat => `
          <button class="category-pill ${cat === selected ? 'active' : ''}" data-category="${cat}">${cat}</button>
        `).join('')}
      </div>
    `;
  }
};
