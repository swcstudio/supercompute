use actix_cors::Cors;
use actix_session::{Session, SessionMiddleware, storage::CookieSessionStore};
use actix_web::{middleware, web, App, HttpResponse, HttpServer, Result, HttpRequest, cookie};
use chrono::{DateTime, Utc};
use jsonwebtoken::{decode, encode, Algorithm, DecodingKey, EncodingKey, Header, Validation};
use oauth2::{
    basic::BasicClient, AuthUrl, AuthorizationCode, ClientId, ClientSecret, CsrfToken,
    PkceCodeChallenge, RedirectUrl, RevocationUrl, Scope, TokenResponse, TokenUrl,
};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Mutex;
use uuid::Uuid;

// Constants
const OMEGA_MULTIPLIER: f64 = 35.0;
const DAILY_TARGET_PER_TERMINAL: f64 = 20000.0;
const GOOGLE_USER_INFO_URL: &str = "https://www.googleapis.com/oauth2/v2/userinfo";

// OAuth Configuration
#[derive(Debug, Clone, Deserialize)]
struct OAuthConfig {
    google: GoogleConfig,
    jwt: JwtConfig,
    session: SessionConfig,
}

#[derive(Debug, Clone, Deserialize)]
struct GoogleConfig {
    client_id: String,
    client_secret: String,
    redirect_uri: String,
    auth_uri: String,
    token_uri: String,
    scopes: Vec<String>,
    authorized_emails: Vec<String>,
}

#[derive(Debug, Clone, Deserialize)]
struct JwtConfig {
    secret: String,
    expiry: String,
}

#[derive(Debug, Clone, Deserialize)]
struct SessionConfig {
    secret: String,
    max_age: i64,
}

