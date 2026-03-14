/**
 * YouTube URL Utilities
 */
const YouTubeUtils = {
  /**
   * YouTube URLからVideo IDを抽出
   * @param {string} url
   * @returns {string|null}
   */
  extractVideoId(url) {
    if (!url) return null;
    try {
      const u = new URL(url);
      // youtu.be
      if (u.hostname === 'youtu.be' || u.hostname === 'www.youtu.be') {
        const id = u.pathname.slice(1).split('?')[0];
        return this.isValidId(id) ? id : null;
      }
      // youtube.com/watch?v=
      if (u.hostname.includes('youtube.com')) {
        const v = u.searchParams.get('v');
        if (v && this.isValidId(v)) return v;
        // /embed/ID
        const segs = u.pathname.split('/');
        const embedIdx = segs.indexOf('embed');
        if (embedIdx !== -1 && segs[embedIdx + 1]) {
          const id = segs[embedIdx + 1].split('?')[0];
          if (this.isValidId(id)) return id;
        }
      }
    } catch (e) { /* invalid URL */ }
    return null;
  },

  /**
   * ビデオIDが有効な形式かチェック
   */
  isValidId(id) {
    return id && id.length === 11 && /^[a-zA-Z0-9_-]{11}$/.test(id);
  },

  /**
   * サムネイルURLを取得
   */
  getThumbnailUrl(url, quality = 'hq') {
    const id = this.extractVideoId(url);
    if (!id) return null;
    const q = quality === 'max' ? 'maxresdefault' : 'hqdefault';
    return `https://img.youtube.com/vi/${id}/${q}.jpg`;
  },

  /**
   * YouTube視聴URLを生成
   */
  getWatchUrl(url) {
    const id = this.extractVideoId(url);
    if (!id) return url;
    return `https://www.youtube.com/watch?v=${id}`;
  }
};
