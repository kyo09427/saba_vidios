# サバの動画

仲間内でYouTubeの限定公開動画を共有し、楽しむための「秘密基地」的カタログアプリです。

## 特徴

- 🔐 **共有パスワードによる招待制**: 仲間内だけでアクセス
- 📹 **YouTube動画カタログ**: サムネイル付きで見やすい一覧表示
- 👤 **ユーザープロフィール**: アバター、ユーザー名、自己紹介の設定が可能
- 🎯 **シンプルな操作**: タップでYouTubeアプリを起動
- ⚡ **リアルタイム更新**: 誰かが投稿したらすぐに反映
- 🎨 **YouTubeライクなUI**: 使い慣れたインターフェース

## 技術スタック

- **フロントエンド**: Flutter 3.10.1+ (Dart)
- **バックエンド/DB**: Supabase
- **認証**: Supabase Auth (メールアドレス・パスワード)
- **ストレージ**: Supabase Storage (アバター画像)
- **対応プラットフォーム**: Android、iOS、Web

## セットアップ

### 必要な環境

- Flutter SDK 3.10.1以上
- Dart SDK 3.10.1以上
- Android Studio または Visual Studio Code
- Supabaseアカウント

### 1. リポジトリのクローン

```bash
git clone <repository-url>
cd saba_videos
```

### 2. 依存関係のインストール

```bash
flutter pub get
```

### 3. Supabaseプロジェクトの設定

