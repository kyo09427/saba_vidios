# サバの動画

仲間内でYouTubeの限定公開動画を共有し、楽しむための「秘密基地」的カタログアプリです。

## 特徴

- 🔐 **共有パスワードによる招待制**: 仲間内だけでアクセス
- 📹 **YouTube動画カタログ**: サムネイル付きで見やすい一覧表示
- 🎯 **シンプルな操作**: タップでYouTubeアプリを起動
- ⚡ **リアルタイム更新**: 誰かが投稿したらすぐに反映

## 技術スタック

- **フロントエンド**: Flutter (Dart)
- **バックエンド/DB**: Supabase
- **認証**: Supabase Auth (メールアドレス・パスワード)
- **対応プラットフォーム**: Android (将来的にWeb対応予定)

## セットアップ

### 1. 依存関係のインストール

```bash
flutter pub get
```

### 2. Supabaseプロジェクトの設定

1. [Supabase](https://supabase.com/)でプロジェクトを作成
2. `.env.example`を`.env`にコピー
3. `.env`ファイルに必要な情報を入力

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SHARED_PASSWORD=your-shared-password
```

### 3. データベースのセットアップ

Supabaseダッシュボードの「SQL Editor」で`database_setup.sql`の内容を実行してください。これにより以下が作成されます:

- `videos`テーブル
- Row Level Security (RLS) ポリシー
- パフォーマンス向上用のインデックス

### 4. アプリの起動

```bash
# Androidエミュレータで起動
flutter run

# Chromeで起動（将来対応）
flutter run -d chrome
```

## 使い方

### 初回登録

1. アプリを起動
2. 「新規登録はこちら」をタップ
3. メールアドレス、パスワード、**共有パスワード**を入力
4. 登録ボタンをタップ

### 動画の閲覧

- ホーム画面に投稿された動画が一覧表示されます
- カードをタップするとYouTubeアプリ/ブラウザで動画が開きます
- 下にスワイプして最新情報に更新できます

### 動画の投稿

1. 右下の「+」ボタンをタップ
2. 動画タイトルとYouTube URLを入力
3. 「投稿する」ボタンをタップ

## プロジェクト構成

```
lib/
├── main.dart                      # エントリーポイント
├── models/                        # データモデル
│   ├── video.dart                # 動画モデル
│   └── app_user.dart             # ユーザーモデル
├── services/                      # サービス層
│   ├── supabase_service.dart     # Supabase接続管理
│   └── youtube_service.dart      # YouTube関連機能
├── screens/                       # 画面
│   ├── auth/
│   │   ├── login_screen.dart     # ログイン画面
│   │   └── register_screen.dart  # 新規登録画面
│   ├── home/
│   │   └── home_screen.dart      # ホーム画面（動画一覧）
│   └── post/
│       └── post_video_screen.dart # 投稿画面
└── widgets/                       # ウィジェット
    └── video_card.dart           # 動画カード
```

## データベーススキーマ

### videos テーブル

| カラム名 | 型 | 説明 |
|---------|---|------|
| id | UUID | 主キー（自動生成） |
| created_at | TIMESTAMPTZ | 作成日時 |
| title | TEXT | 動画タイトル |
| url | TEXT | YouTube URL |
| user_id | UUID | 投稿者のUID |

## セキュリティ

- **Row Level Security (RLS)**: 認証済みユーザーのみがデータにアクセス可能
- **共有パスワード**: 新規登録時に検証（環境変数で管理）
- **環境変数**: `.gitignore`で`.env`を除外し、機密情報を保護

## 今後の拡張案

- [ ] Web版の対応
- [ ] 動画の編集・削除機能
- [ ] いいね・コメント機能
- [ ] カテゴリー分類
- [ ] 検索機能

## ライセンス

このプロジェクトは私的利用を目的としています。

## 開発者

サバの仲間たち 🐟