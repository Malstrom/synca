# frozen_string_literal: true

class MagicLinkSerializer
  include Alba::Resource

  attribute :access_token
  attribute :refresh_token
  attribute :token_type, default: "Bearer"
  attribute :account_type, default: "active"
end
