# frozen_string_literal: true

class SparkSessionSerializer
  include Alba::Resource

  attributes :id,
             :session_code,
             :qr_token,
             :status,
             :started_at,
             :location_lat,
             :location_lng
end
