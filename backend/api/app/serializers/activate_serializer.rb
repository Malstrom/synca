# frozen_string_literal: true

class ActivateSerializer
  include Alba::Resource

  attributes :access_token, :refresh_token, :token_type, :account_type

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
