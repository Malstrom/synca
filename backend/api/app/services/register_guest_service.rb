# frozen_string_literal: true

# Registers or retrieves a guest account.
# If an email is supplied and already belongs to an active account, returns
# Failure[:email_already_active]. Otherwise creates (or reuses) a guest user.
#
# @example
#   case RegisterGuestService.call(params: params.to_unsafe_h)
#   in Success(user)                        then render_created(guest_response(user))
#   in Failure[:email_already_active, msg]  then render_error(code: "email_already_active", message: msg)
#   in Failure[:validation_failed, r]       then render_contract_errors(r)
#   end
class RegisterGuestService
  include Dry::Monads[:result]

  def self.call(...) = new(...).call

  def initialize(params:)
    @params = params
  end

  def call
    result = GuestRegistrationContract.new.call(@params)
    return Failure[:validation_failed, result] if result.failure?

    email = result[:auth][:email]&.downcase
    user  = User.find_by(email: email) if email

    if user&.active?
      return Failure[:email_already_active, I18n.t("errors.auth.email_already_active")]
    end

    user ||= User.create!(
      email:         email,
      auth_provider: :email,
      account_type:  :guest
    )

    Success(user)
  end
end
