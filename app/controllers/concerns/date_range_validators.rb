# 日付パラメータのバリデーションと解析を提供
module DateRangeValidators
  extend ActiveSupport::Concern

  private

  # 日付文字列を安全にパース
  def safe_date_parse(date_string)
    Date.parse(date_string)
  rescue ArgumentError => e
    Rails.logger.warn("Invalid date format: #{date_string} - #{e.message}")
    nil
  end

  # 日付範囲の妥当性を検証
  def valid_date_range?(from_date, to_date)
    return false if from_date.nil? || to_date.nil?
    from_date <= to_date
  end

  # 日付エラーレスポンスをレンダリング
  def render_date_error(message)
    render json: { error: message }, status: :bad_request
  end
end
