# frozen_string_literal: true

class MagicLinkSerializer
  include Alba::Resource

  attributes :magic_link_token, :magic_link_sent_at

  link :activate do
    activate_url(token: object.magic_link_token)
  end
end