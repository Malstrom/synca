# frozen_string_literal: true

class JwtService
  ALGORITHM   = "HS256"
  ACCESS_EXP  = 15.minutes
  REFRESH_EXP = 30.days

  # Prefer explicit env var so CI works without a master key file.
  SECRET = ENV["SECRET_KEY_BASE"].presence || Rails.application.credentials.secret_key_base

  def self.encode(payload, exp: ACCESS_EXP)
    payload = payload.merge(exp: exp.from_now.to_i)
    JWT.encode(payload, SECRET, ALGORITHM)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET, true, { algorithm: ALGORITHM })
    decoded.first
  rescue JWT::ExpiredSignature, JWT::DecodeError
    nil
  end

  # Returns { status: :ok, payload: hash } | { status: :expired, payload: hash } | { status: :invalid }
  def self.decode_with_status(token)
    decoded = JWT.decode(token, SECRET, true, { algorithm: ALGORITHM })
    { status: :ok, payload: decoded.first }
  rescue JWT::ExpiredSignature
    begin
      decoded = JWT.decode(token, SECRET, false, { algorithm: ALGORITHM })
      { status: :expired, payload: decoded.first }
    rescue JWT::DecodeError
      { status: :invalid }
    end
  rescue JWT::DecodeError
    { status: :invalid }
  end

  def self.access_token(user)
    encode({ sub: user.id, type: "access" })
  end

  def self.refresh_token(user)
    encode({ sub: user.id, type: "refresh" }, exp: REFRESH_EXP)
  end
end
