# frozen_string_literal: true

class UserSerializer
  include Alba::Resource

  attributes :id,
            :email,
            :account_type,
            :auth_provider,
            :created_at,
            :updated_at

  attribute :access_token do |user|
    JwtService.encode(user_id: user.id) if user.account_type_active?
  end

  attribute :refresh_token do |user|
    JwtService.encode(user_id: user.id, refresh: true) if user.account_type_active?
  end

  attribute :token_type do |user|
    "Bearer" if user.account_type_active?
  end

  attribute :profile do |user|
    ProfileSerializer.new(user.profile).as_json if user.profile
  end
end