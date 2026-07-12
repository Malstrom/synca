# frozen_string_literal: true

class TokensSerializer
  include Alba::Resource

  attribute :access_token do |user|
    JwtService.access_token(user)
  end

  attribute :refresh_token do |user|
    JwtService.refresh_token(user)
  end

  attribute :token_type do
    "Bearer"
  end

  attribute :account_type do |user|
    user.account_type
  end
end