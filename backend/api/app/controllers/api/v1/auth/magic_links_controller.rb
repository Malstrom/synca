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

            if user.present?
              ResendMagicLinkService.call(user: user)
            end

            render_success({ message: I18n.t("controllers.magic_links.resent") })
          in Failure(errors)
            render_unprocessable_entity(errors)
          end
        end
      end
    end
  end
end