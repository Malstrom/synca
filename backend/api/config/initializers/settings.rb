# frozen_string_literal: true

# Domain settings loaded from config/settings/ YAML files.
# Access via Settings.namespace.key — e.g. Settings.spark.expiry_minutes
# Per-environment overrides: config/settings.{environment}.yml
# Convention: one file per domain area. Do not add hardcoded thresholds
# or numeric limits in contracts or models — define them here.
#
# NOTE: the config gem railtie only loads settings.yml + settings/{env}.yml.
# Domain files in config/settings/*.yml are loaded here by re-invoking
# Config.load_and_set_settings with the full merged file list. This must
# happen before eager loading (production boots with eager_load: true and
# references Settings.* at class-definition time, e.g. LoginContract), so
# hook into :before_eager_load rather than :after_initialize.
Config.setup do |config|
  config.const_name = "Settings"
  config.fail_on_missing = true
end

load_domain_settings = -> do
  domain_files = Dir[Rails.root.join("config", "settings", "*.yml")].sort
  base_files   = Config.setting_files(Rails.root.join("config"), Rails.env)
  Config.load_and_set_settings(base_files + domain_files)
end

ActiveSupport.on_load(:before_eager_load) { load_domain_settings.call }
Rails.application.config.after_initialize { load_domain_settings.call unless Rails.application.config.eager_load }
