# frozen_string_literal: true

# Registers a new user account.
# Handles email uniqueness at the service level — no rescue in the controller.
#
# @example
#   case RegisterUserService.call(params: params.to_unsafe_h)
#   in Success(user)  then render_created(auth_response(user))
#   in Failure[:email_taken, msg]     then render_error(code: "email_taken", message: msg, field: "email", status: :unprocessable_entity)
#   in Failure[:validation_failed, r] then render_contract_errors(r)
#   end
class RegisterUserService
  include Dry::Monads[:result]

  def self.call(...) = new(...).call

  def initialize(params:)
    @params = params
  end

  def call
    result = RegistrationContract.new.call(@params)
    return Failure[:validation_failed, result] if result.failure?

    user = build_user(result)
    return Failure[:email_taken, I18n.t("errors.auth.email_taken")] unless user.save

    Success(user)
  rescue ActiveRecord::RecordNotUnique
    Failure[:email_taken, I18n.t("errors.auth.email_taken")]
  end

  private

  def build_user(result)
    auth = result[:auth]
    User.new(
      email:         auth[:email]&.downcase,
      phone:         auth[:phone],
      password:      auth[:password],
      provider_uid:  auth[:provider_uid],
      auth_provider: auth[:auth_provider]
    )
  end
end
