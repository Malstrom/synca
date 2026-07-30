# frozen_string_literal: true

class ActivateUserSerializer
  include FastJsonapi::ObjectSerializer

  attribute :access_token do |user|
    AuthTokenService.encode(user_id: user.id)
  end

  attribute :refresh_token do |user|
    AuthTokenService.encode(user_id: user.id, refresh: true)
  end

  attribute :token_type do
    "Bearer"
  end

  attribute :account_type do |user|
    user.account_type
  end
end