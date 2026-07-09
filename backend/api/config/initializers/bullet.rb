# frozen_string_literal: true

# Bullet — N+1 query detection
# In test: raises an error so the suite fails immediately on any N+1.
# In development: logs to Rails.logger and shows an alert in the browser console.
if defined?(Bullet)
  Bullet.enable = true

  if Rails.env.test?
    Bullet.raise = true
  end

  if Rails.env.development?
    Bullet.rails_logger = true
    Bullet.add_footer    = true
  end
end
