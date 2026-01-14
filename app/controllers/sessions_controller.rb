class SessionsController < ApplicationController
  # GET /auth/:provider/callback
  def create
    auth_hash = request.env["omniauth.auth"]

    begin
      @user = User.from_omniauth(auth_hash)
      session[:user_id] = @user.id

      flash[:notice] = "Successfully authenticated with #{auth_hash['provider'].titleize}!"
      redirect_to root_path
    rescue => e
      Rails.logger.error "Authentication error: #{e.message}"
      flash[:alert] = "Authentication failed. Please try again."
      redirect_to root_path
    end
  end

  # GET /auth/failure
  def failure
    flash[:alert] = "Authentication failed: #{params[:message]}"
    redirect_to root_path
  end

  # DELETE /logout
  def destroy
    session.delete(:user_id)
    @current_user = nil
    flash[:notice] = "Successfully logged out."
    redirect_to root_path
  end
end
