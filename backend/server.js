const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const express = require('express');
const cors = require('cors');
const http = require('http');
const socketIO = require('socket.io');
const morgan = require('morgan');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('./models/user.model');
const config = require('./config/config');
const logger = require('./utils/logger');
const AppError = require('./utils/appError');
const { scheduleDailyRewards } = require('./jobs/referralRewards');
require('./jobs/referralEarningsJob');
const authRoutes = require('./routes/auth.routes');
const walletRoutes = require('./routes/wallet.routes');
const rewardsRoutes = require('./routes/rewards');
const referralRoutes = require('./routes/referral.routes');
const transactionRoutes = require('./routes/transaction.routes');
const marketRoutes = require('./routes/market.routes');
const imagesRoutes = require('./routes/images.routes');
const adminRoutes = require('./routes/admin.routes');
const proxyRoutes = require('./routes/proxy.routes');
const { authenticate } = require('./middleware/auth.middleware');
const nodemailer = require('nodemailer');
const mongoSanitize = require('express-mongo-sanitize');
const xss = require('xss-clean');
const { connectDB } = require('./config/database');
const { initializeFirebase } = require('./config/firebase.config');

const app = express();
const server = http.createServer(app);

// Socket.io setup
const io = socketIO(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
    credentials: true
  },
  path: '/socket.io/',
  pingTimeout: 60000,
  maxHttpBufferSize: 1e6
});

// Socket.io connection handling
io.on('connection', (socket) => {
  logger.info('New client connected:', socket.id);

  // Handle authentication
  socket.on('authenticate', (data) => {
    if (data.userId) {
      socket.join(data.userId);
      logger.info('User authenticated:', data.userId);
    }
  });

  // Handle disconnection
  socket.on('disconnect', () => {
    logger.info('Client disconnected:', socket.id);
  });
});

// Middleware
const allowedOrigins = [
  'https://bitcoincloudmining.web.app',
  'https://bitcoincloudmining.firebaseapp.com',
  'https://web.bitcoincloudmining.onrender.com',
  'https://bitcoincloudmining.onrender.com',
  'http://localhost:3000',
  'http://localhost:5000',
  'http://127.0.0.1:3000',
  'http://127.0.0.1:5000'
];

app.use(cors({
  origin: function (origin, callback) {
    // allow requests with no origin (like mobile apps, curl, etc.)
    if (!origin) return callback(null, true);
    if (
      origin?.includes('localhost') ||
      origin?.includes('127.0.0.1') ||
      origin?.includes('[::1]') ||
      process.env.NODE_ENV === 'development'
    ) {
      return callback(null, true);
    }
    if (allowedOrigins.indexOf(origin) !== -1) {
      return callback(null, true);
    } else {
      return callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH', 'HEAD'],
  allowedHeaders: [
    'Content-Type',
    'Authorization',
    'Accept',
    'X-Requested-With',
    'Origin',
    'Access-Control-Allow-Origin',
    'Access-Control-Allow-Methods',
    'Access-Control-Allow-Headers',
    'Access-Control-Allow-Credentials'
  ],
  preflightContinue: false,
  optionsSuccessStatus: 204,
  maxAge: 86400 // 24 hours
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));
app.use(helmet());
app.use(compression());
app.use(mongoSanitize()); // This will now work
app.use(xss());

// Trust proxy for correct IP detection (Railway, Heroku, etc.)
app.set('trust proxy', true);

// Debug middleware to log all requests
app.use((req, res, next) => {
  logger.info(`Incoming request: ${req.method} ${req.url}`, {
    body: req.body,
    query: req.query,
    params: req.params,
    path: req.path,
    userAgent: req.get('User-Agent'),
    origin: req.get('Origin'),
    ip: req.ip || req.connection.remoteAddress
  });
  next();
});

// Enhanced logging middleware for health check endpoints
app.use('/health', (req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.info(`Health check completed: ${res.statusCode} in ${duration}ms`, {
      method: req.method,
      url: req.url,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      userAgent: req.get('User-Agent'),
      ip: req.ip || req.connection.remoteAddress
    });
  });
  next();
});

app.use('/api/health', (req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.info(`API health check completed: ${res.statusCode} in ${duration}ms`, {
      method: req.method,
      url: req.url,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      userAgent: req.get('User-Agent'),
      ip: req.ip || req.connection.remoteAddress
    });
  });
  next();
});

