# frozen_string_literal: true

class ActivateService
  include Dry::Monads[:result]

  def self.call(...) = new(...).call

  def initialize(params:)
    @params = params
  end

  def call
    contract = ActivateContract.new.call(@params)
    return Failure[:validation_failed, contract] if contract.failure?

    user = User.find_by(magic_link_token: contract[:token])
    return Failure[:not_found] unless user

    if user.magic_link_expired?
      return Failure[:token_expired]
    elsif user.magic_link_token.nil?
      return Failure[:token_already_used]
    elsif user.active?
      return Failure[:account_already_active]
    end

    user.transaction do
      user.update!(
        magic_link_token: nil,
        account_type: :active
      )

      user.create_profile!(display_name: contract[:profile][:display_name])
    end

    Success(user)
  end
end