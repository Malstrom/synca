# Error tracking via GlitchTip (Sentry-compatible open-source)
# Self-hosted as a Kamal accessory on the same VPS.
# Set SENTRY_DSN in credentials or environment to activate.
return unless ENV["SENTRY_DSN"].present?

Sentry.init do |config|
  config.dsn                  = ENV["SENTRY_DSN"]
  config.breadcrumbs_logger   = [ :active_support_logger, :http_logger ]
  config.traces_sample_rate   = Rails.env.production? ? 0.1 : 0.0
  config.profiles_sample_rate = 0.0
  config.environment          = Rails.env
end
