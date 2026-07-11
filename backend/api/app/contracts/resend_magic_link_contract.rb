# frozen_string_literal: true

class ResendMagicLinkContract < ApplicationContract
  params do
    required(:email).filled(:string)
  end
end