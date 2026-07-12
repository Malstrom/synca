# frozen_string_literal: true

class TokenResponseSerializer
  include Alba::Resource

  attributes :access_token, :refresh_token, :token_type, :account_type

  attribute :token_type do
    "Bearer"
  end

  attribute :account_type do
    "active"
  end
end
