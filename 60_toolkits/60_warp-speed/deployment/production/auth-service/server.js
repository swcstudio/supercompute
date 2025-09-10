// Secure Authentication Service for Warp-Speed Founders Platform
const express = require('express');
const helmet = require('helmet');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const passport = require('passport');
const OAuth2Strategy = require('passport-oauth2').Strategy;
const JwtStrategy = require('passport-jwt').Strategy;
const ExtractJwt = require('passport-jwt').ExtractJwt;
const speakeasy = require('speakeasy');
const QRCode = require('qrcode');
const session = require('express-session');
const RedisStore = require('connect-redis').default;
const redis = require('redis');
const rateLimit = require('express-rate-limit');
const { body, validationResult } = require('express-validator');
const winston = require('winston');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 8443;

// Configure Winston logger with security audit trail
const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
    ),
    transports: [
        new winston.transports.File({ filename: '/var/log/audit/security.log', level: 'info' }),
        new winston.transports.File({ filename: '/var/log/audit/error.log', level: 'error' }),
        new winston.transports.Console({
            format: winston.format.simple()
        })
    ]
});

// Security middleware
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            scriptSrc: ["'self'"],
            imgSrc: ["'self'", "data:", "https:"],
        },
    },
    hsts: {
        maxAge: 31536000,
        includeSubDomains: true,
        preload: true
    }
}));

// CORS configuration
app.use(cors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || ['https://founders.warp-speed.tech'],
    credentials: true,
    optionsSuccessStatus: 200
}));

// Body parser
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Redis client for session storage
const redisClient = redis.createClient({
    url: process.env.REDIS_URL || 'redis://redis-service:6379',
    legacyMode: false
});

redisClient.connect().catch(console.error);

// Session configuration
app.use(session({
    store: new RedisStore({ client: redisClient }),
    secret: process.env.SESSION_SECRET || uuidv4(),
    resave: false,
    saveUninitialized: false,
    cookie: {
        secure: true,
        httpOnly: true,
        maxAge: 1000 * 60 * 60, // 1 hour
        sameSite: 'strict'
    }
}));

// Rate limiting
const loginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 5, // 5 requests per window
    message: 'Too many login attempts, please try again later',
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res) => {
        logger.warn('Rate limit exceeded', {
            ip: req.ip,
            path: req.path,
            user: req.body.username
        });
        res.status(429).json({
            error: 'Too many login attempts, please try again later'
        });
    }
});

const apiLimiter = rateLimit({
    windowMs: 1 * 60 * 1000, // 1 minute
    max: 100, // 100 requests per minute
    message: 'API rate limit exceeded'
});

// Initialize Passport
app.use(passport.initialize());
app.use(passport.session());

// OAuth2 Strategy
passport.use(new OAuth2Strategy({
    authorizationURL: process.env.OAUTH_AUTHORIZE_URL,
    tokenURL: process.env.OAUTH_TOKEN_URL,
    clientID: process.env.OAUTH_CLIENT_ID,
    clientSecret: process.env.OAUTH_CLIENT_SECRET,
    callbackURL: process.env.OAUTH_CALLBACK_URL
}, async (accessToken, refreshToken, profile, done) => {
    try {
        // Validate user and create/update in database
        logger.info('OAuth2 authentication successful', {
            userId: profile.id,
            provider: 'oauth2'
        });
        return done(null, profile);
    } catch (error) {
        logger.error('OAuth2 authentication failed', { error: error.message });
        return done(error);
    }
}));

// JWT Strategy
const jwtOptions = {
    jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
    secretOrKey: process.env.JWT_SECRET,
    algorithms: ['HS256']
};

passport.use(new JwtStrategy(jwtOptions, async (payload, done) => {
    try {
        // Validate JWT payload
        if (payload.exp < Date.now() / 1000) {
            return done(null, false, { message: 'Token expired' });
        }
        
        logger.info('JWT authentication successful', {
            userId: payload.sub,
            sessionId: payload.jti
        });
        
        return done(null, payload);
    } catch (error) {
        logger.error('JWT authentication failed', { error: error.message });
        return done(error);
    }
}));

// IP Whitelist Middleware
const ipWhitelist = (process.env.IP_WHITELIST || '').split(',').filter(Boolean);

const checkIPWhitelist = (req, res, next) => {
    const clientIP = req.ip || req.connection.remoteAddress;
    
    if (ipWhitelist.length > 0 && !ipWhitelist.includes(clientIP)) {
        logger.warn('IP whitelist violation', {
            ip: clientIP,
            path: req.path
        });
        return res.status(403).json({ error: 'Access denied' });
    }
    
    next();
};

// Authentication Routes

