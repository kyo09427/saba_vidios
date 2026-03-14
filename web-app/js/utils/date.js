/**
 * Date/Time Utilities (Japanese)
 */
const DateUtils = {
  /**
   * 相対時間表示: 3分前、2時間前、etc.
   */
  relativeTime(dateStr) {
    try {
      const date = new Date(dateStr);
      const now = new Date();
      const diff = now - date;
      const mins = Math.floor(diff / 60000);
      const hours = Math.floor(diff / 3600000);
      const days = Math.floor(diff / 86400000);

      if (days > 365) return `${Math.floor(days / 365)}年前`;
      if (days > 30) return `${Math.floor(days / 30)}か月前`;
      if (days > 0) return `${days}日前`;
      if (hours > 0) return `${hours}時間前`;
      if (mins > 0) return `${mins}分前`;
      return 'たった今';
    } catch (e) {
      return '';
    }
  },

  /**
   * フォーマット: 2026年02月07日 15:30
   */
  formatFull(dateStr) {
    try {
      const d = new Date(dateStr);
      const y = d.getFullYear();
      const m = String(d.getMonth() + 1).padStart(2, '0');
      const day = String(d.getDate()).padStart(2, '0');
      const h = String(d.getHours()).padStart(2, '0');
      const min = String(d.getMinutes()).padStart(2, '0');
      return `${y}年${m}月${day}日 ${h}:${min}`;
    } catch (e) {
      return '日時不明';
    }
  },

  /**
   * 年月ラベル: 2026年2月
   */
  formatYearMonth(dateStr) {
    try {
      const d = new Date(dateStr);
      return `${d.getFullYear()}年${d.getMonth() + 1}月`;
    } catch (e) {
      return '';
    }
  },

  /**
   * 月名を取得: 1月, 2月 ...
   */
  getMonthName(month) {
    return `${month}月`;
  },

  /**
   * 動画を年月ごとにグループ化
   */
  groupByYearMonth(videos) {
    const groups = {};
    videos.forEach(v => {
      const d = new Date(v.created_at);
      const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
      if (!groups[key]) {
        groups[key] = {
          year: d.getFullYear(),
          month: d.getMonth() + 1,
          videos: []
        };
      }
      groups[key].videos.push(v);
    });
    // 新しい月順にソート
    return Object.entries(groups)
      .sort((a, b) => b[0].localeCompare(a[0]))
      .map(([key, val]) => val);
  }
};
