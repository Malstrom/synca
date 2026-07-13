# frozen_string_literal: true

# Authenticates a user by email + password.
#
# Returns:
#   Success(user)                              — credentials valid
#   Failure[:validation_failed, errors_hash]  — contract validation failed
#   Failure[:invalid_credentials, message]    — user not found or wrong password
class LoginService
  include Dry::Monads[:result]

  def self.call(...) = new(...).call

  def initialize(params:)
    @params = params
  end

  def call
    contract = LoginContract.new.call(@params)
    return Failure[:validation_failed, contract.errors.to_h] if contract.failure?

    user = User.find_by(email: contract[:auth][:email].downcase)
    unless user&.authenticate(contract[:auth][:password])
      return Failure[:invalid_credentials, I18n.t("errors.auth.invalid_credentials")]
    end

    Success(user)
  end
end
