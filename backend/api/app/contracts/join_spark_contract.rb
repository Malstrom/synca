# frozen_string_literal: true

class JoinSparkContract < Dry::Validation::Contract
  params do
    required(:spark).hash do
      optional(:session_code).maybe(:string)
      optional(:qr_token).maybe(:string)
    end
  end

  rule(:spark) do
    session_code = value[:session_code]
    qr_token     = value[:qr_token]

    if (session_code.nil? || session_code.strip.empty?) && (qr_token.nil? || qr_token.strip.empty?)
      key.failure("either session_code or qr_token must be provided")
    end
  end
end
