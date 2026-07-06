# frozen_string_literal: true

# Domain settings loaded from config/settings/ YAML files.
# Access via Settings.namespace.key — e.g. Settings.spark.expiry_minutes
# Per-environment overrides: config/settings.{environment}.yml
# Convention: one file per domain area. Do not add hardcoded thresholds
# or numeric limits in contracts or models — define them here.
#
# NOTE: the config gem railtie only loads settings.yml + settings/{env}.yml.
# Domain files in config/settings/*.yml are loaded here by re-invoking
# Config.load_and_set_settings with the full merged file list.
Config.setup do |config|
  config.const_name = "Settings"
  config.fail_on_missing = true
end

Rails.application.config.after_initialize do
  domain_files = Dir[Rails.root.join("config", "settings", "*.yml")].sort
  base_files   = Config.setting_files(Rails.root.join("config"), Rails.env)
  Config.load_and_set_settings(base_files + domain_files)
end
