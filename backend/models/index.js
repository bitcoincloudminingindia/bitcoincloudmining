const mongoose = require('mongoose');
const logger = require('../utils/logger');

// Model registration state tracking
let modelsRegistered = false;

// Define model names
const MODEL_NAMES = {
  USER: 'User',
  WALLET: 'Wallet',
  TRANSACTION: 'Transaction',
  WITHDRAWAL: 'Withdrawal'
};

function validateModel(model, name) {
  if (!model || typeof model.findOne !== 'function') {
    throw new Error(`Model ${name} not registered correctly or missing required methods`);
  }
  return model;
}

function registerModels() {
  if (modelsRegistered) {
    return;
  }

  try {
    logger.info('Starting model registration');

    // Import all schemas first
    const schemas = {
      User: require('./user.model'),
      Wallet: require('./wallet.model'),
      Transaction: require('./transaction.model'),
      Withdrawal: require('./withdrawal.model')
    };

    // Create models object to store registered models
    const models = {};

    // Register User model first since others depend on it
    if (!mongoose.models[MODEL_NAMES.USER]) {
      models.User = mongoose.model(MODEL_NAMES.USER, schemas.User);
      logger.info('Registered User model');
    } else {
      models.User = mongoose.models[MODEL_NAMES.USER];
    }

    // Register Wallet model
    if (!mongoose.models[MODEL_NAMES.WALLET]) {
      models.Wallet = mongoose.model(MODEL_NAMES.WALLET, schemas.Wallet);
      logger.info('Registered Wallet model');
    } else {
      models.Wallet = mongoose.models[MODEL_NAMES.WALLET];
    }

    // Register Transaction model
    if (!mongoose.models[MODEL_NAMES.TRANSACTION]) {
      models.Transaction = mongoose.model(MODEL_NAMES.TRANSACTION, schemas.Transaction);
      logger.info('Registered Transaction model');
    } else {
      models.Transaction = mongoose.models[MODEL_NAMES.TRANSACTION];
    }

    // Register Withdrawal model
    if (!mongoose.models[MODEL_NAMES.WITHDRAWAL]) {
      models.Withdrawal = mongoose.model(MODEL_NAMES.WITHDRAWAL, schemas.Withdrawal);
      logger.info('Registered Withdrawal model');
    } else {
      models.Withdrawal = mongoose.models[MODEL_NAMES.WITHDRAWAL];
    }

    // Validate all models have required methods
    Object.entries(models).forEach(([name, model]) => {
      validateModel(model, name);
    });

    modelsRegistered = true;
    logger.info('All models registered and validated successfully');

    return models;

    modelsRegistered = true;
    logger.info('All models registered and validated successfully');

  } catch (error) {
    logger.error('Error registering models:', error);
    modelsRegistered = false;
    throw error;
  }
}

// Initialize models and get references
const models = registerModels();

// Ensure all models are available before exporting
if (!models || !models.User || !models.Wallet || !models.Transaction || !models.Withdrawal) {
  throw new Error('Failed to initialize all required models');
}

// Export the registered models
module.exports = {
  User: models.User,
  Wallet: models.Wallet,
  Transaction: models.Transaction,
  Withdrawal: models.Withdrawal
};