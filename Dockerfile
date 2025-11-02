# ===================================
# Base Stage - 共通のベースイメージ
# ===================================
FROM ruby:3.4.5-slim AS base

# 必要なパッケージをインストール
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev libyaml-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 作業ディレクトリを設定
WORKDIR /app

# ===================================
# Development Stage - 開発環境用
# ===================================
FROM base AS development

# GemfileとGemfile.lockをコピー
COPY Gemfile Gemfile.lock ./

# 全てのgem（development, test含む）をインストール
RUN bundle install

# アプリケーションコードをコピー
COPY . .

# ポート3000を公開
EXPOSE 3000

# Railsサーバーを起動
CMD ["bin/rails", "server", "-b", "0.0.0.0"]

# ===================================
# Production Stage - 本番環境用
# ===================================
FROM base AS production

# GemfileとGemfile.lockをコピー
COPY Gemfile Gemfile.lock ./

# 本番環境用のgemのみインストール（development, testグループを除外）
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install

# アプリケーションコードをコピー
COPY . .

# アセットのプリコンパイル（必要に応じて）
# RUN bundle exec rails assets:precompile

# ポート3000を公開
EXPOSE 3000

# 本番環境でRailsサーバーを起動
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-e", "production"]
