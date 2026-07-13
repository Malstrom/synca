# frozen_string_literal: true

class SparkScoringJob < ApplicationJob
  queue_as :spark
  limits_concurrency to: 1, key: ->(job) { job.arguments.first }

  def perform(spark_id)
    SparkScoringService.call(spark_id)
  end
end
