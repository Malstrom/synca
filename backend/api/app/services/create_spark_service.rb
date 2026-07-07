# frozen_string_literal: true

class CreateSparkService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(current_user:, attrs: {})
    return Failure([ :already_active, "initiator already has an active Spark" ]) if active_spark?(current_user)

    spark = current_user.initiated_sparks.build(
      session_code: generate_session_code,
      qr_token:     SecureRandom.uuid,
      **map_location_attrs(attrs)
    )

    if spark.save
      Success(spark)
    else
      Failure([ :validation_failed, spark.errors.full_messages.first ])
    end
  end

  private

    def active_spark?(user)
      Spark.where(initiator_id: user.id, status: [ :pending, :active ]).exists?
    end

    def generate_session_code
      loop do
        code = SecureRandom.random_number(10**6).to_s.rjust(6, "0")
        break code unless Spark.exists?(session_code: code)
      end
    end

    def map_location_attrs(attrs)
      result = {}
      result[:location_lat] = attrs[:lat] if attrs.key?(:lat)
      result[:location_lng] = attrs[:lng] if attrs.key?(:lng)
      result
    end
end
