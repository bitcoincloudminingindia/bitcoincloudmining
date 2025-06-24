const { Wallet } = require('../models');
const { formatBTC } = require('./format');
const logger = require('./logger');

// Centralized wallet initialization utility
exports.initializeWallet = async (userId) => {
    try {
        logger.info('Initializing new wallet for user:', { userId });
        const wallet = await Wallet.create({
            userId,
            balance: formatBTC('0'),
            currency: 'BTC',
            transactions: [],
            balanceHistory: [{
                balance: formatBTC('0'),
                timestamp: new Date(),
                type: 'initialization'
            }]
        });
        logger.info('Wallet initialized successfully:', { userId, walletId: wallet._id });
        return wallet;
    } catch (error) {
        logger.error('Error initializing wallet:', { error, userId });
        throw error;
    }
};

// Get or create wallet utility
exports.getOrCreateWallet = async (userId, session = null) => {
    try {
        // Find existing wallet, optionally using session
        const query = { userId };
        const options = session ? { session } : {};

        let wallet = await Wallet.findOne(query, null, options);

        // Create new wallet if not found
        if (!wallet) {
            wallet = new Wallet({
                userId,
                balance: '0.000000000000000000',
                pendingBalance: '0.000000000000000000',
                currency: 'BTC',
                transactions: [],
                balanceHistory: [{
                    balance: '0.000000000000000000',
                    timestamp: new Date(),
                    type: 'initial'
                }]
            });

            if (session) {
                await wallet.save({ session });
            } else {
                await wallet.save();
            }

            logger.info('Created new wallet:', { userId, walletId: wallet._id });
        }

        return wallet;
    } catch (error) {
        logger.error('Error in getOrCreateWallet:', error);
        throw error;
    }
};