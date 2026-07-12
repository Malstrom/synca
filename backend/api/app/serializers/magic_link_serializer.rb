# frozen_string_literal: true

class MagicLinkSerializer
  include FastJsonapi::ObjectSerializer

  set_type :magic_link

  attributes :access_token, :refresh_token, :token_type, :account_type

  attribute :account_type do |user|
    user.account_type
  end
end