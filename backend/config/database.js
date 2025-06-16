const mongoose = require('mongoose');
const logger = require('../utils/logger');

// Singleton instance to track connection state
let instance = null;

// Track initialization state
let isInitialized = false;
let indexesInitialized = false;

const initializeIndexes = async () => {
  if (indexesInitialized) {
    console.log('ℹ️ Indexes already initialized');
    return;
  }

  try {
    console.log('🔄 Initializing database indexes...');

    // Initialize indexes for collections
    const collections = ['wallets', 'users', 'transactions'];

    for (const collection of collections) {
      console.log(`🔧 Managing ${collection} collection indexes...`);

      // Get current indexes
      const currentIndexes = await mongoose.connection.db
        .collection(collection)
        .indexes();

      // Define required indexes for each collection
      const indexes = {
        wallets: [
          { key: { walletId: 1 }, unique: true, background: true },
          { key: { userId: 1 }, unique: true, background: true }
        ],
        users: [
          { key: { userId: 1 }, unique: true, background: true },
          { key: { userName: 1 }, unique: true, background: true },
          { key: { userEmail: 1 }, unique: true, background: true }
        ],
        transactions: [
          { key: { transactionId: 1 }, unique: true, background: true },
          { key: { userId: 1 }, background: true },
          { key: { timestamp: -1 }, background: true }
        ]
      };

      // Create required indexes if they don't exist
      const requiredIndexes = indexes[collection] || [];
      if (requiredIndexes.length > 0) {
        await mongoose.connection.db
          .collection(collection)
          .createIndexes(requiredIndexes);
        console.log(`✅ Created indexes for ${collection} collection`);
      }
    }

    indexesInitialized = true;
    console.log('✅ All database indexes initialized successfully');

  } catch (error) {
    console.error('❌ Error initializing database indexes:', error);
    // Don't throw error to prevent connection issues
  }
};

const connectDB = async () => {
  if (isInitialized) {
    console.log('ℹ️ Database connection already initialized');
    return;
  }

  try {
    const options = {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      serverSelectionTimeoutMS: 30000,
      socketTimeoutMS: 45000,
      maxPoolSize: 10,
      retryWrites: true,
      retryReads: true,
      w: 'majority'
    };

    console.log('🔄 Connecting to MongoDB...');
    // Don't log full URI in production for security
    console.log('📡 URI:', process.env.MONGODB_URI?.replace(/\/\/([^@]+@)?/, '//***:***@'));

    await mongoose.connect(process.env.MONGODB_URI, options);

    mongoose.connection.removeAllListeners();

    mongoose.connection.on('connected', async () => {
      isInitialized = true;
      console.log('✅ MongoDB Connected Successfully!');
      console.log('📊 Database:', mongoose.connection.name);
      console.log('🔌 Host:', mongoose.connection.host);
      console.log('📝 Port:', mongoose.connection.port);

      if (!indexesInitialized) {
        await initializeIndexes();
      }
    });

    mongoose.connection.on('error', (err) => {
      logger.error('❌ MongoDB Connection Error:', err);
    });

    mongoose.connection.on('disconnected', () => {
      logger.warn('⚠️ MongoDB Disconnected');
      isInitialized = false;
      indexesInitialized = false;
    });

    // The following duplicate block was removed to fix syntax error

    // Handle application termination
    process.on('SIGINT', async () => {
      try {
        await mongoose.connection.close();
        logger.info('MongoDB connection closed through app termination');
        process.exit(0);
      } catch (err) {
        logger.error('Error during MongoDB connection closure:', err);
        process.exit(1);
      }
    });

    isInitialized = true;

  } catch (error) {
    logger.error('❌ MongoDB Connection Error:', error);
    console.error('❌ MongoDB Connection Error:', error);
    process.exit(1);
  }
};

module.exports = connectDB;