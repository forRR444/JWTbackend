# Heroku本番環境セットアップガイド

## 問題の概要

本番環境でJWT認証が失敗していた原因：

1. **BASE_URL環境変数が未設定** → JWTのissuer/audienceが`http://localhost:3000`になっていた
2. **ALLOWED_ORIGINS環境変数が未設定** → CORSエラー
3. **Cookie設定** → クロスオリジン対応のため`SameSite=None`が必要

## Heroku環境変数の設定

以下のコマンドでHerokuに環境変数を設定してください：

```bash
# Herokuアプリ名を確認
heroku apps

# 環境変数を設定（バックエンド）
heroku config:set \
  BASE_URL=https://jwt-backend-api-5baa9f62386d.herokuapp.com \
  ALLOWED_ORIGINS=http://localhost:5173,https://your-frontend-domain.vercel.app \
  COOKIES_SAME_SITE=none \
  RAILS_FORCE_SSL=true \
  APP_HOST=jwt-backend-api-5baa9f62386d.herokuapp.com \
  ACCESS_TOKEN_LIFETIME=10 \
  REFRESH_TOKEN_LIFETIME=1440 \
  --app jwt-backend-api
```

### フロントエンドのデプロイ先URLを追加

フロントエンドをデプロイした後、`ALLOWED_ORIGINS`を更新してください：

```bash
# 例: フロントエンドをVercelにデプロイした場合
heroku config:set \
  ALLOWED_ORIGINS=https://your-frontend-app.vercel.app \
  --app jwt-backend-api
```

## フロントエンドの環境変数

### 本番環境（`.env.production`）

```env
VITE_API_ORIGIN=https://jwt-backend-api-5baa9f62386d.herokuapp.com
```

### デプロイ先での環境変数設定

#### Vercel の場合

1. Vercelダッシュボードでプロジェクトを選択
2. Settings → Environment Variables
3. 以下を追加：
   - Name: `VITE_API_ORIGIN`
   - Value: `https://jwt-backend-api-5baa9f62386d.herokuapp.com`
   - Environment: `Production`

#### Netlify の場合

1. Netlifyダッシュボードでサイトを選択
2. Site settings → Build & deploy → Environment
3. Environment variables に以下を追加：
   - Key: `VITE_API_ORIGIN`
   - Value: `https://jwt-backend-api-5baa9f62386d.herokuapp.com`

## 設定確認

### 1. Heroku環境変数の確認

```bash
heroku config --app jwt-backend-api
```

以下の変数が設定されていることを確認：
- `BASE_URL`
- `ALLOWED_ORIGINS`
- `COOKIES_SAME_SITE`
- `RAILS_FORCE_SSL`
- `APP_HOST`

### 2. デプロイ後の動作確認

#### バックエンド

```bash
# ヘルスチェック
curl https://jwt-backend-api-5baa9f62386d.herokuapp.com/health

# ログイン動作確認
curl -X POST https://jwt-backend-api-5baa9f62386d.herokuapp.com/api/v1/auth_token \
  -H "Content-Type: application/json" \
  -H "X-Requested-With: XMLHttpRequest" \
  -d '{"email":"test@example.com","password":"password"}' \
  -c cookies.txt
```

#### フロントエンド

1. ブラウザでフロントエンドにアクセス
2. 開発者ツールのコンソールを開く
3. ログインを試す
4. エラーがないか確認

## トラブルシューティング

### 401 Unauthorized エラーが続く場合

1. HerokuログでJWTのissuer/audienceを確認：
   ```bash
   heroku logs --tail --app jwt-backend-api
   ```

2. 生成されたトークンをデコード（[jwt.io](https://jwt.io)）して、`iss`と`aud`が正しいか確認

### CORS エラーが出る場合

1. `ALLOWED_ORIGINS`にフロントエンドのURLが含まれているか確認
2. URLにスペースやタイポがないか確認
3. プロトコル（https://）が正しいか確認

### Cookie が送信されない場合

1. `COOKIES_SAME_SITE=none`が設定されているか確認
2. `RAILS_FORCE_SSL=true`が設定されているか確認
3. ブラウザの開発者ツール → Application → Cookies で、`refresh_token`が`Secure; SameSite=None`になっているか確認

## 参考情報

- [Heroku環境変数の管理](https://devcenter.heroku.com/articles/config-vars)
- [クロスオリジンCookie設定](https://developer.mozilla.org/ja/docs/Web/HTTP/Headers/Set-Cookie/SameSite)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)
