const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const cors = require('cors');
const logger = require('./utils/logger');

// Load environment variables
dotenv.config({ path: './config.env' });

// Initialize models first
try {
    require('./models');
    logger.info('Models initialized successfully');
} catch (error) {
    logger.error('Error initializing models:', error);
    process.exit(1);
}

// Import routes after models are initialized
const authRoutes = require('./routes/auth.routes');
const walletRoutes = require('./routes/wallet.routes');
const marketRoutes = require('./routes/market.routes');
const transactionRoutes = require('./routes/transaction.routes');
const AppError = require('./utils/appError');
const globalErrorHandler = require('./middleware/error.middleware');

const app = express();

// Pre-flight request handling
app.options('*', cors());

// CORS middleware
app.use(cors());

// Body parser middleware with increased limit
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// MongoDB connection is handled in server.js
// Removed duplicate connection to prevent conflicts

// Routes
logger.info('Registering routes...');
app.use('/api/auth', authRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/market', marketRoutes);
logger.info('Registering transaction routes at /api/transactions');
app.use('/api/transactions', transactionRoutes);
logger.info('Routes registered successfully');

// Global error handler
app.use(globalErrorHandler);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});