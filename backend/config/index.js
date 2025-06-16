require('dotenv').config();

const config = {
  port: process.env.PORT || 5000,
  corsOptions: {
    origin: ['http://localhost:3000', 'http://10.0.2.2:3000', 'http://localhost'],
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Platform', 'X-App-Version']
  },
  mongoUri: process.env.MONGO_URI || 'mongodb://localhost:27017/bitcoin_mining',
  jwtSecret: process.env.JWT_SECRET || 'your-secret-key'
};

module.exports = config;