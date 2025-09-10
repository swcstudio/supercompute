# 🔐 Google OAuth Setup Guide for Warp-Speed

## Prerequisites
- Google Cloud Console account
- Domain verified (kled.io)
- SSL certificate installed

## Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing:
   - Project Name: `Warp-Speed-Omega`
   - Project ID: `warp-speed-omega`

## Step 2: Enable Google+ API

1. Navigate to **APIs & Services** > **Library**
2. Search for "Google+ API"
3. Click **Enable**

## Step 3: Configure OAuth Consent Screen

1. Go to **APIs & Services** > **OAuth consent screen**
2. Choose **External** user type
3. Fill in the required information:
   - **App name**: Warp-Speed Omega Terminal
   - **User support email**: oveshen.govender@gmail.com
   - **App logo**: Upload if available
   - **App domain**: kled.io
   - **Authorized domains**: kled.io
   - **Developer contact**: oveshen.govender@gmail.com

4. Add Scopes:
   - `openid`
   - `email`
   - `profile`

5. Add Test Users (while in development):
   - oveshen.govender@gmail.com
   - quinesryan@gmail.com

## Step 4: Create OAuth 2.0 Credentials

1. Go to **APIs & Services** > **Credentials**
2. Click **+ CREATE CREDENTIALS** > **OAuth client ID**
3. Choose **Web application**
4. Configure:
   - **Name**: Warp-Speed Web Client
   - **Authorized JavaScript origins**:
     - `https://kled.io`
     - `https://www.kled.io`
   - **Authorized redirect URIs**:
     - `https://kled.io/auth/google/callback`
     - `https://www.kled.io/auth/google/callback`

5. Click **CREATE**
6. Copy the **Client ID** and **Client Secret**

## Step 5: Update Configuration

1. Edit `/home/ubuntu/src/repos/supercompute/60_toolkits/60_warp-speed/deployment/production/oauth-config.json`

```json
{
  "google": {
    "client_id": "YOUR_ACTUAL_CLIENT_ID.apps.googleusercontent.com",
    "client_secret": "YOUR_ACTUAL_CLIENT_SECRET",
    ...
  }
}
```

2. Update JWT and session secrets with secure random strings:

```bash
# Generate secure secrets
openssl rand -base64 32  # For JWT secret
openssl rand -base64 32  # For session secret
```

## Step 6: Environment Variables

Create `.env` file:

```bash
GOOGLE_CLIENT_ID=your_client_id_here
GOOGLE_CLIENT_SECRET=your_client_secret_here
JWT_SECRET=your_jwt_secret_here
SESSION_SECRET=your_session_secret_here
DATABASE_URL=postgresql://user:pass@localhost/warpspeed
```

## Step 7: Deploy with SSL

1. Ensure SSL is configured:
```bash
sudo ./configure-https.sh
```

2. Build and run the OAuth server:
```bash
cd warp-server-oauth
cargo build --release
./target/release/warp-speed-oauth-server
```

## Security Checklist

- [ ] SSL/HTTPS enabled on kled.io
- [ ] Client ID and Secret stored securely
- [ ] JWT secret is strong and unique
- [ ] Session secret is strong and unique
- [ ] Only authorized emails can login
- [ ] Cookies set with Secure and HttpOnly flags
- [ ] CORS properly configured
- [ ] Rate limiting implemented (optional)

## Testing

1. Navigate to https://kled.io
2. Click "Sign in with Google"
3. Authenticate with authorized Gmail account
4. Verify redirect to dashboard
5. Check terminal assignment (ove/ryan)

## Troubleshooting

### "Redirect URI mismatch" error
- Ensure the redirect URI in Google Console exactly matches the one in your config
- Check for trailing slashes
- Verify HTTPS vs HTTP

### "This app isn't verified" warning
- Normal for development
- Click "Advanced" > "Go to Warp-Speed (unsafe)" during testing
- Submit for verification when ready for production

### SSL Certificate Issues
- Ensure Let's Encrypt certificate is valid
- Check certificate chain is complete
- Verify domain ownership

## Production Checklist

- [ ] Remove test users and go through verification process
- [ ] Enable additional security features (2FA, etc.)
- [ ] Set up monitoring and alerts
- [ ] Configure backup authentication method
- [ ] Document recovery procedures

## Support

- Technical: oveshen.govender@gmail.com
- OAuth Issues: Check Google Cloud Console logs
- Domain/SSL: Verify with `certbot certificates`

---

🌌 ∞ Ω ∞ Secure Authentication Configured ∞ Ω ∞ 🌌