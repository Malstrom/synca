# frozen_string_literal: true

class Api::V1::Signals::SummaryController < Api::V1::BaseController
  before_action :authenticate_user!

  def show
    case SignalsSummaryService.call(user: current_user)
    in Success[record]
      render_success(SignalsSummarySerializer.new(record).as_json)
    in Failure[:not_found, message]
      render_error(:not_found, message)
    end
  end
end