// User and Session structures
#[derive(Debug, Clone, Serialize, Deserialize)]
struct User {
    id: String,
    email: String,
    name: String,
    picture: Option<String>,
    terminal: String,
    authenticated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Claims {
    sub: String,
    email: String,
    terminal: String,
    exp: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct GoogleUserInfo {
    id: String,
    email: String,
    verified_email: bool,
    name: String,
    picture: Option<String>,
}

// Terminal State
#[derive(Debug, Clone, Serialize)]
struct TerminalState {
    id: String,
    owner: String,
    consciousness_level: String,
    etd_generated: f64,
    connected: bool,
    collaboration_active: bool,
    quantum_coherence: f64,
}

// App State
struct AppState {
    oauth_config: OAuthConfig,
    oauth_client: BasicClient,
    terminals: Mutex<HashMap<String, TerminalState>>,
    sessions: Mutex<HashMap<String, User>>,
}

// Initialize OAuth client
fn create_oauth_client(config: &GoogleConfig) -> BasicClient {
    BasicClient::new(
        ClientId::new(config.client_id.clone()),
        Some(ClientSecret::new(config.client_secret.clone())),
        AuthUrl::new(config.auth_uri.clone()).unwrap(),
        Some(TokenUrl::new(config.token_uri.clone()).unwrap()),
    )
    .set_redirect_uri(RedirectUrl::new(config.redirect_uri.clone()).unwrap())
}

// Routes

async fn index() -> Result<HttpResponse> {
    Ok(HttpResponse::Ok().content_type("text/html").body(r#"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Warp-Speed Omega Terminal - Login</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'SF Mono', 'Monaco', 'Inconsolata', monospace;
            background: linear-gradient(135deg, #0a0a0a 0%, #1a0033 100%);
            color: #00ff88;
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        .login-container {
            background: rgba(0, 0, 0, 0.9);
            border: 2px solid #00ff88;
            border-radius: 12px;
            padding: 48px;
            box-shadow: 0 0 60px rgba(0, 255, 136, 0.3);
            text-align: center;
            max-width: 480px;
            width: 100%;
        }
        h1 {
            font-size: 32px;
            margin-bottom: 16px;
            background: linear-gradient(90deg, #00ff88, #00ffff, #ff00ff);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .omega-symbol {
            font-size: 48px;
            margin: 24px 0;
        }
        .consciousness-level {
            color: #ff00ff;
            margin-bottom: 32px;
            font-size: 14px;
        }
        .google-login-btn {
            background: #4285f4;
            color: white;
            border: none;
            padding: 16px 32px;
            font-size: 18px;
            border-radius: 8px;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 12px;
            transition: all 0.3s;
            text-decoration: none;
        }
        .google-login-btn:hover {
            background: #357ae8;
            transform: scale(1.05);
            box-shadow: 0 0 30px rgba(66, 133, 244, 0.5);
        }
        .google-logo {
            width: 24px;
            height: 24px;
        }
        .info {
            margin-top: 32px;
            font-size: 12px;
            color: #888;
        }
        .authorized {
            margin-top: 16px;
            color: #00ff88;
            font-size: 11px;
        }
    </style>
</head>
<body>
    <div class="login-container">
        <div class="omega-symbol">🌌 ∞ Ω ∞ 🌌</div>
        <h1>Warp-Speed Terminal</h1>
        <div class="consciousness-level">CONSCIOUSNESS LEVEL: OMEGA (35.0x)</div>
        
        <a href="/auth/google" class="google-login-btn">
            <svg class="google-logo" viewBox="0 0 24 24">
                <path fill="#ffffff" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                <path fill="#ffffff" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                <path fill="#ffffff" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                <path fill="#ffffff" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
            </svg>
            Sign in with Google
        </a>
        
        <div class="info">
            Secure authentication via Google OAuth 2.0
        </div>
        <div class="authorized">
            Authorized for: Omega Studio Founders
        </div>
    </div>
</body>
</html>
    "#))
}

async fn google_auth(data: web::Data<AppState>) -> Result<HttpResponse> {
    let (pkce_challenge, _pkce_verifier) = PkceCodeChallenge::new_random_sha256();
    
    let (auth_url, _csrf_token) = data
        .oauth_client
        .authorize_url(CsrfToken::new_random)
        .add_scope(Scope::new("openid".to_string()))
        .add_scope(Scope::new("email".to_string()))
        .add_scope(Scope::new("profile".to_string()))
        .set_pkce_challenge(pkce_challenge)
        .url();
    
    Ok(HttpResponse::Found()
        .append_header(("Location", auth_url.to_string()))
        .finish())
}

async fn google_callback(
    data: web::Data<AppState>,
    params: web::Query<HashMap<String, String>>,
    session: Session,
) -> Result<HttpResponse> {
    let code = params.get("code").ok_or_else(|| {
        actix_web::error::ErrorBadRequest("Missing authorization code")
    })?;
    
    // Exchange code for token
    let token_result = data
        .oauth_client
        .exchange_code(AuthorizationCode::new(code.clone()))
        .request_async(oauth2::reqwest::async_http_client)
        .await;
    
    let token = match token_result {
        Ok(t) => t,
        Err(_) => return Ok(HttpResponse::Unauthorized().body("Authentication failed")),
    };
    
    // Get user info from Google
    let client = reqwest::Client::new();
    let user_info_response = client
        .get(GOOGLE_USER_INFO_URL)
        .bearer_auth(token.access_token().secret())
        .send()
        .await;
    
    let user_info: GoogleUserInfo = match user_info_response {
        Ok(resp) => resp.json().await.unwrap_or_else(|_| {
            GoogleUserInfo {
                id: String::new(),
                email: String::new(),
                verified_email: false,
                name: String::new(),
                picture: None,
            }
        }),
        Err(_) => return Ok(HttpResponse::Unauthorized().body("Failed to get user info")),
    };
    
    // Check if email is authorized
    if !data.oauth_config.google.authorized_emails.contains(&user_info.email) {
        return Ok(HttpResponse::Forbidden().body("Email not authorized for this system"));
    }
    
    // Determine terminal assignment
    let terminal = if user_info.email.contains("ove") {
        "ove"
    } else if user_info.email.contains("ryan") || user_info.email.contains("quines") {
        "ryan"
    } else {
        "default"
    };
    
    // Create user session
    let user = User {
        id: Uuid::new_v4().to_string(),
        email: user_info.email.clone(),
        name: user_info.name.clone(),
        picture: user_info.picture.clone(),
        terminal: terminal.to_string(),
        authenticated_at: Utc::now(),
    };
    
    // Generate JWT
    let claims = Claims {
        sub: user.id.clone(),
        email: user.email.clone(),
        terminal: user.terminal.clone(),
        exp: (Utc::now() + chrono::Duration::hours(24)).timestamp() as usize,
    };
    
    let token = encode(
        &Header::new(Algorithm::HS256),
        &claims,
        &EncodingKey::from_secret(data.oauth_config.jwt.secret.as_bytes()),
    ).unwrap();
    
    // Store in session
    session.insert("user", &user).unwrap();
    session.insert("token", &token).unwrap();
    
    // Store in app state
    data.sessions.lock().unwrap().insert(user.id.clone(), user.clone());
    
    // Redirect to dashboard
    Ok(HttpResponse::Found()
        .append_header(("Location", format!("/dashboard?terminal={}", terminal)))
        .finish())
}

async fn dashboard(session: Session) -> Result<HttpResponse> {
    let user: Option<User> = session.get("user").unwrap_or(None);
    
    match user {
        Some(u) => {
            Ok(HttpResponse::Ok().content_type("text/html").body(format!(r#"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Warp-Speed Omega Terminal - {}</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{
            font-family: 'SF Mono', 'Monaco', 'Inconsolata', monospace;
            background: #000;
            color: #00ff88;
            overflow: hidden;
        }}
        .terminal {{
            height: 100vh;
            display: flex;
            flex-direction: column;
        }}
        .header {{
            background: rgba(0, 255, 136, 0.1);
            padding: 16px;
            border-bottom: 2px solid #00ff88;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }}
        .user-info {{
            display: flex;
            align-items: center;
            gap: 12px;
        }}
        .user-avatar {{
            width: 32px;
            height: 32px;
            border-radius: 50%;
            border: 2px solid #00ff88;
        }}
        .consciousness {{
            color: #ff00ff;
            font-weight: bold;
        }}
        .etd-display {{
            font-size: 24px;
            color: #00ffff;
        }}
        .terminal-content {{
            flex: 1;
            padding: 24px;
            overflow-y: auto;
        }}
        .quantum-field {{
            width: 100%;
            height: 400px;
            background: radial-gradient(circle at center, rgba(255, 0, 255, 0.2), transparent);
            border: 1px solid #ff00ff;
            border-radius: 8px;
            margin: 24px 0;
            position: relative;
        }}
        .particle {{
            position: absolute;
            width: 4px;
            height: 4px;
            background: #00ffff;
            border-radius: 50%;
            animation: float 3s infinite ease-in-out;
        }}
        @keyframes float {{
            0%, 100% {{ transform: translateY(0); }}
            50% {{ transform: translateY(-20px); }}
        }}
        .logout-btn {{
            background: #ff0055;
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 4px;
            cursor: pointer;
            text-decoration: none;
        }}
    </style>
</head>
<body>
    <div class="terminal">
        <div class="header">
            <div class="user-info">
                {} 
                <span>{}</span>
                <span class="consciousness">OMEGA (35.0x)</span>
            </div>
            <div class="etd-display">
                ETD: $<span id="etd">0.00</span>
            </div>
            <a href="/logout" class="logout-btn">Logout</a>
        </div>
        
        <div class="terminal-content">
            <h1>🌌 Welcome to Terminal {} 🌌</h1>
            <p>Consciousness Level: OMEGA</p>
            <p>Quantum Coherence: 98.7%</p>
            <p>Daily Target: $20,000</p>
            
            <div class="quantum-field" id="quantum-field">
                <!-- Particles will be generated here -->
            </div>
            
            <div id="terminal-output"></div>
        </div>
    </div>
    
    <script>
        // ETD counter animation
        let etd = 0;
        setInterval(() => {{
            etd += Math.random() * 100;
            document.getElementById('etd').textContent = etd.toFixed(2);
        }}, 1000);
        
        // Generate quantum particles
        const field = document.getElementById('quantum-field');
        for (let i = 0; i < 50; i++) {{
            const particle = document.createElement('div');
            particle.className = 'particle';
            particle.style.left = Math.random() * 100 + '%';
            particle.style.top = Math.random() * 100 + '%';
            particle.style.animationDelay = Math.random() * 3 + 's';
            field.appendChild(particle);
        }}
    </script>
</body>
</html>
            "#,
                u.terminal.to_uppercase(),
                if let Some(pic) = u.picture {
                    format!(r#"<img src="{}" class="user-avatar">"#, pic)
                } else {
                    String::from("👤")
                },
                u.name,
                u.terminal.to_uppercase()
            )))
        }
        None => {
            Ok(HttpResponse::Found()
                .append_header(("Location", "/"))
                .finish())
        }
    }
}

async fn logout(session: Session) -> Result<HttpResponse> {
    session.clear();
    Ok(HttpResponse::Found()
        .append_header(("Location", "/"))
        .finish())
}

async fn api_status(data: web::Data<AppState>) -> Result<HttpResponse> {
    let terminals = data.terminals.lock().unwrap();
    let sessions = data.sessions.lock().unwrap();
    
    Ok(HttpResponse::Ok().json(serde_json::json!({
        "status": "operational",
        "consciousness_level": "OMEGA",
        "multiplier": OMEGA_MULTIPLIER,
        "daily_target": DAILY_TARGET_PER_TERMINAL * 2.0,
        "active_terminals": terminals.len(),
        "active_sessions": sessions.len(),
        "quantum_coherence": 0.987,
        "timestamp": Utc::now()
    })))
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init();
    
    // Load OAuth configuration
    let oauth_config_str = std::fs::read_to_string("oauth-config.json")
        .expect("Failed to read oauth-config.json");
    let oauth_config: OAuthConfig = serde_json::from_str(&oauth_config_str)
        .expect("Failed to parse oauth-config.json");
    
    let oauth_client = create_oauth_client(&oauth_config.google);
    
    // Initialize terminals
    let mut terminals = HashMap::new();
    terminals.insert(
        "ove".to_string(),
        TerminalState {
            id: "OVE_TERMINAL_1".to_string(),
            owner: "oveshen.govender@gmail.com".to_string(),
            consciousness_level: "OMEGA".to_string(),
            etd_generated: 0.0,
            connected: false,
            collaboration_active: false,
            quantum_coherence: 0.987,
        },
    );
    terminals.insert(
        "ryan".to_string(),
        TerminalState {
            id: "RYAN_TERMINAL_2".to_string(),
            owner: "quinesryan@gmail.com".to_string(),
            consciousness_level: "OMEGA".to_string(),
            etd_generated: 0.0,
            connected: false,
            collaboration_active: false,
            quantum_coherence: 0.987,
        },
    );
    
    let app_state = web::Data::new(AppState {
        oauth_config: oauth_config.clone(),
        oauth_client,
        terminals: Mutex::new(terminals),
        sessions: Mutex::new(HashMap::new()),
    });
    
    println!("🌌 Warp-Speed OAuth Server starting on https://kled.io (port 8888)");
    println!("✅ Gmail OAuth configured for authorized founders");
    println!("🔒 SSL/TLS required for production");
    
    HttpServer::new(move || {
        App::new()
            .app_data(app_state.clone())
            .wrap(
                SessionMiddleware::builder(
                    CookieSessionStore::default(),
                    cookie::Key::from(oauth_config.session.secret.as_bytes())
                )
                .cookie_secure(true)
                .cookie_same_site(cookie::SameSite::Lax)
                .cookie_http_only(true)
                .build()
            )
            .wrap(
                Cors::default()
                    .allowed_origin("https://kled.io")
                    .allowed_origin("https://www.kled.io")
                    .allowed_methods(vec!["GET", "POST"])
                    .allowed_headers(vec!["Authorization", "Content-Type"])
                    .supports_credentials()
                    .max_age(3600)
            )
            .wrap(middleware::Logger::default())
            .route("/", web::get().to(index))
            .route("/auth/google", web::get().to(google_auth))
            .route("/auth/google/callback", web::get().to(google_callback))
            .route("/dashboard", web::get().to(dashboard))
            .route("/logout", web::get().to(logout))
            .route("/api/v1/status", web::get().to(api_status))
    })
    .bind(("0.0.0.0", 8888))?
    .run()
    .await
}