app.use('/status', (req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.info(`Status check completed: ${res.statusCode} in ${duration}ms`, {
      method: req.method,
      url: req.url,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      userAgent: req.get('User-Agent'),
      ip: req.ip || req.connection.remoteAddress
    });
  });
  next();
});

// Add request timeout middleware
app.use((req, res, next) => {
  req.setTimeout(30000, () => {
    logger.error('Request timeout');
    res.status(408).json({
      success: false,
      message: 'Request timeout'
    });
  });
  next();
});

// Rate limiting with different limits for different endpoints
const generalLimiter = rateLimit({
  windowMs: 10 * 60 * 1000, // 10 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: {
    success: false,
    message: 'Too many requests, please try again later'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 50, // limit each IP to 50 auth requests per windowMs (increased from 5)
  message: {
    success: false,
    message: 'Too many authentication attempts, please try again later'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api', generalLimiter);
app.use('/api/auth', authLimiter);

// Routes
// Mount all routes under /api prefix
logger.info('Registering routes...');
app.use('/api/auth', authRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/rewards', rewardsRoutes);
app.use('/api/referral', referralRoutes);
app.use('/api/referrals', referralRoutes);
app.use('/api/wallet/transactions', transactionRoutes);  // Keep existing wallet transactions route
app.use('/api/market', marketRoutes);
app.use('/api/images', imagesRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/proxy', proxyRoutes);

// Handle transaction claim endpoint
app.post('/api/transactions/claim', authenticate, (req, res) => {
  const transactionController = require('./controllers/transaction.controller');
  return transactionController.claimRejectedTransaction(req, res);
});

app.use('/api/transactions', transactionRoutes);  // Handle other transaction routes

// Root endpoint for health/status
app.get('/', (req, res) => {
  res.status(200).json({
    status: 'ok',
    message: 'Bitcoin Cloud Mining API is running',
    version: '1.0.5',
    timestamp: new Date().toISOString()
  });
});

// Comprehensive health check endpoints for failover system
const getHealthStatus = () => {
  const uptime = process.uptime();
  const memUsage = process.memoryUsage();

  return {
    success: true,
    status: 'healthy',
    message: 'Server is operational',
    timestamp: new Date().toISOString(),
    uptime: {
      seconds: Math.floor(uptime),
      human: `${Math.floor(uptime / 3600)}h ${Math.floor((uptime % 3600) / 60)}m ${Math.floor(uptime % 60)}s`
    },
    memory: {
      used: `${Math.round(memUsage.heapUsed / 1024 / 1024)}MB`,
      total: `${Math.round(memUsage.heapTotal / 1024 / 1024)}MB`,
      percentage: Math.round((memUsage.heapUsed / memUsage.heapTotal) * 100)
    },
    server: {
      platform: process.platform,
      nodeVersion: process.version,
      environment: process.env.NODE_ENV || 'development',
      port: process.env.PORT || 5000
    },
    database: {
      connected: true, // This will be updated below based on actual connection
      name: 'MongoDB'
    }
  };
};

// Primary health check endpoint (fastest response)
app.get('/health', async (req, res) => {
  try {
    const healthData = getHealthStatus();

    // Quick database connectivity check
    try {
      const mongoose = require('mongoose');
      healthData.database.connected = mongoose.connection.readyState === 1;
      healthData.database.status = mongoose.connection.readyState === 1 ? 'connected' : 'disconnected';
    } catch (error) {
      healthData.database.connected = false;
      healthData.database.status = 'error';
      healthData.database.error = error.message;
    }

    // If database is down, still return 200 but mark as degraded
    if (!healthData.database.connected) {
      healthData.status = 'degraded';
      healthData.message = 'Server running but database connection issues';
    }

    res.status(200).json(healthData);
  } catch (error) {
    logger.error('Health check error:', error);
    res.status(503).json({
      success: false,
      status: 'unhealthy',
      message: 'Health check failed',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// API health check endpoint (with more detailed checks)
app.get('/api/health', async (req, res) => {
  try {
    const healthData = getHealthStatus();

    // Enhanced checks for API health
    const checks = {
      server: true,
      database: false,
      auth: false,
      routes: false
    };

    // Database check
    try {
      const mongoose = require('mongoose');
      checks.database = mongoose.connection.readyState === 1;
      healthData.database.connected = checks.database;
      healthData.database.status = checks.database ? 'connected' : 'disconnected';
    } catch (error) {
      healthData.database.error = error.message;
    }

    // Auth service check
    try {
      const jwt = require('jsonwebtoken');
      const testToken = jwt.sign({ test: true }, process.env.JWT_SECRET || 'test', { expiresIn: '1s' });
      checks.auth = !!testToken;
    } catch (error) {
      healthData.auth = { error: error.message };
    }

    // Routes check (basic)
    checks.routes = true;

    healthData.checks = checks;
    healthData.overall = Object.values(checks).every(check => check === true);

    if (!healthData.overall) {
      healthData.status = 'degraded';
      healthData.message = 'Some services are experiencing issues';
    }

    res.status(200).json(healthData);
  } catch (error) {
    logger.error('API health check error:', error);
    res.status(503).json({
      success: false,
      status: 'unhealthy',
      message: 'API health check failed',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Status endpoint (lightweight for load balancers)
app.get('/status', (req, res) => {
  try {
    const uptime = process.uptime();
    res.status(200).json({
      status: 'ok',
      uptime: Math.floor(uptime),
      timestamp: new Date().toISOString(),
      version: '1.0.5'
    });
  } catch (error) {
    res.status(503).json({
      status: 'error',
      message: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Ping endpoint (fastest possible response)
app.get('/ping', (req, res) => {
  res.status(200).send('pong');
});

// HEAD requests for health checks (some load balancers prefer HEAD)
app.head('/', (req, res) => {
  res.status(200).end();
});

app.head('/health', (req, res) => {
  res.status(200).end();
});

app.head('/api/health', (req, res) => {
  res.status(200).end();
});

app.head('/status', (req, res) => {
  res.status(200).end();
});

// Server metrics endpoint (for monitoring)
app.get('/api/metrics', (req, res) => {
  try {
    const uptime = process.uptime();
    const memUsage = process.memoryUsage();
    const cpuUsage = process.cpuUsage();

    res.status(200).json({
      success: true,
      timestamp: new Date().toISOString(),
      uptime: {
        seconds: Math.floor(uptime),
        human: `${Math.floor(uptime / 3600)}h ${Math.floor((uptime % 3600) / 60)}m ${Math.floor(uptime % 60)}s`
      },
      memory: {
        rss: `${Math.round(memUsage.rss / 1024 / 1024)}MB`,
        heapTotal: `${Math.round(memUsage.heapTotal / 1024 / 1024)}MB`,
        heapUsed: `${Math.round(memUsage.heapUsed / 1024 / 1024)}MB`,
        external: `${Math.round(memUsage.external / 1024 / 1024)}MB`,
        heapUsagePercentage: Math.round((memUsage.heapUsed / memUsage.heapTotal) * 100)
      },
      cpu: {
        user: cpuUsage.user,
        system: cpuUsage.system
      },
      process: {
        pid: process.pid,
        platform: process.platform,
        arch: process.arch,
        nodeVersion: process.version,
        title: process.title
      },
      environment: {
        nodeEnv: process.env.NODE_ENV || 'development',
        port: process.env.PORT || 5000,
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone
      }
    });
  } catch (error) {
    logger.error('Metrics endpoint error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get server metrics',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Failover test endpoint (helps verify failover system) - Available in all environments for monitoring
app.get('/api/failover-test', (req, res) => {
  const { action } = req.query;

  if (action === 'identify') {
    // Help identify which backend is responding
    const backendType = process.env.BACKEND_TYPE || 'render';
    const baseUrl = backendType === 'railway'
      ? 'https://bitcoincloudmining-production.up.railway.app'
      : 'https://bitcoincloudmining.onrender.com';

    const serverInfo = {
      success: true,
      backend: backendType,
      baseUrl: baseUrl,
      hostname: require('os').hostname(),
      timestamp: new Date().toISOString(),
      message: `This response is from the ${backendType.toUpperCase()} backend`,
      environment: process.env.NODE_ENV || 'development',
      port: process.env.PORT || 5000,
      headers: {
        'X-Backend-Server': backendType,
        'X-Server-Instance': process.env.HOSTNAME || require('os').hostname(),
        'X-Deploy-Platform': backendType,
        'X-Base-URL': baseUrl
      }
    };

    // Set response headers to identify the backend
    res.set('X-Backend-Server', backendType);
    res.set('X-Server-Instance', process.env.HOSTNAME || require('os').hostname());
    res.set('X-Deploy-Platform', backendType);
    res.set('X-Base-URL', baseUrl);

    res.status(200).json(serverInfo);
  } else if (action === 'delay') {
    // Simulate slow response (for testing failover timing)
    const delay = parseInt(req.query.ms) || 5000;
    setTimeout(() => {
      const backendType = process.env.BACKEND_TYPE || 'render';
      res.status(200).json({
        success: true,
        backend: backendType,
        message: `Response delayed by ${delay}ms from ${backendType.toUpperCase()} backend`,
        timestamp: new Date().toISOString()
      });
    }, delay);
  } else if (action === 'error') {
    // Simulate server error (for testing error handling)
    const backendType = process.env.BACKEND_TYPE || 'render';
    res.status(500).json({
      success: false,
      backend: backendType,
      message: `Simulated server error from ${backendType.toUpperCase()} backend for testing`,
      timestamp: new Date().toISOString()
    });
  } else {
    const backendType = process.env.BACKEND_TYPE || 'render';
    const baseUrl = backendType === 'railway'
      ? 'https://bitcoincloudmining-production.up.railway.app'
      : 'https://bitcoincloudmining.onrender.com';

    res.status(200).json({
      success: true,
      backend: backendType,
      baseUrl: baseUrl,
      message: `Failover test endpoint - ${backendType.toUpperCase()} backend`,
      availableActions: ['identify', 'delay', 'error'],
      usage: {
        identify: `${baseUrl}/api/failover-test?action=identify`,
        delay: `${baseUrl}/api/failover-test?action=delay&ms=3000`,
        error: `${baseUrl}/api/failover-test?action=error`
      },
      timestamp: new Date().toISOString()
    });
  }
});



// 404 handler for unmatched routes
app.use((req, res, next) => {
  logger.info(`Route not found: ${req.method} ${req.url}`);
  res.status(404).json({
    success: false,
    message: `Route ${req.method} ${req.url} not found`
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error details:', {
    message: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
    body: req.body,
    userAgent: req.get('User-Agent'),
    ip: req.ip || req.connection.remoteAddress
  });

  // Log error to logger
  logger.error('Unhandled error:', err);

  // Don't expose internal errors in production
  const isDevelopment = process.env.NODE_ENV === 'development';

  res.status(err.status || 500).json({
    success: false,
    message: isDevelopment ? err.message : 'Internal Server Error',
    error: isDevelopment ? err.stack : 'Something went wrong',
    timestamp: new Date().toISOString()
  });
});

// Ensure valid status codes are used
app.get('/api/rewards', (req, res) => {
  try {
    // Your rewards logic here
    res.status(200).json({
      success: true,
      data: {
        // Your data here
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching rewards',
      error: error.message
    });
  }
});

// Initialize daily referral rewards job
scheduleDailyRewards();

// Get all users endpoint (for debugging)
app.get('/api/debug/users', async (req, res) => {
  try {
    const users = await User.find({});
    console.log('All users:', users);
    res.json({
      status: 'success',
      count: users.length,
      users: users
    });
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({
      status: 'error',
      message: 'Error fetching users'
    });
  }
});

// Health check endpoint for auth
app.get('/api/auth/health', (req, res) => {
  res.json({ status: 'ok', message: 'Auth service is running' });
});

// Email configuration
const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST || 'smtp.gmail.com',
  port: process.env.EMAIL_PORT || 587,
  secure: false,
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

// Initialize Firebase Admin SDK
try {
  initializeFirebase();
} catch (error) {
  console.error('❌ Firebase initialization failed:', error);
}

// Connect to MongoDB
connectDB();

// MongoDB connection events are handled in config/database.js

// Register endpoint
app.post('/auth/register', async (req, res) => {
  try {
    console.log('📥 Received registration request');
    console.log('📝 Request body:', JSON.stringify(req.body, null, 2));

    const { fullName, userName, userEmail, password, referredByCode } = req.body;

    // Validate required fields
    if (!fullName || !userName || !userEmail || !password) {
      console.log('❌ Missing required fields');
      console.log('📝 Fields received:', { fullName, userName, userEmail });
      return res.status(400).json({
        success: false,
        message: 'All fields are required',
        error: 'MISSING_FIELDS'
      });
    }

    // Check if user already exists
    const existingUser = await User.findOne({
      $or: [
        { userEmail },
        { userName }
      ]
    });

    if (existingUser) {
      console.log('❌ User already exists');
      return res.status(400).json({
        success: false,
        message: 'User with this email or username already exists',
        error: 'USER_EXISTS'
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create new user
    const newUser = new User({
      fullName,
      userName,
      userEmail,
      password: hashedPassword,
      referredByCode: referredByCode || null,
    });

    await newUser.save();
    console.log('✅ User created successfully');

    // Generate token
    const token = jwt.sign(
      {
        userId: newUser._id,
        userName: newUser.userName,
        userEmail: newUser.userEmail,
        role: newUser.role
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || process.env.JWT_EXPIRE || '30d' }
    );

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        user: {
          id: newUser._id,
          fullName: newUser.fullName,
          userName: newUser.userName,
          userEmail: newUser.userEmail,
          role: newUser.role,
        },
        token
      }
    });
  } catch (error) {
    console.error('❌ Error in registration:', error);
    res.status(500).json({
      success: false,
      message: 'An error occurred during registration',
      error: error.message
    });
  }
});

// Claimed rewards info endpoint
const rewardsController = require('./controllers/rewardsController');

// Claimed rewards info endpoint
app.get('/api/rewards/claimed', authenticate, rewardsController.getClaimedRewardsInfo);

// Referral controller
const referralController = require('./controllers/referral.controller');

// Add direct endpoints for referral list and earnings
app.get('/api/referral/list', authenticate, referralController.getReferrals);
app.get('/api/referral/earnings', authenticate, referralController.getReferralEarnings);

// Static folder for images
app.use('/public', express.static(path.join(__dirname, 'public')));

// Start server
const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  logger.info(`Server running on port ${PORT}`);

  // Determine backend type and URL based on environment
  const backendType = process.env.BACKEND_TYPE || 'render';
  const baseUrl = backendType === 'railway'
    ? 'https://bitcoincloudmining-production.up.railway.app'
    : 'https://bitcoincloudmining.onrender.com';

  console.log('\n\x1b[32m%s\x1b[0m', '🚀 Server is running on port:', PORT);
  console.log('\x1b[36m%s\x1b[0m', '🌐 Environment:', process.env.NODE_ENV || 'development', `node server.js`);
  console.log('\x1b[33m%s\x1b[0m', '🔗 Base URL:', baseUrl);
  console.log('\x1b[35m%s\x1b[0m', '📊 Health Endpoints:');
  console.log('   ├─ /health (Primary health check)');
  console.log('   ├─ /api/health (Detailed API health)');
  console.log('   ├─ /status (Lightweight status)');
  console.log('   ├─ /ping (Fastest response)');
  console.log('   └─ /api/metrics (Server metrics)');
  console.log('\x1b[34m%s\x1b[0m', '🔄 Failover System: Ready for Flutter app');

  // Show backend type information
  console.log('\x1b[32m%s\x1b[0m', '🎯 Backend Type:', backendType.toUpperCase());

  // Show both URLs for failover system
  if (process.env.NODE_ENV === 'production') {
    console.log('\x1b[36m%s\x1b[0m', '🔄 Failover URLs:');
    console.log('   ├─ Primary (Render):', 'https://bitcoincloudmining.onrender.com');
    console.log('   └─ Secondary (Railway):', 'https://bitcoincloudmining-production.up.railway.app');
  }

  // Only show test endpoint in development
  if (process.env.NODE_ENV !== 'production') {
    console.log('\x1b[31m%s\x1b[0m', '🧪 Test Endpoint: /api/failover-test');
  }

  console.log('----------------------------------------\n');
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  logger.error('Unhandled Rejection:', err);
  console.error('❌ Unhandled Promise Rejection:', err);
  // Don't exit in production, just log the error
  if (process.env.NODE_ENV === 'development') {
    process.exit(1);
  }
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  logger.error('Uncaught Exception:', err);
  console.error('❌ Uncaught Exception:', err);
  // Don't exit in production, just log the error
  if (process.env.NODE_ENV === 'development') {
    process.exit(1);
  }
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  server.close(() => {
    logger.info('Process terminated');
    process.exit(0);
  });
});

module.exports = { app, server };
