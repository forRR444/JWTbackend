# frozen_string_literal: true

# 日付パラメータのバリデーションと解析

module DateRangeValidators
  extend ActiveSupport::Concern

  private

  # 文字列を日付に変換
  def safe_date_parse(date_string)
    Date.parse(date_string)
  rescue ArgumentError => e
    Rails.logger.warn("Invalid date format: #{date_string} - #{e.message}")
    nil
  end

  # 日付範囲の妥当性を検証
  # # 両方存在、かつfrom <= toの場合のみtrueを返す
  def valid_date_range?(from_date, to_date)
    return false if from_date.nil? || to_date.nil?

    from_date <= to_date
  end

  # 不正な日付入力時のレスポンス
  # ステータス: 400 Bad Request
  def render_date_error(message)
    render json: { error: message }, status: :bad_request
  end
end
