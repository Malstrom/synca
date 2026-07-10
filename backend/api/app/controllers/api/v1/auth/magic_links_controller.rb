# frozen_string_literal: true

module Api
  module V1
    module Auth
      class MagicLinksController < ApplicationController
        include Dry::Monads[:result]

        def create
          case ResendMagicLinkService.call(email: params[:email])
          in Success(message)
            render_success({ message: message })
          in Failure([:rate_limited, message])
            render_error(:too_many_requests, message, code: "rate_limited")
          end
        end
      end
    end
  end
end
