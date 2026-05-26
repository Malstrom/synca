class JwtService
  ALGORITHM  = "HS256"
  ACCESS_EXP = 15.minutes
  REFRESH_EXP = 30.days

  SECRET = Rails.application.credentials.secret_key_base

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

  def self.access_token(user)
    encode({ sub: user.id, type: "access" })
  end

  def self.refresh_token(user)
    encode({ sub: user.id, type: "refresh" }, exp: REFRESH_EXP)
  end
end
