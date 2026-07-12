# frozen_string_literal: true

class GuestMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  def magic_link_email(user)
    @user = user
    @token = user.magic_link_token
    @activate_url = activate_url(token: @token)

    mail(to: @user.email, subject: "Activate your account")
  end
end
```

```