#### 3.1 Supabaseプロジェクトの作成
1. [Supabase](https://supabase.com/)でアカウントを作成
2. 新しいプロジェクトを作成
3. プロジェクトURLとAnon Keyを取得
   - Settings > API から確認できます

#### 3.2 環境変数の設定
1. プロジェクトルートに `.env` ファイルを作成
2. 以下の内容を記入:

```env
# Supabase設定
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here

# 共有パスワード（仲間内で共有）
SHARED_PASSWORD=your-shared-password
```

⚠️ **重要**: `.env` ファイルは `.gitignore` に含まれており、Gitで追跡されません。チーム内で安全に共有してください。

#### 3.3 データベースのセットアップ

Supabaseダッシュボードの「SQL Editor」で `database_setup.sql` の内容を実行してください。

このSQLファイルには以下が含まれています:
- **videosテーブル**: 動画情報を保存
- **profilesテーブル**: ユーザープロフィール情報（ユーザー名、アバター、自己紹介）
- **RLSポリシー**: セキュリティ設定
- **インデックス**: パフォーマンス最適化
- **トリガー**: 新規ユーザー登録時の自動プロフィール作成

**Supabase Storageの設定**:
1. Supabaseダッシュボード > Storage > Create a new bucket
2. バケット名: `avatars`
3. Public bucket: ✅ はい（チェックを入れる）
4. File size limit: 5MB
5. Allowed MIME types: `image/jpeg`, `image/png`, `image/webp`
6. Create bucket をクリック
7. `avatars` バケットの Policies タブで以下のポリシーを追加:
   - **Anyone can view avatars**: SELECT (Policy: `true`)
   - **Users can upload their own avatar**: INSERT (Policy: `bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text`)
   - **Users can update their own avatar**: UPDATE (同上)
   - **Users can delete their own avatar**: DELETE (同上)

#### 3.4 メール認証の設定
1. Supabaseダッシュボード > Authentication > Settings
2. "Enable email confirmations" を有効化
3. メールテンプレートをカスタマイズ（オプション）

### 4. アプリの起動

```bash
# Androidエミュレータで起動
flutter run

# 特定のデバイスを指定
flutter devices  # 利用可能なデバイスを確認
flutter run -d <device-id>

# リリースビルド
flutter run --release
```

## 使い方

### 初回登録

1. アプリを起動
2. 「新規登録はこちら」をタップ
3. 以下の情報を入力:
   - メールアドレス
   - パスワード（6文字以上）
   - パスワード確認
   - 共有パスワード（仲間から共有されたもの）
4. 「登録する」ボタンをタップ
5. 登録したメールアドレスに確認メールが届く
6. メール内のリンクをクリックして認証完了
7. アプリに戻ってログイン

### ログイン

1. メールアドレスとパスワードを入力
2. 「ログイン」ボタンをタップ

### 動画の閲覧

- ホーム画面に投稿された動画が一覧表示されます
- カードをタップするとYouTubeアプリ/ブラウザで動画が開きます
- 画面を下にスワイプして最新情報に更新できます

### 動画の投稿

1. 画面下部中央の「+」ボタンをタップ
2. YouTube URLを入力
   - 入力するとプレビューが表示されます
3. 動画タイトルを入力
4. 「投稿する」ボタンをタップ

### マイページ

1. 画面下部右端の「マイページ」をタップ
2. 以下の情報を確認・設定できます:
   - プロフィール情報
   - 投稿動画数などの統計
   - 各種設定
   - ヘルプ・使い方
   - ログアウト

## プロジェクト構成

```
lib/
├── main.dart                              # エントリーポイント
├── models/                                # データモデル
│   ├── video.dart                        # 動画モデル
│   └── app_user.dart                     # ユーザーモデル
├── services/                              # サービス層
│   ├── supabase_service.dart             # Supabase接続管理
│   └── youtube_service.dart              # YouTube関連機能
├── screens/                               # 画面
│   ├── auth/                             # 認証関連
│   │   ├── login_screen.dart             # ログイン画面
│   │   ├── register_screen.dart          # 新規登録画面
│   │   └── email_verification_screen.dart # メール確認画面
│   ├── home/
│   │   └── home_screen.dart              # ホーム画面（動画一覧）
│   ├── post/
│   │   └── post_video_screen.dart        # 投稿画面
│   └── profile/
│       └── my_page_screen.dart           # マイページ画面
└── widgets/                               # 再利用可能なウィジェット
    ├── video_card.dart                   # 動画カード
    └── app_bottom_navigation_bar.dart    # ボトムナビゲーション
```

## データベーススキーマ

### videos テーブル

| カラム名 | 型 | 説明 | 制約 |
|---------|---|------|------|
| id | UUID | 主キー | PRIMARY KEY, DEFAULT gen_random_uuid() |
| created_at | TIMESTAMPTZ | 作成日時 | DEFAULT NOW() |
| title | TEXT | 動画タイトル | NOT NULL |
| url | TEXT | YouTube URL | NOT NULL |
| user_id | UUID | 投稿者のUID | REFERENCES auth.users(id), NOT NULL |

### インデックス

- `videos_created_at_idx`: 作成日時の降順（最新順取得の高速化）
- `videos_user_id_idx`: ユーザーIDでの検索の高速化

## 主要な機能実装

### 1. 認証システム
- Supabase Authを使用したメール認証
- 共有パスワードによる招待制
- セッション管理とリアルタイム認証状態監視

### 2. リアルタイム更新
- Supabase Realtimeを使用して新規投稿を即座に反映
- PostgreSQL Changesの購読により自動更新

### 3. YouTube連携
- URLからビデオIDを自動抽出
- サムネイル画像の自動取得と表示
- 外部アプリ起動による動画再生

### 4. エラーハンドリング
- ネットワークエラーの適切な処理
- ユーザーフレンドリーなエラーメッセージ
- null安全性の確保

## トラブルシューティング

### Supabase接続エラー

**症状**: アプリ起動時に初期化エラーが発生

**解決策**:
1. `.env` ファイルが存在し、正しい場所にあるか確認
2. `SUPABASE_URL` と `SUPABASE_ANON_KEY` が正しいか確認
3. インターネット接続を確認
4. Supabaseプロジェクトが有効か確認

### ログインできない

**症状**: メールアドレスとパスワードでログインできない

**解決策**:
1. メール確認リンクをクリックしたか確認
2. パスワードが6文字以上か確認
3. Supabaseダッシュボード > Authentication > Users でユーザーが作成されているか確認
4. ユーザーの "Email Confirmed" が true になっているか確認

### 動画が表示されない

**症状**: ホーム画面に動画が表示されない

**解決策**:
1. Supabaseダッシュボード > Table Editor > videos でデータが存在するか確認
2. RLS (Row Level Security) ポリシーが正しく設定されているか確認
3. アプリを再起動してみる
4. 下にスワイプして手動更新してみる

### YouTube動画が開けない

**症状**: 動画カードをタップしても何も起こらない

**解決策**:
1. URLが正しいYouTube URLか確認
2. 動画が削除されていないか確認
3. YouTubeアプリがインストールされているか確認
4. ブラウザで開けるか試してみる

### メールが届かない

**症状**: 登録確認メールが届かない

**解決策**:
1. 迷惑メールフォルダを確認
2. メールアドレスのスペルミスがないか確認
3. Supabaseの送信制限に達していないか確認
4. Supabaseダッシュボード > Authentication > Logs でエラーを確認

## セキュリティ

### Row Level Security (RLS)
- 認証済みユーザーのみがデータにアクセス可能
- 投稿者のみが自分の投稿を削除可能
- SQLインジェクション対策

### 共有パスワード
- 新規登録時に検証
- 環境変数で管理
- Gitで追跡されない

### 環境変数
- `.env` ファイルは `.gitignore` で除外
- 機密情報を保護
- チーム内で安全に共有

## 今後の拡張案

### v2.0 (予定)
- [ ] Web版の対応
- [ ] 動画の編集・削除機能
- [ ] プロフィール画像のカスタマイズ
- [ ] 検索機能

### v3.0 (予定)
- [ ] いいね・コメント機能
- [ ] カテゴリー分類
- [ ] プレイリスト機能
- [ ] プッシュ通知

### v4.0 (予定)
- [ ] ダークモード対応
- [ ] 多言語対応
- [ ] 動画の埋め込み再生
- [ ] ソーシャル機能の強化

## バージョン履歴

### v1.1.0 (2026-02-07) - 最新版
- YouTubeライクなUIデザインに刷新
- マイページ機能の追加
- ボトムナビゲーションの実装
- ショート動画セクションの追加（ダミーデータ）
- エラーハンドリングの改善
- パフォーマンスの最適化
- コード品質の向上

### v1.0.0 (初回リリース)
- 基本的な認証機能
- 動画の投稿・閲覧機能
- リアルタイム更新
- YouTubeサムネイル表示

## ライセンス

このプロジェクトは私的利用を目的としています。

## 開発者

サバの仲間たち 🐟

## サポート

問題が発生した場合や機能リクエストがある場合は、以下の方法でお知らせください:

1. GitHubのIssuesで報告
2. 開発チームに直接連絡

## 貢献

このプロジェクトは仲間内での利用を目的としていますが、改善提案は歓迎します:

1. このリポジトリをフォーク
2. 新しいブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add some amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

## 技術的な詳細

### 使用しているパッケージ

- `supabase_flutter: ^2.9.4` - Supabaseクライアント
- `url_launcher: ^6.3.1` - 外部URLの起動
- `flutter_dotenv: ^5.2.1` - 環境変数管理
- `intl: ^0.20.1` - 日付フォーマット
- `cached_network_image: ^3.4.1` - 画像キャッシング

### アーキテクチャパターン

- **サービス層**: ビジネスロジックの分離
- **モデル層**: データ構造の定義
- **UI層**: プレゼンテーション層

### パフォーマンス最適化

- 画像のキャッシング
- リアルタイム購読の適切なクリーンアップ
- 不要な再レンダリングの削減
- インデックスによるデータベースクエリの高速化

---

**注意**: このアプリは仲間内での利用を目的としており、公開されたアプリストアでの配布は想定していません。