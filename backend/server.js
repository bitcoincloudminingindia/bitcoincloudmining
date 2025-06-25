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
const { authenticate } = require('./middleware/auth.middleware');
const nodemailer = require('nodemailer'); // Add this import
const mongoSanitize = require('express-mongo-sanitize'); // Add this import
const xss = require('xss-clean');

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
app.use(cors({
  origin: '*',  // Allow all origins in development
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  credentials: true,
  preflightContinue: false,
  optionsSuccessStatus: 204
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));
app.use(helmet());
app.use(compression());
app.use(mongoSanitize()); // This will now work
app.use(xss());

// Debug middleware to log all requests
app.use((req, res, next) => {
  logger.info(`Incoming request: ${req.method} ${req.url}`, {
    body: req.body,
    query: req.query,
    params: req.params,
    path: req.path
  });
  next();
});

// Rate limiting
const limiter = rateLimit({
  windowMs: 10 * 60 * 1000, // 10 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api', limiter);

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

// Handle transaction claim endpoint
app.post('/api/transactions/claim', authenticate, (req, res) => {
  const transactionController = require('./controllers/transaction.controller');
  return transactionController.claimRejectedTransaction(req, res);
});

app.use('/api/transactions', transactionRoutes);  // Handle other transaction routes

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
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: 'Internal Server Error',
    error: err.message
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

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Server is running' });
});

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

// Connect to MongoDB
const connectDB = require('./config/database');
connectDB();

// MongoDB connection events are handled in config/database.js

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

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
      { expiresIn: '7d' }
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

// Root endpoint for health/status
app.get('/', (req, res) => {
  res.status(200).json({
    status: 'ok',
    message: 'Bitcoin Cloud Mining API is running',
    version: '1.0.0'
  });
});

// Start server
const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  logger.info(`Server running on port ${PORT}`);
  console.log('\n\x1b[32m%s\x1b[0m', '🚀 Server is running on port:', PORT);
  console.log('\x1b[36m%s\x1b[0m', '🌐 Environment:', process.env.NODE_ENV || 'development');
  console.log('----------------------------------------\n');
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  logger.error('Unhandled Rejection:', err);
  process.exit(1);
});

module.exports = { app, server };
