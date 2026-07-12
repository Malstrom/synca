# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ResendMagicLinkController < ApplicationController
        include Dry::Monads[:result]

        def create
          user = User.find_by(email: params[:email])

          if user&.guest?
            case MagicLinkService.call(user: user)
            in Success(user)
              GuestMailer.magic_link_email(user).deliver_later
            in Failure([:rate_limited, _])
              render_error(status: :too_many_requests, code: :rate_limited)
              return
            end
          end

          render_success({ message: I18n.t("services.magic_link.resend_success") })
        end
      end
    end
  end
end
```

```