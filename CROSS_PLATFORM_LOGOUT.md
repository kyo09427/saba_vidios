# クロスプラットフォーム強制ログアウト 動作仕様

## 概要

Android と Web で同一アカウントに同時ログインできないようにする仕組み。
後からログインした側が「勝者」となり、先にログインしていた側が強制ログアウトされる。

---

## DB スキーマ（profiles テーブル）

| カラム          | 用途                          |
|----------------|-------------------------------|
| `fcm_token`     | Android の FCM デバイストークン |
| `web_fcm_token` | Web の FCM デバイストークン     |

---

## ケース1: リアルタイム検知（両プラットフォームが同時に起動中）

```
Android 起動中（fcm_token = "A"）

↓ Web でログイン

Web: registerFcmToken() を呼ぶ
  → DB UPDATE: { web_fcm_token: "W", fcm_token: null }
  → Android の fcm_token を null に上書き

↓ Supabase Realtime が Android に通知

Android: _subscribeProfileChanges() コールバック発火
  → _isDisposing == false → 続行
  → _hadToken == true（登録済みフラグ）→ 続行
  → newRecord に 'fcm_token' キーが存在する → 続行
  → newRecord['fcm_token'] == null → 強制ログアウト確定
  → forcedLogout.value = true

↓ main.dart の _onForcedLogout() が発火

  ダイアログ表示「ブラウザからログインされました」
  OK → dispose() → clearFcmToken() → signOut()
  → ログイン画面へ
```

---

## ケース2: タスクキル後の再開（片方がバックグラウンドで不在だった場合）

```
Android 起動 → FCM 登録（had_fcm_token = true を SharedPreferences に保存）

↓ Android をタスクキル（Realtime 購読が切れる）

↓ Web でログイン

Web: registerFcmToken()
  → DB UPDATE: { web_fcm_token: "W", fcm_token: null }
  （Android は不在なので Realtime を受け取れない）

↓ Android を再起動

Android: initialize() が呼ばれる
  → _isDisplacedByAnotherPlatform() を実行

  [判定ロジック]
  1. SharedPreferences had_fcm_token == true → 以前トークンを持っていた
  2. DB: fcm_token == null → タスクキル中に消された
  → true を返す → 強制ログアウト確定

  → forcedLogout.value = true
  → ダイアログ → OK → clearFcmToken() → signOut()
  → ログイン画面へ
```

---

## 誤検知を防ぐためのガード

### 1. `_hadToken`（インメモリ）
Realtime コールバック用のガード。
FCM トークンを登録する前（新規ログイン直後）はフラグが false のため、
自分が登録する前のイベントを無視できる。

### 2. `had_fcm_token`（SharedPreferences）
タスクキル後の誤検知防止。
「以前トークンを登録したことがあるか」を永続化する。
- `registerFcmToken()` 成功時 → `true`
- `clearFcmToken()` 実行時 → `false`（明示的ログアウト・強制ログアウト後）

新規ログイン時は `false` なので、`_isDisplacedByAnotherPlatform()` はスキップされる。

### 3. `_isDisposing`（インメモリ）
自分のログアウト処理中（dispose → clearFcmToken）に
Realtime イベントが届いても無視するためのフラグ。

### 4. `containsKey(myColumn)` チェック
Supabase Realtime のペイロードが全カラムを含まない場合、
`newRecord['fcm_token']` が存在しないキーへのアクセスで `null` になり誤検知する。
キーの存在確認を先に行うことで防ぐ。

---

## 関連ファイル

| ファイル | 役割 |
|---------|------|
| `lib/services/notification_service.dart` | FCM トークン管理・Realtime 購読・強制ログアウト検知 |
| `lib/main.dart` の `_AuthWrapperState` | `forcedLogout` リスナー・ダイアログ表示・ログアウト実行 |

---

## トラブルシューティング

### 強制ログアウトが発生しない
- Supabase ダッシュボードで `profiles` テーブルの Realtime が有効か確認
  - Database → Replication → supabase_realtime publication に `profiles` が含まれているか
  - SQL: `SELECT tablename FROM pg_publication_tables WHERE pubname = 'supabase_realtime';`

### 意図せず強制ログアウトされる
- SharedPreferences の `had_fcm_token` が `true` のまま残っている可能性
- 明示的ログアウト後に `clearFcmToken()` が正常に呼ばれているか確認
- `_isDisposing` フラグの順序: `dispose()` は必ず `clearFcmToken()` より前に呼ぶこと

### ログアウト後に再ログインできない（ループ）
- `clearFcmToken()` の失敗により SharedPreferences が `true` のまま残っている
- かつ DB でも自分のトークンが null の場合に発生
- 対処: Supabase コンソールで直接 `fcm_token` / `web_fcm_token` を null に更新
