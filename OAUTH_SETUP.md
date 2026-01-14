# OAuth Authentication Setup Guide

This application uses OAuth2 for authentication with Steam, GOG, Facebook, and Google. No username/password authentication is supported.

## Overview

Users can log in using any of these providers:
- **Steam** - For gamers with Steam accounts
- **GOG** (Good Old Games) - For GOG Galaxy users
- **Facebook** - Social authentication
- **Google** - Google account authentication

## Setup Instructions

### 1. Steam Authentication

1. Get your Steam API key:
   - Visit https://steamcommunity.com/dev/apikey
   - Register for a Steam Web API Key
   - Domain name can be your app's domain or `localhost` for development

2. Add to your `.env` file:
   ```
   STEAM_API_KEY=your_steam_api_key_here
   ```

3. Callback URL: `https://yourdomain.com/auth/steam/callback`

**Note:** Steam uses OpenID, which is slightly different from OAuth2 but works through OmniAuth.

### 2. Google OAuth2

1. Create a Google Cloud project:
   - Go to https://console.cloud.google.com/
   - Create a new project or select existing one
   - Enable Google+ API

2. Create OAuth2 credentials:
   - Navigate to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "OAuth 2.0 Client ID"
   - Application type: "Web application"
   - Authorized redirect URIs:
     - Development: `http://localhost:3000/auth/google_oauth2/callback`
     - Production: `https://yourdomain.com/auth/google_oauth2/callback`

3. Add to your `.env` file:
   ```
   GOOGLE_CLIENT_ID=your_google_client_id
   GOOGLE_CLIENT_SECRET=your_google_client_secret
   ```

### 3. Facebook OAuth

1. Create a Facebook App:
   - Go to https://developers.facebook.com/apps
   - Click "Create App"
   - Choose "Consumer" as app type
   - Fill in app details

2. Configure Facebook Login:
   - In app dashboard, go to "Products" > "Facebook Login" > "Settings"
   - Add OAuth redirect URIs:
     - Development: `http://localhost:3000/auth/facebook/callback`
     - Production: `https://yourdomain.com/auth/facebook/callback`
   - Enable "Client OAuth Login" and "Web OAuth Login"

3. Get App credentials:
   - Go to "Settings" > "Basic"
   - Copy App ID and App Secret

4. Add to your `.env` file:
   ```
   FACEBOOK_APP_ID=your_facebook_app_id
   FACEBOOK_APP_SECRET=your_facebook_app_secret
   ```

### 4. GOG (Good Old Games) OAuth

**Note:** GOG doesn't have an official public OAuth API. This implementation includes a custom strategy that may need adjustments based on GOG's actual API.

1. Register at GOG Developer Portal (if available):
   - Contact GOG for developer access
   - Or check https://devportal.gog.com/

2. Get OAuth credentials (when available)

3. Add to your `.env` file:
   ```
   GOG_CLIENT_ID=your_gog_client_id
   GOG_CLIENT_SECRET=your_gog_client_secret
   ```

**Alternative:** If GOG doesn't provide OAuth, you may need to use their Galaxy API or implement a different integration method.

## Testing OAuth Providers

### Local Development

1. Install ngrok for testing OAuth callbacks locally:
   ```bash
   ngrok http 3000
   ```

2. Use the ngrok URL as your callback URL in OAuth provider settings

3. Update your `.env` with the appropriate callback URLs

### Test Mode

For automated testing, OmniAuth provides test mode:

```ruby
# In test environment
OmniAuth.config.test_mode = true
OmniAuth.config.mock_auth[:google] = OmniAuth::AuthHash.new({
  provider: 'google',
  uid: '12345',
  info: {
    email: 'test@example.com',
    name: 'Test User'
  }
})
```

## Security Considerations

1. **Never commit `.env` file** - It contains sensitive credentials
2. **Use environment variables** - Never hardcode credentials
3. **HTTPS required in production** - OAuth providers require secure callbacks
4. **Validate state parameter** - OmniAuth handles this automatically
5. **Token storage** - Access tokens are stored securely in the database
6. **Token expiration** - The Identity model includes expiration tracking

## Troubleshooting

### "Redirect URI mismatch" error
- Ensure callback URL in provider settings exactly matches your app URL
- Check for http vs https
- Verify trailing slashes match

### Steam authentication fails
- Verify Steam API key is correct
- Check that your domain is properly registered
- Ensure OpenID endpoint is accessible

### Facebook app not working
- Make sure app is not in "Development Mode" for production
- Verify app domain is added to settings
- Check that Facebook Login product is added

### Google OAuth "Access blocked"
- Verify OAuth consent screen is configured
- Check authorized domains are added
- Ensure redirect URI is whitelisted

## Architecture

### Authentication Flow

1. User clicks "Login with [Provider]"
2. Request sent to `/auth/:provider` (e.g., `/auth/google`)
3. OmniAuth redirects to provider's OAuth page
4. User authorizes the application
5. Provider redirects back to `/auth/:provider/callback`
6. SessionsController processes the OAuth data:
   - Creates or finds User record
   - Creates or updates Identity record
   - Stores user ID in session
7. User is redirected to application homepage

### Database Schema

**Users table:**
- `email` - User's email (from OAuth provider)
- `username` - Display name
- `provider` - Primary OAuth provider
- `uid` - Provider's user ID
- `avatar_url` - Profile image URL

**Identities table:**
- `user_id` - Foreign key to users
- `provider` - OAuth provider name
- `uid` - Provider's user ID
- `access_token` - OAuth access token
- `refresh_token` - OAuth refresh token (if available)
- `expires_at` - Token expiration timestamp
- `extra_info` - JSON field for additional provider data

### Helper Methods

Available in all controllers and views:

- `current_user` - Returns the currently logged-in user or nil
- `logged_in?` - Returns true if user is logged in
- `require_login` - Before filter to protect routes

## Links in Views

```erb
<!-- Login buttons -->
<%= button_to "Login with Steam", "/auth/steam", method: :post, class: "btn-steam" %>
<%= button_to "Login with Google", "/auth/google_oauth2", method: :post, class: "btn-google" %>
<%= button_to "Login with Facebook", "/auth/facebook", method: :post, class: "btn-facebook" %>
<%= button_to "Login with GOG", "/auth/gog", method: :post, class: "btn-gog" %>

<!-- Logout -->
<%= button_to "Logout", logout_path, method: :delete, class: "btn-logout" %>

<!-- Show user info -->
<% if logged_in? %>
  <p>Welcome, <%= current_user.username %>!</p>
  <%= image_tag current_user.avatar_url, alt: current_user.username if current_user.avatar_url %>
<% end %>
```

## Production Deployment

1. Set all environment variables in your hosting platform
2. Ensure HTTPS is enabled
3. Update OAuth callback URLs to production domain
4. Run migrations: `rails db:migrate`
5. Verify each OAuth provider works in production

## Additional Resources

- [OmniAuth Documentation](https://github.com/omniauth/omniauth)
- [Steam Web API Documentation](https://developer.valvesoftware.com/wiki/Steam_Web_API)
- [Google OAuth2 Documentation](https://developers.google.com/identity/protocols/oauth2)
- [Facebook Login Documentation](https://developers.facebook.com/docs/facebook-login)
