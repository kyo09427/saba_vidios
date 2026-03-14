/// 日本語テキストユーティリティ
///
/// ひらがな・カタカナを区別せずに検索するためのユーティリティ関数を提供します。
library;

/// ひらがなをカタカナに変換する
///
/// [s] 変換元の文字列
/// Returns: カタカナに統一された文字列
String hiraganaToKatakana(String s) {
  return s.replaceAllMapped(RegExp(r'[\u3041-\u3096]'), (match) {
    return String.fromCharCode(match.group(0)!.codeUnitAt(0) + 0x60);
  });
}

/// カタカナをひらがなに変換する
///
/// [s] 変換元の文字列
/// Returns: ひらがなに統一された文字列
String katakanaToHiragana(String s) {
  return s.replaceAllMapped(RegExp(r'[\u30A1-\u30F6]'), (match) {
    return String.fromCharCode(match.group(0)!.codeUnitAt(0) - 0x60);
  });
}

/// 文字列を検索用に正規化する
///
/// - ひらがな→カタカナに統一
/// - 英字を小文字に変換
/// - 全角英数字→半角に変換
///
/// [s] 正規化する文字列
/// Returns: 正規化された文字列
String normalizeForSearch(String s) {
  // 全角英数→半角
  var result = s.replaceAllMapped(RegExp(r'[Ａ-Ｚａ-ｚ０-９]'), (match) {
    return String.fromCharCode(match.group(0)!.codeUnitAt(0) - 0xFEE0);
  });
  // ひらがな→カタカナ
  result = hiraganaToKatakana(result);
  // 英字→小文字
  result = result.toLowerCase();
  return result;
}

/// テキストにクエリが含まれているか（ひらがな/カタカナを区別しない）
///
/// [text] 検索対象のテキスト
/// [query] 検索クエリ
/// Returns: クエリが含まれている場合true
bool containsIgnoreKana(String text, String query) {
  if (query.isEmpty) return true;
  return normalizeForSearch(text).contains(normalizeForSearch(query));
}
