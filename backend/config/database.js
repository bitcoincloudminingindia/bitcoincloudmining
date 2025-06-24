const mongoose = require('mongoose');
const logger = require('../utils/logger');

// Singleton instance to track connection state
let instance = null;

// Track initialization state
let isInitialized = false;

const connectDB = async () => {
  if (instance) {
    return instance;
  }

  try {
    const mongoURI = process.env.MONGODB_URI;
    console.log('\n🔄 Connecting to MongoDB...');
    console.log('📡 URI:', mongoURI.replace(/:[^:]*@/, ':***@'));

    // Configure Mongoose
    mongoose.set('strictQuery', false);

    // Connect to MongoDB
    const conn = await mongoose.connect(mongoURI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      serverSelectionTimeoutMS: 5000
    });

    console.log('\n✅ MongoDB Connected Successfully!');
    console.log('📊 Database:', conn.connection.name);
    console.log('🖥️  Host:', conn.connection.host);
    console.log('🌐 Port:', conn.connection.port);
    console.log('----------------------------------------\n');

    instance = conn;
    isInitialized = true;
    return instance;
  } catch (error) {
    console.error('\n❌ MongoDB Connection Error:', error.message);
    console.error('Stack:', error.stack);
    console.log('----------------------------------------\n');
    process.exit(1);
  }
};

// Add MongoDB connection event handlers
mongoose.connection.on('connected', () => {
  console.log('🟢 MongoDB connection established');
});

mongoose.connection.on('error', (err) => {
  console.error('🔴 MongoDB connection error:', err);
});

mongoose.connection.on('disconnected', () => {
  console.log('🟡 MongoDB connection disconnected');
});

process.on('SIGINT', async () => {
  try {
    await mongoose.connection.close();
    console.log('MongoDB connection closed through app termination');
    process.exit(0);
  } catch (err) {
    console.error('Error closing MongoDB connection:', err);
    process.exit(1);
  }
});

module.exports = connectDB;