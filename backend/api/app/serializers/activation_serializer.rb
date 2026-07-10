# frozen_string_literal: true

class ActivationSerializer
  include Alba::Resource

  attributes :access_token,
             :refresh_token,
             :token_type,
             :account_type
end