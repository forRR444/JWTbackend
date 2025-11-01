# Ruby 3.4.5イメージ（ARM64対応）
FROM ruby:3.4.5-slim

# 必要なパッケージをインストール
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev libyaml-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 作業ディレクトリを設定
WORKDIR /app

# GemfileとGemfile.lockをコピー
COPY Gemfile Gemfile.lock ./

# bundlerをインストールしてgem依存関係をインストール
RUN bundle install

# アプリケーションコードをコピー
COPY . .

# ポート3000を公開
EXPOSE 3000

# Railsサーバーを起動
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
