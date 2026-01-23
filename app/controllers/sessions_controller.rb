class SessionsController < ApplicationController
  # GET /auth/:provider/callback
  def create
    auth_hash = request.env["omniauth.auth"]

    begin
      @user = User.from_omniauth(auth_hash)
      session[:user_id] = @user.id

      # Handle Steam-specific post-authentication checks
      if auth_hash["provider"] == "steam" || auth_hash["provider"] == "steam_custom"
        handle_steam_authentication(@user)
      else
        flash[:notice] = "Successfully authenticated with #{auth_hash['provider'].titleize}!"
      end

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

  # POST /steam/refresh_profile
  def refresh_steam_profile
    unless current_user&.steam_connected?
      flash[:alert] = "No Steam account connected."
      redirect_to user_games_path and return
    end

    identity = current_user.steam_identity
    visibility_data = identity.refresh_steam_visibility!

    if visibility_data
      if identity.public_profile?
        flash[:notice] = "Steam profile refreshed! Your profile is public and ready for syncing."
      elsif identity.private_profile?
        flash[:alert] = "Steam profile refreshed. Your profile is still set to Private. Please change your Steam privacy settings to Public."
      else
        flash[:alert] = "Steam profile refreshed. Your profile visibility is set to #{identity.profile_visibility.titleize}. Please change to Public for full access."
      end
    else
      flash[:alert] = "Failed to refresh Steam profile. Please try again later."
    end

    redirect_to user_games_path
  end

  private

  def handle_steam_authentication(user)
    identity = user.identities.find_by(provider: "steam")
    return unless identity

    # Check Steam profile visibility
    visibility_data = identity.refresh_steam_visibility!

    if visibility_data.nil?
      flash[:alert] = "Successfully authenticated with Steam, but we couldn't verify your profile visibility. Please try again later."
    elsif !identity.profile_configured
      flash[:alert] = "Successfully authenticated with Steam! However, your Steam community profile is not set up. Please configure your Steam profile to enable game library syncing."
    elsif identity.public_profile?
      flash[:notice] = "Successfully authenticated with Steam! Your profile is public and ready for game syncing."
    elsif identity.private_profile?
      flash[:alert] = "Successfully authenticated with Steam! However, your profile is set to Private. To sync your game library, please change your Steam profile visibility to Public in your Steam privacy settings."
    else
      flash[:alert] = "Successfully authenticated with Steam! However, your profile visibility is set to Friends Only. To sync your game library, please change your Steam profile visibility to Public in your Steam privacy settings."
    end
  end
end
