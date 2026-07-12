# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::ActivateControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:guest_user)
    @user.generate_magic_link_token!
    @token = @user.magic_link_token
  end

  test "activate with valid token and display_name" do
    post api_v1_auth_activate_path, params: {
      token: @token,
      profile: { display_name: "New Name" }
    }

    assert_response :success
    assert_equal "active", @user.reload.account_type
    assert_nil @user.reload.magic_link_token
    assert_equal "New Name", @user.profile.reload.display_name
  end

  test "second use of same token" do
    @user.update!(account_type: :active, magic_link_token: nil)

    post api_v1_auth_activate_path, params: {
      token: @token,
      profile: { display_name: "New Name" }
    }

    assert_response :unprocessable_entity
    assert_equal "token_already_used", json_response["error"]["code"]
  end

  test "expired token" do
    @user.update!(magic_link_sent_at: 73.hours.ago)

    post api_v1_auth_activate_path, params: {
      token: @token,
      profile: { display_name: "New Name" }
    }

    assert_response :unprocessable_entity
    assert_equal "token_expired", json_response["error"]["code"]
  end

  test "account already active" do
    @user.update!(account_type: :active)

    post api_v1_auth_activate_path, params: {
      token: @token,
      profile: { display_name: "New Name" }
    }

    assert_response :unprocessable_entity
    assert_equal "account_already_active", json_response["error"]["code"]
  end

  test "token not found" do
    post api_v1_auth_activate_path, params: {
      token: "invalid_token",
      profile: { display_name: "New Name" }
    }

    assert_response :not_found
    assert_equal "token_not_found", json_response["error"]["code"]
  end
end
```

```