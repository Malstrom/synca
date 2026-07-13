# frozen_string_literal: true

class CreateSparkService
  include Dry::Monads[:result]

  def self.call(...) = new(...).call

  def initialize(current_user:, params:)
    @current_user = current_user
    @params       = params
  end

  def call
    contract_result = CreateSparkContract.new.call(@params)
    return Failure[:contract_invalid, contract_result] if contract_result.failure?

    location_attrs = map_location(contract_result.to_h.fetch(:spark, {}))
    spark = @current_user.initiated_sparks.build(
      session_code: generate_session_code,
      qr_token:     SecureRandom.uuid,
      **location_attrs
    )

    if spark.save
      Success(spark)
    else
      Failure[:validation_failed, spark.errors.full_messages.join(", ")]
    end
  end

  private

    def map_location(attrs)
      result = {}
      result[:location_lat] = attrs[:lat] if attrs.key?(:lat)
      result[:location_lng] = attrs[:lng] if attrs.key?(:lng)
      result
    end

    def generate_session_code
      loop do
        code = SecureRandom.random_number(10**6).to_s.rjust(6, "0")
        break code unless Spark.exists?(session_code: code)
      end
    end
end
