const mongoose = require('mongoose');

const socialMediaSchema = new mongoose.Schema({
  platform: {
    type: String,
    required: true,
    enum: ['instagram', 'twitter', 'telegram', 'facebook', 'youtube', 'tiktok'],
    unique: true
  },
  handle: {
    type: String,
    required: true
  },
  url: {
    type: String,
    required: true
  },
  rewardAmount: {
    type: String,
    required: true,
    default: '0.000000000000010000'
  },
  isActive: {
    type: Boolean,
    default: true
  },
  verificationMethod: {
    type: String,
    enum: ['api', 'webhook', 'manual'],
    default: 'manual'
  },
  apiCredentials: {
    clientId: String,
    clientSecret: String,
    accessToken: String
  },
  webhookUrl: String,
  lastVerified: Date,
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Update timestamp on save
socialMediaSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('SocialMedia', socialMediaSchema); 