// Login endpoint
app.post('/auth/login', 
    loginLimiter,
    checkIPWhitelist,
    [
        body('username').isEmail().normalizeEmail(),
        body('password').isLength({ min: 12 }),
        body('mfa_token').optional().isLength({ min: 6, max: 6 })
    ],
    async (req, res) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            logger.warn('Login validation failed', {
                errors: errors.array(),
                username: req.body.username
            });
            return res.status(400).json({ errors: errors.array() });
        }

        const { username, password, mfa_token } = req.body;

        try {
            // Get user from secure storage (would be database in production)
            const userHash = await getUserHash(username);
            
            if (!userHash) {
                logger.warn('Login attempt for non-existent user', { username });
                return res.status(401).json({ error: 'Invalid credentials' });
            }

            // Verify password
            const validPassword = await bcrypt.compare(password, userHash);
            
            if (!validPassword) {
                logger.warn('Invalid password attempt', { username });
                return res.status(401).json({ error: 'Invalid credentials' });
            }

            // Verify MFA if enabled
            const mfaSecret = await getUserMFASecret(username);
            if (mfaSecret) {
                if (!mfa_token) {
                    return res.status(401).json({ 
                        error: 'MFA token required',
                        mfa_required: true 
                    });
                }

                const verified = speakeasy.totp.verify({
                    secret: mfaSecret,
                    encoding: 'base32',
                    token: mfa_token,
                    window: 2
                });

                if (!verified) {
                    logger.warn('Invalid MFA token', { username });
                    return res.status(401).json({ error: 'Invalid MFA token' });
                }
            }

            // Generate JWT
            const token = jwt.sign(
                {
                    sub: username,
                    jti: uuidv4(),
                    iat: Math.floor(Date.now() / 1000),
                    exp: Math.floor(Date.now() / 1000) + (60 * 60) // 1 hour
                },
                process.env.JWT_SECRET,
                { algorithm: 'HS256' }
            );

            // Log successful authentication
            logger.info('Successful login', {
                username,
                ip: req.ip,
                sessionId: req.session.id
            });

            res.json({
                success: true,
                token,
                expires_in: 3600
            });

        } catch (error) {
            logger.error('Login error', { error: error.message, username });
            res.status(500).json({ error: 'Authentication failed' });
        }
    }
);

// MFA Setup endpoint
app.post('/auth/mfa/setup',
    passport.authenticate('jwt', { session: false }),
    async (req, res) => {
        try {
            const username = req.user.sub;
            
            // Generate secret
            const secret = speakeasy.generateSecret({
                name: `WarpSpeed (${username})`,
                length: 32
            });

            // Generate QR code
            const qrCodeUrl = await QRCode.toDataURL(secret.otpauth_url);

            // Store secret securely (would be encrypted in database)
            await storeUserMFASecret(username, secret.base32);

            logger.info('MFA setup initiated', { username });

            res.json({
                secret: secret.base32,
                qr_code: qrCodeUrl
            });

        } catch (error) {
            logger.error('MFA setup error', { error: error.message });
            res.status(500).json({ error: 'MFA setup failed' });
        }
    }
);

// Token refresh endpoint
app.post('/auth/refresh',
    passport.authenticate('jwt', { session: false }),
    async (req, res) => {
        try {
            const username = req.user.sub;
            
            // Generate new token
            const token = jwt.sign(
                {
                    sub: username,
                    jti: uuidv4(),
                    iat: Math.floor(Date.now() / 1000),
                    exp: Math.floor(Date.now() / 1000) + (60 * 60)
                },
                process.env.JWT_SECRET,
                { algorithm: 'HS256' }
            );

            logger.info('Token refreshed', { username });

            res.json({
                success: true,
                token,
                expires_in: 3600
            });

        } catch (error) {
            logger.error('Token refresh error', { error: error.message });
            res.status(500).json({ error: 'Token refresh failed' });
        }
    }
);

// Logout endpoint
app.post('/auth/logout',
    passport.authenticate('jwt', { session: false }),
    async (req, res) => {
        try {
            const username = req.user.sub;
            
            // Invalidate session
            req.session.destroy((err) => {
                if (err) {
                    logger.error('Session destruction error', { error: err.message });
                }
            });

            logger.info('User logged out', { username });

            res.json({ success: true });

        } catch (error) {
            logger.error('Logout error', { error: error.message });
            res.status(500).json({ error: 'Logout failed' });
        }
    }
);

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString()
    });
});

// Helper functions (would be database operations in production)
async function getUserHash(username) {
    // This would query a secure database
    // For demo purposes, returning from environment
    if (username === 'ove@warp-speed.tech') {
        return process.env.OVE_PASSWORD_HASH;
    } else if (username === 'ryan@warp-speed.tech') {
        return process.env.RYAN_PASSWORD_HASH;
    }
    return null;
}

async function getUserMFASecret(username) {
    // This would query a secure database
    if (username === 'ove@warp-speed.tech') {
        return process.env.OVE_MFA_SECRET;
    } else if (username === 'ryan@warp-speed.tech') {
        return process.env.RYAN_MFA_SECRET;
    }
    return null;
}

async function storeUserMFASecret(username, secret) {
    // This would store in a secure database
    logger.info('MFA secret stored', { username });
    return true;
}

// Error handling middleware
app.use((err, req, res, next) => {
    logger.error('Unhandled error', {
        error: err.message,
        stack: err.stack,
        path: req.path,
        method: req.method
    });
    
    res.status(500).json({
        error: 'Internal server error'
    });
});

// Start server
app.listen(PORT, () => {
    logger.info(`Secure authentication service running on port ${PORT}`);
    console.log(`🔐 Auth service ready on port ${PORT}`);
});