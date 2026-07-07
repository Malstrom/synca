# frozen_string_literal: true

class SparkSerializer
  include Alba::Resource

  attributes :id,
             :session_code,
             :qr_token,
             :status,
             :started_at,
             :location_lat,
             :location_lng
end
