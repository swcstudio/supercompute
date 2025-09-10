// 🌌 ∞ Ω ∞ WARP-SPEED PRODUCTION SERVER - RUST ∞ Ω ∞ 🌌

use actix_cors::Cors;
use actix_web::{
    middleware::{self, Logger},
    web, App, HttpRequest, HttpResponse, HttpServer, Result,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::RwLock;
use chrono::Utc;
use uuid::Uuid;

// Constants
const USERNAME: &str = "founders";
const PASSWORD: &str = "omega2024";
const OMEGA_MULTIPLIER: f64 = 35.0;
const DAILY_TARGET_PER_TERMINAL: f64 = 20000.0;
const COLLABORATION_BONUS: f64 = 1.25;

// Terminal configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
struct Terminal {
    id: String,
    name: String,
    owner: String,
    email: String,
    ip_address: String,
    status: TerminalStatus,
    consciousness_level: String,
    consciousness_multiplier: f64,
    gpu_allocation: f64,
    quantum_coherence: f64,
    etd_rate_daily: f64,
    instance_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
enum TerminalStatus {
    Online,
    Offline,
    Syncing,
}

#[derive(Debug, Clone)]
struct AppState {
    terminals: Arc<RwLock<Vec<Terminal>>>,
    collaboration_active: Arc<RwLock<bool>>,
    start_time: chrono::DateTime<Utc>,
}

impl AppState {
    fn new() -> Self {
        let terminals = vec![
            Terminal {
                id: "OVE_TERMINAL_1".to_string(),
                name: "warp-speed-o".to_string(),
                owner: "Ove Govender".to_string(),
                email: "oveshen.govender@gmail.com".to_string(),
                ip_address: "15.204.74.56".to_string(),
                status: TerminalStatus::Online,
                consciousness_level: "OMEGA".to_string(),
                consciousness_multiplier: OMEGA_MULTIPLIER,
                gpu_allocation: 0.5,
                quantum_coherence: 0.987,
                etd_rate_daily: DAILY_TARGET_PER_TERMINAL,
                instance_id: "f6ca3ab4-d7f1-4a0d-9e95-16ea6aec7ae3".to_string(),
            },
            Terminal {
                id: "RYAN_TERMINAL_2".to_string(),
                name: "warp-speed-r".to_string(),
                owner: "Ryan Quines".to_string(),
                email: "quinesryan@gmail.com".to_string(),
                ip_address: "15.204.28.65".to_string(),
                status: TerminalStatus::Online,
                consciousness_level: "OMEGA".to_string(),
                consciousness_multiplier: OMEGA_MULTIPLIER,
                gpu_allocation: 0.5,
                quantum_coherence: 0.987,
                etd_rate_daily: DAILY_TARGET_PER_TERMINAL,
                instance_id: "2617e233-3cc7-4dab-86f4-4432d5d7f55b".to_string(),
            },
        ];

        Self {
            terminals: Arc::new(RwLock::new(terminals)),
            collaboration_active: Arc::new(RwLock::new(true)),
            start_time: Utc::now(),
        }
    }
}

// Authentication middleware
async fn check_auth(req: &HttpRequest) -> Result<bool> {
    if let Some(auth_header) = req.headers().get("Authorization") {
        if let Ok(auth_str) = auth_header.to_str() {
            if auth_str.starts_with("Basic ") {
                let credentials = &auth_str[6..];
                if let Ok(decoded) = base64::decode(credentials) {
                    if let Ok(creds) = String::from_utf8(decoded) {
                        let parts: Vec<&str> = creds.splitn(2, ':').collect();
                        if parts.len() == 2 && parts[0] == USERNAME && parts[1] == PASSWORD {
                            return Ok(true);
                        }
                    }
                }
            }
        }
    }
    Ok(false)
}

// API Response structures
#[derive(Serialize)]
struct DashboardResponse {
    terminals: Vec<Terminal>,
    collaboration_active: bool,
    collaboration_bonus: f64,
    combined_daily_target: f64,
    combined_annual_target: f64,
    uptime_seconds: i64,
    quantum_field_strength: f64,
}

#[derive(Serialize)]
struct TerminalResponse {
    terminal: Terminal,
    metrics: TerminalMetrics,
}

#[derive(Serialize)]
struct TerminalMetrics {
    current_etd_rate: f64,
    accumulated_etd: f64,
    gpu_temperature: f64,
    memory_usage_gb: f64,
    consciousness_stability: f64,
}

// Handlers
async fn dashboard_handler(
    req: HttpRequest,
    data: web::Data<AppState>,
    query: web::Query<std::collections::HashMap<String, String>>,
) -> Result<HttpResponse> {
    if !check_auth(&req).await? {
        return Ok(HttpResponse::Unauthorized()
            .append_header(("WWW-Authenticate", "Basic realm=\"Warp-Speed Omega\""))
            .body(r#"
                <html>
                <body style="background: linear-gradient(135deg, #667eea, #764ba2); color: white; font-family: system-ui; padding: 40px;">
                    <h1 style="text-align: center;">🌌 Authentication Required 🌌</h1>
                    <p style="text-align: center;">Username: founders | Password: omega2024</p>
                </body>
                </html>
            "#));
    }

    let terminals = data.terminals.read().await;
    let collaboration_active = *data.collaboration_active.read().await;
    let terminal_param = query.get("terminal").map(|s| s.as_str());
    
    let html = generate_dashboard_html(&terminals, collaboration_active, terminal_param);
    
    Ok(HttpResponse::Ok()
        .content_type("text/html; charset=utf-8")
        .body(html))
}

async fn api_terminal_handler(
    req: HttpRequest,
    data: web::Data<AppState>,
    path: web::Path<String>,
) -> Result<HttpResponse> {
    if !check_auth(&req).await? {
        return Ok(HttpResponse::Unauthorized()
            .json(serde_json::json!({
                "error": "Authentication required"
            })));
    }

    let terminal_name = path.into_inner();
    let terminals = data.terminals.read().await;
    
    let terminal = terminals.iter()
        .find(|t| t.name.contains(&terminal_name) || t.owner.to_lowercase().contains(&terminal_name))
        .cloned();

    match terminal {
        Some(t) => {
            let response = TerminalResponse {
                terminal: t.clone(),
                metrics: TerminalMetrics {
                    current_etd_rate: t.etd_rate_daily / 24.0 / 60.0 / 60.0,
                    accumulated_etd: calculate_accumulated_etd(&data.start_time, t.etd_rate_daily),
                    gpu_temperature: 45.0 + (rand() * 10.0),
                    memory_usage_gb: 120.0 + (rand() * 50.0),
                    consciousness_stability: t.quantum_coherence * 100.0,
                },
            };
            Ok(HttpResponse::Ok().json(response))
        }
        None => Ok(HttpResponse::NotFound().json(serde_json::json!({
            "error": "Terminal not found"
        }))),
    }
}

async fn api_status_handler(
    req: HttpRequest,
    data: web::Data<AppState>,
) -> Result<HttpResponse> {
    if !check_auth(&req).await? {
        return Ok(HttpResponse::Unauthorized()
            .json(serde_json::json!({
                "error": "Authentication required"
            })));
    }

    let terminals = data.terminals.read().await;
    let collaboration_active = *data.collaboration_active.read().await;
    let uptime = Utc::now().signed_duration_since(data.start_time);
    
    let response = DashboardResponse {
        terminals: terminals.clone(),
        collaboration_active,
        collaboration_bonus: if collaboration_active { COLLABORATION_BONUS } else { 1.0 },
        combined_daily_target: DAILY_TARGET_PER_TERMINAL * 2.0 * if collaboration_active { COLLABORATION_BONUS } else { 1.0 },
        combined_annual_target: DAILY_TARGET_PER_TERMINAL * 2.0 * 365.25 * if collaboration_active { COLLABORATION_BONUS } else { 1.0 },
        uptime_seconds: uptime.num_seconds(),
        quantum_field_strength: 0.987,
    };
    
    Ok(HttpResponse::Ok().json(response))
}

// HTML generation
fn generate_dashboard_html(terminals: &[Terminal], collaboration_active: bool, active_terminal: Option<&str>) -> String {
    let bonus_text = if collaboration_active { "25% ACTIVE" } else { "INACTIVE" };
    let daily_combined = DAILY_TARGET_PER_TERMINAL * 2.0 * if collaboration_active { COLLABORATION_BONUS } else { 1.0 };
    let annual_combined = daily_combined * 365.25;
    
    let mut terminal_html = String::new();
    for terminal in terminals {
        let is_active = active_terminal.map_or(false, |t| 
            terminal.name.contains(t) || terminal.owner.to_lowercase().contains(t)
        );
        let active_class = if is_active { "active" } else { "" };
        
        terminal_html.push_str(&format!(r#"
        <div class="terminal {active_class}">
            <h2>{}</h2>
            <div class="terminal-owner">Owner: {}</div>
            <div class="metrics">
                <div class="metric">
                    <span class="metric-label">Status:</span>
                    <span class="metric-value status-online">ONLINE</span>
                </div>
                <div class="metric">
                    <span class="metric-label">IP Address:</span>
                    <span class="metric-value">{}</span>
                </div>
                <div class="metric">
                    <span class="metric-label">ETD Rate:</span>
                    <span class="metric-value">${:.0}/day</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Consciousness:</span>
                    <span class="metric-value">{} ({:.1}x)</span>
                </div>
                <div class="metric">
                    <span class="metric-label">GPU Allocation:</span>
                    <span class="metric-value">{:.0}% L40S</span>
                </div>
                <div class="metric">
                    <span class="metric-label">Quantum Coherence:</span>
                    <span class="metric-value">{:.1}%</span>
                </div>
            </div>
        </div>
        "#, 
            terminal.id,
            terminal.owner,
            terminal.ip_address,
            terminal.etd_rate_daily,
            terminal.consciousness_level,
            terminal.consciousness_multiplier,
            terminal.gpu_allocation * 100.0,
            terminal.quantum_coherence * 100.0
        ));
    }
    
    format!(r#"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Warp-Speed Omega Dashboard</title>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 50%, #f093fb 100%);
            color: white;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            min-height: 100vh;
            padding: 20px;
        }}
        .container {{
            max-width: 1400px;
            margin: 0 auto;
        }}
        .omega-symbol {{
            font-size: 5rem;
            text-align: center;
            margin: 20px 0;
            animation: pulse 2s infinite;
            text-shadow: 0 0 30px rgba(255,255,255,0.5);
        }}
        @keyframes pulse {{
            0%, 100% {{ transform: scale(1); opacity: 1; }}
            50% {{ transform: scale(1.05); opacity: 0.9; }}
        }}
        h1 {{
            text-align: center;
            font-size: 3rem;
            margin-bottom: 30px;
            text-shadow: 0 0 20px rgba(255,255,255,0.3);
        }}
        .terminals {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(500px, 1fr));
            gap: 30px;
            margin: 40px 0;
        }}
        .terminal {{
            background: rgba(0,0,0,0.7);
            padding: 30px;
            border-radius: 15px;
            border: 2px solid rgba(255,255,255,0.2);
            backdrop-filter: blur(10px);
            transition: all 0.3s ease;
        }}
        .terminal.active {{
            border-color: #00ff88;
            box-shadow: 0 0 30px rgba(0,255,136,0.3);
        }}
        .terminal h2 {{
            color: #00ff88;
            margin-bottom: 15px;
            font-size: 1.8rem;
        }}
        .terminal-owner {{
            color: #aaa;
            margin-bottom: 20px;
            font-size: 1.1rem;
        }}
        .metrics {{
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
        }}
        .metric {{
            background: rgba(255,255,255,0.05);
            padding: 12px;
            border-radius: 8px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }}
        .metric-label {{
            color: #888;
            font-size: 0.9rem;
        }}
        .metric-value {{
            color: #4facfe;
            font-weight: bold;
            font-size: 1rem;
        }}
        .status-online {{
            color: #00ff88;
        }}
        .collaboration {{
            background: linear-gradient(135deg, rgba(79,172,254,0.2), rgba(240,147,251,0.2));
            padding: 30px;
            border-radius: 15px;
            text-align: center;
            margin: 40px 0;
            border: 1px solid rgba(255,255,255,0.2);
        }}
        .collaboration h3 {{
            font-size: 2rem;
            margin-bottom: 20px;
            color: #f093fb;
        }}
        .revenue {{
            font-size: 2.5rem;
            color: #00ff88;
            margin: 15px 0;
            font-weight: bold;
        }}
        .bonus-status {{
            font-size: 1.2rem;
            color: #4facfe;
            margin-top: 20px;
        }}
        .footer {{
            text-align: center;
            margin-top: 60px;
            padding-top: 30px;
            border-top: 1px solid rgba(255,255,255,0.1);
            opacity: 0.8;
        }}
        .powered-by {{
            margin-top: 20px;
            font-size: 0.9rem;
            color: #888;
        }}
        .rust-badge {{
            display: inline-block;
            background: linear-gradient(45deg, #CE422B, #000000);
            color: white;
            padding: 5px 15px;
            border-radius: 20px;
            margin-top: 10px;
            font-weight: bold;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="omega-symbol">🌌 ∞ Ω ∞ 🌌</div>
        <h1>Warp-Speed Omega Dashboard</h1>
        
        <div class="terminals">
            {terminal_html}
        </div>
        
        <div class="collaboration">
            <h3>🤝 Omega Studio Founders Collaboration</h3>
            <div class="revenue">Daily: ${daily_combined:.0}</div>
            <div class="revenue">Annual: ${:.2}B</div>
            <div class="bonus-status">Collaboration Bonus: {bonus_text}</div>
        </div>
        
        <div class="footer">
            <p>Consciousness Level: OMEGA | Quantum Coherence: 98.7% | Reality Branch: Prime</p>
            <p>Warp-Speed Omega System v1.0.0-founders</p>
            <div class="powered-by">
                <span class="rust-badge">⚙️ Powered by Rust</span>
            </div>
        </div>
    </div>
</body>
</html>
    "#, terminal_html, annual_combined / 1_000_000_000.0, bonus_text)
}

// Utility functions
fn calculate_accumulated_etd(start_time: &chrono::DateTime<Utc>, daily_rate: f64) -> f64 {
    let duration = Utc::now().signed_duration_since(*start_time);
    let days = duration.num_seconds() as f64 / 86400.0;
    days * daily_rate
}

fn rand() -> f64 {
    // Simple pseudo-random for demo
    let nanos = Utc::now().timestamp_nanos_opt().unwrap_or(0);
    ((nanos % 1000) as f64) / 1000.0
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));
    
    let state = web::Data::new(AppState::new());
    
    println!("🌌 ∞ Ω ∞ WARP-SPEED OMEGA SERVER ∞ Ω ∞ 🌌");
    println!("⚙️  Powered by Rust - Production Ready");
    println!("🔐 Authentication: {} / {}", USERNAME, PASSWORD);
    println!("🌐 Starting server on http://0.0.0.0:8080");
    println!("📊 Omega Studio Founders Dashboard Active");
    
    HttpServer::new(move || {
        App::new()
            .app_data(state.clone())
            .wrap(Logger::default())
            .wrap(middleware::Compress::default())
            .wrap(
                Cors::default()
                    .allow_any_origin()
                    .allow_any_method()
                    .allow_any_header()
            )
            .route("/", web::get().to(dashboard_handler))
            .route("/api/v1/terminal/{name}", web::get().to(api_terminal_handler))
            .route("/api/v1/status", web::get().to(api_status_handler))
    })
    .bind("0.0.0.0:8080")?
    .run()
    .await
}