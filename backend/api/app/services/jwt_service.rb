# frozen_string_literal: true

class JwtService
  ALGORITHM = "HS256"

  # Prefer explicit env var so CI works without a master key file.
  SECRET = ENV["SECRET_KEY_BASE"].presence || Rails.application.credentials.secret_key_base

  def self.encode(payload, exp:)
    payload = payload.merge(exp: exp.from_now.to_i)
    JWT.encode(payload, SECRET, ALGORITHM)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET, true, { algorithm: ALGORITHM })
    decoded.first
  rescue JWT::ExpiredSignature, JWT::DecodeError
    nil
  end

  def self.access_token(user, exp: Settings.auth.access_token_ttl.seconds)
    encode({ sub: user.id, type: "access" }, exp: exp)
  end

  def self.refresh_token(user, exp: Settings.auth.refresh_token_ttl.seconds)
    encode({ sub: user.id, type: "refresh" }, exp: exp)
  end
end
