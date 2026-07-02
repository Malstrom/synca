# frozen_string_literal: true

class CreateSparkSessionService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(current_user:, attrs: {})
    spark_session = current_user.initiated_spark_sessions.build(map_location_attrs(attrs))

    if spark_session.save
      Success(spark_session)
    else
      Failure([ :validation_failed, spark_session.errors.full_messages.first ])
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
