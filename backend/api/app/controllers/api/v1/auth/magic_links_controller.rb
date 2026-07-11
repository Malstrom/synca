# frozen_string_literal: true

module Api
  module V1
    module Auth
      class MagicLinksController < ApplicationController
        include Dry::Monads[:result]

        def create
          result = ResendMagicLinkContract.new.call(params)

          case result
          in Success(attrs)
            user = User.find_by(email: attrs[:email])

            if user
              case ResendMagicLinkService.call(user: user)
              in Success()
                render_success({ message: I18n.t("controllers.magic_links.success") })
              in Failure([:rate_limit_exceeded, message])
                render_error(:too_many_requests, message)
              end
            else
              render_success({ message: I18n.t("controllers.magic_links.success") })
            end
          in Failure(errors)
            render_error(:unprocessable_entity, errors.to_h)
          end
        end
      end
    end
  end
end