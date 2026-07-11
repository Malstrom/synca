# frozen_string_literal: true

module Api
  module V1
    module Auth
      class MagicLinksController < ApplicationController
        include Dry::Monads[:result]

        def create
          result = ResendMagicLinkContract.new.call(params)

          case result
          in Success
            user = User.find_by(email: result[:email])

            if user
              resend_result = ResendMagicLinkService.call(user: user)

              case resend_result
              in Success
                render_success({ message: I18n.t("controllers.magic_links.success") })
              in Failure
                render_error(:too_many_requests, resend_result.failure.last)
              end
            else
              render_success({ message: I18n.t("controllers.magic_links.success") })
            end
          in Failure
            render_error(:unprocessable_entity, result.errors.to_h)
          end
        end
      end
    end
  end
end
