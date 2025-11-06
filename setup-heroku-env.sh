#!/bin/bash

# Heroku環境変数設定スクリプト
# 使用方法: ./scripts/setup-heroku-env.sh

# アプリ名
APP_NAME="jwt-backend-api"

# フロントエンドのURL（デプロイ後に変更してください）
FRONTEND_URL="https://your-frontend-domain.vercel.app"

echo "==================================================================="
echo "Heroku環境変数設定スクリプト"
echo "==================================================================="
echo ""
echo "アプリ名: $APP_NAME"
echo ""

# フロントエンドURLの確認
read -p "フロントエンドのデプロイ先URL（例: https://your-app.vercel.app）: " FRONTEND_INPUT
if [ -n "$FRONTEND_INPUT" ]; then
  FRONTEND_URL="$FRONTEND_INPUT"
fi

echo ""
echo "設定する環境変数:"
echo "  BASE_URL=https://jwt-backend-api-5baa9f62386d.herokuapp.com"
echo "  ALLOWED_ORIGINS=http://localhost:5173,$FRONTEND_URL"
echo "  COOKIES_SAME_SITE=none"
echo "  RAILS_FORCE_SSL=true"
echo "  APP_HOST=jwt-backend-api-5baa9f62386d.herokuapp.com"
echo "  ACCESS_TOKEN_LIFETIME=10"
echo "  REFRESH_TOKEN_LIFETIME=1440"
echo ""

read -p "この設定で続行しますか？ [y/N]: " CONFIRM
if [ "$CONFIRM" != "y" ]; then
  echo "キャンセルしました。"
  exit 0
fi

echo ""
echo "環境変数を設定中..."

# Heroku環境変数を設定
heroku config:set \
  BASE_URL=https://jwt-backend-api-5baa9f62386d.herokuapp.com \
  ALLOWED_ORIGINS="http://localhost:5173,$FRONTEND_URL" \
  COOKIES_SAME_SITE=none \
  RAILS_FORCE_SSL=true \
  APP_HOST=jwt-backend-api-5baa9f62386d.herokuapp.com \
  ACCESS_TOKEN_LIFETIME=10 \
  REFRESH_TOKEN_LIFETIME=1440 \
  --app $APP_NAME

if [ $? -eq 0 ]; then
  echo ""
  echo "==================================================================="
  echo "環境変数の設定が完了しました！"
  echo "==================================================================="
  echo ""
  echo "次のステップ:"
  echo "1. コードをコミットしてHerokuにデプロイ"
  echo "   git add ."
  echo "   git commit -m 'Fix production environment configuration'"
  echo "   git push heroku main"
  echo ""
  echo "2. デプロイ後、以下のコマンドで設定を確認"
  echo "   heroku config --app $APP_NAME"
  echo ""
  echo "3. ログを確認してエラーがないかチェック"
  echo "   heroku logs --tail --app $APP_NAME"
  echo "==================================================================="
else
  echo ""
  echo "エラー: 環境変数の設定に失敗しました。"
  echo "Herokuにログインしているか確認してください: heroku login"
  exit 1
fi
