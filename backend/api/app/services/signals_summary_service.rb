# frozen_string_literal: true

class SignalsSummaryService
  include Dry::Monads[:result]

  def self.call(health_summary:)
    new(health_summary: health_summary).call
  end

  def initialize(health_summary:)
    @health_summary = health_summary
  end

  def call
    Success(health_summary)
  end

  private

    attr_reader :health_summary
end
