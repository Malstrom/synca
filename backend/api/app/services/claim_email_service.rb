# frozen_string_literal: true

# Attaches an email to an already-authenticated (typically anonymous guest)
# user, without creating a new user record — keeps whatever Spark/health data
# is already linked to this session's JWT `sub`.
#
# @example
#   case ClaimEmailService.call(user: current_user, params: params.to_unsafe_h)
#   in Success(user)                  then render_success(UserSerializer.new(user).serializable_hash)
#   in Failure[:email_taken, msg]     then render_error(code: "email_taken", message: msg, field: "email", status: :unprocessable_entity)
#   in Failure[:validation_failed, r] then render_contract_errors(r)
#   end
class ClaimEmailService
  include Dry::Monads[:result]

  def self.call(...) = new(...).call

  def initialize(user:, params:)
    @user = user
    @params = params
  end

  def call
    result = ClaimEmailContract.new.call(@params)
    return Failure[:validation_failed, result] if result.failure?

    @user.update!(email: result[:auth][:email].downcase)
    Success(@user)
  rescue ActiveRecord::RecordNotUnique
    Failure[:email_taken, I18n.t("errors.auth.email_taken")]
  end
end
