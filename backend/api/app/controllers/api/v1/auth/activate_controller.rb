# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivateController < ApplicationController
        include Dry::Monads[:result]

        def create
          case MagicLinkService.call(user: user)
          in Success(user)
            render_success({ user: UserSerializer.new(user).as_json })
          in Failure([:account_already_active, _])
            render_error(status: :unprocessable_entity, code: :account_already_active)
          in Failure([:rate_limited, _])
            render_error(status: :too_many_requests, code: :rate_limited)
          in Failure([:token_not_found, _])
            render_error(status: :not_found, code: :token_not_found)
          in Failure([:token_expired, _])
            render_error(status: :unprocessable_entity, code: :token_expired)
          end
        end

        private

        def user
          @user ||= User.find_by(magic_link_token: params[:token])
        end
      end
    end
  end
end
```

```