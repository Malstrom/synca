# frozen_string_literal: true

# Composite serializer for GET /api/v1/me.
# Composes UserSerializer, ProfileSerializer, and HealthSummarySerializer.
class MeSerializer
  include Alba::Resource

  # object is the User
  attribute :user do |user|
    UserSerializer.new(user).serializable_hash
  end

  attribute :profile do |user|
    profile = user.profile
    profile ? ProfileSerializer.new(profile).serializable_hash : nil
  end

  attribute :health_summary do |user|
    summary = user.health_summary
    summary ? HealthSummarySerializer.new(summary).serializable_hash : nil
  end
end
