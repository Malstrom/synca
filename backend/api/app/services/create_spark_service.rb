# frozen_string_literal: true

class CreateSparkService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(current_user:, attrs: {})
    spark = current_user.initiated_sparks.build(map_location_attrs(attrs))

    if spark.save
      Success(spark)
    else
      Failure([ :validation_failed, spark.errors.full_messages.first ])
    end
  end

  private

    def map_location_attrs(attrs)
      result = {}
      result[:location_lat] = attrs[:lat] if attrs.key?(:lat)
      result[:location_lng] = attrs[:lng] if attrs.key?(:lng)
      result
    end
end
