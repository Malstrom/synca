module AuthHelpers
  extend ActiveSupport::Concern

  included do
    include AuthHelpers
  end

  def auth_response(user)
    {
      access_token:  JwtService.access_token(user),
      refresh_token: JwtService.refresh_token(user),
      user: {
        id:            user.id,
        email:         user.email,
        auth_provider: user.auth_provider
      }
    }
  end
end
