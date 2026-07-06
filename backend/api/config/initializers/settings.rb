# frozen_string_literal: true

# Domain settings loaded from config/settings/ YAML files.
# Access via Settings.namespace.key — e.g. Settings.spark.expiry_minutes
# Per-environment overrides: config/settings.{environment}.yml
# Convention: one file per domain area. Do not add hardcoded thresholds
# or numeric limits in contracts or models — define them here.
Config.setup do |config|
  config.const_name = "Settings"
  config.fail_on_missing = true
  config.extra_sources = Dir[Rails.root.join("config", "settings", "*.yml")].sort
end
