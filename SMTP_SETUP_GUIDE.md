# Gmail SMTP設定ガイド

Supabaseのデフォルトメール送信上限を超えた場合、独自のGmail SMTPサーバーを設定できます。

## 手順

### 1. Gmailアプリパスワードの作成

1. Googleアカウントにログイン: https://myaccount.google.com/
2. **セキュリティ** > **2段階認証プロセス** を有効化（まだの場合）
3. **セキュリティ** > **アプリパスワード** に移動
4. アプリを選択: 「メール」
5. デバイスを選択: 「その他（カスタム名）」と入力（例: "Supabase Saba Videos"）
6. **生成** をクリック
7. 表示された16文字のパスワードをコピー（例: `abcd efgh ijkl mnop`）

> [!IMPORTANT]
> このパスワードは一度しか表示されません。必ずコピーして保存してください。

### 2. Supabase SMTP設定

1. Supabaseダッシュボードにログイン
2. プロジェクトを選択
3. **Settings** > **Authentication** > **SMTP Settings** に移動
4. 以下の情報を入力:

```
Enable Custom SMTP: ✅ 有効化

Host: smtp.gmail.com
Port: 587
Username: あなたのGmailアドレス（例: your-email@gmail.com）
Password: 手順1で生成したアプリパスワード（スペースなし: abcdefghijklmnop）
Sender email: あなたのGmailアドレス（例: your-email@gmail.com）
Sender name: サバの動画（または任意の送信者名）
```

5. **Save** をクリック

### 3. テストメール送信

1. アプリで新規ユーザー登録を試す
2. 登録したメールアドレスにメールが届くか確認

## トラブルシューティング

### メールが届かない場合

1. **スパムフォルダを確認**: Gmailのスパムフォルダをチェック
2. **アプリパスワードを確認**: スペースなしで正しく入力されているか
3. **2段階認証を確認**: Googleアカウントで2段階認証が有効になっているか
4. **Gmailの送信制限**: 
   - 1日あたり500通まで
   - 1時間あたり100通まで

### エラー: "Invalid login"

- アプリパスワードが間違っている可能性があります
- 新しいアプリパスワードを生成して再試行してください

### エラー: "Username and Password not accepted"

- Googleアカウントで「安全性の低いアプリのアクセス」が無効になっている可能性があります
- アプリパスワードを使用すれば、この設定は不要です

## セキュリティ上の注意

- アプリパスワードは第三者に共有しないでください
- 不要になったアプリパスワードは削除してください
- 定期的にアプリパスワードをローテーションすることを推奨します

## 参考リンク

- [Supabase SMTP設定ドキュメント](https://supabase.com/docs/guides/auth/auth-smtp)
- [Googleアプリパスワードについて](https://support.google.com/accounts/answer/185833)
