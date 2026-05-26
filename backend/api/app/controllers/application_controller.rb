class ApplicationController < ActionController::API
  include ApiResponse

  before_action :authenticate_user!

  private

  def authenticate_user!
    token = request.headers["Authorization"]&.split(" ")&.last
    return render_unauthorized unless token

    payload = JwtService.decode(token)
    return render_unauthorized unless payload

    @current_user = User.find_by(id: payload["sub"])
    render_unauthorized unless @current_user
  rescue JWT::DecodeError
    render_unauthorized
  end

  def current_user
    @current_user
  end
end
